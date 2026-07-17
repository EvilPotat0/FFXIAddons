# Houdini

A magic burst automation and coordination addon for Final Fantasy XI Windower.

**Author**: EvilPotat0
**Version**: 0.1.0
**Last Update**: 2025.11.1

## Overview

Houdini is a sophisticated addon designed to automate magic bursting during skillchains and coordinate spell casting across multiple characters. It supports intelligent spell selection, multi-character coordination, and includes specialized features for different mage jobs (BLM, RDM, SCH, GEO, COR).

## Features

- **Automated Magic Bursting**: Automatically casts 3-tier magic burst sequences on skillchains
- **Multi-Boxing Support**: Leader/follower system for coordinating multiple characters
- **Intelligent Spell Selection**: Automatically selects the highest available spell tier based on MP and recast
- **Job-Specific Logic**: Specialized behavior for BLM, SCH, GEO, and COR
- **Skillchain Element Mapping**: Configurable element selection per skillchain type
- **AoE Casting**: Support for -ga spell casting
- **Party/Tell Commands**: Remote control via party chat or tells
- **Myrkr Automation**: Automatic Myrkr usage for SCH
- **MP Warning System**: Alerts party when MP falls below threshold
- **Visual Display**: Optional on-screen status display

## Installation

1. Extract the Houdini folder to your `Windower/addons/` directory
2. In-game, type: `//lua load houdini`
3. Configure your settings with the commands below

## Quick Start

### Basic Setup

```lua
//ho on                          -- Enable Houdini
//ho element Light Fire          -- Set Light skillchains to use Fire
//ho element Darkness Stone      -- Set Darkness to use Stone
```

### For Multi-Boxing (Leader Character)

```lua
//ho leader                      -- Mark as leader (auto-disables on others)
//ho leader 1                    -- Mark as leader who is NOT doing the SC (gets 3 bursts)
//ho send_target                 -- Send target to followers
//ho send_messages               -- Send party messages
```

### For Multi-Boxing (Follower Characters)

```lua
//ho use_messages                -- Listen to party/tell messages
```

## Commands

### Core Commands

| Command | Description |
|---------|-------------|
| `//ho on` | Enable Houdini |
| `//ho off` | Disable Houdini |
| `//ho toggle` | Toggle enabled state |
| `//ho status` | Display current settings |
| `//ho help` | Show help information |

### Leader/Follower

| Command | Description |
|---------|-------------|
| `//ho leader` | Toggle leader mode (automatically disables on others) |
| `//ho leader 1` | Set as leader who is NOT doing SC (gets 3 bursts instead of 2) |
| `//ho leader off` | Disable leader mode |
| `//ho send_target` | Toggle automatic target sending to followers |
| `//ho send_messages` | Toggle sending party messages for commands |
| `//ho use_messages` | Toggle listening to party/tell messages |

**Command Aliases:**
- `send_target`: Also accepts `sendtarget`, `sendtar`
- `send_messages`: Also accepts `sendmessage`, `sendmsg`
- `use_messages`: Also accepts `usemessages`, `usemsg`
- `use_aja`: Also accepts `useaja`, `aja`

### Magic Burst

| Command | Description |
|---------|-------------|
| `//ho burst <skillchain/element> [ignoreLeader]` | Start 3-hit MB sequence |
| `//ho cancelburst` | Cancel active burst sequence |
| `//ho enableburst` | Enable Burst Mode in GearSwap |
| `//ho disableburst` | Disable Burst Mode in GearSwap |

**Note**: The `cancelburst` command allows you to stop an ongoing burst sequence mid-execution.

**Example:**
```lua
//ho burst Light              -- Burst using Light element (Fire)
//ho burst Darkness           -- Burst using Darkness element (Stone)
//ho burst Fire               -- Burst using Fire directly
//ho burst Distortion 1       -- Burst as leader (ignores leader delay)
```

### Spell Casting

| Command | Description |
|---------|-------------|
| `//ho nuke <element> [tier]` | Cast nuke on current target |
| `//ho aoe <element>` | Cast -ga AoE spell |
| `//ho aspir` | Cast highest available Aspir |
| `//ho meteor` | Trigger Elemental Seal + Meteor (BLM only) |

