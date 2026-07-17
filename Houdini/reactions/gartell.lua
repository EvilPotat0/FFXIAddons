-- Reaction sidecar for Gartell / Leshonn
-- Runs with Houdini's globals in scope: TitleCase, CastNuke, UpdateSkillchainElementFromReact,
-- ElementToQuickDraw, ElementToStorm, windower.*

local function GartellReaction(args)
	if args[2] == nil then
		return
	end
	UpdateSkillchainElementFromReact(TitleCase(args[2]))
	local player = windower.ffxi.get_player()
	if player.main_job == "SCH" then
		windower.send_command('input /ma "'..ElementToStorm[TitleCase(args[2])]..'" <me>')
	elseif player.main_job == "COR" then
		windower.send_command('input /ja "'..ElementToQuickDraw[TitleCase(args[2])]..'" <t>')
	end
end

return {
	Gartell = GartellReaction,
	Leshonn = GartellReaction,
}
