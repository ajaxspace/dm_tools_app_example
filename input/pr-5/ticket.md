# pr-5: gh-4 fork-e2e: add a marker file to verify the forked machine loop end-to-end

## Description

Closes #4
### What changed
Added `FORK_E2E_MARKER.md` at the repo root containing one line: `fork e2e round 1 — 2026-10-21`, per gh-4 (round-1 e2e verification of the forked machine loop).

### Key decisions
- Marker only — no production code touched; gh-2 login implementation remains untouched on `main`.

### How to verify
```bash
cat FORK_E2E_MARKER.md   # fork e2e round 1 — 2026-10-21
git log origin/main..HEAD --oneline
```
