# legal_case

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Client Dashboard: Court Live Board Integration

The client dashboard now includes a **Court Live Board** section that shows:
- Display board availability
- Hearing timing
- Current queue number of the case
- Case order number
- Reportable / Unreportable label
- District-court fallback when no display board is available
- Last update status (expected daily after 6:00 PM)
- Case scheduling time

### Firestore fields expected on each `booking_requests` document

Required existing fields:
- `clientId`
- `caseNumber`
- `caseTitle`

Court board fields (from scraper/backend):
- `courtName` (String)
- `courtType` (String; e.g. `District Court`, `High Court`, `Supreme Court`)
- `hasDisplayBoard` (bool)
- `hearingTime` (Timestamp)
- `queueNumber` (int)
- `caseOrder` (int)
- `reportability` (String: `Reportable` or `Unreportable`)
- `scheduledDate` (Timestamp)
- `boardText` (String)
- `courtSourceUrl` (String)
- `courtLastUpdatedAt` (Timestamp)

### Scraper flow (recommended)

1. Run a backend scraper job on schedule (daily, 6:00 PM).
2. Fetch court listing/board pages for tracked case numbers.
3. Normalize parsed values into the field schema above.
4. Update matching `booking_requests/{caseId}` docs in Firestore.
5. Client dashboard auto-refreshes through Firestore streams.

### Optional manual sync trigger from app

The dashboard can trigger a backend sync endpoint if configured:
- Add to `.env`: `COURT_SCRAPER_SYNC_URL=https://<your-backend>/court-sync`
- The app sends `clientId`, `caseIds`, and `targetUpdateTime` in POST JSON.

### All-courts display-number page source config

The dashboard toggle opens a page that scrapes all courts with display-number boards.

Configure Firestore collection `court_board_sources` with docs like:

```json
{
	"enabled": true,
	"hasDisplayBoard": true,
	"courtName": "Delhi High Court",
	"courtType": "High Court",
	"sourceUrl": "https://example-court-site/board"
}
```

The scraper supports:
- JSON endpoints (`application/json`) with keys like `displayNumber`, `caseNumber`, `caseOrder`, `caseTiming`
- HTML pages with fallback keyword extraction for display number / case number / order / timing

Only courts with valid display numbers are shown on that page.

### Important note

Court websites may have legal/technical restrictions on scraping. Prefer official APIs or approved data feeds where available, and follow each court portal's terms of use.
