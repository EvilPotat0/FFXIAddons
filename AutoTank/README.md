# AutoTank

**Version:** 1.0.0
**Author:** YourName
**Last Updated:** 2026.01.29

## Overview

AutoTank is a comprehensive automation addon for **Paladin (PLD)** and **Rune Fencer (RUN)** tanking jobs in Final Fantasy XI. It automates job abilities, spell casting, enmity generation, and defensive cooldowns to maintain threat and survivability.

## Features

### Core Features
- ✅ Full automation for PLD and RUN main jobs
- ✅ Subjob support for WAR, BLU, and SCH
- ✅ **Simplified commands** - Toggle any ability without job prefixes (`//at stoneskin` instead of `//at sch stoneskin`)
- ✅ Configurable HP thresholds for abilities and healing
- ✅ Automatic enmity generation and maintenance
- ✅ Defensive cooldown management
- ✅ Self-buff maintenance
- ✅ Rune management for RUN (auto-casting and maintenance)
- ✅ On-screen status display
- ✅ Per-character configuration saved automatically

### Paladin (PLD) Features
- **Defensive Abilities:**
  - Sentinel (emergency defense at configurable HP%)
  - Rampart (damage reduction at configurable HP%)
  - Reprisal (damage reflection)
  - Palisade (damage reduction)

- **Enmity Generation:**
  - Flash (configurable interval)
  - Shield Bash (stun + enmity)
  - Divine Emblem + Flash combo

- **Healing:**
  - Auto-Cure self (Cure II-IV based on HP%)
  - Auto-Cure party members (prioritizes lowest HP member below threshold)
  - Configurable HP% threshold for curing

- **Buff Maintenance:**
  - Enlight/Enlight II
  - Reprisal (spell)
  - Phalanx/Phalanx II
  - Majesty

- **MP Management:**
  - Chivalry (HP → MP conversion at low MP%)

- **Support:**
  - Cover (protect designated ally)
  - Holy Circle (vs undead)

### Rune Fencer (RUN) Features
- **Rune Management:**
  - Auto-cast selected rune element
  - Maintain configurable rune count (1-3)
  - Supports all 8 elements: Ignis, Gelus, Flabra, Tellus, Sulpor, Unda, Lux, Tenebrae

- **Defensive Wards:**
  - Vallation (damage reduction)
  - Valiance (enhanced reduction, requires 3 runes)
  - Pflug (emergency damage cut at configurable HP%)
  - Battuta (parry rate increase)
  - Liement (enemy attack down)

- **Offensive Abilities:**
  - Rayke (enemy defense down)
  - Gambit (attack/accuracy boost)
  - Swordplay (double attack rate)
  - Embolden (party enhancement)

- **Enmity Abilities:**
  - Lunge (rune-based magic damage + enmity)
  - Swipe (AoE rune damage + enmity)
  - Flash (standard enmity)

- **Buff Maintenance:**
  - Phalanx
  - Stoneskin
  - Aquaveil

#### Rune Element Selection

AutoTank supports both traditional rune names and common element names for convenience:

| Element | Accepted Names | Rune Name |
|---------|---------------|-----------|
| Fire | fire, ignis | Ignis |
| Ice | ice, gelus | Gelus |
| Wind | wind, aero, flabra | Flabra |
| Earth | earth, stone, tellus | Tellus |
| Thunder | thunder, lightning, sulpor | Sulpor |
| Water | water, unda | Unda |
| Light | light, lux | Lux |
| Dark | dark, darkness, tenebrae | Tenebrae |

**Examples:**
```bash
//at rune fire        # Sets to Ignis
//at rune stone       # Sets to Tellus
//at rune lightning   # Sets to Sulpor
//at rune Ignis       # Also works with rune names directly
```

This makes it easier to set runes by element type without memorizing the Latin rune names.

### Subjob Support

