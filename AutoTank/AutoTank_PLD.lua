--[[
    AutoTank - Paladin Module
    Handles PLD job abilities and spell automation
]]--

AutoTank_PLD = {}

-- Track cooldowns
local cooldowns = {
    last_flash = 0,
    last_cure = 0,
    last_sentinel = 0,
    last_rampart = 0,
    last_enmity_spell = 0,
}

local L = ATLog.write

-- Maintain self buffs
local function maintain_buffs(player, settings)
    local ctx = 'PLD.maintain_buffs'

    -- Enlight
    if not settings.spells.use_enlight then
        L(ctx, 'SKIP Enlight: disabled in settings')
    elseif AutoTankUtils.has_buff('Enlight') then
        L(ctx, 'SKIP Enlight: buff already active')
    else
        if AutoTankUtils.is_spell_ready('Enlight II') then
            AutoTankUtils.cast_spell('Enlight II', '<me>')
            return true
        elseif AutoTankUtils.is_spell_ready('Enlight') then
            AutoTankUtils.cast_spell('Enlight', '<me>')
            return true
        else
            L(ctx, 'SKIP Enlight: on recast (II='..AutoTankUtils.spell_recast_str('Enlight II')..' I='..AutoTankUtils.spell_recast_str('Enlight')..')')
        end
    end

    -- Reprisal
    if not settings.spells.use_reprisal then
        L(ctx, 'SKIP Reprisal: disabled in settings')
    elseif AutoTankUtils.has_buff('Reprisal') then
        L(ctx, 'SKIP Reprisal: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Reprisal') then
        L(ctx, 'SKIP Reprisal: on recast ('..AutoTankUtils.spell_recast_str('Reprisal')..')')
    else
        AutoTankUtils.cast_spell('Reprisal', '<me>')
        return true
    end

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

    -- Majesty
    if not settings.pld.use_majesty then
        L(ctx, 'SKIP Majesty: disabled in settings')
    elseif AutoTankUtils.has_buff('Majesty') then
        L(ctx, 'SKIP Majesty: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Majesty') then
        L(ctx, 'SKIP Majesty: on recast ('..AutoTankUtils.ability_recast_str('Majesty')..')')
    else
        AutoTankUtils.use_ability('Majesty', '<me>')
        return true
    end

    return false
end

-- Emergency defensive abilities
local function emergency_defense(player, settings)
    local ctx = 'PLD.emergency_defense'
    local hp_percent = AutoTankUtils.get_hp_percent()

    -- Sentinel
    if not settings.pld.use_sentinel then
        L(ctx, 'SKIP Sentinel: disabled in settings')
    elseif hp_percent > settings.pld.sentinel_hp then
        L(ctx, string.format('SKIP Sentinel: HP %d%% > threshold %d%%', hp_percent, settings.pld.sentinel_hp))
    elseif not AutoTankUtils.is_ability_ready('Sentinel') then
        L(ctx, 'SKIP Sentinel: on recast ('..AutoTankUtils.ability_recast_str('Sentinel')..')')
    else
        if AutoTankUtils.use_ability('Sentinel', '<me>') then
            cooldowns.last_sentinel = os.clock()
            return true
        end
    end

    -- Rampart
    if not settings.pld.use_rampart then
        L(ctx, 'SKIP Rampart: disabled in settings')
    elseif hp_percent > settings.pld.rampart_hp then
        L(ctx, string.format('SKIP Rampart: HP %d%% > threshold %d%%', hp_percent, settings.pld.rampart_hp))
    elseif not AutoTankUtils.is_ability_ready('Rampart') then
        L(ctx, 'SKIP Rampart: on recast ('..AutoTankUtils.ability_recast_str('Rampart')..')')
    else
        if AutoTankUtils.use_ability('Rampart', '<me>') then
            cooldowns.last_rampart = os.clock()
            return true
        end
    end

    -- Palisade
    if not settings.pld.use_palisade then
        L(ctx, 'SKIP Palisade: disabled in settings')
    elseif hp_percent > settings.pld.palisade_hp then
        L(ctx, string.format('SKIP Palisade: HP %d%% > threshold %d%%', hp_percent, settings.pld.palisade_hp))
    elseif not AutoTankUtils.is_ability_ready('Palisade') then
        L(ctx, 'SKIP Palisade: on recast ('..AutoTankUtils.ability_recast_str('Palisade')..')')
    else
        if AutoTankUtils.use_ability('Palisade', '<me>') then
            return true
        end
    end

    return false
