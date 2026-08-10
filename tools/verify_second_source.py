#!/usr/bin/env python3
"""Cross-check National Dex #001-251 Gen II-V SpA/SpD against a frozen second-source snapshot.

Source: Bulbapedia, "List of Pokémon by base stats in Generations II-V"
https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_base_stats_in_Generations_II-V
Snapshot checked 2026-08-08, National Dex rows 0001-0251, columns Sp. Atk / Sp. Def.

The snapshot is intentionally embedded separately from the production Lua/CSV data so
future edits to the mod data cannot silently update the expected second-source values.
"""
from __future__ import annotations
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_URL = "https://bulbapedia.bulbagarden.net/wiki/List_of_Pok%C3%A9mon_by_base_stats_in_Generations_II-V"
BULBAPEDIA_PAIRS = """65/65 80/80 100/100 60/50 80/65 109/85 50/64 65/80 85/105 20/20 25/25 80/80 20/20 25/25 45/80 35/35 50/50 70/70 25/35 50/70 31/31 61/61 40/54 65/79 50/40 90/80 20/30 45/55 40/40 55/55 75/85 40/40 55/55 85/75 60/65 85/90 50/65 81/100 45/25 75/50 30/40 65/75 75/65 85/75 100/90 45/55 60/80 40/55 90/75 35/45 50/70 40/40 65/65 65/50 95/80 35/45 60/70 70/50 100/80 40/40 50/50 70/90 105/55 120/70 135/85 35/35 50/60 65/85 70/30 85/45 100/60 50/100 80/120 30/30 45/45 55/65 65/65 80/80 40/40 100/80 95/55 120/70 58/62 35/35 60/60 45/70 70/95 40/50 65/100 45/25 85/45 100/35 115/55 130/75 30/45 43/90 73/115 25/25 50/50 55/55 80/80 60/45 125/65 40/50 50/80 35/110 35/110 60/75 60/45 85/70 30/30 45/45 35/105 100/40 40/80 70/25 95/45 35/50 65/80 70/55 100/85 100/120 55/80 115/95 95/85 100/85 55/70 40/70 15/20 60/100 85/95 48/48 45/65 110/95 110/95 95/110 85/75 90/55 115/70 55/45 65/70 60/75 65/110 95/125 125/90 125/85 50/50 70/70 100/100 154/90 100/100 49/65 63/80 83/100 60/50 80/65 109/85 44/48 59/63 79/83 35/45 45/55 36/56 76/96 40/80 55/110 40/40 60/60 70/80 56/56 76/76 35/35 45/55 40/20 40/65 80/105 70/45 95/70 65/45 80/60 115/90 90/100 20/50 50/80 30/65 90/100 35/55 45/65 55/85 40/55 30/30 105/85 75/45 25/25 65/65 130/95 60/130 85/42 100/110 85/85 72/48 33/58 90/65 35/35 60/60 65/65 35/65 55/65 40/40 60/60 55/55 55/80 10/230 40/95 35/75 50/50 75/75 70/40 80/80 30/30 60/60 65/85 65/35 105/75 65/45 80/140 40/70 80/50 110/80 95/95 40/40 60/60 105/95 85/65 20/45 35/35 35/110 85/65 65/55 70/55 40/70 75/135 115/100 90/75 90/115 45/50 65/70 95/100 90/154 110/154 100/100""".split()


def main() -> int:
    rows = list(csv.DictReader((ROOT / "data" / "gen2_special_stats.csv").open(newline="", encoding="utf-8")))
    if len(rows) != 251 or len(BULBAPEDIA_PAIRS) != 251:
        raise SystemExit(f"SECOND SOURCE COUNT: FAIL (mod={len(rows)}, source={len(BULBAPEDIA_PAIRS)})")
    mismatches = []
    for dex, (row, pair) in enumerate(zip(rows, BULBAPEDIA_PAIRS), start=1):
        spa, spd = map(int, pair.split("/"))
        got = (int(row["sp_atk"]), int(row["sp_def"]))
        expected = (spa, spd)
        if int(row["dex"]) != dex or got != expected:
            mismatches.append((dex, row.get("id"), got, expected))
    if mismatches:
        print("BULBAPEDIA GEN II-V CROSSCHECK: FAIL")
        for m in mismatches:
            print("  dex %03d %-16s got %s expected %s" % m)
        return 1
    print("BULBAPEDIA GEN II-V CROSSCHECK: 251/251 species, 502/502 values PASS")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
