// Public configuration only; never publish service_role, OAuth secrets or personal data.
// Activation requires an approved controller notice, terms, DB policy version, RLS tests and private host.
// The privateHostingVerified flag is only a release checklist gate, NOT server-side access control.
window.AAA_IDENTITY_CONFIG = Object.freeze({
  enabled: false,
  environment: "unconfigured",
  testPasswordEnabled: false,
  privateHostingVerified: false,
  url: "https://eqmxqgctdfzrbvsqenuo.supabase.co",
  publishableKey: "sb_publishable_xFArNiZO6NM9hZJNEnjzdg_6wjQklgN",
  providers: ["google"],
  privacyNoticeUrl: "",
  privacyNoticeVersion: "",
  privacySummary: "",
  termsUrl: ""
});
