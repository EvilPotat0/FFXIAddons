--[[
    AutoTank - Shared Utilities Module
    Common functions used across all AutoTank modules
]]--

AutoTankUtils = {}

-- Track last action times for separate ability/spell delays
local last_ability_time = 0
local last_spell_time = 0
local ability_delay = 1.0 -- Default 1.0 second delay between abilities
local spell_delay = 2.0 -- Default 2.0 second delay between spells

-- Movement tracking (updated by outgoing chunk 0x015 in main addon)
local is_moving = false

function AutoTankUtils.set_moving(val)
    is_moving = val
end

function AutoTankUtils.is_player_moving()
    return is_moving
end

--[[
    BUFF CHECKING
]]--

-- Check if player has a specific buff
function AutoTankUtils.has_buff(buff_name)
    local player = windower.ffxi.get_player()
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

-- Count active runes (for RUN)
-- If rune_element is provided, counts stacks of that specific rune
-- Otherwise, counts total number of rune stacks across all elements
function AutoTankUtils.count_runes(rune_element)
    local player = windower.ffxi.get_player()
    if not player then return 0 end

    -- Get all rune buff IDs
    local rune_buffs = {
        [res.buffs:with('en', 'Ignis').id] = true,
        [res.buffs:with('en', 'Gelus').id] = true,
        [res.buffs:with('en', 'Flabra').id] = true,
        [res.buffs:with('en', 'Tellus').id] = true,
        [res.buffs:with('en', 'Sulpor').id] = true,
        [res.buffs:with('en', 'Unda').id] = true,
        [res.buffs:with('en', 'Lux').id] = true,
        [res.buffs:with('en', 'Tenebrae').id] = true,
    }

    -- If specific rune element requested, only count that one
    if rune_element then
        local buff_id = res.buffs:with('en', rune_element)
        if not buff_id then return 0 end

        local count = 0
        for _, buff in ipairs(player.buffs) do
            if buff == buff_id.id then
                count = count + 1
            end
        end
        return count
    end

    -- Otherwise count all rune stacks across all elements
    local count = 0
    for _, buff in ipairs(player.buffs) do
        if rune_buffs[buff] then
            count = count + 1
        end
    end

    return count
end

--[[
    ABILITY AND SPELL CHECKING
]]--

-- Check if ability is ready (off cooldown)
function AutoTankUtils.is_ability_ready(ability_name)
    local ability = res.job_abilities:with('en', ability_name)
    if not ability then return false end

    local recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
    return recast == 0
end

-- Check if spell is ready (off cooldown)
function AutoTankUtils.is_spell_ready(spell_name)
    local spell = res.spells:with('en', spell_name)
    if not spell then return false end

    local recast = windower.ffxi.get_spell_recasts()[spell.recast_id]
    return recast == 0
end

--[[
    ACTION EXECUTION
]]--

-- Check if enough time has passed since last ability
local function can_perform_ability()
    local now = os.clock()
    if now - last_ability_time < ability_delay then
        return false
    end
    return true
end

-- Check if enough time has passed since last spell
local function can_perform_spell()
    local now = os.clock()
    if now - last_spell_time < spell_delay then
        return false
    end
    return true
end

-- Use job ability on target
function AutoTankUtils.use_ability(ability_name, target)
    if not can_perform_ability() or not can_perform_spell() then return false end
    if AutoTankUtils.is_player_busy() then return false end
    if AutoTankUtils.is_ability_ready(ability_name) then
        local target_str = target or '<me>'
        windower.send_command('input /ja "'..ability_name..'" '..target_str)
        last_ability_time = os.clock()
        return true
    end
    return false
end

-- Cast spell on target
function AutoTankUtils.cast_spell(spell_name, target)
    if not can_perform_spell() or not can_perform_ability() then return false end
    if AutoTankUtils.is_player_busy() then return false end
    if is_moving then
        ATLog.write('cast_spell', 'SKIP '..spell_name..': player is moving')
        return false
    end
    if AutoTankUtils.is_spell_ready(spell_name) then
        local target_str = target or '<me>'
        windower.send_command('input /ma "'..spell_name..'" '..target_str)
        last_spell_time = os.clock()
        return true
    end
    return false
end

-- Set ability delay (in seconds)
function AutoTankUtils.set_ability_delay(delay)
    ability_delay = delay
end

-- Get current ability delay
function AutoTankUtils.get_ability_delay()
    return ability_delay
end

-- Set spell delay (in seconds)
function AutoTankUtils.set_spell_delay(delay)
    spell_delay = delay
end

-- Get current spell delay
function AutoTankUtils.get_spell_delay()
    return spell_delay
end

--[[
    PLAYER INFO
]]--

