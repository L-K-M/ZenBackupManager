# Design and implementation

## Product

A single native SwiftUI window: profile picker and backup timeline on the left,
summary cards, space filters and a tab table on the right. Recovering a session
requires an explicit confirmation showing its date, profile and counts. Read-only
inspection works while Zen is running. Restore waits for the user to quit it.

## Architecture

- `App`: SwiftUI lifecycle, Zen process detection and application launch.
- `Model`: lightweight previews, records, profiles and main-actor app state.
- `Storage`: profile discovery, bounded JSONLZ4 decoding through Compression,
  catalog scan, atomic file writing, profile lock, safety archive and restore.
- `UI`: native split view, dated backup rows, summary cards, searchable table,
  confirmation sheet, status and error states.
- `Updates`: shared GitHub release checker from RepoMen.
- `ZenBackupManagerTests`: synthetic codec and temporary-profile tests.

Scanning and restore I/O run off the main actor. Scans use cancellation and a
request generation to discard results from an obsolete profile. Full decoded JSON
is discarded after constructing a small preview; previews do not retain favicons,
form data, storage, or history beyond the selected entry. No URLs are fetched.

## Write contract

1. Validate the profile and reject symlinked/non-regular destination files.
2. Refuse while Zen is running; acquire and hold a POSIX record lock on
   `.parentlock`, matching Mozilla on macOS. Never force quit or remove its lock.
3. Re-read the selected file and compare SHA-256 with the preview's source hash.
   Decode it again. A changed, corrupt or oversized source cannot restore.
4. Save both existing root session files into a private safety directory. Verify
   their hashes; commit a manifest only after the copies are complete.
5. Modern restore: atomically replace only `zen-sessions.jsonlz4` with the original
   compressed bytes. Legacy restore: install `sessionstore.jsonlz4`, then remove
   the modern file so Zen imports the old session on startup.
6. Verify the installed bytes. On failure, restore both original root files (or
   their absence) using the safety archive. A rollback failure reports its path.
7. Undo verifies the archive and profile identity, creates another safety copy,
   then restores the exact file set. Undo can itself be reversed with Undo Restore.

Writes use a unique same-directory temporary file created with mode 0600, a full
write loop, fsync, then atomic rename. Archives use 0700 directories and 0600 files.
Archives contain a fixed allowlist of session filenames. Other profile files,
including preferences, bookmarks and logins, are never replaced. The browser's
own backup directories are read-only. The lock file may be created if absent.

## Limits

- Individual compressed and uncompressed files are capped at 256 MB.
- Modern previews require `tabs` and `spaces`; legacy previews require `windows`.
  Unknown formats fail closed. Missing history entries display `about:blank`.
- The process check is conservative: all known Zen variants must be closed even
  if a different profile is being restored. Network/symlinked profiles are not
  supported when normal POSIX locking/path validation fails.
- Exact-byte preservation avoids losing unknown metadata. Preview counts cannot
  guarantee how a future Zen release will interpret a legacy session.
- Undo is a saved-file restore, not a merge with browsing since the restore.
- A process crash or power failure between two legacy/undo file changes can leave
  a partial state; the verified archive remains available after relaunch. The
  app does not claim a multi-file filesystem transaction.
- Safety copies have no automatic retention/deletion policy; manage them in Finder.
- Custom folder selections are session-local; normal Zen profiles are rediscovered
  at launch. This initial version does not import arbitrary external backups.

## Manual QA

Read the real installed profile without restoring it. Confirm timeline dates,
space filters, search and large tables. Inspect the restore sheet while Zen runs:
Restore is disabled. Use temporary profiles for all destructive-path tests.
Verify the app at its minimum window size, including an empty/invalid profile.

## Verification (2026-09-11)

- 23 XCTest cases passed on macOS with Xcode 26.6; test restores used temporary
  profiles. A second-process lock contention test also passed.
- Live read-only scan displayed 1,031 tabs across five spaces and the historical
  backups. Searching `github.com` returned 212 tabs; the Work filter narrowed
  that to 87. The restore sheet correctly disabled restoration while Zen ran.
- Screen capture was unavailable from the local computer-use service, so live UI
  checks used accessibility state; screenshot-level visual QA remains manual.
