# BagInfo

A Windower addon for Final Fantasy XI that displays current/max item counts for your inventory bags and currency amounts.

## Overview

BagInfo provides an on-screen display showing:
- How many items you have in each bag versus the maximum capacity
- Your current currency amounts (gil, bayld, sparks, etc.)

By default, only your main Inventory is shown, but you can toggle any bag or currency on/off to monitor what matters to you.

## Features

- Real-time inventory tracking with current/max counts
- Currency tracking (gil, bayld, sparks, capacity points, etc.)
- Color-coded bag display (green/orange/red based on fullness)
- Toggle individual bags and currencies on/off
- Draggable display window
- Automatic updates when items/currencies change
- Supports all FFXI bags and currencies

## Installation

1. Copy the `BagInfo` folder to your `Windower/addons/` directory
2. Load the addon in-game:
   ```
   //lua load BagInfo
   ```

**Requirements**: This addon requires the `packets` library (included with Windower).

**Note**: Currency values are retrieved from network packets sent by the game server. They update automatically when you:
- Open currency-related menus
- Zone into new areas
- Gain or spend currencies
- Login to the game

If currencies show as 0, open your currency menu in-game (Key Items → Currency) to trigger an update packet.

## Commands

| Command | Description |
|---------|-------------|
| `//bag toggle <bag>` | Toggle a specific bag display on/off |
| `//bag currency <name>` | Toggle a specific currency display on/off |
| `//bag all` | Show all available bags |
| `//bag allcurrency` | Show all currencies |
| `//bag none` | Hide all bags except Inventory |
| `//bag nocurrency` | Hide all currencies |
| `//bag pos <x> <y>` | Set display position |
| `//bag status` | Show current settings |
| `//bag help` | Show help information |

### Command Aliases

You can use either of these command prefixes:
- `//bag` (short)
- `//baginfo` (full)

## Usage Examples

### Basic Usage
```bash
//bag toggle satchel      # Show Satchel
//bag toggle sack         # Show Sack
//bag toggle case         # Show Case
//bag toggle wardrobe     # Show Wardrobe
```

### Currency Tracking
```bash
//bag currency gil        # Show Gil
//bag currency bayld      # Show Bayld
//bag currency sparks     # Show Sparks of Eminence
//bag currency capacity_points  # Show Capacity Points
//bag currency escha_beads      # Show Escha Beads
```

### Managing Display
```bash
//bag all                 # Show all available bags
//bag allcurrency         # Show all currencies
//bag none                # Show only Inventory
//bag nocurrency          # Hide all currencies
//bag pos 100 200         # Move display to x=100, y=200
//bag status              # See what's currently displayed
```

### Wardrobe Bags
```bash
//bag toggle wardrobe     # Wardrobe 1
//bag toggle wardrobe2    # Wardrobe 2
//bag toggle wardrobe3    # Wardrobe 3
# ... up to wardrobe8
```

## Available Bags

**Main Inventory:**
- `inventory` - Main inventory (default: visible)

**Expansion Bags:**
- `satchel` - Gobbiebag expansion
- `sack` - Gobbiebag expansion
- `case` - Gobbiebag expansion

**Wardrobe:**
- `wardrobe` - Wardrobe 1
- `wardrobe2` through `wardrobe8` - Additional wardrobes

**Storage:**
- `safe` - Mog Safe
- `storage` - Mog Storage
- `locker` - Mog Locker
- `temporary` - Temporary items

## Available Currencies

**Basic Currencies:**
- `gil` - Gil
- `bayld` - Bayld
- `sparks` - Sparks of Eminence
- `unity_accolades` - Unity Accolades

**Battle Content:**
- `hallmarks` - Hallmarks (Ambuscade)
- `gallantry` - Gallantry (Ambuscade)

**Character Progress:**
- `capacity_points` - Capacity Points
- `login_points` - Login Points

**Nation/Allegiance:**
- `conquest_points` - Conquest Points
- `imperial_standing` - Imperial Standing (Aht Urhgan)
- `allied_notes` - Allied Notes