end

-- Healing
local function handle_healing(player, settings)
    local ctx = 'PLD.handle_healing'
    local hp_percent = AutoTankUtils.get_hp_percent()
    local now = os.clock()

    if not settings.healing.use_cures then
        L(ctx, 'SKIP: use_cures disabled in settings')
        return false
    end

    if not AutoTankUtils.cooldown_ready(cooldowns.last_cure, 2) then
        L(ctx, 'SKIP: cure cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_cure, 2)..' remaining)')
        return false
    end

    -- Self cure
    if hp_percent <= settings.healing.cure_hp then
        if AutoTankUtils.is_spell_ready('Cure IV') then
            AutoTankUtils.cast_spell('Cure IV', '<me>')
            cooldowns.last_cure = now
            return true
        elseif AutoTankUtils.is_spell_ready('Cure III') then
            AutoTankUtils.cast_spell('Cure III', '<me>')
            cooldowns.last_cure = now
            return true
        elseif AutoTankUtils.is_spell_ready('Cure II') then
            AutoTankUtils.cast_spell('Cure II', '<me>')
            cooldowns.last_cure = now
            return true
        else
            L(ctx, string.format('SKIP self-cure: HP %d%% <= %d%% but all cures on recast (IV=%s III=%s II=%s)',
                hp_percent, settings.healing.cure_hp,
                AutoTankUtils.spell_recast_str('Cure IV'),
                AutoTankUtils.spell_recast_str('Cure III'),
                AutoTankUtils.spell_recast_str('Cure II')))
        end
    else
        L(ctx, string.format('SKIP self-cure: HP %d%% > threshold %d%%', hp_percent, settings.healing.cure_hp))
    end

    -- Party cure
    if not settings.healing.cure_party then
        L(ctx, 'SKIP party-cure: cure_party disabled in settings')
        return false
    end

    local party = windower.ffxi.get_party()
    if not party then
        L(ctx, 'SKIP party-cure: no party data')
        return false
    end

    local lowest_hp_member = nil
    local lowest_hp_percent = 100

    for i = 0, 5 do
        local member = party['p' .. i]
        if member and member.mob then
            local member_hpp = member.mob.hpp
            if member_hpp and member_hpp <= settings.healing.cure_hp and member_hpp < lowest_hp_percent then
                lowest_hp_percent = member_hpp
                lowest_hp_member = member
            end
        end
    end

    if not lowest_hp_member then
        L(ctx, string.format('SKIP party-cure: no party member below %d%% HP', settings.healing.cure_hp))
        return false
    end

    local target_id = '<' .. lowest_hp_member.name .. '>'

    if AutoTankUtils.is_spell_ready('Cure IV') then
        AutoTankUtils.cast_spell('Cure IV', target_id)
        cooldowns.last_cure = now
        return true
    elseif AutoTankUtils.is_spell_ready('Cure III') then
        AutoTankUtils.cast_spell('Cure III', target_id)
        cooldowns.last_cure = now
        return true
    elseif AutoTankUtils.is_spell_ready('Cure II') then
        AutoTankUtils.cast_spell('Cure II', target_id)
        cooldowns.last_cure = now
        return true
    else
        L(ctx, string.format('SKIP party-cure: %s at %d%% but all cures on recast (IV=%s III=%s II=%s)',
            lowest_hp_member.name, lowest_hp_percent,
            AutoTankUtils.spell_recast_str('Cure IV'),
            AutoTankUtils.spell_recast_str('Cure III'),
            AutoTankUtils.spell_recast_str('Cure II')))
    end

    return false
end

