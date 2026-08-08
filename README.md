# Special Stat Split

A small mod for Gen1Recomp that brings the Generation II **Special Attack / Special Defense split** into Pokémon Red.

In Gen I, Pokémon only have one `SPECIAL` stat. Starting with Gen II, that stat was split into:

- **SP. ATK**
- **SP. DEF**

<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/6821cf1b-4cc7-4bce-bb43-4412a73ddc1c" />


This mod does the same thing while keeping the rest of Pokémon Red's battle system intact.

## What it changes

All 151 Pokémon use their original **Generation II Special Attack and Special Defense base stats**.

For example:

| Pokémon | Gen I SPECIAL | SP. ATK | SP. DEF |
|---|---:|---:|---:|
| Chansey | 105 | 35 | 105 |
| Alakazam | 135 | 135 | 85 |
| Gengar | 130 | 130 | 75 |
| Mewtwo | 154 | 154 | 90 |

Special moves now use:

**Attacker's SP. ATK → Defender's SP. DEF**

Physical moves still use Attack and Defense normally.

Moves and items that affected SPECIAL were also split where appropriate:

- **Growth** → SP. ATK
- **Amnesia** → SP. DEF
- **X Special** → SP. ATK
- **Psychic's stat drop** → SP. DEF
- **Transform** copies both stats

The Summary screen also displays SP. ATK and SP. DEF separately.

## What it doesn't change

This is **not a full Gen II battle conversion**.

Pokémon Red still keeps its original mechanics for things like critical hits, badges, move data and other Gen I battle rules.

The goal is simply:

> Pokémon Red, but with the Special stat split introduced in Generation II.

Moves are also still Physical or Special based on their **type**, just like in Gen I/II. This mod does not add the Gen IV physical/special move split.

## Vanilla mode

The mod includes a **VANILLA** mode if you want to go back to the original single SPECIAL stat without uninstalling the mod.

After changing the mode, save the setting and restart the game.

## Pokédex Plus

Pokédex Plus 1.3.0 is supported.

Its Stats page will show SP. ATK, SP. DEF and the updated total when the Gen II split is enabled.

## Installation

Download the latest release and extract the mod into your Gen1Recomp `mods` folder.

Enable **Special Stat Split** in the Mod Manager and restart the game.

## Compatibility

Made and tested for:

**Gen1Recomp v0.1.75**

The mod keeps the original Special DV and Special Stat Exp system, so existing saves do not need new DV/Stat Exp data.

## Version

Current version: **1.0.1**
