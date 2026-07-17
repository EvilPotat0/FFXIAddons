--[[
    AutoTank - Subjob Module
    Handles subjob abilities (WAR/BLU/SCH)
]]--

AutoTank_Subjobs = {}

-- Track cooldowns
local cooldowns = {
    last_provoke = 0,
    last_blu_spell = {},  -- Track individual BLU spell cooldowns
    last_buff_check = 0,
}

local L = ATLog.write

--[[
    WARRIOR SUBJOB ABILITIES
]]--
local function handle_warrior_subjob(player, settings, state)
    local ctx = 'SUB.war'

    if player.sub_job ~= 'WAR' then return false end

    local now = os.clock()

    -- Provoke
    if not settings.subjob.use_provoke then
        L(ctx, 'SKIP Provoke: disabled in settings')
    elseif not state.in_combat then
        L(ctx, 'SKIP Provoke: not in combat')
    elseif not AutoTankUtils.has_valid_target() then
        L(ctx, 'SKIP Provoke: no valid target')
    elseif not AutoTankUtils.cooldown_ready(cooldowns.last_provoke, settings.enmity.provoke_interval) then
        L(ctx, 'SKIP Provoke: cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_provoke, settings.enmity.provoke_interval)..' remaining)')
    elseif not AutoTankUtils.is_ability_ready('Provoke') then
        L(ctx, 'SKIP Provoke: on recast ('..AutoTankUtils.ability_recast_str('Provoke')..')')
    else
        if AutoTankUtils.use_ability('Provoke', '<t>') then
            cooldowns.last_provoke = now
            state.last_provoke = now
            return true
        end
    end

    -- Defender
    if not settings.subjob.use_defender then
        L(ctx, 'SKIP Defender: disabled in settings')
    elseif AutoTankUtils.has_buff('Defender') then
        L(ctx, 'SKIP Defender: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Defender') then
        L(ctx, 'SKIP Defender: on recast ('..AutoTankUtils.ability_recast_str('Defender')..')')
    else
        if AutoTankUtils.use_ability('Defender', '<me>') then
            return true
        end
    end

    -- Warcry
    if not settings.subjob.use_warcry then
        L(ctx, 'SKIP Warcry: disabled in settings')
    elseif not AutoTankUtils.is_ability_ready('Warcry') then
        L(ctx, 'SKIP Warcry: on recast ('..AutoTankUtils.ability_recast_str('Warcry')..')')
    else
        if AutoTankUtils.use_ability('Warcry', '<me>') then
            return true
        end
    end

    -- Aggressor
    if not settings.subjob.use_aggressor then
        L(ctx, 'SKIP Aggressor: disabled in settings')
    elseif AutoTankUtils.has_buff('Aggressor') then
        L(ctx, 'SKIP Aggressor: buff already active')
    elseif not AutoTankUtils.is_ability_ready('Aggressor') then
        L(ctx, 'SKIP Aggressor: on recast ('..AutoTankUtils.ability_recast_str('Aggressor')..')')
    else
        if AutoTankUtils.use_ability('Aggressor', '<me>') then
            return true
        end
    end

    return false
end

--[[
    BLUE MAGE SUBJOB ABILITIES
    Uses configurable spell list from settings
]]--
local function handle_blue_mage_subjob(player, settings, state)
    local ctx = 'SUB.blu'

    if player.sub_job ~= 'BLU' then return false end

    local hp_percent = AutoTankUtils.get_hp_percent()
    local now = os.clock()

    for _, spell_config in ipairs(settings.subjob.blu_spells) do
        local spell_name = spell_config.name

        if not spell_config.enabled then
            L(ctx, 'SKIP '..spell_name..': disabled in spell list')
        else
            -- Initialize cooldown tracking for this spell
            if not cooldowns.last_blu_spell[spell_name] then
                cooldowns.last_blu_spell[spell_name] = 0
            end

            if not AutoTankUtils.cooldown_ready(cooldowns.last_blu_spell[spell_name], 5) then
                L(ctx, 'SKIP '..spell_name..': internal cooldown ('..AutoTankUtils.cooldown_remaining(cooldowns.last_blu_spell[spell_name], 5)..' remaining)')
            else
                local target_type = spell_config.target
                local hp_threshold = spell_config.hp_threshold and tonumber(spell_config.hp_threshold) or nil
                local target_str = '<me>'
                local should_cast = false
                local skip_reason = nil

                if target_type == 'self' then
                    target_str = '<me>'
                    local buff_to_check = spell_config.is_buff and (spell_config.buff_name or spell_name) or nil
                    -- Healing spells default to 75% if no threshold is explicitly set
                    local effective_threshold = hp_threshold or (spell_config.is_heal and 75) or nil
                    if buff_to_check and AutoTankUtils.has_buff(buff_to_check) then
                        skip_reason = 'buff "' .. buff_to_check .. '" already active'
                    elseif effective_threshold and hp_percent > effective_threshold then
                        skip_reason = string.format('HP %d%% > threshold %d%%', hp_percent, effective_threshold)
                    else
                        should_cast = true
                    end
                elseif target_type == 'enemy' then
                    target_str = '<t>'
                    if not state.in_combat then
                        skip_reason = 'not in combat'
                    elseif not AutoTankUtils.has_valid_target() then
                        skip_reason = 'no valid target'
                    else
                        should_cast = true
                    end
                end

                if skip_reason then
                    L(ctx, 'SKIP '..spell_name..': '..skip_reason)
                elseif should_cast then
                    if not AutoTankUtils.is_spell_ready(spell_name) then
                        L(ctx, 'SKIP '..spell_name..': on recast ('..AutoTankUtils.spell_recast_str(spell_name)..')')
                    else
                        if AutoTankUtils.cast_spell(spell_name, target_str) then
                            cooldowns.last_blu_spell[spell_name] = now
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