#### Warrior (/WAR)
- Provoke (enmity generation)
- Defender (defense boost)
- Warcry (attack boost)
- Aggressor (accuracy boost)

#### Blue Mage (/BLU)
**Fully Configurable Spell System** - Add any BLU spell with custom settings:
- Spell name, target type (self/enemy), HP threshold, AoE flag
- Default spells included: Cocoon, Geist Wall, Refueling
- Optional spells available: Metallic Body, Diamondhide, Jettatura, Blank Gaze, Battery Charge, Sheep Song, Soporific, Frightful Roar
- Easy to add more spells via configuration file
- Individual spell enable/disable toggles
- Per-spell cooldown tracking

**Default Configuration:**
- **Defensive Spells (self):** Cocoon (75% HP), Metallic Body (60% HP), Diamondhide (65% HP)
- **Offensive Spells (enemy):** Geist Wall, Jettatura, Blank Gaze
- **Utility Spells (self):** Refueling, Battery Charge
- **AoE/Control Spells (enemy):** Sheep Song, Soporific, Frightful Roar

#### Scholar (/SCH)
- Regen (I-IV)
- Stoneskin
- Phalanx
- Aquaveil

## Quick Start

1. Load the addon: `//lua load autotank`
2. Enable AutoTank: `//at on`
3. Set cure threshold: `//at cure 75`
4. (RUN only) Set rune element: `//at rune fire`

**Common Quick Toggles:**
```bash
//at stoneskin      # Toggle Stoneskin
//at provoke        # Toggle Provoke
//at sentinel       # Toggle Sentinel (PLD)
//at vallation      # Toggle Vallation (RUN)
//at party          # Toggle party healing
```

## Installation

1. Copy the `AutoTank` folder to your `Windower/addons/` directory
2. In-game, load the addon:
   ```
   //lua load autotank
   ```
3. Configure settings as desired (see Commands section)

## Commands

### Basic Commands

| Command | Description |
|---------|-------------|
| `//at on` | Enable AutoTank |
| `//at off` | Disable AutoTank |
| `//at toggle` | Toggle AutoTank on/off |
| `//at status` | Display current settings |
| `//at help` | Show command list |

### Configuration Commands

| Command | Description |
|---------|-------------|
| `//at cure [hp%]` | Set HP% threshold for auto-curing (default: 75) |
| `//at rune [element]` | Set rune element for RUN - accepts element names (fire, ice, wind, earth, thunder, water, light, dark) or rune names (Ignis, Gelus, Flabra, Tellus, Sulpor, Unda, Lux, Tenebrae) |
| `//at flash` | Toggle Flash usage on/off |

### Simplified Ability/Spell Toggles

You can toggle any ability or spell directly without job prefixes:

**Usage:** `//at <ability_name>`

**Examples:**
```bash
//at stoneskin          # Toggle Stoneskin (SCH subjob)
//at sentinel           # Toggle Sentinel (PLD)
//at provoke            # Toggle Provoke (WAR subjob)
//at vallation          # Toggle Vallation (RUN)
//at phalanx            # Toggle Phalanx (spell)
//at regen              # Toggle Regen (SCH subjob)
//at aquaveil           # Toggle Aquaveil
```

**Supported Abilities/Spells:**
- **PLD:** sentinel, rampart, bash/shieldbash, emblem/divineemblem, majesty, palisade, chivalry, cover, circle/holycircle, cureparty/party
- **RUN:** rune/autorune, vallation, valiance, pflug, battuta, liement, rayke, gambit, swordplay, embolden, lunge, swipe
- **Spells:** enlight, reprisal, phalanx, crusade, aquaveil
- **WAR Subjob:** provoke, defender, warcry, aggressor
- **SCH Subjob:** regen, stoneskin, phalanx, aquaveil

This simplified syntax makes it faster to toggle abilities without remembering which job category they belong to.

### BLU Spell Management Commands

Manage Blue Mage spells at runtime without editing config files:

