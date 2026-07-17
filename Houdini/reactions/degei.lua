-- Reaction sidecar for Degei / Aita
-- Runs with Houdini's globals in scope: TitleCase, CastNuke, UpdateSkillchainElementFromReact,
-- ElementToQuickDraw, ElementToStorm, windower.*

local function DegeiReaction(args)
	if args[2] == nil then
		return
	end

	UpdateSkillchainElementFromReact(TitleCase(args[2]))
	local player = windower.ffxi.get_player()
	local WasBursting = BurstActive
	if WasBursting then
		CancelBurst()
	end
	if player.main_job == "BLM" or player.main_job == "GEO" then
		if WasBursting then
			windower.send_command:schedule(BurstDelay, 'input //ho nuke '..TitleCase(args[2]))
		else
			CastNuke(TitleCase(args[2]))
		end
	elseif player.main_job == "COR" then
		windower.send_command('input /ja "'..ElementToQuickDraw[TitleCase(args[2])]..'" <t>')
	elseif player.main_job == "SCH" then
		if WasBursting then
			windower.send_command:schedule(BurstDelay,'input /ma "'..ElementToStorm[TitleCase(args[2])]..'" <me>')
		else
			windower.send_command('input /ma "'..ElementToStorm[TitleCase(args[2])]..'" <me>')
		end
	end
end

return {
	Degei = DegeiReaction,
	Aita = DegeiReaction,
}
