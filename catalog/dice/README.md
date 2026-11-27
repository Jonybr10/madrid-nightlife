# AAA · DICE global discovery catalog

Source: user-provided DICE directory screenshot PDFs captured 2026-11-27.
The artist PDF contains **A only** (31 pages); the venues PDF spans A–Z and numeric entries (75 pages, final page footer).
These are **staging OCR candidates**, not verified DICE entity IDs or confirmed active venues.

- `artists.json`: compact rows with named `fields` in the header.
- `venues.json`: compact rows with named `fields` in the header, original OCR address, geographical candidates.
- `review.json`: fragments and ambiguous records excluded from ordinary candidates.
- `manifest.json`: extraction coverage, counts, source metadata and status.

Use the `fields` header to decode each row. Stable *snapshot row* identifiers are constructed as
`dice:2026-11-27:<artist|venue>:p<page>:c<column>:r<row>`.
These are not DICE profile IDs. A duplicate spelling may correspond to two different profiles.
Do not deduplicate artists by name alone or merge venues solely by name.
OCR confidence is text-recognition confidence, not factual verification; even high-confidence rows can contain errors.
A venue record may be a concert hall, church, festival site, temporary address, club or another event space.
Country and city candidates come only from address text and need validation before use as canonical geographic entities.
No coordinates, styles, capacities, events, promoter relationships or activity status are inferred from directory inclusion.
Keep the Madrid operational `agenda.json` separate. Link global rows to existing AAA entities only after identity verification.
A future city selector must scope agenda events by verified city/metro identifiers; artist profiles remain global.