| Command | Description |
|---------|-------------|
| `//at blu` | List all configured BLU spells with status |
| `//at blu add <name> <target> [hp%] [aoe]` | Add new BLU spell |
| `//at blu remove <name\|index>` | Remove BLU spell by name or index |
| `//at blu enable <name\|index>` | Enable BLU spell |
| `//at blu disable <name\|index>` | Disable BLU spell |
| `//at blu hp <name\|index> <hp%>` | Set HP threshold for spell |

**BLU Command Parameters:**
- `<name>` - Spell name (case-insensitive)
- `<target>` - Either `self` or `enemy`
- `[hp%]` - Optional HP percentage threshold (0-100)
- `[aoe]` - Optional AoE flag (`true` or `false`, defaults to `false`)
- `<index>` - Spell list number (shown with `//at blu`)

### Job Ability Toggle Commands

Toggle job-specific abilities and spells on/off at runtime:

| Command | Description |
|---------|-------------|
| `//at pld` | List all PLD abilities/spells with status |
| `//at pld <ability>` | Toggle specific PLD ability/spell |
| `//at run` | List all RUN abilities/spells with status |
| `//at run <ability>` | Toggle specific RUN ability/spell |
| `//at war` | List all WAR subjob abilities with status |
| `//at war <ability>` | Toggle specific WAR ability |
| `//at sch` | List all SCH subjob spells with status |
| `//at sch <spell>` | Toggle specific SCH spell |

**Available PLD Abilities:**
- sentinel, rampart, bash/shieldbash, emblem/divineemblem, majesty
- palisade, chivalry, cover, circle/holycircle
- enlight, reprisal, phalanx, crusade, flash
- cureparty/party (toggle party member healing)

**Available RUN Abilities:**
- rune/autorune, vallation, valiance, pflug, battuta, liement
- rayke, gambit, swordplay, embolden, lunge, swipe
- flash, phalanx, crusade

**Available WAR Abilities:**
- provoke, defender, warcry, aggressor

**Available SCH Spells:**
- regen, stoneskin, phalanx, aquaveil

### Examples

```lua
// Basic commands
//at on                    -- Enable AutoTank
//at cure 80               -- Auto-cure when HP drops below 80%
//at rune fire             -- Set RUN to use Ignis (fire) runes
//at rune stone            -- Set RUN to use Tellus (earth) runes
//at flash                 -- Toggle Flash enmity generation

// BLU spell management
//at blu                   -- List all BLU spells

// Add new BLU spells
//at blu add Cocoon self 75         -- Add Cocoon, cast at 75% HP
//at blu add "Metallic Body" self 60  -- Add Metallic Body at 60% HP
//at blu add "Geist Wall" enemy      -- Add Geist Wall (no HP threshold)
//at blu add "Sheep Song" enemy 0 true  -- Add Sheep Song as AoE

// Enable/disable spells
//at blu enable Cocoon     -- Enable Cocoon by name
//at blu disable 3         -- Disable spell #3
//at blu enable "Sheep Song"  -- Enable Sheep Song

// Remove spells
//at blu remove Cocoon     -- Remove by name
//at blu remove 5          -- Remove by index

// Adjust HP thresholds
//at blu hp Cocoon 80      -- Change Cocoon to trigger at 80% HP
//at blu hp 1 65           -- Change spell #1 to 65% HP

// Simplified ability toggles (no job prefix needed)
//at sentinel              -- Toggle Sentinel
//at stoneskin             -- Toggle Stoneskin
//at provoke               -- Toggle Provoke
//at vallation             -- Toggle Vallation
//at phalanx               -- Toggle Phalanx
//at party                 -- Toggle party member healing

// Job-specific commands (still available)
//at pld                   -- List all PLD abilities
//at pld sentinel          -- Toggle Sentinel on/off
//at run                   -- List all RUN abilities
//at run vallation         -- Toggle Vallation on/off
//at run rune              -- Toggle auto-rune management on/off

//at war                   -- List all WAR abilities
//at war provoke           -- Toggle Provoke on/off
//at war defender          -- Toggle Defender on/off

//at sch                   -- List all SCH spells
//at sch regen             -- Toggle Regen on/off
//at sch stoneskin         -- Toggle Stoneskin on/off
```

