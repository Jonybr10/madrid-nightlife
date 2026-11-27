# AAA — Privacy engineering and RGPD readiness

**Status: preactivation only.** This is a technical and legal readiness checklist, not a published privacy notice, certification, or statement of compliance. Controller identity, lawful bases and retention must be approved before any live account is collected. Apply both SQL migrations to a private staging project; never publish a database dump or user record to GitHub.

## Registration and privacy notice

Provide layered information (GDPR art. 13/14) before calling the identity provider: controller legal name and contact, DPO contact if applicable, purposes and legal bases, recipients/processors, international transfers and safeguards, retention criteria, rights and AEPD complaint, mandatory/optional fields and consequences, source of OAuth data, recommendation logic and effects. The short notice is configured in privacySummary, the complete notice and terms at their real HTTPS URLs. Receipt of information is separate from accepting terms and from specific consent. No prechecked optional box. Register approved immutable notice/terms copies and their version, consent text and timestamp in aaa_private.policy_versions; a change of version requires review before access. Activate exactly one version after approval; never alter the text behind an already recorded version. Age >=18 is a proposed product rule for adult nightlife, not legal digital consent age; it is a self-declaration, not age verification or proof of identity. Evaluate a proportionate age assurance method and account for jurisdiction-specific rules.

## Processing inventory (draft RAT, art. 30)

| Processing | Necessary data | Proposed basis (confirm before launch) | Retention proposal (validate) |
|---|---|---|---|
| Registration, identity, account and authorization | verified email, UUID, adult declaration, terms version, access role | contract/precontractual measures; legal obligation where applicable | active account; pending accounts 30 days |
| Optional saved preferences | alias, coarse territory, language, manually chosen genres/event types/artist IDs/radius | requested account functionality; separate opt-in for recommendations | until removal or account deletion |
| Personal recommendations | selected AAA favorites, optional preferences; no inferred sensitive attributes | consent, freely given and reversible | until withdrawal; no retained computed profile |
| Security, fraud prevention and access audit | minimal access/security events, timestamps, necessary IDs | legitimate interest with balancing assessment or legal obligation as applicable | propose 90 days security logs, 12 months restricted access audit |
| Rights requests and consent evidence | request identifiers, status, deadlines, policy versions and decisions | legal obligation / accountability | only as necessary under applicable limitation and evidence rules |
| Staff and technical access | verified work identity, assigned scopes and audit | applicable work/contract/security basis | disable immediately when relationship ends; retention per security policy |

No marketing, advertising targeting, nonessential analytics, precise location collection, push notifications or Spotify data ingestion in this release. Do not infer sensitive traits or evaluate workers from music preferences. Do not request phone, full date of birth, national ID, address or payment data unless a separate necessary use case is approved. No sharing/selling individual preference data. Future marketing or analytics require distinct opt-ins, LSSI/ePrivacy assessment and real withdrawal endpoints, cookie controls with equally easy reject/accept, and no nonessential storage before consent.

## Engineering / operational gates
- Set up EU data region, confirm processor DPA (art. 28), subprocessors and transfer assessment including any identity, CDN, hosting or mail vendors; EU hosting alone does not eliminate transfers. Record controller, processors and access roles.
- Enforce verified user session and current onboarding on every restricted route and API in private hosting. Check enabled, role, permissions, MFA for privileged staff; never rely on JS flags or public Pages. Separate workers from people; service credentials in managed secret storage, scoped and rotated.
- TLS in transit and verify provider encryption at rest, backups encryption, key management, restoration tests, session timeout/revocation, rate limiting, CAPTCHA, CSP, dependency checks and least privilege. Avoid logs containing OAuth tokens, emails or preferences; protect audit evidence. Staff training and access reviews.
- Before enabling run SQL tests for unauthenticated and two authenticated users, no cross-user reads/writes, inability to modify own role or consent directly, stale policy version rejection, new consent default false, withdrawal history and effect, duplicated open requests, admin MFA, disabled accounts, OAuth and session handling. Test on staging with synthetic records only.
- Rights workflow: access, rectification, deletion, restriction, objection, portability and withdrawal. UI records receipt and initial one-month deadline (art. 12); verify identity proportionately, assign responsible staff, respond securely, document extensions where lawful (notify within initial month), refusals and appeals. Implement actual export of all applicable personal data and deletion/retention/backup propagation; status updates are not fulfilment by themselves. No public tickets or logs with personal details. If deletion is requested, revoke sessions when appropriate and preserve only data legally required.
- Define purge jobs after approved retention policy, including abandoned registration, expired tokens, backup expiry, privacy requests and consent evidence. Test erasure and recovery. No automatic retention jobs active yet.
- Assess risk and need for DPIA (art. 35), especially recommendations/profiling at scale, vulnerable users, location or combining datasets. Maintain risk register, processing inventory, evidence of decisions, DPO necessity assessment and incident plan. Notify supervisory authority within 72 hours where art. 33 requires; notify affected people when art. 34 applies. Document every breach.
- Review GDPR, Spanish LOPDGDD and LSSI and target-country requirements; legal review before worldwide roll-out. No claim of universal compliance.

## Release blockers

1. Controller legal identity/contact, approved notice and terms, permitted age and retention decisions.
2. Connected and configured private backend + approved version row + live route authorization (not GitHub Pages). Separate data and backups; activation flags must remain false on Pages.
3. Provisioned OAuth/SMTP, CAPTCHA, rights fulfilment process, security/RLS and end-to-end tests, risk review/DPIA if required, processor agreements and transfer assessment.
4. Approval by responsible owner, then private deployment. No data collection while any of these gates remains unresolved.

Sources:
- GDPR: https://eur-lex.europa.eu/eli/reg/2016/679/oj/spa
- AEPD information by layers: https://www.aepd.es/derechos-y-deberes/conoce-tus-derechos/derecho-de-informacion
- AEPD processing register: https://www.aepd.es/derechos-y-deberes/cumple-tus-deberes/medidas-de-cumplimiento/actividades-tratamiento
- AEPD consent and privacy clause distinction: https://www.aepd.es/preguntas-frecuentes/2-tus-obligaciones-como-responsable-del-tratamiento/6-el-deber-de-informacion/FAQ-0248-sobre-si-el-usuario-tiene-que-dar-consentimiento-a-clausula-de-privacidad
