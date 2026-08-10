#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
python3 tools/verify_reference.py
python3 tools/verify_second_source.py
python3 tools/verify_battle_math.py
python3 tools/verify_gen4_move_categories.py
python3 tools/verify_generation_audit.py
python3 tools/verify_source_contract.py
python3 tools/verify_link_config.py
texlua tests/reference_contract.lua
texlua tests/runtime_stub_contract.lua gen2 gen4 off on
texlua tests/runtime_stub_contract.lua gen2 gen4 off off
STANDALONE_MOVE_CATEGORY=1 texlua tests/runtime_stub_contract.lua gen2 gen4 off on
STANDALONE_MOVE_CATEGORY=1 texlua tests/runtime_stub_contract.lua gen2 gen4 off off
if [[ -n "${REAL_MOVE_CATEGORY_MAIN:-}" ]]; then
  echo "REAL MOVE CATEGORY COEXIST CONTRACT: ${REAL_MOVE_CATEGORY_MAIN}"
  REAL_MOVE_CATEGORY_MAIN="$REAL_MOVE_CATEGORY_MAIN" texlua tests/runtime_stub_contract.lua gen2 gen4 off on
  REAL_MOVE_CATEGORY_MAIN="$REAL_MOVE_CATEGORY_MAIN" STANDALONE_MOVE_CATEGORY_ENABLED=0 texlua tests/runtime_stub_contract.lua gen2 gen4 off on
  REAL_MOVE_CATEGORY_MAIN="$REAL_MOVE_CATEGORY_MAIN" texlua tests/runtime_stub_contract.lua gen2 gen4 off off
fi
texlua tests/runtime_stub_contract.lua gen2 gen4 on on
texlua tests/runtime_stub_contract.lua gen2 gen1 off on
texlua tests/runtime_stub_contract.lua vanilla gen4 on on
texlua tests/runtime_stub_contract.lua vanilla gen1 off on
NO_MODERN_UI=1 texlua tests/runtime_stub_contract.lua gen2 gen4 on on
MODERN_UI_VERSION=0.9.9 MODERN_UI_API=1 texlua tests/runtime_stub_contract.lua gen2 gen4 on on
MODERN_UI_VERSION=0.9.9 MODERN_UI_API=2 texlua tests/runtime_stub_contract.lua gen2 gen4 on on
if [[ -n "${MODERN_UI_MAIN:-}" ]]; then
  echo "REAL GEN1 MODERN UI CONTRACT: ${MODERN_UI_MAIN}"
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=on texlua tests/runtime_stub_contract.lua gen2 gen4 off on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=on MODERN_UI_PARTY_LAYOUT=one_row texlua tests/runtime_stub_contract.lua gen2 gen4 off on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=on texlua tests/runtime_stub_contract.lua gen2 gen4 on on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=off texlua tests/runtime_stub_contract.lua gen2 gen4 off on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=off texlua tests/runtime_stub_contract.lua gen2 gen4 on on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=on texlua tests/runtime_stub_contract.lua gen2 gen1 off on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=on texlua tests/runtime_stub_contract.lua vanilla gen4 on on
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_OVERRIDE=off texlua tests/runtime_stub_contract.lua vanilla gen1 off on
  echo "FUTURE VERSION-NUMBER COMPAT CONTRACT: same renderer exposed as 0.9.9"
  MODERN_UI_MAIN="$MODERN_UI_MAIN" MODERN_UI_VERSION=0.9.9 MODERN_UI_OVERRIDE=on texlua tests/runtime_stub_contract.lua gen2 gen4 off on
fi
texlua tests/crystal251_contract.lua gen4
texlua tests/crystal251_contract.lua gen1
if [[ $# -ge 1 ]]; then
  FROZEN="$1"
  python3 tools/verify_frozen_sources.py "$FROZEN"
  texlua tests/frozen_link_fingerprint_contract.lua "$FROZEN"
  texlua tests/frozen_upstream_contract.lua "$FROZEN" gen2
  texlua tests/frozen_upstream_contract.lua "$FROZEN" vanilla
  texlua tests/frozen_save_contract.lua "$FROZEN"
  texlua tests/frozen_lifecycle_contract.lua "$FROZEN"
else
  echo 'NOTE: frozen upstream integration skipped; pass Gen1Recomp 60cf07f root to run it.'
fi
