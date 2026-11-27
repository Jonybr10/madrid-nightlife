# AAA founder identities

Status: source only; no Auth account, password or real identity has been provisioned. The public Pages configuration remains disabled. Use two separate private projects, production and staging, and approved terms/privacy versions. Do not use real Google/Spotify identities in synthetic fixtures.

| Persona | Environment | Account address | Intended access | Avatar motif |
|---|---|---|---|---|
| Founder Prime | production | user's verified real address, not prefilled | owner + admin + experience + operations + catalog + cron | gold crown / FP |
| Founder Systems | staging | founder-systems@example.com | admin, operations, catalog, cron; no experience | graphite shield / FS |
| Founder Experience | staging | founder-experience@example.com | client, experience only | gold headphones / FE |
| Founder Testing | staging | founder-testing@example.com | client, experience only; no optional consents initially | slate flask / FT |

Addresses at example.com are reserved illustrative identities; they cannot receive email. Use password sign-in in staging only. Do not send actual email to them. No copied real photo, location, personal preferences, payment data or provider identities. Populate fictional preferences separately via the normal consent and onboarding flows. To verify unauthorized account access, disable the QA fixture or use separate temporary least-privilege test users.

## Real owner bootstrap
After private deployment and prior migrations, an authorized database operator configures the production environment row (kind=production). Founder Prime registers personally with a configured identity provider or verified email and completes current terms, notice and adult declaration. The trusted operator verifies the actual UUID and calls aaa_private.appoint_initial_founder(UUID). The singleton owner cannot be demoted by another application admin or by self-edit; only the owner may assign other admins. An authorized recovery/ownership transfer procedure is required before founder account deletion, without removing GDPR rights. Enroll TOTP and keep recovery methods and provider accounts secure. Spotify linking remains pending provider eligibility/policy; never enter OAuth credentials directly into the platform.

## Synthetic accounts
In a separate staging project apply migrations and set environment kind=staging by a trusted DB operator. Use the normal approved test policy and private staging origin. The script scripts/provision_staging_accounts.py checks explicit staging environment, exact project reference and a database-side service-only assertion before creating identities. Set environment variables AAA_ENV=staging, AAA_STAGING_PROJECT_REF, AAA_SUPABASE_URL, AAA_STAGING_SERVICE_ROLE_KEY (legacy service-role JWT from a secure secret manager), AAA_FIXTURE_CREDENTIAL_FILE (outside repository). Run manually, never in public CI. The file is exclusively created with mode 0600 and contains independent cryptographically random passwords; move them to a password manager and remove the file. Auth stores password hashes, not plaintext. If any operation fails, inspect private state and reconcile rather than re-run blindly. No credentials printed or committed.

Configure staging-only account page password form with environment=staging and testPasswordEnabled=true after other release gates. Staging RPC validates the admin-assigned fixture marker and exact reserved email. No fixture RPC permitted in production. Systems admin must enroll MFA and complete onboarding; cannot change owner or grant administrator roles. Experience and Testing have identical base permissions initially to test separation; use different synthetic preferences and lifecycle states. Test positive and negative cases with both accounts. Never enable the password test form on public Pages or production. Avatar motifs are proposed design tokens only, not generated photos.
