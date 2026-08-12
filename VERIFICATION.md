# Verification report — v2.6.5

## Release identity

- Manifest version: `2.6.5`
- `games = ["gen1", "gold"]`
- `experimental = false`
- No `game_version` release-number gate

## Live-approved Gen 3 UI presentation

- **Gen 1 fixed footer column: LIVE PASS** — approved TEST F.
- **Gold fixed footer column: LIVE PASS** — approved Gold fixed-footer test.
- Both paths keep the first letter of `PHYSICAL / SPECIAL / STATUS` on a stable footer-local X derived from the literal `TYPE` landmark instead of variable type/PP content.

## Source preservation checks

- Final Gen 1 runtime section matches the live-approved TEST F implementation after normalizing only the release number.
- Final Gold pre-Gen1 runtime section matches the live-approved Gold fixed-footer implementation after normalizing only the release number.

## Automated verification

- Full bundled `bash tools/run_all.sh`: **PASS** before packaging.
- Final ZIP is extracted into a fresh directory and the full suite is run again before delivery.
- Gold contract includes a regression where PP moves horizontally while the category first-letter X remains on the fixed footer column.
- Gen 1 runtime contract includes varying TYPE values, PP positions, and PP transforms while the category first-letter X remains on the fixed footer column.

## Known audit limitation

The official upstream `modkit.py gen2check --notes` command remains unavailable in this workspace because an executable current upstream checkout/tool is not present. The package does not falsely claim that command as PASS; see `GEN2CHECK_STATIC_AUDIT.md`.
