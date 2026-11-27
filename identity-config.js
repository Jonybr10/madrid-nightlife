// Public configuration only; never publish service_role, OAuth secrets or personal data.
// Activation requires an approved controller notice, terms, DB policy version, RLS tests and private host.
// The privateHostingVerified flag is only a release checklist gate, NOT server-side access control.
window.AAA_IDENTITY_CONFIG = Object.freeze({
  enabled: false,
  environment: "unconfigured",
  testPasswordEnabled: false,
  privateHostingVerified: false,
  url: "",
  publishableKey: "",
  providers: [],
  privacyNoticeUrl: "",
  privacyNoticeVersion: "",
  privacySummary: "",
  termsUrl: ""
});
