_addon.name = 'AutoTank'
_addon.author = 'EvilPotat0'
_addon.commands = {'autotank', 'at'}
_addon.version = '1.0.0'
_addon.lastUpdate = '2026.01.29'

require('luau')
require('tables')
require('strings')
require('sets')
require('lists')

res = require('resources')
config = require('config')
texts = require('texts')

-- Element to Rune name mapping
local element_to_rune = {
    -- Fire
    fire = 'Ignis',
    ignis = 'Ignis',
    -- Ice
    ice = 'Gelus',
    gelus = 'Gelus',
    -- Wind
    wind = 'Flabra',
    aero = 'Flabra',
    flabra = 'Flabra',
    -- Earth
    earth = 'Tellus',
    stone = 'Tellus',
    tellus = 'Tellus',
    -- Thunder/Lightning
    thunder = 'Sulpor',
    lightning = 'Sulpor',
    sulpor = 'Sulpor',
    -- Water
    water = 'Unda',
    unda = 'Unda',
    -- Light
    light = 'Lux',
    lux = 'Lux',
    -- Dark
    dark = 'Tenebrae',
    darkness = 'Tenebrae',
    tenebrae = 'Tenebrae',
}

-- Initialize settings with defaults
local defaults = {
    enabled = false,
    auto_engage = false,

    -- Healing thresholds
    healing = {
        cure_hp = 75,           -- HP% to start curing at
        cure_emergency_hp = 50, -- HP% for emergency cure
        use_cures = true,
        cure_party = true,      -- Cure party members below cure_hp threshold
    },

    -- PLD Settings
    pld = {
        use_sentinel = true,
        sentinel_hp = 25,
        use_rampart = true,
        rampart_hp = 50,
        use_palisade = true,
        palisade_hp = 70,
        use_cover = false,
        cover_target = '',
        use_divine_emblem = true,
        use_majesty = true,
        use_chivalry = true,
        chivalry_mp = 30,
        chivalry_tp = 100,
        use_shield_bash = true,
        use_holy_circle = false,
    },

    -- RUN Settings
    run = {
        use_vallation = true,
        use_valiance = true,
        use_pflug = true,
        pflug_hp = 60,
        use_swordplay = true,
        use_battuta = true,
        use_liement = true,
        use_rayke = true,
        use_gambit = true,
        use_embolden = true,

        -- Rune management
        rune_element = 'Ignis',     -- Default rune (Ignis/Gelus/Flabra/Tellus/Sulpor/Unda/Lux/Tenebrae)
        auto_rune = true,
        rune_count = 3,             -- Number of runes to maintain
        use_swipe = false,
        use_lunge = false,
        use_foil = true,
        ward_delay = 5,             -- Seconds between ward ability usages (Vallation/Valiance/Battuta/Liement)
        use_vivacious_pulse = true,
        vivacious_pulse_hp = 85,    -- Use when HP <= this% (non-Tenebrae runes)
        vivacious_pulse_mp = 50,    -- Use when MP <= this% (Tenebrae runes restore MP)
    },

    -- Subjob abilities
    subjob = {
        -- WAR
        use_provoke = true,
        use_warcry = false,
        use_defender = false,
        use_aggressor = false,

        -- BLU (configurable spell list)
        blu_spells = {
            -- Defensive spells (self-target)
            {name = 'Cocoon', target = 'self', enabled = true, aoe = false, is_buff = true, buff_name = 'Defense Boost'},
           -- {name = 'Metallic Body', target = 'self', hp_threshold = 60, enabled = false, aoe = false},
            --{name = 'Diamondhide', target = 'self', hp_threshold = 65, enabled = false, aoe = false},

            -- Healing spells (self-target, cast when HP <= threshold)
            {name = 'Magic Fruit', target = 'self', hp_threshold = 60, enabled = true, aoe = false, is_heal = true},
            {name = 'Healing Breeze', target = 'self', hp_threshold = 75, enabled = true, aoe = false, is_heal = true},
            -- Offensive spells (enemy target)
            {name = 'Jettatura', target = 'enemy', enabled = true, aoe = true},
            {name = 'Blank Gaze', target = 'enemy', enabled = true, aoe = false},
            {name = 'Geist Wall', target = 'enemy', enabled = true, aoe = true},

            -- Utility spells
            --{name = 'Refueling', target = 'self', enabled = true, aoe = false},
            --{name = 'Battery Charge', target = 'self', enabled = false, aoe = false},

            -- AoE/Control spells (use with caution)
            {name = 'Sheep Song', target = 'enemy', enabled = true, aoe = true},
            {name = 'Soporific', target = 'enemy', enabled = true, aoe = true},
            {name = 'Frightful Roar', target = 'enemy', enabled = true, aoe = true},
            {name = 'Cold Wave', target = 'enemy', enabled = true, aoe = true},
        },

        -- SCH
        use_regen = true,
        use_stoneskin = true,
    },

    -- Spell settings
    spells = {
        use_flash = true,
        use_enlight = true,
        use_reprisal = true,
        use_phalanx = true,
        use_crusade = true,
        use_aquaveil = true,
        use_protect = true,
        use_shell = true,
        use_aoe_spells = false,
        use_targeted_spells = true,
    },

    -- Enmity management
    enmity = {
        flash_interval = 30,        -- Seconds between Flash casts
        provoke_interval = 30,      -- Seconds between Provoke uses
        use_enmity_rotation = true,
        maintain_engagement = true,
    },

    -- Action delays (prevents action spam)
    ability_delay = 1.0,            -- Seconds between job abilities
    spell_delay = 2.0,              -- Seconds between spell casts

    -- Consumable items
    items = {
        use_remedy = true,          -- Auto-use Remedy when paralyzed
        use_holy_water = true,      -- Auto-use Holy Water when doomed
        item_interval = 5,          -- Seconds between item uses (retry if debuff persists)
    },
}

local settings = config.load(defaults)

