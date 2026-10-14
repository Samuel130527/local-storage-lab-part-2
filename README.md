# Local Storage Lab Part II — Flutter + SQLite

**Student:** Samuel Raju Parisa  
**Student ID:** [ENTER YOUR STUDENT ID]  
**Course:** Mobile Application Development — In-Class Activity 09  
**Pathway:** Graduate  
**Repository:** https://github.com/Samuel130527/local-storage-lab-part-2

## Overview

This project extends the Part I guest-roster app with a folder/card catalogue using Flutter and SQLite (`sqflite`). The Part I guest table is retained while the database schema is upgraded to version 2. The catalogue has parent `folders` and child `cards` tables, with a foreign key from `cards.folder_id` to `folders.id` and `ON DELETE CASCADE`.

## Implementation summary

- Database version: 2.
- Part I guest table and CRUD screen retained.
- `folders` stores folder IDs, unique names, and creation timestamps.
- `cards` stores card IDs, title, suit, notes, nullable `image_ref`, and `folder_id`.
- `idx_cards_folder_id` is intended to support folder-based card lookups.
- Foreign keys are enabled on database connection configuration.
- Model and repository/helper layers separate data access from the UI.
- A suit-symbol fallback is displayed when an image reference is null or unavailable.
- Release build command: `flutter build apk --release`.

## Evidence files

Keep these files in the `evidence/` directory and ensure they are committed to the repository:

- `T1_before.png` — original Part I data captured **before** migration. Do not recreate or relabel a later screenshot as pre-migration evidence.
- `T2_cards.png` — upgraded catalogue showing cards.
- `T4_after.png` — catalogue after a genuine force-stop and relaunch without clearing app data.
- `T3_folders.png` — optional folder-list evidence.
- `analysis_output.txt` — actual output of `flutter analyze`.

## Observed app data

These are observations reported from the app screenshots; verify the screenshots match before submission.

### Part I guests

| Guest ID | Name |
|---:|---|
| 2 | River |
| 3 | Acron |
| 4 | Oak |

The updated Guests screen continued to display these three records.

### Catalogue sample

| Folder | Folder ID | Card count shown |
|---|---:|---:|
| Fall Festival | 1 | 3 |

| Card ID | Title | Suit | Notes / image |
|---:|---|---|---|
| 1 | Welcome | Hearts | Notes shown in app; image reference was null |
| 2 | Food Booth | Diamonds | Notes shown in app; image reference was null |
| 3 | Music stage | Clubs | Notes shown in app; image reference was null |

The app displayed the suit fallback for a null image reference. Replace or correct these values if your saved evidence shows anything different.

## Test matrix — record actual results

**Important:** Do not mark a test PASS merely because the app builds or a screen looks correct. Fill in the Observed result and Status after performing the test. Write `NOT RUN` or `UNVERIFIED` when it has not been performed.