**Examples:**
```lua
//ho nuke Fire               -- Cast highest Fire spell
//ho nuke Thunder 4          -- Cast Thunder IV
//ho nuke Blizzard aja       -- Cast Blizzaja (BLM only)
//ho aoe Stone               -- Cast Stonega III/II/I
//ho aspir                   -- Cast Aspir III/II/I
//ho meteor                  -- BLMs use Elemental Seal then Meteor
```

### Element Configuration

| Command | Description |
|---------|-------------|
| `//ho element <skillchain> <element>` | Set element for skillchain type |
| `//ho dist <element>` | Shorthand to set element for Distortion |
| `//ho frag <element>` | Shorthand to set element for Fragmentation |
| `//ho light <element>` | Shorthand to set element for Light |
| `//ho dark <element>` | Shorthand to set element for Darkness |

**Skillchain Types:**
- Light, Darkness, Fusion, Distortion, Gravitation, Fragmentation, Scission
- Liquefaction, Detonation, Impaction, Induration, Reverberation

**Example:**
```lua
//ho element Fusion Fire
//ho element Distortion Blizzard
//ho element Fragmentation Thunder

// Shorthand commands:
//ho dist Blizzard           -- Same as: //ho element Distortion Blizzard
//ho frag Thunder            -- Same as: //ho element Fragmentation Thunder
//ho light Fire              -- Same as: //ho element Light Fire
//ho dark Stone              -- Same as: //ho element Darkness Stone
```

### Debuff Management

| Command | Description |
|---------|-------------|
| `//ho debuff <spell>` | Set the debuff spell to use with dodebuff command |
| `//ho dodebuff` | Cast the configured debuff spell on current target |

**Example:**
```lua
//ho debuff Silence          -- Set Silence as the debuff spell
//ho dodebuff                -- Cast Silence on current target
```

### Ra'Kaznar Shard Tracking

| Command | Description |
|---------|-------------|
| `//ho shard_reporting` | Toggle Ra'Kaznar Shard tracking and party reporting |

**Command Aliases:**
- `shard_reporting`: Also accepts `shards`, `shard`

**How It Works:**
When enabled, the addon automatically:
- Detects when you obtain any Ra'Kaznar Shard (A, B, C, or D)
- Checks all your bags and temporary items for all four shards
- Reports to party chat which shards you still need

**Example Output:**
```lua
//ho shard_reporting         -- Enable shard tracking

// After obtaining Shard A:
[Party] Ra'Kaznar Shards still needed: B, C, D

// After obtaining Shard D:
[Party] Ra'Kaznar Shards still needed: B, C

// After obtaining the last shard:
[Party] All Ra'Kaznar Shards obtained!
```

**Usage Notes:**
- Checks all inventory bags (inventory + wardrobes 1-8)
- Checks temporary items
- Disabled by default - must be enabled with `//ho shard_reporting`
- Status shows in `//ho status` output

### Special Features

