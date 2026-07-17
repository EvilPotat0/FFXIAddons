# DebuffWatch

Automatically announces when tracked debuffs wear off monsters in range.

## Overview

DebuffWatch monitors debuffs you apply to enemies and sends a party message when they wear off. This is especially useful for:
- Bards tracking Threnodies on enemies
- Black Mages tracking elemental debuffs (Burn, Frost, Choke, etc.)
- Support jobs tracking enfeebles (Dia, Bio, Slow, Paralyze, etc.)
- Coordinating debuff reapplication in party/alliance content

## Features

- **Automatic Tracking**: Monitors debuffs you cast on enemies
- **Range-Based Announcements**: Only announces for enemies within configurable range
- **Customizable Watch List**: Choose which specific debuffs to track
- **Party Notifications**: Sends messages with auto-translate <call20>
- **Multiple Channels**: Announce to party, linkshell, or say

## Installation

1. Copy the `DebuffWatch` folder to your `Windower/addons/` directory
2. Load the addon in-game:
   ```
   //lua load DebuffWatch
   ```

## Commands

| Command | Description |
|---------|-------------|
| `//dw add <spell>` | Add spell/debuff to watch list |
| `//dw remove <spell>` | Remove spell from watch list |
| `//dw list` | Show current watch list and settings |
| `//dw clear` | Clear all active tracking |
| `//dw range <distance>` | Set announcement range in yalms (default: 50) |
| `//dw channel <p\|l\|s>` | Set channel: p=party, l=linkshell, s=say |
| `//dw toggle` | Toggle DebuffWatch on/off |
| `//dw help` | Show help information |

**Aliases**: `//dw` or `//debuffwatch`

## Usage Examples

### Bard Setup (Tracking Threnodies)

```bash
# Add common threnodies to watch list
//dw add Fire Threnody
//dw add Ice Threnody
//dw add Wind Threnody
//dw add Earth Threnody
//dw add Lightning Threnody
//dw add Water Threnody
//dw add Light Threnody
//dw add Dark Threnody

# Add tier II threnodies
//dw add Fire Threnody II
//dw add Ice Threnody II
//dw add Dark Threnody II
```

### Black Mage Setup (Elemental Debuffs)

```bash
# Track elemental debuffs
//dw add Burn
//dw add Frost
//dw add Choke
//dw add Rasp
//dw add Shock
//dw add Drown
```

### Red Mage/Support Setup (Enfeebles)

```bash
# Track common enfeebles
//dw add Dia
//dw add Dia II
//dw add Dia III
//dw add Bio
//dw add Bio II
//dw add Bio III
//dw add Slow
//dw add Slow II
//dw add Paralyze
//dw add Paralyze II
```

### Configuration

```bash
# Set announcement range to 30 yalms
//dw range 30

# Change to linkshell channel
//dw channel l

# View current settings
//dw list

# Temporarily disable
//dw toggle
```

## How It Works

1. **Application**: When you cast a tracked debuff on an enemy, DebuffWatch starts monitoring it
2. **Tracking**: The addon watches the enemy's status effect list
3. **Detection**: When the debuff wears off (no longer in status list), DebuffWatch detects it
4. **Range Check**: Verifies the enemy is within your configured range
5. **Announcement**: Sends a party message: `"<Spell Name> just wore!! <call20>"`

## Sample Output

When Dark Threnody II wears off an enemy in range:
```
/p Dark Threnody II just wore!! <call20>
```

The party will see:
```
[Player]: Dark Threnody II just wore!! 🔔
```

## Tips

- **Range Setting**: Set range based on your casting distance (30-50 yalms is typical)
- **Watch List**: Only add debuffs you actively use to avoid spam
- **Channel**: Use `/p` for party content, `/l` for linkshell coordination
- **Clear on Zone**: Active tracking automatically clears when you zone
- **Toggle**: Use `//dw toggle` to disable temporarily during solo content

## Technical Details

- Monitors `action` packets to detect debuff application
- Tracks status effect packets (0x076) to detect wear-off
- Automatically cleans up tracking when mobs die
- Stores watched debuffs in per-character settings
- Range calculated using 3D euclidean distance

## Troubleshooting

**Debuffs not being tracked:**
- Verify the spell is in your watch list: `//dw list`
- Check that DebuffWatch is enabled: `//dw toggle`
- Ensure the spell landed successfully (watch for resists)

**Too many/few announcements:**
- Adjust range: `//dw range 30`
- Review watch list and remove unwanted spells

**Announcements in wrong chat:**
- Change channel: `//dw channel p` (for party)

## Version History

### v1.0.0
- Initial release
- Debuff application tracking
- Wear-off detection and announcement
- Configurable range and channel
- Watch list management
- Auto-cleanup on zone/mob death

## Author

Created by EvilPotat0 + Claude code

## License

Free to use and modify