## Configuration File

Settings are saved per-character in:
```
Windower/addons/AutoTank/data/<CharacterName>_settings.xml
```

### Default Settings

#### Healing Settings
```lua
healing = {
    cure_hp = 75,           -- Start curing at 75% HP
    cure_emergency_hp = 50, -- Emergency cure at 50% HP
    use_cures = true,       -- Enable auto-curing
    use_flash = true,       -- Enable Flash usage
}
```

#### Paladin Settings
```lua
pld = {
    use_sentinel = true,
    sentinel_hp = 50,       -- Use Sentinel at 50% HP
    use_rampart = true,
    rampart_hp = 70,        -- Use Rampart at 70% HP
    use_cover = false,      -- Cover disabled by default
    cover_target = '',      -- Target name for Cover
    use_divine_emblem = true,
    use_majesty = true,
    use_chivalry = true,
    chivalry_mp = 30,       -- Use Chivalry at 30% MP
    use_reprisal = true,
    use_palisade = true,
    use_shield_bash = true,
    use_holy_circle = false,
    use_enlight = true,
}
```

#### Rune Fencer Settings
```lua
run = {
    use_vallation = true,
    use_valiance = true,
    use_pflug = true,
    pflug_hp = 60,          -- Use Pflug at 60% HP
    use_swordplay = true,
    use_battuta = true,
    use_liement = true,
    use_rayke = true,
    use_gambit = true,
    use_embolden = true,

    rune_element = 'Ignis', -- Default rune element
    auto_rune = true,       -- Auto-maintain runes
    rune_count = 3,         -- Maintain 3 runes
    use_swipe = true,
    use_lunge = true,
}
```

#### Subjob Settings
```lua
subjob = {
    -- WAR
    use_provoke = true,
    use_warcry = true,
    use_defender = true,
    use_aggressor = false,

    -- BLU
    use_cocoon = true,
    cocoon_hp = 75,         -- Use Cocoon at 75% HP
    use_refueling = true,
    use_sheep_song = false, -- Disabled by default
    use_geist_wall = true,

    -- SCH
    use_regen = true,
    use_stoneskin = true,
    use_phalanx = true,
    use_aquaveil = true,
}
```

#### Blue Mage Spell Configuration
The BLU subjob uses a fully configurable spell list. Each spell has:
- `name` - BLU spell name (exactly as it appears in-game)
- `target` - Either `'self'` or `'enemy'`
- `hp_threshold` - (Optional) Only cast when HP% is at or below this value
- `enabled` - `true` to use this spell, `false` to disable
- `aoe` - `true` if spell is AoE (will only cast in combat)

```lua
subjob = {
    blu_spells = {
        -- Example defensive spell
        {name = 'Cocoon', target = 'self', hp_threshold = 75, enabled = true, aoe = false},

        -- Example offensive spell
        {name = 'Geist Wall', target = 'enemy', enabled = true, aoe = false},

        -- Example utility spell
        {name = 'Refueling', target = 'self', enabled = true, aoe = false},

        -- Example AoE control spell (disabled by default)
        {name = 'Sheep Song', target = 'enemy', enabled = false, aoe = true},
    }
}
```

**Adding Custom BLU Spells:**
1. Open your character's settings XML file: `Windower/addons/AutoTank/data/<CharacterName>_settings.xml`
2. Find the `<blu_spells>` section under `<subjob>`
3. Add new spell entries following the format above
4. Reload addon: `//lua reload autotank`

**Available BLU Spells by Category:**

*Defensive (self-target):*
- Cocoon, Metallic Body, Diamondhide, Refueling, Battery Charge

