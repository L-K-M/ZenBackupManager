# Working on ZenBackupManager

Native SwiftUI windowed macOS 14+ utility, Xcode 16.2+ synchronized groups.
No package dependencies. See README.md and PLAN.md for behavior and safety.

- One primary type per file; nested helper types are fine.
- Keep profile scanning and disk I/O off the main actor.
- Never test restore against the developer's real Zen profile. Use synthetic
  JSONLZ4 fixtures and temporary directories in tests.
- Keep the restore boundaries exact: only the two root session files may change,
  and only after process checks, profile locking, source verification and a
  verified safety copy. Browser backup directories remain read-only.
- Preserve original compressed bytes, including fields unknown to the preview.
- Refuse unreadable/changed sources and symlinked destinations. Do not relax
  safety invariants to hide an error. Undo checks hashes and profile identity.
- Retain the shared Updates implementation unless a task explicitly changes it.
- Build/release scripts configure the sibling `release-tool` engines.
- Do not commit private profiles, backup files, credentials or build products.

Build/test:

```bash
xcodebuild -project ZenBackupManager.xcodeproj -scheme ZenBackupManager \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

CI mirrors RepoMen. Publication is a separate explicit release action; do not
create or push a release tag as part of ordinary feature work.
