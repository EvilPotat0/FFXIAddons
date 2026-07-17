--[[
    AutoTank - Rune Fencer Module
    Handles RUN job abilities, rune management, and spell automation
]]--

AutoTank_RUN = {}

-- Track cooldowns and state
local cooldowns = {
    last_rune = 0,
    last_flash = 0,
    last_enmity = 0,
    last_ward = 0,
}

local L = ATLog.write

-- Rune management
local function manage_runes(player, settings, state)
    local ctx = 'RUN.manage_runes'

    if not settings.run.auto_rune then
        L(ctx, 'SKIP: auto_rune disabled in settings')
        return false
    end

    local now = os.clock()
    local current_runes = AutoTankUtils.count_runes(settings.run.rune_element)
    state.current_runes = current_runes

    if current_runes >= settings.run.rune_count then
        L(ctx, string.format('SKIP %s: have %d/%d runes (at target)', settings.run.rune_element, current_runes, settings.run.rune_count))
        return false
    end

    if not AutoTankUtils.cooldown_ready(cooldowns.last_rune, 4) then
        L(ctx, string.format('SKIP %s: internal cooldown not ready (%s, have %d/%d)',
            settings.run.rune_element,
            AutoTankUtils.cooldown_remaining(cooldowns.last_rune, 4),
            current_runes, settings.run.rune_count))
        return false
    end

    if not AutoTankUtils.is_ability_ready(settings.run.rune_element) then
        L(ctx, string.format('SKIP %s: on recast (%s, have %d/%d)',
            settings.run.rune_element,
            AutoTankUtils.ability_recast_str(settings.run.rune_element),
            current_runes, settings.run.rune_count))
        return false
    end

    if AutoTankUtils.use_ability(settings.run.rune_element, '<me>') then
        cooldowns.last_rune = now
        return true
    end

    return false
end

-- Vivacious Pulse for HP/MP recovery
local function manage_hp(player, settings)
    local ctx = 'RUN.manage_hp'

    if not settings.run.use_vivacious_pulse then
        L(ctx, 'SKIP Vivacious Pulse: disabled in settings')
        return false
    end

    -- Requires at least 1 active rune of any element
    local total_runes = AutoTankUtils.count_runes()
    if total_runes == 0 then
        L(ctx, 'SKIP Vivacious Pulse: no runes active')
        return false
    end

    -- Tenebrae runes restore MP; all others restore HP
    local is_tenebrae = settings.run.rune_element == 'Tenebrae'
    if is_tenebrae then
        local mp_percent = AutoTankUtils.get_mp_percent()
        if mp_percent > settings.run.vivacious_pulse_mp then
            L(ctx, string.format('SKIP Vivacious Pulse: MP %d%% > threshold %d%% (Tenebrae)', mp_percent, settings.run.vivacious_pulse_mp))
            return false
        end
    else
        local hp_percent = AutoTankUtils.get_hp_percent()
        if hp_percent > settings.run.vivacious_pulse_hp then
            L(ctx, string.format('SKIP Vivacious Pulse: HP %d%% > threshold %d%%', hp_percent, settings.run.vivacious_pulse_hp))
            return false
        end
    end

    if not AutoTankUtils.is_ability_ready('Vivacious Pulse') then
        L(ctx, 'SKIP Vivacious Pulse: on recast ('..AutoTankUtils.ability_recast_str('Vivacious Pulse')..')')
        return false
    end

    if AutoTankUtils.use_ability('Vivacious Pulse', '<me>') then
        return true
    end

    return false
end

