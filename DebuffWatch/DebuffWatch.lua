--[[
DebuffWatch - Debuff Wear-Off Notification System
Tracks debuffs applied to monsters and announces when they wear off

Commands:
    //dw add <spell>        - Add spell/debuff to watch list
    //dw remove <spell>     - Remove spell from watch list
    //dw list               - Show watch list
    //dw clear              - Clear all tracked debuffs
    //dw range <distance>   - Set announcement range (default: 50)
    //dw toggle             - Toggle on/off
    //dw help               - Show help

Author: EvilPotat0 + Claude
Version: 1.0.0
]]

_addon.name = 'DebuffWatch'
_addon.author = 'EvilPotat0 + Claude code'
_addon.version = '1.0.0'
_addon.commands = {'debuffwatch', 'dw'}

local config = require('config')
local res = require('resources')

-- Logging helper function with string formatting support
local function log(msg, ...)
    if select('#', ...) > 0 then
        windower.add_to_chat(121, string.format(msg, ...))
    else
        windower.add_to_chat(121, msg)
    end
end

-- Error logging helper
local function error(msg, ...)
    if select('#', ...) > 0 then
        windower.add_to_chat(123, string.format('[DebuffWatch Error] ' .. msg, ...))
    else
        windower.add_to_chat(123, '[DebuffWatch Error] ' .. msg)
    end
end

-- Default settings
local defaults = {
    enabled = true,
    range = 50, -- yalms
    watched_debuffs = {},
    announce_channel = 'p', -- p = party, l = linkshell, s = say
}

-- Load settings
local settings = config.load(defaults)

-- Migrate old watch list entries to new format
local function migrate_watch_list()
    local needs_save = false
    local new_watched = {}

    for spell_id, data in pairs(settings.watched_debuffs) do
        -- Convert string keys to numbers (XML config may save numbers as strings)
        local numeric_id = tonumber(spell_id) or spell_id

        -- Check if this entry is missing the new fields
        if not data.status_name or not data.status_id then
            local spell = res.spells[numeric_id]
            if spell and spell.status then
                local status_effect = res.buffs[spell.status]
                if status_effect then
                    data.spell_name = data.spell_name or data.name or spell.en
                    data.spell_id = numeric_id
                    data.status_id = spell.status
                    data.status_name = status_effect.en
                    needs_save = true
                    log('Migrated watch entry: %s → %s', data.spell_name, data.status_name)
                end
            end
        end

        -- Store with numeric key
        new_watched[numeric_id] = data
    end

    -- Replace watch list with normalized version
    settings.watched_debuffs = new_watched

    if needs_save then
        settings:save()
        log('Watch list migration complete')
    end
end

-- Run migration on load
migrate_watch_list()

-- Active debuff tracking
-- Structure: [mob_id] = { [status_effect_id] = {spell_name = "Dark Threnody II", status_name = "Threnody", applied_time = os.time()} }
local active_debuffs = {}

-- Get player position
local function get_player_pos()
    local player = windower.ffxi.get_mob_by_target('me')
    if player then
        return player.x, player.y, player.z
    end
    return nil, nil, nil
end

-- Get distance between two positions
local function get_distance(x1, y1, z1, x2, y2, z2)
    if not x1 or not x2 then return 999 end
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Check if mob is in range
local function is_mob_in_range(mob_id)
    local mob = windower.ffxi.get_mob_by_id(mob_id)
    if not mob then return false end

    local px, py, pz = get_player_pos()
    if not px then return false end

    local distance = get_distance(px, py, pz, mob.x, mob.y, mob.z)
    return distance <= settings.range
end

-- Announce debuff wear-off
local function announce_wearoff(mob_id, debuff_name, applied_time)
    if not settings.enabled then return end
    if not is_mob_in_range(mob_id) then return end

    local mob = windower.ffxi.get_mob_by_id(mob_id)
    if not mob then return end

    local message = string.format('%s just wore!! <call5>', debuff_name)
    windower.send_command(string.format('input /%s %s', settings.announce_channel, message))

    -- Calculate and log duration if we have applied_time
    if applied_time then
        local duration = os.time() - applied_time
        local minutes = math.floor(duration / 60)
        local seconds = duration % 60

        if minutes > 0 then
            log('Announced: %s wore off %s (lasted %dm %ds)', debuff_name, mob.name or 'unknown', minutes, seconds)
        else
            log('Announced: %s wore off %s (lasted %ds)', debuff_name, mob.name or 'unknown', seconds)
        end
    else
        log('Announced: %s wore off %s', debuff_name, mob.name or 'unknown')
    end
end