| Command | Description |
|---------|-------------|
| `//ho use_aja` | Toggle -aja spell usage (BLM only) |
| `//ho helix` | Toggle Helix II usage (SCH only) |
| `//ho potency` | Trigger Ebullience (SCH) or Collimated Fervor (GEO) |
| `//ho mpwarning [mpp]` | Set the MP percentage to warn party at (0-100) |
| `//ho myrkr [tp] [mp%]` | Configure Myrkr automation |
| `//ho react <name> <element>` | Trigger a named NM reaction (see [NM Reactions](#nm-reactions)) |

**Job-Aware Commands:**

**Potency** (`//ho potency`):
- **SCH**: Triggers Ebullience
- **GEO**: Triggers Collimated Fervor
- When used by leader, sends command to others but doesn't trigger on leader (unless `//ho leader 1`)

**Meteor** (`//ho meteor`):
- **BLM only**: Uses Elemental Seal, then casts Meteor after 1 second delay
- Automatically coordinates with all BLMs in party when used by leader
- Non-BLM jobs ignore this command

**Myrkr Example:**
```lua
//ho myrkr 1000 40           -- Use Myrkr at 1000+ TP when MP ≤ 40%
//ho myrkr                   -- Toggle Myrkr on/off
```

### Display

| Command | Description |
|---------|-------------|
| `//ho display` | Toggle on-screen status display |
| `//ho pos <x> <y>` | Set display position |

### Advanced

| Command | Description |
|---------|-------------|
| `//ho click` | Toggle mouse click interaction with display |
| `//ho addtell <name>` | Add character to tell list for target commands |
| `//ho removetell <name>` | Remove from tell list |
| `//ho cleartells` | Clear entire tell list |

## How Magic Bursting Works

### Burst Sequence

When you execute `//ho burst <skillchain>`, Houdini performs a 3-tier magic burst:

**For Non-Leaders (Standard):**
1. **First Cast**: Highest tier (VI, -aja, or Helix II)
2. **Second Cast**: Tier IV (after delay)
3. **Third Cast**: Tier III (after delay)

**For Leaders:**
- **Standard Leader** (`//ho leader`): Assumes leader is creating the skillchain
  - Only casts 2 bursts to avoid timing conflicts
  - Adds configurable delay (default 3.0s) before first cast
- **Leader Not Doing SC** (`//ho leader 1`): Leader is not making the skillchain
  - Casts full 3-burst sequence like followers
  - Uses standard timing (no extra delay)

**For Corsairs:**
- Fires matching Quick Draw shot
- Single shot timed with mage bursts
- Uses 0.25s delay

### Timing System

Burst delays are configurable in settings:
- Tier 1: 1.0s
- Tier 2: 2.0s
- Tier 3: 3.0s
- Tier 4: 4.1s
- Tier 5: 4.6s
- Tier 6: 5.0s
- Tier 7 (aja): 5.0s

### Intelligent Spell Selection

Houdini automatically:
- Checks MP cost before casting
- Checks spell recast timers
- Falls back to lower tiers if needed
- Respects job restrictions (BLM gets VI/aja, others get V)
- Uses Helix II for SCH when enabled

## Multi-Boxing Setup

### 3-Box Example Setup

**Scenario 1: Leader Creates Skillchains (SCH making Immanence SCs)**

**Main Character (Leader/SCH):**
```lua
//ho on
//ho leader                    -- 2-burst mode (making SCs)
//ho send_target
//ho send_messages
//ho myrkr 1000 40
//ho element Light Fire
//ho element Darkness Stone
```

**Alt Character 1 (BLM Follower):**
```lua
//ho on
//ho use_messages
//ho use_aja
```

**Alt Character 2 (GEO Follower):**
```lua
//ho on
//ho use_messages
```

**Usage:**
1. Leader: `//ho burst Light`
2. Leader casts 2 bursts (Tier VI/V → Tier IV)
3. Followers cast 3 bursts each (Tier VI/aja → IV → III)

---

**Scenario 2: Melee Creates Skillchains (BLM is leader for coordination)**

**BLM (Leader but not SC maker):**
```lua
//ho on
//ho leader 1                  -- 3-burst mode (NOT making SCs)
//ho send_target
//ho send_messages
//ho use_aja
```

**SCH (Follower):**
```lua
//ho on
//ho use_messages
//ho myrkr 1000 40
```

**GEO (Follower):**
```lua
//ho on
//ho use_messages
```

**Usage:**
1. Melee creates skillchain
2. Leader: `//ho burst Fragmentation`
3. All three mages cast full 3-burst sequence
4. No delay on leader's first cast (not making SC)

## Party Chat Commands

When `use_messages` is enabled, characters respond to these party/tell messages:

| Message | Action |
|---------|--------|
| `nuke <element> [tier]` | Cast nuke |
| `burst <skillchain>` | Start burst sequence |
| `cancelburst` | Cancel active burst |
| `aoe <element>` | Cast AoE spell |
| `enableBurst` | Enable GearSwap Burst Mode |
| `disableBurst` | Disable GearSwap Burst Mode |
| `target <id>` | Target specific mob ID |
| `element <skillchain> <element>` | Set element for skillchain type |
| `dist/frag/light/dark <element>` | Shorthand element configuration |
| `potency+` | Trigger Ebullience (SCH) or Collimated Fervor (GEO) |
| `doaspir` | Cast Aspir |
| `dometeor` | Trigger Elemental Seal + Meteor (BLM only) |
| `dodebuff` | Cast configured debuff spell |
| `react <name> <element>` | Trigger a named NM reaction (see [NM Reactions](#nm-reactions)) |

**Note**: Characters must have `//ho use_messages` enabled to respond to these commands.

## Job-Specific Features

### Black Mage (BLM)
- Access to tier VI spells
- Optional -aja spell usage (`//ho use_aja`)
- Can cast -ga AoE spells
- Highest spell tier priority
- Elemental Seal + Meteor support (`//ho meteor`)
  - Automatically uses Elemental Seal
  - Waits 1 second then casts Meteor
  - Coordinates with all BLMs when leader issues command

### Scholar (SCH)
- Helix II spell support (`//ho helix`)
- Myrkr automation for MP recovery
- Ebullience triggering (`//ho potency`)
- Aspir II/Aspir support
- Stratagem integration

### Geomancer (GEO)
- Standard nuke support
- Aspir III/Aspir II support
- Collimated Fervor triggering (`//ho potency`)
- MP management

### Red Mage (RDM)
- Standard tier V spell support
- Element selection

### Corsair (COR)
- Quick Draw shot integration
- Fires matching elemental shot during bursts
- Single-shot timing with mage bursts

## NM Reactions

Houdini includes a `react` command for one-off NM/mob-specific reactions — e.g. "this add spawns and needs Water burned immediately" — that don't fit the normal `burst`/`nuke` flow.

```lua
//ho react Degei Water        -- Trigger the "Degei" reaction with Water as the element
```

- `react` updates the configured skillchain element (like `//ho element`) where applicable, then does job-specific behavior (BLM/GEO nuke, COR Quick Draw, SCH storm spell).
- Leaders sending `react` propagate it to followers the same way `burst`/`nuke` do (`send @others`, optional `send_messages`).
- Also usable via party/tell when `use_messages` is enabled: `react <name> <element>`.

### Adding Your Own Reactions

Reactions are **not** hardcoded in `Houdini.lua`. Each reaction lives in its own file under `Houdini/reactions/`, and every `.lua` file in that folder is loaded automatically — no need to touch the main addon file.

To add a new reaction, create `Houdini/reactions/myname.lua` returning a table that maps a reaction name to a function:

```lua
-- Houdini/reactions/myname.lua
local function MyNmReaction(args)
	if args[2] == nil then
		return
	end
	UpdateSkillchainElementFromReact(TitleCase(args[2]))
	local player = windower.ffxi.get_player()
	if player.main_job == "BLM" or player.main_job == "GEO" then
		CastNuke(TitleCase(args[2]))
	elseif player.main_job == "COR" then
		windower.send_command('input /ja "'..ElementToQuickDraw[TitleCase(args[2])]..'" <t>')
	elseif player.main_job == "SCH" then
		windower.send_command('input /ma "'..ElementToStorm[TitleCase(args[2])]..'" <me>')
	end
end

return {
	MyNM = MyNmReaction,   -- usable as: //ho react MyNM <element>
	MyNmAlias = MyNmReaction, -- an alternate name that triggers the same function
}
```

You can then trigger it with `//ho react MyNM Fire`.

**Notes for reaction authors:**
- The file must `return` a table. Each key becomes a reaction name (matched case-insensitively via `//ho react <name> ...`); each value must be a function that takes `args`, where `args[2]` is the element passed to the command.
- Reaction functions run with Houdini's globals already in scope — `TitleCase`, `CastNuke`, `CastAoE`, `UpdateSkillchainElementFromReact`, `ElementToQuickDraw`, `ElementToStorm`, and `windower.*` — so you don't need to `require` anything.
- Aliases work two ways: assign the same function to multiple keys (as above), or point a key at another key's *name* as a string, e.g. `MyNmAlias = 'MyNM'`.
- Reaction files are loaded once, on addon load/reload (`//ho reload` picks up new/changed files).
- Bundled examples: `reactions/degei.lua` (`Degei`/`Aita`) and `reactions/gartell.lua` (`Gartell`/`Leshonn`).

## Element to Skillchain Mappings

Default mappings (customizable):

```lua
Light         → Fire
Darkness      → Stone
Fusion        → Fire
Distortion    → Blizzard
Gravitation   → Stone
Fragmentation → Thunder
Liquefaction  → Fire
Detonation    → Aero
Impaction     → Thunder
Induration    → Blizzard
Reverberation → Water
```

## Configuration File

Settings are saved per character in:
```
Windower/addons/Houdini/data/<CharacterName>.xml
```

Default settings include:
- Element mappings (per skillchain type)
- Tier delays (configurable: `tierDelays`)
  - Default: `{1.0, 2.0, 3.0, 4.1, 4.6, 5.0, 5.0}` (in seconds)
- Leader burst delay (configurable: `leaderBurstDelay` - default 3.0s)
- COR Quick Draw delay (configurable: `corQuickDrawDelay` - default 0.25s)
- Leader/follower status
- MP warning threshold (configurable: `mppWarning` - default 40.0%)
  - Set via `//ho mpwarning [percent]`
  - Set to 0 to disable warnings
- Myrkr settings:
  - `myrkrTp` - TP threshold (default 1000)
  - `myrkrMpPercent` - MP% threshold (default 40)
- Ra'Kaznar Shard reporting (configurable: `shard_reporting` - default false)
  - Set via `//ho shard_reporting`
  - Tracks and reports missing shards to party chat
- Debuff spell (configurable: `debuff` - default "")
  - Set via `//ho debuff <spell>`
- Display preferences (position, colors, fonts)
- Tell list for target synchronization

**Advanced Configuration:**
Edit the XML settings file directly to customize tier delays or other advanced settings.

## Display

The on-screen display shows:
- Enabled status (green/red)
- Leader status
- Aja usage
- Send target status
- Send/use messages status
- Helix status
- Myrkr status
- Current element mappings
- **Bursting status** (shown in blue when actively magic bursting)

Toggle with `//ho display` and reposition with `//ho pos <x> <y>`.

## Tips and Best Practices

1. **Spell Timing**: Adjust `tierDelays` in settings if bursts are landing outside SC window
2. **MP Management**:
   - Enable Myrkr for SCH to maintain MP during long fights
   - Configure MP warning threshold with `//ho mpwarning [percent]`
   - Set to 0 to disable warnings if managing MP manually
3. **Leader Delay**: Adjust `leaderBurstDelay` (default 3.0s) for your skillchain timing
4. **Leader Who Doesn't SC**: Use `//ho leader 1` if you're the designated leader but another character (like a melee) creates the skillchains
5. **Cancel Burst**: Use `//ho cancelburst` to immediately stop a burst sequence if the target dies or SC fails
6. **Element Selection**: Configure elements based on mob resistances and day/weather
7. **Party Coordination**: Use `send_messages` to keep party informed of actions
8. **GearSwap Integration**: Ensure Burst Mode is configured in your GearSwap files
9. **Meteor Coordination**: Use `//ho meteor` for BLM nuke coordination on tough mobs
10. **Potency Timing**: Leader with `//ho leader 1` will trigger potency on self; standard leader sends to others only

## Integration with Other Addons

### GearSwap
- Integrates with Burst Mode (`//gs c activate Burst Mode`)
    -- example of command in your gearswap lua
    elseif command == "activate Burst Mode" then
        Burst_mode = true
        send_command("@input /echo <----- Magic Burst ON ----->")
    elseif command == "deactivate Burst Mode" then
        Burst_mode = false
        send_command("@input /echo <----- Magic Burst OFF ----->")
- Myrkr locks staff slot (`//gs c lock staff`)
    -- example of command in your gearswap lua
    elseif command == "lock staff" then
        local StaffLock = {main="Marin Staff +1", sub="Enki Strap"}
        equip(StaffLock)
        send_command("gs disable main")
        send_command("gs disable sub")
    elseif command == "unlock staff" then
        send_command("gs enable main")
        send_command("gs enable sub")
        equip(sets.Idle)

### SendAllTarget
- Uses `//sat` commands for target synchronization
- Requires SendAllTarget addon to be loaded

### Send Addon
- Uses `//send @others` for command distribution
- Requires Send addon for multi-boxing

## Troubleshooting

**Bursts landing outside window:**
- Adjust `tierDelays` in settings
- Reduce `leaderBurstDelay` if leader bursts are too slow

**Not responding to party messages:**
- Ensure `//ho use_messages` is enabled
- Check that messages are in party or tell chat (modes 3/4)

**Myrkr not triggering:**
- Verify staff is equipped (checks weapon skill type)
- Check TP threshold (default 1000)
- Check MP% threshold (default 40%)

**Spells not casting:**
- Verify job can cast spell (BLM/RDM/SCH/GEO)
- Check MP is sufficient
- Check spell recast timer

## Recent Updates

### Latest Changes
- **Extensible NM reactions**: Reactions now auto-load from `reactions/*.lua` sidecar files instead of being hardcoded — see [NM Reactions](#nm-reactions) for how to add your own without editing `Houdini.lua`
- **Added Ra'Kaznar Shard tracking**: Automatic shard detection and party reporting
  - `//ho shard_reporting` (aliases: `shards`, `shard`) - Toggle tracking on/off
  - Automatically detects when you obtain Ra'Kaznar Shards A, B, C, or D
  - Scans all bags and temporary items to check which shards you have
  - Reports to party chat which shards are still needed
  - Announces when all shards are obtained
  - Disabled by default
- **Added shorthand element commands**: Quick element configuration for common skillchains
  - `//ho dist/frag/light/dark <element>` - Set elements without typing full skillchain names
  - Party chat support: `dist`, `frag`, `light`, `dark` messages
- **Added debuff management**: Configure and cast debuff spells
  - `//ho debuff <spell>` - Set debuff spell to use
  - `//ho dodebuff` - Cast the configured debuff spell
  - Party chat command: `dodebuff`
- **Added command aliases**: More convenient command syntax
  - `sendtarget`, `sendtar` for `send_target`
  - `sendmessage`, `sendmsg` for `send_messages`
  - `usemessages`, `usemsg` for `use_messages`
  - `useaja`, `aja` for `use_aja`
- **Enhanced display**: Shows "Bursting" status in blue when actively magic bursting
- **Added Scission skillchain**: Support for Scission skillchain element mapping
- **Added `//ho meteor` command**: BLM Elemental Seal + Meteor coordination
  - Uses Elemental Seal, waits 1s, then casts Meteor
  - Leader can coordinate all BLMs with single command
  - Party chat command: `dometeor`
- **Added `//ho mpwarning [mpp]` command**: Configurable MP warning threshold (previously hardcoded at 40%)
- **Added `//ho leader 1`**: Leader mode for characters who don't create skillchains (gets 3 bursts instead of 2)
- **Added `//ho cancelburst`**: Cancel active burst sequences mid-execution
- **Added Collimated Fervor support**: GEO job ability support for `//ho potency` command
- **Added Aspir III support**: Highest tier Aspir for BLM and GEO
- **Improved potency command**: Leader with `//ho leader 1` now triggers potency on self
- **Added `cancelburst` party command**: Remote burst cancellation via party/tell
- **Improved code quality**: Variable naming consistency (Settings, LastCheckTime, etc.)
- **Fixed logout behavior**: Properly unloads addon on logout
- **Enhanced multi-boxing**: Two distinct leader modes for different playstyles

## Version History

### 0.1.0 (2025.11.1)
- Initial release
- Magic burst automation
- Multi-boxing support
- Job-specific features (BLM, SCH, GEO, RDM, COR)
- Party/tell command system
- Myrkr automation for SCH
- Configurable timing system
- MP warning system
- Visual on-screen display

## Credits

**Author**: EvilPotat0

## Support

For issues, suggestions, or contributions, please contact the author or submit via the appropriate channels.

## License

This addon is provided as-is for use with Windower for Final Fantasy XI.