-- Defensive wards (Vallation/Valiance/Pflug)
local function defensive_wards(player, settings, state)
    local ctx = 'RUN.defensive_wards'
    local hp_percent = AutoTankUtils.get_hp_percent()
    local now = os.clock()

    -- Pflug (emergency - no combat or delay restriction)
    if not settings.run.use_pflug then
        L(ctx, 'SKIP Pflug: disabled in settings')
    elseif hp_percent > settings.run.pflug_hp then
        L(ctx, string.format('SKIP Pflug: HP %d%% > threshold %d%%', hp_percent, settings.run.pflug_hp))
    elseif not AutoTankUtils.is_ability_ready('Pflug') then
        L(ctx, 'SKIP Pflug: on recast ('..AutoTankUtils.ability_recast_str('Pflug')..')')
    else
        if AutoTankUtils.use_ability('Pflug', '<me>') then
            return true
        end
    end

    -- Vallation
    if not settings.run.use_vallation then
        L(ctx, 'SKIP Vallation: disabled in settings')
    elseif not state.in_combat then
        L(ctx, 'SKIP Vallation: not in combat')
    elseif AutoTankUtils.has_buff('Vallation') then
        L(ctx, 'SKIP Vallation: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Vallation') then
        L(ctx, 'SKIP Vallation: on recast ('..AutoTankUtils.ability_recast_str('Vallation')..')')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_ward, settings.run.ward_delay) then
        L(ctx, 'SKIP Vallation: ward delay ('..AutoTankUtils.cooldown_remaining(cooldowns.last_ward, settings.run.ward_delay)..' remaining)')
    else
        if AutoTankUtils.use_ability('Vallation', '<me>') then
            cooldowns.last_ward = now
            return true
        end
    end

    -- Valiance
    if not settings.run.use_valiance then
        L(ctx, 'SKIP Valiance: disabled in settings')
    elseif not state.in_combat then
        L(ctx, 'SKIP Valiance: not in combat')
    else
        local rune_count = AutoTankUtils.count_runes(settings.run.rune_element)
        if rune_count < 3 then
            L(ctx, string.format('SKIP Valiance: only %d runes (need 3)', rune_count))
        elseif AutoTankUtils.has_buff('Valiance') then
            L(ctx, 'SKIP Valiance: buff already active')
        elseif not AutoTankUtils.is_ability_ready('Valiance') then
            L(ctx, 'SKIP Valiance: on recast ('..AutoTankUtils.ability_recast_str('Valiance')..')')
        elseif not AutoTankUtils.cooldown_ready(cooldowns.last_ward, settings.run.ward_delay) then
            L(ctx, 'SKIP Valiance: ward delay ('..AutoTankUtils.cooldown_remaining(cooldowns.last_ward, settings.run.ward_delay)..' remaining)')
        else
            if AutoTankUtils.use_ability('Valiance', '<me>') then
                cooldowns.last_ward = now
                return true
            end
        end
    end

    -- Battuta
    if not settings.run.use_battuta then
        L(ctx, 'SKIP Battuta: disabled in settings')
    elseif not state.in_combat then
        L(ctx, 'SKIP Battuta: not in combat')
    elseif AutoTankUtils.has_buff('Battuta') then
        L(ctx, 'SKIP Battuta: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Battuta') then
        L(ctx, 'SKIP Battuta: on recast ('..AutoTankUtils.ability_recast_str('Battuta')..')')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_ward, settings.run.ward_delay) then
        L(ctx, 'SKIP Battuta: ward delay ('..AutoTankUtils.cooldown_remaining(cooldowns.last_ward, settings.run.ward_delay)..' remaining)')
    else
        if AutoTankUtils.use_ability('Battuta', '<me>') then
            cooldowns.last_ward = now
            return true
        end
    end

    -- Liement
    if not settings.run.use_liement then
        L(ctx, 'SKIP Liement: disabled in settings')
    elseif not state.in_combat then
        L(ctx, 'SKIP Liement: not in combat')
    elseif not AutoTankUtils.is_ability_ready('Liement') then
        L(ctx, 'SKIP Liement: on recast ('..AutoTankUtils.ability_recast_str('Liement')..')')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_ward, settings.run.ward_delay) then
        L(ctx, 'SKIP Liement: ward delay ('..AutoTankUtils.cooldown_remaining(cooldowns.last_ward, settings.run.ward_delay)..' remaining)')
    else
        if AutoTankUtils.use_ability('Liement', '<me>') then
            cooldowns.last_ward = now
            return true
        end
    end

    return false
end