-- Add debuff to watch list
local function add_watched_debuff(spell_name)
    -- Find spell in resources
    local spell = res.spells:with('name', spell_name) or res.spells:with('en', spell_name)

    if not spell then
        error('Spell not found: ' .. spell_name)
        return false
    end

    -- Get the status effect this spell applies
    local status_id = spell.status
    if not status_id then
        error('Spell %s does not apply a status effect', spell.en)
        return false
    end

    local status_effect = res.buffs[status_id]
    if not status_effect then
        error('Status effect not found for %s', spell.en)
        return false
    end

    if not settings.watched_debuffs[spell.id] then
        settings.watched_debuffs[spell.id] = {
            spell_name = spell.en,
            spell_id = spell.id,
            status_id = status_id,
            status_name = status_effect.en
        }
        settings:save()
        log('Now watching: %s (applies "%s" effect)', spell.en, status_effect.en)
        return true
    else
        log('Already watching: %s', spell.en)
        return false
    end
end

-- Remove debuff from watch list
local function remove_watched_debuff(spell_name)
    -- Find spell in resources
    local spell = res.spells:with('name', spell_name) or res.spells:with('en', spell_name)

    if not spell then
        error('Spell not found: ' .. spell_name)
        return false
    end

    if settings.watched_debuffs[spell.id] then
        settings.watched_debuffs[spell.id] = nil
        settings:save()
        log('Stopped watching: %s', spell.en)
        return true
    else
        log('Not watching: %s', spell.en)
        return false
    end
end

-- Show watch list
local function show_watch_list()
    log('=== DebuffWatch List ===')
    log('Status: %s', settings.enabled and 'ENABLED' or 'DISABLED')
    log('Range: %d yalms', settings.range)
    log('Channel: /%s', settings.announce_channel)
    log('')
    log('Watched Debuffs:')

    local watch_count = 0
    for _, data in pairs(settings.watched_debuffs) do
        log('  - %s → watches for "%s" wear-off', data.spell_name or data.name, data.status_name or '?')
        watch_count = watch_count + 1
    end

    if watch_count == 0 then
        log('  (none)')
    end

    log('')

    -- Count active tracked debuffs
    local active_count = 0
    for _, debuffs in pairs(active_debuffs) do
        for _ in pairs(debuffs) do
            active_count = active_count + 1
        end
    end

    log('Active Tracked Debuffs: %d', active_count)

    if active_count > 0 then
        log('Active tracking details:')
        for mob_id, debuffs in pairs(active_debuffs) do
            local mob = windower.ffxi.get_mob_by_id(mob_id)
            local mob_name = mob and mob.name or 'Unknown'
            for _, debuff_data in pairs(debuffs) do
                log('  - %s on %s (ID: %d)', debuff_data.spell_name, mob_name, mob_id)
            end
        end
    end
end

-- Clear all active tracking
local function clear_active_tracking()
    active_debuffs = {}
    log('Cleared all active debuff tracking')
end

-- Show help
local function show_help()
    log('=== DebuffWatch Help ===')
    log('//dw add <spell>        - Add spell to watch list')
    log('//dw remove <spell>     - Remove spell from watch list')
    log('//dw list               - Show watch list')
    log('//dw clear              - Clear active tracking')
    log('//dw range <distance>   - Set announcement range (yalms)')
    log('//dw channel <p|l|s>    - Set announce channel (party/linkshell/say)')
    log('//dw toggle             - Toggle on/off')
    log('//dw help               - Show this help')
    log('')
    log('Examples:')
    log('  //dw add "Dark Threnody II"')
    log('  //dw add Dia')
    log('  //dw add Bio')
    log('  //dw range 30')
    log('  //dw channel p')
end

-- Monitor action packets to track debuff application
windower.register_event('action', function(act)
    if not settings.enabled then return end

    -- Check if action is from player
    local player = windower.ffxi.get_player()
    if not player or act.actor_id ~= player.id then return end

    -- Category 4 = spell casting
    if act.category ~= 4 then return end

    -- Process each target in the action
    for _, target in ipairs(act.targets) do
        local mob_id = target.id

        -- Process each action (spell cast, ability use, etc.)
        for _, action in ipairs(target.actions) do
            -- Check if spell landed (message 2 = damage/effect, 236 = enfeeble, 237 = enfeeble)
            if action.message and (action.message == 2 or action.message == 236 or action.message == 237 or action.message == 252) then
                local spell_id = act.param

                -- Check if we're watching this spell
                if settings.watched_debuffs[spell_id] then
                    local spell_data = settings.watched_debuffs[spell_id]
                    local status_id = spell_data.status_id

                    -- Initialize mob tracking if needed
                    if not active_debuffs[mob_id] then
                        active_debuffs[mob_id] = {}
                    end

                    -- Track this debuff application by status effect ID
                    active_debuffs[mob_id][status_id] = {
                        spell_name = spell_data.spell_name,
                        status_name = spell_data.status_name,
                        applied_time = os.time(),
                        announced = false
                    }

                    log('Tracking %s (effect: %s) on mob %d', spell_data.spell_name, spell_data.status_name, mob_id)
                end
            end
        end
    end
end)