-- Enmity generation
local function generate_enmity(player, settings, state)
    local ctx = 'PLD.generate_enmity'

    if not AutoTankUtils.has_valid_target() then
        L(ctx, 'SKIP: no valid target')
        return false
    end

    local now = os.clock()
    local target = AutoTankUtils.get_target()

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

    -- Divine Emblem + Flash combo
    if not settings.pld.use_divine_emblem then
        L(ctx, 'SKIP Divine Emblem: disabled in settings')
    elseif not AutoTankUtils.is_ability_ready('Divine Emblem') then
        L(ctx, 'SKIP Divine Emblem: on recast ('..AutoTankUtils.ability_recast_str('Divine Emblem')..')')
    elseif not AutoTankUtils.is_spell_ready('Flash') then
        L(ctx, 'SKIP Divine Emblem combo: Flash on recast ('..AutoTankUtils.spell_recast_str('Flash')..')')
    else
        AutoTankUtils.use_ability('Divine Emblem', '<me>')
        return true
    end

    -- Shield Bash
    if not settings.pld.use_shield_bash then
        L(ctx, 'SKIP Shield Bash: disabled in settings')
    elseif not AutoTankUtils.is_ability_ready('Shield Bash') then
        L(ctx, 'SKIP Shield Bash: on recast ('..AutoTankUtils.ability_recast_str('Shield Bash')..')')
    else
        if AutoTankUtils.use_ability('Shield Bash', '<t>') then
            return true
        end
    end

    -- Holy Circle
    if not settings.pld.use_holy_circle then
        L(ctx, 'SKIP Holy Circle: disabled in settings')
    elseif not (target.name:find('Skeleton') or target.name:find('Ghost') or target.name:find('Corpse')) then
        L(ctx, 'SKIP Holy Circle: target "'..target.name..'" is not undead')
    elseif AutoTankUtils.has_buff('Holy Circle') then
        L(ctx, 'SKIP Holy Circle: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Holy Circle') then
        L(ctx, 'SKIP Holy Circle: on recast ('..AutoTankUtils.ability_recast_str('Holy Circle')..')')
    else
        AutoTankUtils.use_ability('Holy Circle', '<me>')
        return true
    end

    return false
end

-- MP management
local function manage_mp(player, settings)
    local ctx = 'PLD.manage_mp'
    local mp_percent = AutoTankUtils.get_mp_percent()

    local player_tp = (player.vitals or {}).tp or 0
    if not settings.pld.use_chivalry then
        L(ctx, 'SKIP Chivalry: disabled in settings')
    elseif mp_percent > settings.pld.chivalry_mp then
        L(ctx, string.format('SKIP Chivalry: MP %d%% > threshold %d%%', mp_percent, settings.pld.chivalry_mp))
    elseif player_tp < settings.pld.chivalry_tp then
        L(ctx, string.format('SKIP Chivalry: TP %d < required %d', player_tp, settings.pld.chivalry_tp))
    elseif not AutoTankUtils.is_ability_ready('Chivalry') then
        L(ctx, 'SKIP Chivalry: on recast ('..AutoTankUtils.ability_recast_str('Chivalry')..')')
    else
        if AutoTankUtils.use_ability('Chivalry', '<me>') then
            return true
        end
    end

    return false
end

-- Cover ally
local function handle_cover(player, settings)
    local ctx = 'PLD.handle_cover'

    if not settings.pld.use_cover then
        L(ctx, 'SKIP Cover: disabled in settings')
        return false
    end

    if settings.pld.cover_target == '' then
        L(ctx, 'SKIP Cover: no cover_target configured')
        return false
    end

    if AutoTankUtils.has_buff('Cover') then
        L(ctx, 'SKIP Cover: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Cover') then
        L(ctx, 'SKIP Cover: on recast ('..AutoTankUtils.ability_recast_str('Cover')..')')
    else
        if AutoTankUtils.use_ability('Cover', '<'..settings.pld.cover_target..'>') then
            return true
        end
    end

    return false
end

-- Main PLD automation
function AutoTank_PLD.check_actions(player, settings, state)
    if player.status == 2 or player.status == 3 then return end

    -- Priority 1: Emergency defense
    if emergency_defense(player, settings) then return end

    -- Priority 2: Healing
    if handle_healing(player, settings) then return end

    -- Priority 3: MP management
    if manage_mp(player, settings) then return end

    -- Priority 4: Maintain buffs
    if maintain_buffs(player, settings) then return end

    -- Priority 5: Cover ally
    if handle_cover(player, settings) then return end

    -- Priority 6: Generate enmity (only in combat)
    if state.in_combat then
        if generate_enmity(player, settings, state) then return end
    else
        ATLog.write('PLD.check_actions', 'SKIP enmity: not in combat')
    end
end

return AutoTank_PLD