-- Offensive wards and abilities
local function offensive_abilities(player, settings)
    local ctx = 'RUN.offensive_abilities'

    if not AutoTankUtils.has_valid_target() then
        L(ctx, 'SKIP: no valid target')
        return false
    end

    local rune_count = AutoTankUtils.count_runes(settings.run.rune_element)

    -- Rayke
    if not settings.run.use_rayke then
        L(ctx, 'SKIP Rayke: disabled in settings')
    elseif rune_count < settings.run.rune_count then
        L(ctx, string.format('SKIP Rayke: only %d/%d runes', rune_count, settings.run.rune_count))
    elseif not AutoTankUtils.is_ability_ready('Rayke') then
        L(ctx, 'SKIP Rayke: on recast ('..AutoTankUtils.ability_recast_str('Rayke')..')')
    else
        if AutoTankUtils.use_ability('Rayke', '<t>') then
            return true
        end
    end

    -- Gambit
    if not settings.run.use_gambit then
        L(ctx, 'SKIP Gambit: disabled in settings')
    elseif rune_count < settings.run.rune_count then
        L(ctx, string.format('SKIP Gambit: only %d/%d runes', rune_count, settings.run.rune_count))
    elseif not AutoTankUtils.is_ability_ready('Gambit') then
        L(ctx, 'SKIP Gambit: on recast ('..AutoTankUtils.ability_recast_str('Gambit')..')')
    else
        if AutoTankUtils.use_ability('Gambit', '<t>') then
            return true
        end
    end

    -- Swordplay
    if not settings.run.use_swordplay then
        L(ctx, 'SKIP Swordplay: disabled in settings')
    elseif AutoTankUtils.has_buff('Swordplay') then
        L(ctx, 'SKIP Swordplay: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Swordplay') then
        L(ctx, 'SKIP Swordplay: on recast ('..AutoTankUtils.ability_recast_str('Swordplay')..')')
    else
        if AutoTankUtils.use_ability('Swordplay', '<me>') then
            return true
        end
    end

    -- Embolden
    if not settings.run.use_embolden then
        L(ctx, 'SKIP Embolden: disabled in settings')
    elseif not AutoTankUtils.is_ability_ready('Embolden') then
        L(ctx, 'SKIP Embolden: on recast ('..AutoTankUtils.ability_recast_str('Embolden')..')')
    else
        if AutoTankUtils.use_ability('Embolden', '<me>') then
            return true
        end
    end

    return false
end

-- Rune enmity abilities (Swipe/Lunge)
local function rune_enmity(player, settings)
    local ctx = 'RUN.rune_enmity'

    if not AutoTankUtils.has_valid_target() then
        L(ctx, 'SKIP: no valid target')
        return false
    end

    local rune_count = AutoTankUtils.count_runes()
    if rune_count == 0 then
        L(ctx, 'SKIP: no runes active')
        return false
    end

    local now = os.clock()

    -- Lunge
    if not settings.run.use_lunge then
        L(ctx, 'SKIP Lunge: disabled in settings')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_enmity, 20) then
        L(ctx, 'SKIP Lunge: cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_enmity, 20)..' remaining)')
    elseif not AutoTankUtils.is_ability_ready('Lunge') then
        L(ctx, 'SKIP Lunge: on recast ('..AutoTankUtils.ability_recast_str('Lunge')..')')
    else
        if AutoTankUtils.use_ability('Lunge', '<t>') then
            cooldowns.last_enmity = now
            return true
        end
    end

    -- Swipe
    if not settings.run.use_swipe then
        L(ctx, 'SKIP Swipe: disabled in settings')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_enmity, 25) then
        L(ctx, 'SKIP Swipe: cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_enmity, 25)..' remaining)')
    elseif not AutoTankUtils.is_ability_ready('Swipe') then
        L(ctx, 'SKIP Swipe: on recast ('..AutoTankUtils.ability_recast_str('Swipe')..')')
    else
        if AutoTankUtils.use_ability('Swipe', '<t>') then
            cooldowns.last_enmity = now
            return true
        end
    end

    return false
end