-- Monitor incoming text messages for wear-off notifications
windower.register_event('incoming text', function(original, _modified, _mode)
    if not settings.enabled then return end

    -- Look for wear-off messages in the text
    -- FFXI formats: "X wears off." or "X wears off the Y."
    -- Check if any watched status effect appears in the message
    for _, spell_data in pairs(settings.watched_debuffs) do
        local status_name = spell_data.status_name
        local spell_name = spell_data.spell_name
        local status_id = spell_data.status_id

        -- Check if this status effect name appears in a wear-off message
        if status_name and original:find(status_name) and (original:find('wears off') or original:find('loses the effect')) then
            -- Found a wear-off message for a watched debuff
            -- Try to find which mob it was on
            local mob_id = nil

            -- Search for the mob that had this status effect
            for tracked_mob_id, debuffs in pairs(active_debuffs) do
                if debuffs[status_id] and not debuffs[status_id].announced then
                    mob_id = tracked_mob_id
                    break
                end
            end

            -- If we found the mob, announce and clean up
            if mob_id then
                local applied_time = active_debuffs[mob_id][status_id].applied_time
                announce_wearoff(mob_id, spell_name, applied_time)

                -- Mark as announced and clean up
                if active_debuffs[mob_id] and active_debuffs[mob_id][status_id] then
                    active_debuffs[mob_id][status_id].announced = true

                    -- Remove from tracking after brief delay
                    coroutine.schedule(function()
                        if active_debuffs[mob_id] then
                            active_debuffs[mob_id][status_id] = nil

                            -- Clean up mob entry if no more debuffs
                            local has_debuffs = false
                            for _ in pairs(active_debuffs[mob_id]) do
                                has_debuffs = true
                                break
                            end
                            if not has_debuffs then
                                active_debuffs[mob_id] = nil
                            end
                        end
                    end, 1)
                end
            else
                -- No tracked mob found - might not have been tracking yet
                -- Search all nearby mobs to find which one it came from
                local nearby_mobs = windower.ffxi.get_mob_array()
                for _, mob in pairs(nearby_mobs) do
                    if mob and mob.valid_target and is_mob_in_range(mob.id) then
                        -- Assume it's this mob and announce using the spell name (no duration since we weren't tracking)
                        announce_wearoff(mob.id, spell_name, nil)
                        break
                    end
                end
            end
        end
    end
end)

-- Clean up tracking when mob dies
windower.register_event('action', function(act)
    -- Category 6 = monster defeated
    if act.category == 6 then
        for _, target in ipairs(act.targets) do
            if active_debuffs[target.id] then
                active_debuffs[target.id] = nil
            end
        end
    end
end)

-- Command handler
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower()

    if not command or command == 'help' or command == 'h' then
        show_help()

    elseif command == 'add' or command == 'watch' then
        if #args == 0 then
            error('Specify a spell name to watch')
            log('Example: //dw add "Dark Threnody II"')
            return
        end

        local spell_name = table.concat(args, ' ')
        add_watched_debuff(spell_name)

    elseif command == 'remove' or command == 'unwatch' then
        if #args == 0 then
            error('Specify a spell name to stop watching')
            return
        end

        local spell_name = table.concat(args, ' ')
        remove_watched_debuff(spell_name)

    elseif command == 'list' or command == 'l' then
        show_watch_list()

    elseif command == 'clear' or command == 'reset' then
        clear_active_tracking()

    elseif command == 'range' or command == 'r' then
        if #args == 0 then
            log('Current range: %d yalms', settings.range)
            return
        end

        local range = tonumber(args[1])
        if not range or range < 0 then
            error('Invalid range value')
            return
        end

        settings.range = range
        settings:save()
        log('Announcement range set to %d yalms', range)

    elseif command == 'channel' or command == 'ch' then
        if #args == 0 then
            log('Current channel: /%s', settings.announce_channel)
            log('Options: p (party), l (linkshell), s (say)')
            return
        end

        local channel = args[1]:lower()
        if channel ~= 'p' and channel ~= 'l' and channel ~= 's' then
            error('Invalid channel. Use: p (party), l (linkshell), s (say)')
            return
        end

        settings.announce_channel = channel
        settings:save()
        log('Announcement channel set to /%s', channel)

    elseif command == 'toggle' or command == 't' then
        settings.enabled = not settings.enabled
        settings:save()
        log('DebuffWatch: %s', settings.enabled and 'ENABLED' or 'DISABLED')

    else
        error('Unknown command: ' .. command)
        show_help()
    end
end)

-- Initialize
windower.register_event('load', function()
    log('DebuffWatch v1.0.0 loaded!')
    log('Use //dw help for commands')
    log('Status: %s', settings.enabled and 'ENABLED' or 'DISABLED')
end)

-- Zone change cleanup
windower.register_event('zone change', function()
    clear_active_tracking()
end)

-- Unload cleanup
windower.register_event('unload', function()
    clear_active_tracking()
end)