*Offensive (enemy-target):*
- Geist Wall, Jettatura, Blank Gaze

*AoE/Control (enemy-target, use with caution):*
- Sheep Song, Soporific, Frightful Roar

**Note:** You can add ANY Blue Mage spell you have learned. The addon will attempt to cast it based on your configuration.

#### Enmity Settings
```lua
enmity = {
    flash_interval = 30,        -- Flash every 30 seconds
    provoke_interval = 30,      -- Provoke every 30 seconds
    use_enmity_rotation = true,
    maintain_engagement = true,
}
```

## Usage Scenarios

### Scenario 1: Paladin Tank (PLD/WAR)

**Setup:**
```lua
//at on
//at cure 75
//at flash
```

**What it does:**
1. Maintains Enlight, Reprisal, Phalanx buffs
2. Uses Flash every 30 seconds for enmity
3. Uses Provoke (WAR sub) every 30 seconds
4. Cures self when HP drops below 75%
5. Uses Sentinel at 50% HP emergency
6. Uses Rampart at 70% HP
7. Uses Shield Bash for additional stun/enmity
8. Activates Defender (WAR sub) for defense boost

### Scenario 2: Rune Fencer Tank (RUN/WAR)

**Setup:**
```lua
//at on
//at rune fire
//at cure 70
```

**What it does:**
1. Maintains 3 Ignis (fire) runes at all times
2. Keeps Vallation/Valiance active for damage reduction
3. Uses Pflug at 60% HP for emergency mitigation
4. Uses Lunge/Swipe for rune-based enmity
5. Uses Flash every 30 seconds
6. Uses Provoke (WAR sub) every 30 seconds
7. Activates Gambit/Swordplay for offensive boost
8. Uses Rayke on enemy for defense down

### Scenario 3: Paladin with Scholar Sub (PLD/SCH)

**Setup:**
```lua
//at on
//at cure 80
```

**What it does:**
1. All PLD tank features (buffs, enmity, cooldowns)
2. Maintains Regen, Stoneskin, Phalanx from SCH sub
3. Keeps Aquaveil active for spell interruption resistance
4. Higher cure threshold (80%) for safer healing

### Scenario 4: Rune Fencer with Blue Mage Sub (RUN/BLU)

**Setup:**
```lua
//at on
//at rune dark
```

**What it does:**
1. Maintains 3 Tenebrae (dark) runes
2. All RUN defensive wards and enmity abilities
3. Uses configured BLU spells based on HP thresholds and combat status
4. Default: Cocoon (75% HP), Refueling, Geist Wall

**Customizing BLU Spells at Runtime:**
```lua
// Add defensive spells at different HP thresholds
//at blu add "Metallic Body" self 60
//at blu add Diamondhide self 50

// Add offensive debuffs
//at blu add Jettatura enemy
//at blu add "Blank Gaze" enemy

// View current spell list
//at blu

// Disable a spell temporarily
//at blu disable "Sheep Song"

// Adjust HP threshold
//at blu hp Cocoon 80
```

**Or Edit the Settings XML:**
```xml
<blu_spells>
    <entry>
        <name>Cocoon</name>
        <target>self</target>
        <hp_threshold>75</hp_threshold>
        <enabled>true</enabled>
        <aoe>false</aoe>
    </entry>
    <entry>
        <name>Metallic Body</name>
        <target>self</target>
        <hp_threshold>60</hp_threshold>
        <enabled>true</enabled>
        <aoe>false</aoe>
    </entry>
    <entry>
        <name>Jettatura</name>
        <target>enemy</target>
        <enabled>true</enabled>
        <aoe>false</aoe>
    </entry>
</blu_spells>
```

### Scenario 5: Custom BLU Spell Setup (PLD/BLU or RUN/BLU)

**Advanced Setup:**
For tanks who want maximum defensive utility from BLU subjob:

1. Enable multiple defensive spells at different HP thresholds:
   - Cocoon (75% HP) - First line of defense
   - Metallic Body (60% HP) - Emergency defense
   - Diamondhide (50% HP) - Last resort

2. Add offensive debuffs for extra control:
   - Geist Wall (dispel enemy buffs)
   - Jettatura (terror)
   - Blank Gaze (dispel + damage)

3. Keep utility spells active:
   - Refueling (TP generation)
   - Battery Charge (TP boost)

**Configuration example available in README's Advanced Configuration section.**

### Scenario 6: Runtime BLU Spell Management

**Interactive Setup for RUN/BLU:**

Start with defaults and customize on-the-fly:

```lua
// Load AutoTank and enable
//at on
//at rune fire

// Check current BLU spell configuration
//at blu
// Output shows:
// 1. Cocoon (self) - ON HP<=75%
// 2. Metallic Body (self) - OFF HP<=60%
// 3. Refueling (self) - ON
// 4. Geist Wall (enemy) - ON

// Enable additional defensive layers
//at blu enable "Metallic Body"
//at blu enable Diamondhide

// Add a new debuff spell you just learned
//at blu add Jettatura enemy

// Adjust Cocoon to trigger earlier
//at blu hp Cocoon 80

// Temporarily disable Geist Wall for this fight
//at blu disable "Geist Wall"

// Review updated configuration
//at blu
```

**Benefits of Runtime Management:**
- No addon reload required
- Test spells immediately
- Adjust thresholds based on enemy difficulty
- Enable/disable spells per situation
- Quick fixes without file editing

### Scenario 7: Quick Mid-Battle Adjustments

**Using Simplified Commands for Fast Toggles:**

During a difficult fight, quickly adjust your setup without typing long commands:

```bash
# Tank taking heavy damage - enable more defensive abilities
//at stoneskin           # Enable Stoneskin (SCH sub)
//at defender            # Enable Defender (WAR sub)
//at sentinel            # Enable Sentinel emergency ability

# Need more enmity generation
//at provoke             # Enable Provoke
//at lunge               # Enable Lunge (RUN)

# Boss has strong buffs - enable dispel
//at blu add "Geist Wall" enemy

# Fight over - disable resource-heavy abilities
//at stoneskin           # Disable Stoneskin
//at defender            # Disable Defender
```

**Why Simplified Commands Are Better:**
- **Faster:** `//at stoneskin` vs `//at sch stoneskin`
- **Easier to remember:** No need to recall which job category
- **Combat-friendly:** Type less during tense situations
- **Consistent:** Same syntax for all abilities/spells

## Priority System

AutoTank uses a priority system to determine action order:

### Paladin Priority
1. **Emergency Defense** (Sentinel, Rampart at critical HP)
2. **Healing** (Auto-Cure based on HP thresholds)
3. **MP Management** (Chivalry at low MP)
4. **Buff Maintenance** (Enlight, Reprisal, Phalanx, Majesty)
5. **Cover Ally** (if configured)
6. **Enmity Generation** (Flash, Shield Bash, Divine Emblem combo)

### Rune Fencer Priority
1. **Defensive Wards** (Pflug emergency, Vallation, Valiance, Battuta)
2. **Rune Maintenance** (Auto-cast to maintain rune count)
3. **Buff Maintenance** (Phalanx, Stoneskin, Aquaveil)
4. **Offensive Abilities** (Rayke, Gambit, Swordplay, Embolden)
5. **Rune Enmity** (Lunge, Swipe)
6. **Flash Enmity** (Standard Flash)

### Subjob Priority
- Subjob abilities run after main job priorities
- Provoke (WAR) runs on configured interval
- Defensive buffs (Defender, Cocoon) trigger at HP thresholds
- Buff maintenance (SCH/BLU spells) checks every 10 seconds

## Display