| Test | Action | Expected result | Observed result / evidence | Status |
|---|---|---|---|---|
| T1a — Upgrade existing database | Launch the updated app on the existing Part I installation. Compare original guest IDs and values before and after. | Existing Part I rows and values remain; new tables/index are created. | Updated Guests screen showed River (ID 2), Acron (ID 3), Oak (ID 4). Screenshot: `evidence/T1_before.png` and post-upgrade screenshot. Database PRAGMA/schema diagnostics still need to be recorded if not already captured. | PARTIAL — UI preservation observed; verify schema diagnostics |
| T1b — Fresh database | Use a separate disposable target/installation, not the only installation holding Part I data. | Fresh database creates Part I and catalogue schema; empty folder query works. | [Record target, schema version, tables, foreign-key and index query results.] | NOT RUN unless actually tested |
| T2 — Parent/child create | Create two sample folders (Atlas and Harbor), add two Compass cards to Atlas and one Signal card to Harbor. Record actual IDs and per-folder counts. | Three distinct card IDs; Atlas count 2 and Harbor count 1; cards only appear under their selected folder. | Current reported sample is Fall Festival (folder ID 1) with Welcome (ID 1), Food Booth (ID 2), and Music stage (ID 3), count 3. The exact Atlas/Harbor scenario has not been reported as performed. | PARTIAL — catalogue CRUD shown; specified T2 scenario not verified |
| T3 — Edit identity | Edit one Compass and save; edit the other and cancel. | Only the saved target row changes; cancel writes nothing; counts unchanged. | [Record card IDs, before/after values, affected-row count, and evidence.] | NOT RUN unless actually tested |
| T4 — Restart persistence | Record IDs/counts, force-stop the app through system App Info (not Clear storage), relaunch the same installation. | Same folders, card IDs, values, and counts; no duplicate records. | User reported completing force-stop/relaunch and checking the folder and cards remained. Folder screenshot showed Fall Festival (ID 1), count 3. Add exact before/after comparison and screenshot path. | PARTIAL — persistence reported; complete evidence comparison |
| T5 — Card delete and folder cascade | Use disposable sample data. Cancel a card delete, then confirm it. Cancel a folder delete, then confirm it. Query remaining cards. | Cancel changes nothing; card delete affects one row; folder delete removes the parent and its child cards, while unrelated folder/cards remain. | No deletion result has been reported. Do not use the only sample folder if its records are needed. | NOT RUN unless actually tested |
| T6 — Validation and image fallback | Open a card with null `image_ref`; try whitespace-only title, blank folder name, and duplicate folder name. | Suit fallback appears; invalid inputs show feedback and do not change rows/counts. | Screenshot showed `Image: null` with suit fallback. Invalid-input checks have not been reported. | PARTIAL — null fallback observed; validation tests unverified |

## Analyzer and build

Run the analyzer and save its real output:

```powershell
flutter analyze 2>&1 | Tee-Object -FilePath .\evidence\analysis_output.txt
```

Observed analyzer output:

```text
Analyzing local_storage_lab...
No issues found! (ran in 2.6s)
```

Build the release APK:

```powershell
flutter build apk --release
```

Observed build result: `Built build\app\outputs\flutter-apk\app-release.apk (48.4MB)`.

The analyzer/build results establish static analysis and build success; they do not establish that all database tests passed.

## Read-only schema diagnostics to record

Run diagnostics through a safe debug/helper path against the actual database and paste the actual results below. Do not invent results.

- `PRAGMA user_version;` — actual schema version: `[RECORD RESULT]`
- `PRAGMA foreign_keys;` on the open connection — expected `1`; actual: `[RECORD RESULT]`
- `PRAGMA foreign_key_list(cards);` — confirm reference to `folders(id)` and delete rule; actual: `[RECORD RESULT]`
- `PRAGMA index_list(cards);` — confirm `idx_cards_folder_id`; actual: `[RECORD RESULT]`
- Read-only query of original Part I guest rows before/after — attach actual result or source location: `[RECORD RESULT]`

## How to reproduce

1. Install Flutter and Android tooling for a supported mobile target.
2. From the project root, run `flutter pub get`.
3. Run `flutter analyze`.
4. Run `flutter run` on a supported Android/iOS target.
5. Open Guests to inspect Part I records.
6. Open Catalogue to create folders and cards.
7. Use fictional data only. Test destructive cascade behavior only with disposable sample folders.
8. For T4, force-stop and relaunch the same installation without clearing storage or uninstalling.
9. Run `flutter build apk --release` for the Android release APK.

## Reflection document

See `Parisa_Samuel_CriticalThinking.docx` in the separate iCollege submission. The reflection discusses failure diagnosis, cascade trade-offs, image fallback, and a proposed version-3 migration. G2 and G4 claim text must be copied exactly from the course activity page. The version-3 change is a design proposal only and has not been implemented.

## AI-use disclosure

AI assistance was used to help structure and review the reflection and README. The submitted reflection identifies the tool, date, prompt summary, a short excerpt, and a claim to verify. Student-specific observations and all test statuses must be checked against the actual app and evidence before submission.