-- The config library uses positional matching against defaults to merge XML.
-- Entries in the XML beyond the defaults array length get string keys (e.g. "11")
-- instead of integer keys. When config.save is later called, nest_xml sorts all
-- keys together — mixing integers and strings causes "attempt to compare string
-- with number". Fix: collapse any string-numeric overflow keys into sequential
-- integer keys immediately after load.
do
    local raw = settings.subjob.blu_spells
    local normalized = {}
    for i = 1, #raw do
        normalized[i] = raw[i]
    end
    for k, v in pairs(raw) do
        if type(k) == 'string' and tonumber(k) then
            normalized[#normalized + 1] = v
        end
    end
    for _, spell in ipairs(normalized) do
        if spell.hp_threshold ~= nil then
            spell.hp_threshold = tonumber(spell.hp_threshold) or spell.hp_threshold
        end
    end
    settings.subjob.blu_spells = normalized
end

-- State tracking
local state = {
    last_flash = 0,
    last_provoke = 0,
    last_cure = 0,
    last_rune_check = 0,
    last_item_use = 0,
    current_runes = 0,
    buffs = {},
    in_combat = false,
}

-- Movement detection: compare XYZ bytes from outgoing position packets (0x015)
local last_coords = nil

-- Display text
local display = texts.new('${current_state}', {
    pos = {x = 100, y = 100},
    bg = {alpha = 128, red = 0, green = 0, blue = 0},
    flags = {bold = true},
    text = {size = 10, font = 'Consolas'},
})

-- Utility functions
local function atc(str, ...)
    windower.add_to_chat(121, _addon.name .. ': ' .. str:format(...))
end

local function atcc(color, str, ...)
    windower.add_to_chat(color, _addon.name .. ': ' .. str:format(...))
end

-- Get player info
local function get_player()
    return windower.ffxi.get_player()
end

-- Get current target
local function get_target()
    local target = windower.ffxi.get_mob_by_target('t')
    return target
end

-- Check if ability is ready
local function is_ability_ready(ability_name)
    local ability = res.job_abilities:with('en', ability_name)
    if not ability then return false end

    local recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
    return recast == 0
end

-- Check if spell is ready
local function is_spell_ready(spell_name)
    local spell = res.spells:with('en', spell_name)
    if not spell then return false end

    local recast = windower.ffxi.get_spell_recasts()[spell.recast_id]
    return recast == 0
end

-- Check if player has buff
local function has_buff(buff_name)
    local player = get_player()
    if not player then return false end

    local buff_id = res.buffs:with('en', buff_name)
    if not buff_id then return false end

    for _, buff in ipairs(player.buffs) do
        if buff == buff_id.id then
            return true
        end
    end
    return false
end

-- Use job ability
local function use_ability(ability_name, target)
    if is_ability_ready(ability_name) then
        local target_str = target or '<me>'
        windower.send_command('input /ja "'..ability_name..'" '..target_str)
        return true
    end
    return false
end

-- Cast spell
local function cast_spell(spell_name, target)
    if is_spell_ready(spell_name) then
        local target_str = target or '<me>'
        windower.send_command('input /ma "'..spell_name..'" '..target_str)
        return true
    end
    return false
end

-- Update display
local function update_display()
    if not settings.enabled then
        display:text('AutoTank: OFF')
        display:visible(true)
        return
    end

    local player = get_player()
    if not player then return end

    local lines = {}
    table.insert(lines, 'AutoTank: ON')
    table.insert(lines, 'Job: '..player.main_job..' / '..player.sub_job)
    table.insert(lines, 'HP: '..player.vitals.hp..'/'..player.vitals.max_hp..' ('..player.vitals.hpp..'%)')
    table.insert(lines, 'MP: '..player.vitals.mp..'/'..player.vitals.max_mp..' ('..player.vitals.mpp..'%)')

    if player.main_job == 'RUN' then
        table.insert(lines, 'Runes: '..state.current_runes)
        table.insert(lines, 'Element: '..settings.run.rune_element)
    end

    table.insert(lines, 'Combat: '..(state.in_combat and 'YES' or 'NO'))
    table.insert(lines, 'Moving: '..(AutoTankUtils.is_player_moving() and 'YES' or 'NO'))

    display:text(table.concat(lines, '\n'))
    display:visible(true)
end

-- Save settings
local function save_settings()
    settings:save('all')
end

-- Print status
local function print_status()
    atcc(262, '=== AutoTank Status ===')
    atc('Enabled: %s', settings.enabled and 'ON' or 'OFF')
    atc('Auto Engage: %s', settings.auto_engage and 'ON' or 'OFF')
    atc('Cure HP Threshold: %d%%', settings.healing.cure_hp)

    local player = get_player()
    if player then
        if player.main_job == 'PLD' then
            atc('Sentinel: %s (HP: %d%%)', settings.pld.use_sentinel and 'ON' or 'OFF', settings.pld.sentinel_hp)
            atc('Rampart: %s (HP: %d%%)', settings.pld.use_rampart and 'ON' or 'OFF', settings.pld.rampart_hp)
            atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
        elseif player.main_job == 'RUN' then
            atc('Rune Element: %s', settings.run.rune_element)
            atc('Auto Rune: %s (Count: %d)', settings.run.auto_rune and 'ON' or 'OFF', settings.run.rune_count)
            atc('Vallation: %s', settings.run.use_vallation and 'ON' or 'OFF')
        end
    end
end

-- Load the automation modules
require('AutoTankUtils')
require('AutoTank_PLD')
require('AutoTank_RUN')
require('AutoTank_Subjobs')

--[[
    COMMAND HELPER FUNCTIONS
]]--

-- BLU spell management helper
local function handle_blu_command(args)
    if #args == 0 then
        -- List all BLU spells
        atcc(262, '=== BLU Spells ===')
        for i, spell in ipairs(settings.subjob.blu_spells) do
            local status = spell.enabled and 'ON' or 'OFF'
            local threshold = spell.hp_threshold and (' HP<=' .. spell.hp_threshold .. '%') or ''
            local aoe_flag = spell.aoe and ' [AoE]' or ''
            local buff_flag = spell.is_buff and (' [BUFF' .. (spell.buff_name and ':' .. spell.buff_name or '') .. ']') or ''
            local heal_flag = spell.is_heal and ' [HEAL]' or ''
            atc('%d. %s (%s) - %s%s%s%s%s', i, spell.name, spell.target, status, threshold, aoe_flag, buff_flag, heal_flag)
        end
        return
    end

    local subcmd = args[1]

    if subcmd == 'add' and #args >= 3 then
        -- Add new BLU spell: //at blu add <name> <target> [hp_threshold] [aoe]
        local spell_name = args[2]
        local target_type = args[3]:lower()
        local hp_threshold = args[4] and tonumber(args[4]) or nil
        local is_aoe = args[5] and args[5]:lower() == 'true' or false

        if target_type ~= 'self' and target_type ~= 'enemy' then
            atc('Error: Target must be "self" or "enemy"')
            return
        end

        -- Check if spell already exists
        for _, spell in ipairs(settings.subjob.blu_spells) do
            if spell.name:lower() == spell_name:lower() then
                atc('Error: Spell "%s" already exists. Use "blu enable" to turn it on.', spell_name)
                return
            end
        end

        -- Add new spell
        table.insert(settings.subjob.blu_spells, {
            name = spell_name,
            target = target_type,
            hp_threshold = hp_threshold,
            enabled = true,
            aoe = is_aoe
        })
        save_settings()
        atc('Added BLU spell: %s (target: %s)', spell_name, target_type)

    elseif subcmd == 'remove' and #args >= 2 then
        -- Remove BLU spell: //at blu remove <name or index>
        local identifier = args[2]
        local index = tonumber(identifier)
        local removed = false

        if index then
            -- Remove by index
            if index >= 1 and index <= #settings.subjob.blu_spells then
                local spell = settings.subjob.blu_spells[index]
                table.remove(settings.subjob.blu_spells, index)
                save_settings()
                atc('Removed BLU spell: %s', spell.name)
                removed = true
            end
        else
            -- Remove by name
            for i, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    table.remove(settings.subjob.blu_spells, i)
                    save_settings()
                    atc('Removed BLU spell: %s', spell.name)
                    removed = true
                    break
                end
            end
        end

        if not removed then
            atc('Error: Spell not found: %s', identifier)
        end

    elseif subcmd == 'enable' and #args >= 2 then
        -- Enable BLU spell: //at blu enable <name or index>
        local identifier = args[2]
        local index = tonumber(identifier)
        local found = false

        if index then
            if index >= 1 and index <= #settings.subjob.blu_spells then
                settings.subjob.blu_spells[index].enabled = true
                save_settings()
                atc('Enabled BLU spell: %s', settings.subjob.blu_spells[index].name)
                found = true
            end
        else
            for i, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    spell.enabled = true
                    save_settings()
                    atc('Enabled BLU spell: %s', spell.name)
                    found = true
                    break
                end
            end
        end

        if not found then
            atc('Error: Spell not found: %s', identifier)
        end

    elseif subcmd == 'disable' and #args >= 2 then
        -- Disable BLU spell: //at blu disable <name or index>
        local identifier = args[2]
        local index = tonumber(identifier)
        local found = false

        if index then
            if index >= 1 and index <= #settings.subjob.blu_spells then
                settings.subjob.blu_spells[index].enabled = false
                save_settings()
                atc('Disabled BLU spell: %s', settings.subjob.blu_spells[index].name)
                found = true
            end
        else
            for i, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    spell.enabled = false
                    save_settings()
                    atc('Disabled BLU spell: %s', spell.name)
                    found = true
                    break
                end
            end
        end

        if not found then
            atc('Error: Spell not found: %s', identifier)
        end

    elseif subcmd == 'hp' and #args >= 3 then
        -- Set HP threshold: //at blu hp <name or index> <threshold>
        local identifier = args[2]
        local threshold = tonumber(args[3])
        local index = tonumber(identifier)
        local found = false

        if not threshold or threshold < 0 or threshold > 100 then
            atc('Error: HP threshold must be between 0 and 100')
            return
        end

        if index then
            if index >= 1 and index <= #settings.subjob.blu_spells then
                settings.subjob.blu_spells[index].hp_threshold = threshold
                save_settings()
                atc('Set HP threshold for %s: %d%%', settings.subjob.blu_spells[index].name, threshold)
                found = true
            end
        else
            for i, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    spell.hp_threshold = threshold
                    save_settings()
                    atc('Set HP threshold for %s: %d%%', spell.name, threshold)
                    found = true
                    break
                end
            end
        end

        if not found then
            atc('Error: Spell not found: %s', identifier)
        end

    elseif subcmd == 'buff' and #args >= 2 then
        -- Set buff flag: //at blu buff <name|index> [buff_name]
        -- If buff_name is "none", clears is_buff and buff_name
        local identifier = args[2]
        local buff_name_arg = args[3]
        local index = tonumber(identifier)
        local found = false

        local function apply_buff(spell)
            if buff_name_arg and buff_name_arg:lower() == 'none' then
                spell.is_buff = false
                spell.buff_name = nil
                save_settings()
                atc('Cleared buff flag for %s', spell.name)
            else
                spell.is_buff = true
                spell.buff_name = buff_name_arg or nil
                save_settings()
                if spell.buff_name then
                    atc('Set %s as buff (checks for "%s")', spell.name, spell.buff_name)
                else
                    atc('Set %s as buff (checks for "%s")', spell.name, spell.name)
                end
            end
        end

        if index then
            if index >= 1 and index <= #settings.subjob.blu_spells then
                apply_buff(settings.subjob.blu_spells[index])
                found = true
            end
        else
            for _, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    apply_buff(spell)
                    found = true
                    break
                end
            end
        end

        if not found then
            atc('Error: Spell not found: %s', identifier)
        end

    elseif subcmd == 'heal' and #args >= 2 then
        -- Set heal flag: //at blu heal <name|index> [hp_threshold]
        -- If hp_threshold is "none", clears is_heal flag
        local identifier = args[2]
        local threshold_arg = args[3]
        local index = tonumber(identifier)
        local found = false

        local function apply_heal(spell)
            if threshold_arg and threshold_arg:lower() == 'none' then
                spell.is_heal = false
                save_settings()
                atc('Cleared heal flag for %s', spell.name)
            else
                spell.is_heal = true
                if threshold_arg then
                    local hp = tonumber(threshold_arg)
                    if hp and hp >= 1 and hp <= 99 then
                        spell.hp_threshold = hp
                        save_settings()
                        atc('Set %s as heal spell (HP <= %d%%)', spell.name, hp)
                    else
                        atc('Error: HP threshold must be 1-99')
                        return
                    end
                else
                    spell.hp_threshold = spell.hp_threshold or 75
                    save_settings()
                    atc('Set %s as heal spell (HP <= %d%%)', spell.name, spell.hp_threshold)
                end
            end
        end

        if index then
            if index >= 1 and index <= #settings.subjob.blu_spells then
                apply_heal(settings.subjob.blu_spells[index])
                found = true
            end
        else
            for _, spell in ipairs(settings.subjob.blu_spells) do
                if spell.name:lower() == identifier:lower() then
                    apply_heal(spell)
                    found = true
                    break
                end
            end
        end

        if not found then
            atc('Error: Spell not found: %s', identifier)
        end

    else
        atcc(262, '=== BLU Spell Commands ===')
        atc('//at blu - List all BLU spells')
        atc('//at blu add <name> <self|enemy> [hp%%] [true|false] - Add spell')
        atc('//at blu remove <name|index> - Remove spell')
        atc('//at blu enable <name|index> - Enable spell')
        atc('//at blu disable <name|index> - Disable spell')
        atc('//at blu hp <name|index> <hp%%> - Set HP threshold')
        atc('//at blu buff <name|index> [buff_name] - Flag as buff (skips if active); use "none" to clear')
        atc('//at blu heal <name|index> [hp%%] - Flag as heal spell (casts when HP <= threshold); use "none" to clear')
    end
end

-- PLD ability toggle helper
local function handle_pld_command(args)
    if #args == 0 then
        -- List all PLD abilities with status
        atcc(262, '=== Paladin Abilities ===')
        atc('Sentinel: %s (HP <= %d%%)', settings.pld.use_sentinel and 'ON' or 'OFF', settings.pld.sentinel_hp)
        atc('Rampart: %s (HP <= %d%%)', settings.pld.use_rampart and 'ON' or 'OFF', settings.pld.rampart_hp)
        atc('Palisade: %s (HP <= %d%%)', settings.pld.use_palisade and 'ON' or 'OFF', settings.pld.palisade_hp)
        atc('Shield Bash: %s', settings.pld.use_shield_bash and 'ON' or 'OFF')
        atc('Divine Emblem: %s', settings.pld.use_divine_emblem and 'ON' or 'OFF')
        atc('Majesty: %s', settings.pld.use_majesty and 'ON' or 'OFF')
        atc('Chivalry: %s (MP <= %d%%, TP >= %d)', settings.pld.use_chivalry and 'ON' or 'OFF', settings.pld.chivalry_mp, settings.pld.chivalry_tp)
        atc('Cover: %s', settings.pld.use_cover and 'ON' or 'OFF')
        atc('Holy Circle: %s', settings.pld.use_holy_circle and 'ON' or 'OFF')
        atcc(262, '=== Paladin Spells ===')
        atc('Enlight: %s', settings.spells.use_enlight and 'ON' or 'OFF')
        atc('Reprisal: %s', settings.spells.use_reprisal and 'ON' or 'OFF')
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        atc('Crusade: %s', settings.spells.use_crusade and 'ON' or 'OFF')
        atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
        atcc(262, '=== Healing ===')
        atc('Cure Party: %s', settings.healing.cure_party and 'ON' or 'OFF')
        atc('')
        atc('Usage: //at pld <ability> - Toggle on/off')
        atc('       //at pld sentinel|rampart|palisade <hp%%> - Set HP threshold')
        atc('       //at pld chivalry <mp%%> - Set MP threshold')
        atc('       //at pld chivalry tp <tp> - Set TP required')
        return
    end

    local ability = args[1]:lower()
    local toggled = false

    -- Map command names to settings paths
    if ability == 'sentinel' then
        if args[2] then
            local hp = tonumber(args[2])
            if hp and hp >= 1 and hp <= 99 then
                settings.pld.sentinel_hp = hp
                atc('Sentinel HP threshold: %d%%', hp)
                toggled = true
            else
                atc('Error: HP threshold must be 1-99')
            end
        else
            settings.pld.use_sentinel = not settings.pld.use_sentinel
            atc('Sentinel: %s (HP <= %d%%)', settings.pld.use_sentinel and 'ON' or 'OFF', settings.pld.sentinel_hp)
            toggled = true
        end
    elseif ability == 'rampart' then
        if args[2] then
            local hp = tonumber(args[2])
            if hp and hp >= 1 and hp <= 99 then
                settings.pld.rampart_hp = hp
                atc('Rampart HP threshold: %d%%', hp)
                toggled = true
            else
                atc('Error: HP threshold must be 1-99')
            end
        else
            settings.pld.use_rampart = not settings.pld.use_rampart
            atc('Rampart: %s (HP <= %d%%)', settings.pld.use_rampart and 'ON' or 'OFF', settings.pld.rampart_hp)
            toggled = true
        end
    elseif ability == 'shieldbash' or ability == 'bash' then
        settings.pld.use_shield_bash = not settings.pld.use_shield_bash
        atc('Shield Bash: %s', settings.pld.use_shield_bash and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'divineemblem' or ability == 'emblem' then
        settings.pld.use_divine_emblem = not settings.pld.use_divine_emblem
        atc('Divine Emblem: %s', settings.pld.use_divine_emblem and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'majesty' then
        settings.pld.use_majesty = not settings.pld.use_majesty
        atc('Majesty: %s', settings.pld.use_majesty and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'palisade' then
        if args[2] then
            local hp = tonumber(args[2])
            if hp and hp >= 1 and hp <= 99 then
                settings.pld.palisade_hp = hp
                atc('Palisade HP threshold: %d%%', hp)
                toggled = true
            else
                atc('Error: HP threshold must be 1-99')
            end
        else
            settings.pld.use_palisade = not settings.pld.use_palisade
            atc('Palisade: %s (HP <= %d%%)', settings.pld.use_palisade and 'ON' or 'OFF', settings.pld.palisade_hp)
            toggled = true
        end
    elseif ability == 'chivalry' then
        if args[2] and args[2]:lower() == 'tp' then
            local tp = tonumber(args[3])
            if tp and tp >= 0 and tp <= 3000 then
                settings.pld.chivalry_tp = tp
                atc('Chivalry TP threshold: %d', tp)
                toggled = true
            else
                atc('Error: TP threshold must be 0-3000')
            end
        elseif args[2] then
            local mp = tonumber(args[2])
            if mp and mp >= 1 and mp <= 99 then
                settings.pld.chivalry_mp = mp
                atc('Chivalry MP threshold: %d%%', mp)
                toggled = true
            else
                atc('Error: MP threshold must be 1-99')
            end
        else
            settings.pld.use_chivalry = not settings.pld.use_chivalry
            atc('Chivalry: %s (MP <= %d%%, TP >= %d)', settings.pld.use_chivalry and 'ON' or 'OFF', settings.pld.chivalry_mp, settings.pld.chivalry_tp)
            toggled = true
        end
    elseif ability == 'cover' then
        settings.pld.use_cover = not settings.pld.use_cover
        atc('Cover: %s', settings.pld.use_cover and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'holycircle' or ability == 'circle' then
        settings.pld.use_holy_circle = not settings.pld.use_holy_circle
        atc('Holy Circle: %s', settings.pld.use_holy_circle and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'enlight' then
        settings.spells.use_enlight = not settings.spells.use_enlight
        atc('Enlight: %s', settings.spells.use_enlight and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'reprisal' then
        settings.spells.use_reprisal = not settings.spells.use_reprisal
        atc('Reprisal: %s', settings.spells.use_reprisal and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'phalanx' then
        settings.spells.use_phalanx = not settings.spells.use_phalanx
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'crusade' then
        settings.spells.use_crusade = not settings.spells.use_crusade
        atc('Crusade: %s', settings.spells.use_crusade and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'flash' then
        settings.spells.use_flash = not settings.spells.use_flash
        atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'cureparty' or ability == 'party' then
        settings.healing.cure_party = not settings.healing.cure_party
        atc('Cure Party: %s', settings.healing.cure_party and 'ON' or 'OFF')
        toggled = true
    else
        atc('Unknown PLD ability: %s', args[1])
        atc('Use //at pld to see available abilities')
    end

    if toggled then
        settings:save('all')
    end
end

-- RUN ability toggle helper
local function handle_run_command(args)
    if #args == 0 then
        -- List all RUN abilities with status
        atcc(262, '=== Rune Fencer Abilities ===')
        atc('Auto Rune: %s', settings.run.auto_rune and 'ON' or 'OFF')
        atc('Vallation: %s (in-combat only)', settings.run.use_vallation and 'ON' or 'OFF')
        atc('Valiance: %s (in-combat only)', settings.run.use_valiance and 'ON' or 'OFF')
        atc('Pflug: %s (HP <= %d%%)', settings.run.use_pflug and 'ON' or 'OFF', settings.run.pflug_hp)
        atc('Battuta: %s (in-combat only)', settings.run.use_battuta and 'ON' or 'OFF')
        atc('Liement: %s (in-combat only)', settings.run.use_liement and 'ON' or 'OFF')
        atc('Ward Delay: %ds', settings.run.ward_delay)
        atc('Rayke: %s', settings.run.use_rayke and 'ON' or 'OFF')
        atc('Gambit: %s', settings.run.use_gambit and 'ON' or 'OFF')
        atc('Swordplay: %s', settings.run.use_swordplay and 'ON' or 'OFF')
        atc('Embolden: %s', settings.run.use_embolden and 'ON' or 'OFF')
        atc('Lunge: %s', settings.run.use_lunge and 'ON' or 'OFF')
        atc('Swipe: %s', settings.run.use_swipe and 'ON' or 'OFF')
        atc('Foil: %s', settings.run.use_foil and 'ON' or 'OFF')
        atc('Vivacious Pulse: %s (HP <= %d%%, MP <= %d%%)', settings.run.use_vivacious_pulse and 'ON' or 'OFF', settings.run.vivacious_pulse_hp, settings.run.vivacious_pulse_mp)
        atcc(262, '=== Rune Fencer Spells ===')
        atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        atc('Crusade: %s', settings.spells.use_crusade and 'ON' or 'OFF')
        atc('')
        atc('Usage: //at run <ability> - Toggle on/off')
        atc('       //at run pflug <hp%%> - Set Pflug HP threshold')
        atc('       //at run warddelay <seconds> - Set delay between ward usages')
        atc('       //at run pulse <hp%%> - Set Vivacious Pulse HP threshold')
        atc('       //at run pulse mp <mp%%> - Set Vivacious Pulse MP threshold (Tenebrae)')
        return
    end

    local ability = args[1]:lower()
    local toggled = false

    -- Map command names to settings paths
    if ability == 'autorune' or ability == 'rune' then
        settings.run.auto_rune = not settings.run.auto_rune
        atc('Auto Rune: %s', settings.run.auto_rune and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'vallation' then
        settings.run.use_vallation = not settings.run.use_vallation
        atc('Vallation: %s', settings.run.use_vallation and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'valiance' then
        settings.run.use_valiance = not settings.run.use_valiance
        atc('Valiance: %s', settings.run.use_valiance and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'pflug' then
        if args[2] then
            local hp = tonumber(args[2])
            if hp and hp >= 1 and hp <= 99 then
                settings.run.pflug_hp = hp
                atc('Pflug HP threshold: %d%%', hp)
                toggled = true
            else
                atc('Error: HP threshold must be 1-99')
            end
        else
            settings.run.use_pflug = not settings.run.use_pflug
            atc('Pflug: %s (HP <= %d%%)', settings.run.use_pflug and 'ON' or 'OFF', settings.run.pflug_hp)
            toggled = true
        end
    elseif ability == 'warddelay' then
        local delay = tonumber(args[2])
        if delay and delay >= 0 then
            settings.run.ward_delay = delay
            atc('Ward delay: %ds', delay)
            toggled = true
        else
            atc('Error: Ward delay must be a non-negative number')
        end
    elseif ability == 'battuta' then
        settings.run.use_battuta = not settings.run.use_battuta
        atc('Battuta: %s', settings.run.use_battuta and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'liement' then
        settings.run.use_liement = not settings.run.use_liement
        atc('Liement: %s', settings.run.use_liement and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'rayke' then
        settings.run.use_rayke = not settings.run.use_rayke
        atc('Rayke: %s', settings.run.use_rayke and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'gambit' then
        settings.run.use_gambit = not settings.run.use_gambit
        atc('Gambit: %s', settings.run.use_gambit and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'swordplay' then
        settings.run.use_swordplay = not settings.run.use_swordplay
        atc('Swordplay: %s', settings.run.use_swordplay and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'embolden' then
        settings.run.use_embolden = not settings.run.use_embolden
        atc('Embolden: %s', settings.run.use_embolden and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'lunge' then
        settings.run.use_lunge = not settings.run.use_lunge
        atc('Lunge: %s', settings.run.use_lunge and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'swipe' then
        settings.run.use_swipe = not settings.run.use_swipe
        atc('Swipe: %s', settings.run.use_swipe and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'foil' then
        settings.run.use_foil = not settings.run.use_foil
        atc('Foil: %s', settings.run.use_foil and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'vivaciousepulse' or ability == 'vivacious' or ability == 'pulse' then
        if args[2] and args[2]:lower() == 'mp' then
            local mp = tonumber(args[3])
            if mp and mp >= 1 and mp <= 99 then
                settings.run.vivacious_pulse_mp = mp
                atc('Vivacious Pulse MP threshold: %d%%', mp)
                toggled = true
            else
                atc('Error: MP threshold must be 1-99')
            end
        elseif args[2] then
            local hp = tonumber(args[2])
            if hp and hp >= 1 and hp <= 99 then
                settings.run.vivacious_pulse_hp = hp
                atc('Vivacious Pulse HP threshold: %d%%', hp)
                toggled = true
            else
                atc('Error: HP threshold must be 1-99')
            end
        else
            settings.run.use_vivacious_pulse = not settings.run.use_vivacious_pulse
            atc('Vivacious Pulse: %s (HP <= %d%%, MP <= %d%%)', settings.run.use_vivacious_pulse and 'ON' or 'OFF', settings.run.vivacious_pulse_hp, settings.run.vivacious_pulse_mp)
            toggled = true
        end
    elseif ability == 'flash' then
        settings.spells.use_flash = not settings.spells.use_flash
        atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'phalanx' then
        settings.spells.use_phalanx = not settings.spells.use_phalanx
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'crusade' then
        settings.spells.use_crusade = not settings.spells.use_crusade
        atc('Crusade: %s', settings.spells.use_crusade and 'ON' or 'OFF')
        toggled = true
    else
        atc('Unknown RUN ability: %s', args[1])
        atc('Use //at run to see available abilities')
    end

    if toggled then
        settings:save('all')
    end
end

-- WAR subjob toggle helper
local function handle_war_command(args)
    if #args == 0 then
        -- List all WAR abilities with status
        atcc(262, '=== Warrior Subjob Abilities ===')
        atc('Provoke: %s', settings.subjob.use_provoke and 'ON' or 'OFF')
        atc('Defender: %s', settings.subjob.use_defender and 'ON' or 'OFF')
        atc('Warcry: %s', settings.subjob.use_warcry and 'ON' or 'OFF')
        atc('Aggressor: %s', settings.subjob.use_aggressor and 'ON' or 'OFF')
        atc('')
        atc('Usage: //at war <ability> - Toggle ability on/off')
        return
    end

    local ability = args[1]:lower()
    local toggled = false

    if ability == 'provoke' then
        settings.subjob.use_provoke = not settings.subjob.use_provoke
        atc('Provoke: %s', settings.subjob.use_provoke and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'defender' then
        settings.subjob.use_defender = not settings.subjob.use_defender
        atc('Defender: %s', settings.subjob.use_defender and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'warcry' then
        settings.subjob.use_warcry = not settings.subjob.use_warcry
        atc('Warcry: %s', settings.subjob.use_warcry and 'ON' or 'OFF')
        toggled = true
    elseif ability == 'aggressor' then
        settings.subjob.use_aggressor = not settings.subjob.use_aggressor
        atc('Aggressor: %s', settings.subjob.use_aggressor and 'ON' or 'OFF')
        toggled = true
    else
        atc('Unknown WAR ability: %s', args[1])
        atc('Use //at war to see available abilities')
    end

    if toggled then
        settings:save('all')
    end
end

-- SCH subjob toggle helper
local function handle_sch_command(args)
    if #args == 0 then
        -- List all SCH spells with status
        atcc(262, '=== Scholar Subjob Spells ===')
        atc('Regen: %s', settings.subjob.use_regen and 'ON' or 'OFF')
        atc('Stoneskin: %s', settings.subjob.use_stoneskin and 'ON' or 'OFF')
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        atc('Aquaveil: %s', settings.spells.use_aquaveil and 'ON' or 'OFF')
        atc('')
        atc('Usage: //at sch <spell> - Toggle spell on/off')
        return
    end

    local spell = args[1]:lower()
    local toggled = false

    if spell == 'regen' then
        settings.subjob.use_regen = not settings.subjob.use_regen
        atc('Regen: %s', settings.subjob.use_regen and 'ON' or 'OFF')
        toggled = true
    elseif spell == 'stoneskin' then
        settings.subjob.use_stoneskin = not settings.subjob.use_stoneskin
        atc('Stoneskin: %s', settings.subjob.use_stoneskin and 'ON' or 'OFF')
        toggled = true
    elseif spell == 'phalanx' then
        settings.spells.use_phalanx = not settings.spells.use_phalanx
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        toggled = true
    elseif spell == 'aquaveil' then
        settings.spells.use_aquaveil = not settings.spells.use_aquaveil
        atc('Aquaveil: %s', settings.spells.use_aquaveil and 'ON' or 'OFF')
        toggled = true
    else
        atc('Unknown SCH spell: %s', args[1])
        atc('Use //at sch to see available spells')
    end

    if toggled then
        settings:save('all')
    end
end

-- Main automation loop
local function handle_items()
    if not AutoTankUtils.cooldown_ready(state.last_item_use, settings.items.item_interval) then
        return false
    end

    -- Doom: Holy Water (highest priority)
    if settings.items.use_holy_water and AutoTankUtils.has_buff('Doom') then
        windower.send_command('input /item "Holy Water" <me>')
        state.last_item_use = os.clock()
        atc('Using Holy Water (Doom!)')
        return true
    end

    -- Paralysis: Remedy
    if settings.items.use_remedy and AutoTankUtils.has_buff('Paralysis') then
        windower.send_command('input /item "Remedy" <me>')
        state.last_item_use = os.clock()
        atc('Using Remedy (Paralysis)')
        return true
    end

    return false
end

local function check_actions()
    if not settings.enabled then return end

    local player = get_player()
    if not player then return end

    -- Check if player is alive
    if player.status == 2 or player.status == 3 then
        state.in_combat = false
        return
    end

    -- Update combat state
    state.in_combat = player.status == 1

    -- Consumable items (highest priority — retried until debuff clears)
    if handle_items() then return end

    -- Run job-specific automation
    if player.main_job == 'PLD' then
        AutoTank_PLD.check_actions(player, settings, state)
    elseif player.main_job == 'RUN' then
        AutoTank_RUN.check_actions(player, settings, state)
    end

    -- Run subjob automation
    AutoTank_Subjobs.check_actions(player, settings, state)

    -- Update display
    update_display()
end

-- Unified ability/spell toggle function
local function toggle_ability(ability_name)
    local name = ability_name:lower()
    local toggled = false

    -- PLD abilities
    if name == 'sentinel' then
        settings.pld.use_sentinel = not settings.pld.use_sentinel
        atc('Sentinel: %s', settings.pld.use_sentinel and 'ON' or 'OFF')
        toggled = true
    elseif name == 'rampart' then
        settings.pld.use_rampart = not settings.pld.use_rampart
        atc('Rampart: %s', settings.pld.use_rampart and 'ON' or 'OFF')
        toggled = true
    elseif name == 'bash' or name == 'shieldbash' then
        settings.pld.use_shield_bash = not settings.pld.use_shield_bash
        atc('Shield Bash: %s', settings.pld.use_shield_bash and 'ON' or 'OFF')
        toggled = true
    elseif name == 'emblem' or name == 'divineemblem' then
        settings.pld.use_divine_emblem = not settings.pld.use_divine_emblem
        atc('Divine Emblem: %s', settings.pld.use_divine_emblem and 'ON' or 'OFF')
        toggled = true
    elseif name == 'majesty' then
        settings.pld.use_majesty = not settings.pld.use_majesty
        atc('Majesty: %s', settings.pld.use_majesty and 'ON' or 'OFF')
        toggled = true
    elseif name == 'palisade' then
        settings.pld.use_palisade = not settings.pld.use_palisade
        atc('Palisade: %s', settings.pld.use_palisade and 'ON' or 'OFF')
        toggled = true
    elseif name == 'chivalry' then
        settings.pld.use_chivalry = not settings.pld.use_chivalry
        atc('Chivalry: %s', settings.pld.use_chivalry and 'ON' or 'OFF')
        toggled = true
    elseif name == 'cover' then
        settings.pld.use_cover = not settings.pld.use_cover
        atc('Cover: %s', settings.pld.use_cover and 'ON' or 'OFF')
        toggled = true
    elseif name == 'circle' or name == 'holycircle' then
        settings.pld.use_holy_circle = not settings.pld.use_holy_circle
        atc('Holy Circle: %s', settings.pld.use_holy_circle and 'ON' or 'OFF')
        toggled = true
    elseif name == 'cureparty' or name == 'party' then
        settings.healing.cure_party = not settings.healing.cure_party
        atc('Cure Party: %s', settings.healing.cure_party and 'ON' or 'OFF')
        toggled = true

    -- RUN abilities
    elseif name == 'rune' or name == 'autorune' then
        settings.run.auto_rune = not settings.run.auto_rune
        atc('Auto Rune: %s', settings.run.auto_rune and 'ON' or 'OFF')
        toggled = true
    elseif name == 'vallation' then
        settings.run.use_vallation = not settings.run.use_vallation
        atc('Vallation: %s', settings.run.use_vallation and 'ON' or 'OFF')
        toggled = true
    elseif name == 'valiance' then
        settings.run.use_valiance = not settings.run.use_valiance
        atc('Valiance: %s', settings.run.use_valiance and 'ON' or 'OFF')
        toggled = true
    elseif name == 'pflug' then
        settings.run.use_pflug = not settings.run.use_pflug
        atc('Pflug: %s', settings.run.use_pflug and 'ON' or 'OFF')
        toggled = true
    elseif name == 'battuta' then
        settings.run.use_battuta = not settings.run.use_battuta
        atc('Battuta: %s', settings.run.use_battuta and 'ON' or 'OFF')
        toggled = true
    elseif name == 'liement' then
        settings.run.use_liement = not settings.run.use_liement
        atc('Liement: %s', settings.run.use_liement and 'ON' or 'OFF')
        toggled = true
    elseif name == 'rayke' then
        settings.run.use_rayke = not settings.run.use_rayke
        atc('Rayke: %s', settings.run.use_rayke and 'ON' or 'OFF')
        toggled = true
    elseif name == 'gambit' then
        settings.run.use_gambit = not settings.run.use_gambit
        atc('Gambit: %s', settings.run.use_gambit and 'ON' or 'OFF')
        toggled = true
    elseif name == 'swordplay' then
        settings.run.use_swordplay = not settings.run.use_swordplay
        atc('Swordplay: %s', settings.run.use_swordplay and 'ON' or 'OFF')
        toggled = true
    elseif name == 'embolden' then
        settings.run.use_embolden = not settings.run.use_embolden
        atc('Embolden: %s', settings.run.use_embolden and 'ON' or 'OFF')
        toggled = true
    elseif name == 'lunge' then
        settings.run.use_lunge = not settings.run.use_lunge
        atc('Lunge: %s', settings.run.use_lunge and 'ON' or 'OFF')
        toggled = true
    elseif name == 'foil' then
        settings.run.use_foil = not settings.run.use_foil
        atc('Foil: %s', settings.run.use_foil and 'ON' or 'OFF')
        toggled = true
    elseif name == 'swipe' then
        settings.run.use_swipe = not settings.run.use_swipe
        atc('Swipe: %s', settings.run.use_swipe and 'ON' or 'OFF')
        toggled = true

    -- Spells (PLD/RUN)
    elseif name == 'enlight' then
        settings.spells.use_enlight = not settings.spells.use_enlight
        atc('Enlight: %s', settings.spells.use_enlight and 'ON' or 'OFF')
        toggled = true
    elseif name == 'reprisal' then
        settings.spells.use_reprisal = not settings.spells.use_reprisal
        atc('Reprisal: %s', settings.spells.use_reprisal and 'ON' or 'OFF')
        toggled = true
    elseif name == 'phalanx' then
        settings.spells.use_phalanx = not settings.spells.use_phalanx
        atc('Phalanx: %s', settings.spells.use_phalanx and 'ON' or 'OFF')
        toggled = true
    elseif name == 'crusade' then
        settings.spells.use_crusade = not settings.spells.use_crusade
        atc('Crusade: %s', settings.spells.use_crusade and 'ON' or 'OFF')
        toggled = true
    elseif name == 'aquaveil' then
        settings.spells.use_aquaveil = not settings.spells.use_aquaveil
        atc('Aquaveil: %s', settings.spells.use_aquaveil and 'ON' or 'OFF')
        toggled = true

    -- WAR subjob abilities
    elseif name == 'provoke' then
        settings.subjob.use_provoke = not settings.subjob.use_provoke
        atc('Provoke: %s', settings.subjob.use_provoke and 'ON' or 'OFF')
        toggled = true
    elseif name == 'defender' then
        settings.subjob.use_defender = not settings.subjob.use_defender
        atc('Defender: %s', settings.subjob.use_defender and 'ON' or 'OFF')
        toggled = true
    elseif name == 'warcry' then
        settings.subjob.use_warcry = not settings.subjob.use_warcry
        atc('Warcry: %s', settings.subjob.use_warcry and 'ON' or 'OFF')
        toggled = true
    elseif name == 'aggressor' then
        settings.subjob.use_aggressor = not settings.subjob.use_aggressor
        atc('Aggressor: %s', settings.subjob.use_aggressor and 'ON' or 'OFF')
        toggled = true

    -- SCH subjob spells
    elseif name == 'regen' then
        settings.subjob.use_regen = not settings.subjob.use_regen
        atc('Regen: %s', settings.subjob.use_regen and 'ON' or 'OFF')
        toggled = true
    elseif name == 'stoneskin' then
        settings.subjob.use_stoneskin = not settings.subjob.use_stoneskin
        atc('Stoneskin: %s', settings.subjob.use_stoneskin and 'ON' or 'OFF')
        toggled = true
    end

    if toggled then
        settings:save('all')
    end

    return toggled
end

-- Command handler
windower.register_event('addon command', function(command, ...)
    command = command and command:lower() or 'help'
    local args = {...}

    if command == 'on' then
        settings.enabled = true
        save_settings()
        atc('AutoTank enabled')
        update_display()
    elseif command == 'off' then
        settings.enabled = false
        save_settings()
        atc('AutoTank disabled')
        update_display()
    elseif command == 'toggle' then
        settings.enabled = not settings.enabled
        save_settings()
        atc('AutoTank %s', settings.enabled and 'enabled' or 'disabled')
        update_display()
    elseif command == 'status' then
        print_status()
    elseif command == 'cure' then
        if #args > 0 then
            settings.healing.cure_hp = tonumber(args[1])
            save_settings()
            atc('Cure HP threshold set to %d%%', settings.healing.cure_hp)
        else
            atc('Current Cure HP threshold: %d%%', settings.healing.cure_hp)
        end
    elseif command == 'rune' then
        if #args > 0 then
            local input = args[1]:lower()
            -- Try to convert element name to rune name
            local rune = element_to_rune[input]
            if not rune then
                -- If not in mapping, capitalize first letter and use as-is
                rune = args[1]:gsub("^%l", string.upper)
            end

            -- Validate rune name
            local valid_runes = {Ignis=true, Gelus=true, Flabra=true, Tellus=true, Sulpor=true, Unda=true, Lux=true, Tenebrae=true}
            if valid_runes[rune] then
                settings.run.rune_element = rune
                save_settings()
                atc('Rune element set to %s', rune)
            else
                atc('Invalid rune element: %s', args[1])
                atc('Valid: Fire/Ignis, Ice/Gelus, Wind/Aero/Flabra, Earth/Stone/Tellus')
                atc('       Thunder/Lightning/Sulpor, Water/Unda, Light/Lux, Dark/Darkness/Tenebrae')
            end
        else
            atc('Current rune element: %s', settings.run.rune_element)
        end
    elseif command == 'flash' then
        settings.spells.use_flash = not settings.spells.use_flash
        save_settings()
        atc('Flash: %s', settings.spells.use_flash and 'ON' or 'OFF')
    elseif command == 'delay' then
        local subcmd = args[1] and args[1]:lower()
        if subcmd == 'ability' or subcmd == 'abil' or subcmd == 'ja' then
            -- Set ability delay
            if #args > 1 then
                local delay = tonumber(args[2])
                if delay and delay >= 0.1 and delay <= 5.0 then
                    settings.ability_delay = delay
                    AutoTankUtils.set_ability_delay(delay)
                    save_settings()
                    atc('Ability delay set to %.1f seconds', delay)
                else
                    atc('Error: Delay must be between 0.1 and 5.0 seconds')
                end
            else
                atc('Current ability delay: %.1f seconds', settings.ability_delay)
            end
        elseif subcmd == 'spell' or subcmd == 'magic' or subcmd == 'ma' then
            -- Set spell delay
            if #args > 1 then
                local delay = tonumber(args[2])
                if delay and delay >= 0.5 and delay <= 10.0 then
                    settings.spell_delay = delay
                    AutoTankUtils.set_spell_delay(delay)
                    save_settings()
                    atc('Spell delay set to %.1f seconds', delay)
                else
                    atc('Error: Delay must be between 0.5 and 10.0 seconds')
                end
            else
                atc('Current spell delay: %.1f seconds', settings.spell_delay)
            end
        else
            -- Show both delays if no subcommand
            atc('Current delays:')
            atc('  Ability: %.1f seconds', settings.ability_delay)
            atc('  Spell: %.1f seconds', settings.spell_delay)
        end
    elseif command == 'blu' then
        handle_blu_command(args)

    -- PLD ability toggles
    elseif command == 'pld' then
        handle_pld_command(args)

    -- RUN ability toggles
    elseif command == 'run' then
        handle_run_command(args)

    -- WAR subjob toggles
    elseif command == 'war' then
        handle_war_command(args)

    -- SCH subjob toggles
    elseif command == 'sch' then
        handle_sch_command(args)

    elseif command == 'item' then
        local subcmd = args[1] and args[1]:lower()
        if subcmd == 'remedy' then
            settings.items.use_remedy = not settings.items.use_remedy
            save_settings()
            atc('Auto-Remedy: %s', settings.items.use_remedy and 'ON' or 'OFF')
        elseif subcmd == 'holywater' or subcmd == 'holy' then
            settings.items.use_holy_water = not settings.items.use_holy_water
            save_settings()
            atc('Auto-Holy Water: %s', settings.items.use_holy_water and 'ON' or 'OFF')
        elseif subcmd == 'interval' and args[2] then
            local secs = tonumber(args[2])
            if secs and secs >= 1 then
                settings.items.item_interval = secs
                save_settings()
                atc('Item interval: %ds', secs)
            else
                atc('Error: Interval must be at least 1 second')
            end
        else
            atcc(262, '=== Auto Items ===')
            atc('Remedy: %s', settings.items.use_remedy and 'ON' or 'OFF')
            atc('Holy Water: %s', settings.items.use_holy_water and 'ON' or 'OFF')
            atc('Interval: %ds', settings.items.item_interval)
            atc('Usage: //at item remedy|holy|interval <secs>')
        end

    -- Debug logging
    elseif command == 'log' then
        local subcmd = args[1] and args[1]:lower()
        if subcmd == 'on' then
            if ATLog.start() then
                atc('Debug logging ON — writing to: %sAutoTank\\debug.log', windower.addon_path)
            else
                atc('Error: could not open log file for writing')
            end
        elseif subcmd == 'off' then
            ATLog.stop()
            atc('Debug logging OFF')
        elseif subcmd == 'clear' then
            local was_enabled = ATLog.enabled
            ATLog.stop()
            ATLog.start()
            if not was_enabled then ATLog.stop() end
            atc('Log file cleared')
        elseif subcmd == 'throttle' and args[2] then
            local secs = tonumber(args[2])
            if secs and secs >= 0 then
                ATLog._throttle = secs
                atc('Log throttle set to %.1fs', secs)
            else
                atc('Invalid throttle value')
            end
        else
            atc('Debug log status: %s', ATLog.enabled and 'ON' or 'OFF')
            if ATLog._file_path then
                atc('Log file: %s', ATLog._file_path)
            end
            atc('Throttle: %.1fs (same message suppressed for this long)', ATLog._throttle)
            atc('Usage: //at log on|off|clear|throttle <secs>')
        end

    elseif command == 'help' then
        atcc(262, '=== AutoTank Commands ===')
        atc('//at on/off/toggle - Enable/disable AutoTank')
        atc('//at status - Show current settings')
        atc('//at cure [hp%%] - Set cure HP threshold')
        atc('//at rune [element] - Set rune element for RUN')
        atc('//at flash - Toggle Flash usage')
        atc('//at delay - View current delays')
        atc('//at delay ability [seconds] - Set ability delay (0.1-5.0)')
        atc('//at delay spell [seconds] - Set spell delay (0.5-10.0)')
        atc('//at blu - Manage BLU spells (see //at blu for details)')
        atc('//at pld [ability] - Toggle PLD abilities/spells')
        atc('//at run [ability] - Toggle RUN abilities/spells')
        atc('//at war [ability] - Toggle WAR subjob abilities')
        atc('//at sch [spell] - Toggle SCH subjob spells')
        atc('//at item - Show/toggle auto-item settings (Remedy, Holy Water)')
        atc('//at log on|off|clear - Toggle debug log to file')
        atc('')
        atc('Simplified Commands (no job prefix required):')
        atc('//at <ability> - Toggle any ability/spell directly')
        atc('Examples: //at stoneskin, //at sentinel, //at provoke')
    else
        -- Try to toggle ability/spell directly without job prefix
        if not toggle_ability(command) then
            atc('Unknown command: %s', command)
            atc('Use //at help for command list')
        end
    end
end)

-- Event: Load
windower.register_event('load', function()
    atcc(262, 'AutoTank v%s loaded!', _addon.version)
    -- Set action delays from settings
    AutoTankUtils.set_ability_delay(settings.ability_delay)
    AutoTankUtils.set_spell_delay(settings.spell_delay)
    update_display()
end)

-- Event: Unload
windower.register_event('unload', function()
    display:hide()
end)

-- Event: Outgoing chunk - detect player movement via position packet
windower.register_event('outgoing chunk', function(id, _, modified)
    if id == 0x015 then
        local coords = modified:sub(5, 16)
        AutoTankUtils.set_moving(last_coords ~= nil and last_coords ~= coords)
        last_coords = coords
    end
end)

-- Event: Zone change
windower.register_event('zone change', function()
    state.in_combat = false
    state.last_flash = 0
    state.last_provoke = 0
end)

-- Event: Status change
windower.register_event('status change', function(new_status)
    if new_status == 1 then
        state.in_combat = true
    elseif new_status == 0 or new_status == 4 then
        state.in_combat = false
    end
end)

-- Main loop
windower.register_event('prerender', function()
    local now = os.clock()

    -- Run automation every 0.5 seconds
    if now - (state.last_check or 0) >= 0.5 then
        state.last_check = now
        check_actions()
    end
end)