The on-screen display shows:
- AutoTank status (ON/OFF)
- Current job and subjob
- HP and MP (current/max and percentage)
- Rune count (RUN only)
- Current rune element (RUN only)
- Combat status (YES/NO)

Position: Top-left corner (default)
*Display repositioning coming in future update*

## Tips and Best Practices

1. **Adjust Cure Thresholds:** Set based on your gear and situation
   - Well-geared: 70-75%
   - Undergeared: 80-85%
   - Emergency situations: 60-65%

2. **Rune Element Selection (RUN):**
   - **Ignis** (Fire): Physical damage resistance
   - **Gelus** (Ice): Magic damage resistance
   - **Tenebrae** (Dark): General balanced resistance
   - Match element to enemy damage type when possible

3. **Enmity Management:**
   - Flash interval (30s) balanced for enmity without spam
   - Combine with Provoke for maximum hate generation
   - Divine Emblem + Flash (PLD) for burst enmity
   - Lunge/Swipe (RUN) for rune-based enmity

4. **Subjob Selection:**
   - **/WAR**: Best for enmity (Provoke) + defense (Defender)
   - **/BLU**: Versatile with Cocoon, Refueling, utility spells
   - **/SCH**: Best for self-sustainability with Regen, Stoneskin

5. **MP Management (PLD):**
   - Chivalry at 30% MP converts HP to MP
   - Adjust threshold based on cure frequency
   - Consider /SCH for longer fights

6. **Cover Usage (PLD):**
   - Disabled by default
   - Set target name in settings XML file
   - Best for protecting specific party members

## Troubleshooting

### AutoTank not working
- Check that addon is loaded: `//lua list`
- Ensure AutoTank is enabled: `//at on`
- Verify you're on PLD or RUN job

### Not casting spells/abilities
- Check that abilities are off cooldown
- Verify sufficient MP for spells
- Ensure you're in proper stance (engaged for combat actions)

### Runes not being maintained (RUN)
- Check `auto_rune` setting is `true`
- Verify `rune_element` is set correctly
- Confirm rune ability is off cooldown (4s between casts)

### Healing not triggering
- Check `use_cures` setting is `true`
- Verify `cure_hp` threshold
- Ensure sufficient MP for Cure spells

## Advanced Configuration

Edit the settings XML file directly for advanced options:

```xml
<settings>
    <healing>
        <cure_hp>75</cure_hp>
        <cure_emergency_hp>50</cure_emergency_hp>
    </healing>

    <pld>
        <sentinel_hp>50</sentinel_hp>
        <rampart_hp>70</rampart_hp>
        <cover_target>PlayerName</cover_target>
    </pld>

    <run>
        <rune_element>Ignis</rune_element>
        <rune_count>3</rune_count>
        <pflug_hp>60</pflug_hp>
    </run>

    <enmity>
        <flash_interval>30</flash_interval>
        <provoke_interval>30</provoke_interval>
    </enmity>
</settings>
```

After editing, reload the addon:
```
//lua reload autotank
```

## Future Enhancements

Planned features for future versions:
- Display repositioning commands
- Auto-engage on target
- Alliance member monitoring
- Custom ability rotations
- Party Cover priority list
- Gear set integration
- IPC (Inter-Process Communication) for multi-boxing
- Situational rune element switching
- Enemy resistance detection

## Support

For issues, suggestions, or contributions:
- Report bugs with detailed information (job, subjob, situation)
- Include relevant settings from your XML file
- Describe expected vs actual behavior

## Changelog

### Version 1.0.0 (2026.01.29)
- Initial release
- Full PLD automation (abilities, spells, healing, enmity)
- Full RUN automation (runes, wards, enmity)
- Subjob support (WAR/BLU/SCH)
- Configurable thresholds and toggles
- Per-character settings
- On-screen display

## Credits

- Inspired by HealBot and other automation addons
- Thanks to the Windower development team
- Community feedback and testing

---

**AutoTank** - Automate your tanking, focus on strategy!
