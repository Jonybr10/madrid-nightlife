#!/usr/bin/env python3
"""Create only synthetic AAA accounts in an explicitly approved staging project.

Run manually in a trusted environment after all SQL migrations.
Never run in GitHub Actions or against production. No credential logging.
The service-role credential must be injected by a secure secret manager.
"""
import json, os, pathlib, secrets, sys, urllib.request, urllib.error

PERSONAS = ("founder_systems", "founder_experience", "founder_testing")

def main():
    if os.environ.get("AAA_ENV") != "staging":
        raise SystemExit("Refusing: AAA_ENV must equal staging.")
    ref = os.environ["AAA_STAGING_PROJECT_REF"]
    url = os.environ["AAA_SUPABASE_URL"].rstrip("/")
    if len(ref) != 20 or not ref.isalnum() or url != "https://" + ref + ".supabase.co":
        raise SystemExit("Refusing: project URL does not match staging project reference.")
    key = os.environ["AAA_STAGING_SERVICE_ROLE_KEY"]
    output = pathlib.Path(os.environ["AAA_FIXTURE_CREDENTIAL_FILE"]).expanduser().resolve()
    repo = pathlib.Path(__file__).resolve().parent.parent
    if output == repo or repo in output.parents:
        raise SystemExit("Credential file must be outside repository.")
    if not output.parent.is_dir():
        raise SystemExit("Credential destination directory must exist.")
    if output.exists():
        raise SystemExit("Credential file already exists; do not overwrite or rotate automatically.")
    def request(path, payload):
        req = urllib.request.Request(url+path, data=json.dumps(payload).encode(), method="POST",
            headers={"apikey":key, "Authorization":"Bearer "+key, "Content-Type":"application/json"})
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                return json.load(response)
        except urllib.error.HTTPError as exc:
            raise RuntimeError("API rejected request (HTTP "+str(exc.code)+"). No response body logged.") from None
    # Fail closed before creating identities if the database is not marked staging.
    # The RPC must deny an invalid fixture, so use the dedicated staging assertion.
    request("/rest/v1/rpc/aaa_assert_staging", {})
    records = [{"persona":p,"email":p.replace("_","-")+"@example.com",
                "password":secrets.token_urlsafe(36)+"aA1!","status":"not_created"} for p in PERSONAS]
    # Create secure file before network calls; retain any generated password even on partial failure.
    flags = os.O_WRONLY|os.O_CREAT|os.O_EXCL
    if hasattr(os,"O_NOFOLLOW"): flags |= os.O_NOFOLLOW
    fd = os.open(output,flags,0o600)
    with os.fdopen(fd,"w",encoding="utf-8") as f:
        def persist():
            f.seek(0); json.dump(records,f,indent=2); f.truncate(); f.flush(); os.fsync(f.fileno())
        persist()
        for row in records:
            row["status"]="creation_requested"; persist()
            result=request("/auth/v1/admin/users", {"email":row["email"],"password":row["password"],
                "email_confirm":True,"app_metadata":{"aaa_fixture":row["persona"]}})
            row["user_id"]=result["id"]; row["status"]="created_pending_permissions"; persist()
            request("/rest/v1/rpc/aaa_provision_fixture", {"p_user":row["user_id"],"p_persona":row["persona"]})
            row["status"]="provisioned"; persist()
    print("Three staging identities provisioned. Transfer the local credential file to your password manager; securely remove it afterwards.")
if __name__=="__main__":
    try: main()
    except (KeyError,RuntimeError,ValueError,OSError) as exc:
        print("Provisioning stopped. Check the staging configuration and protected local credential file. No secrets logged.",file=sys.stderr)
        sys.exit(1)