**Special Areas:**
- `cruor` - Cruor (Abyssea)
- `resistance_credits` - Resistance Credits (Abyssea)
- `dominion_notes` - Dominion Notes
- `coalition_imprimaturs` - Coalition Imprimaturs (Adoulin)
- `plasm` - Mweya Plasm (Reisenjima)
- `escha_silt` - Escha Silt
- `escha_beads` - Escha Beads

## Display Features

### Color Coding

**Bags** use color coding to show fullness:
- **Green** (0-74% full) - Plenty of space
- **Orange** (75-89% full) - Getting full
- **Red** (90%+ full) - Nearly full

**Currencies** are displayed in yellow for easy visibility.

### Display Format

```
=== Bag Info ===
Inventory: 45/80
Satchel: 12/80
Sack: 8/80
Wardrobe: 78/80

=== Currencies ===
Gil: 1,234,567
Bayld: 45,000
Sparks: 12,345
Capacity Points: 987
```

### Draggable Window

The display window is draggable - click and drag to reposition it anywhere on screen.

## Configuration

Settings are automatically saved to `addons/BagInfo/data/settings.xml` and include:
- Display position (x, y coordinates)
- Which bags are visible

### Manual Configuration

Edit `data/settings.xml`:
```xml
<?xml version="1.0" ?>
<settings>
    <pos>
        <x>0</x>
        <y>500</y>
    </pos>
    <show_bags>
        <inventory>true</inventory>
        <satchel>false</satchel>
        <sack>false</sack>
        <case>false</case>
        <!-- ... other bags ... -->
    </show_bags>
</settings>
```

## Tips & Tricks

### Quick Setup for Mules
```bash
//bag all                # Show everything at once
```

### Crafting Setup
Monitor just the bags you need:
```bash
//bag toggle inventory
//bag toggle satchel
//bag toggle case
```

### Inventory Management
Keep an eye on your main bags:
```bash
//bag toggle inventory
//bag toggle satchel
//bag toggle sack
//bag toggle case
```

### Currency Tracking for Activities

**Ambuscade Farming:**
```bash
//bag currency hallmarks
//bag currency gallantry
```

**Domain Invasion / Capacity Point Parties:**
```bash
//bag currency capacity_points
//bag currency domain_notes
```

**Sparks Farming:**
```bash
//bag currency sparks
//bag currency unity_accolades
```

**Escha Content:**
```bash
//bag currency escha_silt
//bag currency escha_beads
```

**Abyssea:**
```bash
//bag currency cruor
//bag currency resistance_credits
```

**Adoulin (Coalition Assignments):**
```bash
//bag currency coalition_imprimaturs
//bag currency bayld
```

### Minimal Display
```bash
//bag none              # Just show inventory
//bag nocurrency        # Hide all currencies
```

## Troubleshooting

### Display not showing
- Verify addon is loaded: `//lua list`
- Try reloading: `//lua reload BagInfo`
- Check that at least one bag is toggled on: `//bag status`

### Counts not updating
- The display updates automatically when items change
- Also updates every game-time change (roughly every 1 minute real time)
- Try `//lua reload BagInfo` if stuck

### Bag not appearing
- Some bags only appear when you have access to them (e.g., wardrobes require purchase)
- Use `//bag status` to see which bags are available

## Version History

### v2.0.0
- Added currency tracking (gil, bayld, sparks, capacity points, etc.)
- 18 different currencies supported
- Commands: `currency`, `allcurrency`, `nocurrency`
- Formatted currency display with commas
- Updated help and status commands
- Currencies: gil, bayld, sparks, unity_accolades, hallmarks, gallantry, capacity_points, login_points, conquest_points, imperial_standing, allied_notes, cruor, resistance_credits, dominion_notes, coalition_imprimaturs, plasm, escha_silt, escha_beads

### v1.0.0
- Initial release
- Real-time inventory tracking
- Toggle individual bags
- Color-coded fullness indicators
- Draggable display window

## License

This addon is provided as-is for use with Windower for FFXI.

---

**Quick Reference:**
- Load: `//lua load BagInfo`
- Toggle bag: `//bag toggle <name>`
- Toggle currency: `//bag currency <name>`
- Show all bags: `//bag all`
- Show all currencies: `//bag allcurrency`
- Hide all bags: `//bag none`
- Hide all currencies: `//bag nocurrency`
- Move: `//bag pos <x> <y>`
- Status: `//bag status`