--[[
    SCHOLAR SUBJOB ABILITIES
]]--
local function handle_scholar_subjob(player, settings)
    local ctx = 'SUB.sch'

    if player.sub_job ~= 'SCH' then return false end

    local now = os.clock()

    if not AutoTankUtils.cooldown_ready(cooldowns.last_buff_check, 10) then
        L(ctx, 'SKIP: buff check cooldown not ready ('..AutoTankUtils.cooldown_remaining(cooldowns.last_buff_check, 10)..' remaining)')
        return false
    end

    -- Regen
    if not settings.subjob.use_regen then
        L(ctx, 'SKIP Regen: disabled in settings')
    elseif AutoTankUtils.has_buff('Regen') then
        L(ctx, 'SKIP Regen: buff already active')
    else
        if AutoTankUtils.is_spell_ready('Regen IV') then
            AutoTankUtils.cast_spell('Regen IV', '<me>')
            cooldowns.last_buff_check = now
            return true
        elseif AutoTankUtils.is_spell_ready('Regen III') then
            AutoTankUtils.cast_spell('Regen III', '<me>')
            cooldowns.last_buff_check = now
            return true
        elseif AutoTankUtils.is_spell_ready('Regen II') then
            AutoTankUtils.cast_spell('Regen II', '<me>')
            cooldowns.last_buff_check = now
            return true
        elseif AutoTankUtils.is_spell_ready('Regen') then
            AutoTankUtils.cast_spell('Regen', '<me>')
            cooldowns.last_buff_check = now
            return true
        else
            L(ctx, 'SKIP Regen: no buff, but all tiers on recast (IV='..AutoTankUtils.spell_recast_str('Regen IV')
                ..' III='..AutoTankUtils.spell_recast_str('Regen III')
                ..' II='..AutoTankUtils.spell_recast_str('Regen II')
                ..' I='..AutoTankUtils.spell_recast_str('Regen')..')')
        end
    end

    -- Stoneskin
    if not settings.subjob.use_stoneskin then
        L(ctx, 'SKIP Stoneskin: disabled in settings')
    elseif AutoTankUtils.has_buff('Stoneskin') then
        L(ctx, 'SKIP Stoneskin: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Stoneskin') then
        L(ctx, 'SKIP Stoneskin: on recast ('..AutoTankUtils.spell_recast_str('Stoneskin')..')')
    else
        if AutoTankUtils.cast_spell('Stoneskin', '<me>') then
            cooldowns.last_buff_check = now
            return true
        end
    end

    -- Phalanx
    if not settings.spells.use_phalanx then
        L(ctx, 'SKIP Phalanx: disabled in settings')
    elseif AutoTankUtils.has_buff('Phalanx') then
        L(ctx, 'SKIP Phalanx: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Phalanx') then
        L(ctx, 'SKIP Phalanx: on recast ('..AutoTankUtils.spell_recast_str('Phalanx')..')')
    else
        if AutoTankUtils.cast_spell('Phalanx', '<me>') then
            cooldowns.last_buff_check = now
            return true
        end
    end

    -- Aquaveil
    if not settings.spells.use_aquaveil then
        L(ctx, 'SKIP Aquaveil: disabled in settings')
    elseif AutoTankUtils.has_buff('Aquaveil') then
        L(ctx, 'SKIP Aquaveil: buff already active')
    elseif not AutoTankUtils.is_spell_ready('Aquaveil') then
        L(ctx, 'SKIP Aquaveil: on recast ('..AutoTankUtils.spell_recast_str('Aquaveil')..')')
    else
        if AutoTankUtils.cast_spell('Aquaveil', '<me>') then
            cooldowns.last_buff_check = now
            return true
        end
    end

    return false
end

-- Main subjob automation
function AutoTank_Subjobs.check_actions(player, settings, state)
    if player.status == 2 or player.status == 3 then return end

    if player.sub_job == 'WAR' then
        if handle_warrior_subjob(player, settings, state) then return end
    elseif player.sub_job == 'BLU' then
        if handle_blue_mage_subjob(player, settings, state) then return end
    elseif player.sub_job == 'SCH' then
        if handle_scholar_subjob(player, settings) then return end
    else
        ATLog.write('SUB.check_actions', 'SKIP: subjob '..tostring(player.sub_job)..' not handled')
    end
end

return AutoTank_Subjobs