-- Flash and Foil for enmity
local function generate_enmity(player, settings, state)
    local ctx = 'RUN.generate_enmity'

    if not AutoTankUtils.has_valid_target() then
        L(ctx, 'SKIP: no valid target')
        return false
    end

    local now = os.clock()

    -- Foil (short recast enmity spell, use before Flash)
    if not settings.run.use_foil then
        L(ctx, 'SKIP Foil: disabled in settings')
    elseif not AutoTankUtils.is_spell_ready('Foil') then
        L(ctx, 'SKIP Foil: on recast ('..AutoTankUtils.spell_recast_str('Foil')..')')
    else
        if AutoTankUtils.cast_spell('Foil', '<me>') then
            return true
        end
    end

    -- Flash
    if not settings.spells.use_flash then
        L(ctx, 'SKIP Flash: disabled in settings')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_flash, settings.enmity.flash_interval) then
        L(ctx, 'SKIP Flash: cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_flash, settings.enmity.flash_interval)..' remaining)')
    elseif not AutoTankUtils.is_spell_ready('Flash') then
        L(ctx, 'SKIP Flash: on recast ('..AutoTankUtils.spell_recast_str('Flash')..')')
    else
        if AutoTankUtils.cast_spell('Flash', '<t>') then
            cooldowns.last_flash = now
            state.last_flash = now
            return true
        end
    end

    return false
end

-- Maintain self buffs
local function maintain_buffs(player, settings)
    local ctx = 'RUN.maintain_buffs'

    -- Phalanx
    if not settings.spells.use_phalanx then
        L(ctx, 'SKIP Phalanx: disabled in settings')
    elseif AutoTankUtils.has_buff('Phalanx') then
        L(ctx, 'SKIP Phalanx: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Phalanx') then
        L(ctx, 'SKIP Phalanx: on recast ('..AutoTankUtils.spell_recast_str('Phalanx')..')')
    else
        AutoTankUtils.cast_spell('Phalanx', '<me>')
        return true
    end

    -- Crusade
    if not settings.spells.use_crusade then
        L(ctx, 'SKIP Crusade: disabled in settings')
    elseif AutoTankUtils.has_buff('Enmity Boost') then
        L(ctx, 'SKIP Crusade: Enmity Boost buff already active')
    elseif not AutoTankUtils.is_spell_ready('Crusade') then
        L(ctx, 'SKIP Crusade: on recast ('..AutoTankUtils.spell_recast_str('Crusade')..')')
    else
        AutoTankUtils.cast_spell('Crusade', '<me>')
        return true
    end

    -- Aquaveil
    if not settings.spells.use_aquaveil then
        L(ctx, 'SKIP Aquaveil: disabled in settings')
    elseif AutoTankUtils.has_buff('Aquaveil') then
        L(ctx, 'SKIP Aquaveil: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Aquaveil') then
        L(ctx, 'SKIP Aquaveil: on recast ('..AutoTankUtils.spell_recast_str('Aquaveil')..')')
    else
        AutoTankUtils.cast_spell('Aquaveil', '<me>')
        return true
    end

    -- Stoneskin
    if not settings.subjob.use_stoneskin then
        L(ctx, 'SKIP Stoneskin: disabled in settings')
    elseif AutoTankUtils.has_buff('Stoneskin') then
        L(ctx, 'SKIP Stoneskin: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Stoneskin') then
        L(ctx, 'SKIP Stoneskin: on recast ('..AutoTankUtils.spell_recast_str('Stoneskin')..')')
    else
        AutoTankUtils.cast_spell('Stoneskin', '<me>')
        return true
    end

    return false
end

-- Main RUN automation
function AutoTank_RUN.check_actions(player, settings, state)
    if player.status == 2 or player.status == 3 then return end

    -- Priority 1: Maintain runes
    if manage_runes(player, settings, state) then return end

    -- Priority 2: Vivacious Pulse (heal/mp recovery)
    if manage_hp(player, settings) then return end

    -- Priority 3: Defensive wards
    if defensive_wards(player, settings, state) then return end

    -- Priority 3: Maintain buffs
    if maintain_buffs(player, settings) then return end

    -- Priority 4: Offensive abilities (in combat)
    if state.in_combat then
        if offensive_abilities(player, settings) then return end
    else
        ATLog.write('RUN.check_actions', 'SKIP offensive_abilities: not in combat')
    end

    -- Priority 5: Rune enmity (in combat)
    if state.in_combat then
        if rune_enmity(player, settings) then return end
    else
        ATLog.write('RUN.check_actions', 'SKIP rune_enmity: not in combat')
    end

    -- Priority 6: Flash enmity (in combat)
    if state.in_combat then
        if generate_enmity(player, settings, state) then return end
    else
        ATLog.write('RUN.check_actions', 'SKIP flash_enmity: not in combat')
    end
end

return AutoTank_RUN
