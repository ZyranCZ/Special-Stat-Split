# Special Stat Split

A mod for Gen1Recomp that brings both the Generation II **Special Attack / Special Defense stat split** and the Generation IV+ **Physical / Special move split** into Pokémon Red.

In Gen I, Pokémon only have one `SPECIAL` stat. Starting with Gen II, that stat was split into:

* **SP. ATK**
* **SP. DEF**

Generation I also determines whether a damaging move is Physical or Special entirely by its **type**. Starting with Generation IV, every move has its own individual damage category instead.

For example:

* **Fire Punch** → Physical
* **Waterfall** → Physical
* **Hyper Beam** → Special
* **Flamethrower** → Special

<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/6821cf1b-4cc7-4bce-bb43-4412a73ddc1c" />
<img width="1026" height="800" alt="image" src="https://github.com/user-attachments/assets/ebcba933-6e07-465a-bf6c-4b2152d6fffa" />
[BEST PAIRED WITH Move Category (PHYS/SPEC) Preview
](https://github.com/ZyranCZ/Move-Category-Preview)

This mod adds both systems while keeping the rest of Pokémon Red's battle mechanics as intact as possible.

**Check out my other mods:**

* [Autofire A/B + Directional Keys Mod](https://github.com/ZyranCZ/Move-Category-Preview)

* [Steel and/or Fairy and/or Typing Charts](https://github.com/ZyranCZ/Steel-and-or-Fairy-and-or-Typing-Charts)

* [Move Category (PHYS/SPEC) Preview](https://github.com/ZyranCZ/Move-Category-Preview)

* [Special Stat Split](https://github.com/ZyranCZ/Special-Stat-Split/)

* [Enemy HP Visible](https://github.com/ZyranCZ/Enemy-HP)

* [Can Always Escape](https://github.com/ZyranCZ/Can-Always-Escape)

## What it changes

### Special Attack / Special Defense split

All 151 Pokémon use their original **Generation II Special Attack and Special Defense base stats**.

For example:

| Pokémon  | Gen I SPECIAL | SP. ATK | SP. DEF |
| -------- | ------------: | ------: | ------: |
| Chansey  |           105 |      35 |     105 |
| Alakazam |           135 |     135 |      85 |
| Gengar   |           130 |     130 |      75 |
| Mewtwo   |           154 |     154 |      90 |

Special moves use:

**Attacker's SP. ATK → Defender's SP. DEF**

Physical moves use:

**Attacker's Attack → Defender's Defense**

Moves and items that affected SPECIAL were also split where appropriate:

* **Growth** → SP. ATK
* **Amnesia** → SP. DEF
* **X Special** → SP. ATK
* **Psychic's stat drop** → SP. DEF
* **Transform** copies both stats

The Summary screen also displays SP. ATK and SP. DEF separately.

### Generation IV+ Physical / Special move split

The mod can also replace Gen I's type-based Physical/Special system with the **per-move category system introduced in Generation IV**.

This means a move's elemental type no longer determines which attacking stat it uses.

For example, Fire-type moves are no longer automatically Special:

* **Fire Punch** is Physical and uses Attack / Defense.
* **Flamethrower** is Special and uses SP. ATK / SP. DEF.

Likewise:

* **Waterfall** → Physical
* **Crabhammer** → Physical
* **Hyper Beam** → Special
* **Swift** → Special

All original **165 Generation I moves** have been assigned their proper Generation IV+ Physical, Special or Status category.

For the original Gen I move pool, these categories remain the same from **Generation IV through Generation IX**, so the option is labeled **GEN IV+ (BY MOVE)** rather than pretending that Gen IV, V, VI, VII, VIII and IX use different categories when they do not.

## Available modes

The two systems can be configured independently.

### Special Stats

* **VANILLA** — original single SPECIAL stat
* **GEN II (SP. ATK / SP. DEF)** — separate Special Attack and Special Defense

### Move Categories

* **GEN I (BY TYPE)** — Physical/Special category is determined by move type, like the original games
* **GEN IV+ (BY MOVE)** — every move uses its individual Physical/Special category

This means you can use the Generation IV move split together with either the original Gen I SPECIAL stat or the Generation II SP. ATK / SP. DEF split.

After changing either option, save the setting and restart the game.

## What it doesn't change

This is **not a full later-generation battle conversion**.

Pokémon Red still keeps its original mechanics for things such as:

* critical hits
* badge effects
* damage formula behavior
* move Power
* move Accuracy
* move PP
* move effects
* most other Generation I battle rules

The **GEN IV+ (BY MOVE)** setting changes the Physical / Special / Status category of moves. It does not automatically replace every move with its modern-generation version.

Some moves changed their Power, Accuracy, PP, type or effects in later generations. Those changes are outside the scope of the Physical/Special category split.

The goal is:

> Pokémon Red with the Generation II Special stat split and the Generation IV+ per-move Physical/Special split, without turning the entire battle system into a later-generation engine.

## Vanilla modes

Both major systems can be returned to their original Gen I behavior without uninstalling the mod.

Set:

* **SPECIAL STATS** → `VANILLA`
* **MOVE CATEGORIES** → `GEN I (BY TYPE)`

Then save the settings and restart the game.

## Pokédex Plus

Pokédex Plus 1.3.0 is supported.

Its Stats page will show SP. ATK, SP. DEF and the updated total when the Gen II stat split is enabled.

## Installation

Download the latest release and extract the mod into your Gen1Recomp `mods` folder.

Enable **Special Stat Split** in the Mod Manager and restart the game.

## Compatibility

Made and tested for:

**Gen1Recomp v0.1.75**

The mod keeps the original Special DV and Special Stat Exp system, so existing saves do not need new DV/Stat Exp data.

The move-category system uses Gen1Recomp's native move registry and damage-category support.

Because gameplay-affecting move categories must match between players, the mod is marked as affecting link compatibility.

## Version

Current version: **2.1.0**