-- Check if player is busy (casting/using ability)
function AutoTankUtils.is_player_busy()
    local player = windower.ffxi.get_player()
    if not player then return true end

    -- Status values:
    -- 0 = idle, 1 = engaged, 2 = dead, 3 = event, 4 = chocobo, 5 = fishing
    -- 33 = sitting
    -- Check if mounted
    if player.status == 4 then return true end

    -- Check debuffs that prevent actions
    if AutoTankUtils.has_buff('sleep') then return true end
    if AutoTankUtils.has_buff('paralysis') then return true end
    if AutoTankUtils.has_buff('petrification') then return true end
    if AutoTankUtils.has_buff('stun') then return true end
    if AutoTankUtils.has_buff('terror') then return true end

    return false
end

-- Get HP percentage
function AutoTankUtils.get_hp_percent()
    local player = windower.ffxi.get_player()
    if not player or not player.vitals then return 100 end

    -- hpp is HP percentage (0-100); clamp in case of stale data at load
    return math.min(player.vitals.hpp or 100, 100)
end

-- Get MP percentage
function AutoTankUtils.get_mp_percent()
    local player = windower.ffxi.get_player()
    if not player or not player.vitals then return 100 end

    -- mpp is MP percentage (0-100)
    return player.vitals.mpp or 100
end

-- Get current target
function AutoTankUtils.get_target()
    return windower.ffxi.get_mob_by_target('t')
end

-- Check if target is a valid attackable enemy (not a Trust or party member)
function AutoTankUtils.has_valid_target()
    local target = AutoTankUtils.get_target()
    if not target or not target.is_npc then return false end

    -- Exclude party members and Trusts (Trusts appear as NPCs but can't be attacked)
    local party = windower.ffxi.get_party()
    if party then
        for i = 0, 5 do
            local member = party['p' .. i]
            if member and member.mob and member.mob.id == target.id then
                return false
            end
        end
    end

    return true
end

--[[
    COOLDOWN MANAGEMENT
]]--

-- Check if enough time has passed since last action
function AutoTankUtils.cooldown_ready(last_time, interval)
    local now = os.clock()
    return now - last_time >= interval
end

-- Get remaining cooldown as a formatted string
function AutoTankUtils.cooldown_remaining(last_time, interval)
    local remaining = interval - (os.clock() - last_time)
    if remaining <= 0 then return 'ready' end
    return string.format('%.0fs', remaining)
end

-- Get ability recast remaining as a formatted string
function AutoTankUtils.ability_recast_str(ability_name)
    local ability = res.job_abilities:with('en', ability_name)
    if not ability then return 'not_in_resources' end
    local recast = windower.ffxi.get_ability_recasts()[ability.recast_id]
    if recast == nil then return 'no_recast_data' end
    if recast == 0 then return 'ready' end
    return string.format('%.0fs', recast)
end

-- Get spell recast remaining as a formatted string
function AutoTankUtils.spell_recast_str(spell_name)
    local spell = res.spells:with('en', spell_name)
    if not spell then return 'not_in_resources' end
    local recast = windower.ffxi.get_spell_recasts()[spell.recast_id]
    if recast == nil then return 'no_recast_data' end
    if recast == 0 then return 'ready' end
    return string.format('%.0fs', recast / 60)
end

--[[
    FILE-BASED DEBUG LOGGING
]]--

ATLog = {}
ATLog.enabled = false
ATLog._file_path = nil
ATLog._last_logged = {}  -- throttle: key -> last log time
ATLog._throttle = 5.0    -- seconds between identical log entries

function ATLog.start()
    ATLog._file_path = windower.addon_path .. 'debug.log'
    local f = io.open(ATLog._file_path, 'w')
    if f then
        f:write(string.format('[%s] === AutoTank Debug Log Started ===\n', os.date('%Y-%m-%d %H:%M:%S')))
        f:close()
        ATLog.enabled = true
        return true
    end
    return false
end

function ATLog.stop()
    ATLog.enabled = false
    if ATLog._file_path then
        local f = io.open(ATLog._file_path, 'a')
        if f then
            f:write(string.format('[%s] === AutoTank Debug Log Stopped ===\n', os.date('%Y-%m-%d %H:%M:%S')))
            f:close()
        end
    end
end

function ATLog.write(context, msg)
    if not ATLog.enabled then return end
    local key = context .. '|' .. msg
    local now = os.clock()
    -- Throttle: don't repeat the same message within _throttle seconds
    if ATLog._last_logged[key] and (now - ATLog._last_logged[key]) < ATLog._throttle then
        return
    end
    ATLog._last_logged[key] = now
    local line = string.format('[%s] %-22s %s\n', os.date('%H:%M:%S'), context, msg)
    local f = io.open(ATLog._file_path, 'a')
    if f then
        f:write(line)
        f:close()
    end
end

return AutoTankUtils
