
_addon.name = 'Houdini'
_addon.author = 'EvilPotat0'
_addon.commands = {'houdini','ho'}
_addon.version = '0.1.0'
_addon.lastUpdate = '2025.11.1'

require('luau')
require('lor/lor_utils')
files = require('files')
_libs.lor.req('all')
_libs.lor.debug = false
require('tables')
require 'sets'
require 'lists'
require 'strings'
require 'logger'
require 'pack'
require 'actions'
local res = require('resources')
extdata = require 'extdata'
texts = require('texts')

local bags = {[0]='inventory',[8]='wardrobe',[10]='wardrobe2',[11]='wardrobe3',[12]='wardrobe4',[13]='wardrobe5',[14]='wardrobe6',[15]='wardrobe7',[16]='wardrobe8'}

local ElementSpellNames = T{
	'Fire',
	'Water',
	'Thunder',
	'Stone',
	'Blizzard',
	'Aero'
}

local SpellAjaMap = T{
	Fire = 'Firaja',
	Water = 'Waterja',
	Thunder = 'Thundaja',
	Stone = 'Stoneja',
	Blizzard = 'Blizzaja',
	Aero = 'Aeroja',
}

local SpellHelixMap = T{
	Fire = 'Pyrohelix II',
	Water = 'Hydrohelix II',
	Thunder = 'Ionohelix II',
	Stone = 'Geohelix II',
	Blizzard = 'Cryohelix II',
	Aero = 'Anemohelix II',
}

local ElementToGa = {Fire = 'Firaga', Blizzard='Blizzaga', Aero='Aeroga', Stone='Stonega',Thunder='Thundaga',Water='Waterga'}
-- global (not local): reaction sidecar files in reactions/ reference this
ElementToQuickDraw = {Fire = 'Fire Shot', Blizzard='Ice Shot', Aero='Wind Shot', Stone='Earth Shot',Thunder='Thunder Shot',Water='Water Shot'}
-- global (not local): reaction sidecar files in reactions/ reference this
ElementToStorm = {Fire = 'FireStorm II', Water="Rainstorm II", Thunder="Thunderstorm II", Stone="Sandstorm II", Aero="Windstorm II", Blizzard="Hailstorm II"}
local TierMap = {'',' II', ' III',' IV',' V',' VI', 'aja'}

local Town = S {
    "Ru'Lude Gardens", "Upper Jeuno", "Lower Jeuno", "Port Jeuno",
    "Port Windurst", "Windurst Waters", "Windurst Woods", "Windurst Walls", "Heavens Tower",
    "Port San d'Oria", "Northern San d'Oria", "Southern San d'Oria", "Chateau d'Oraguille",
    "Port Bastok", "Bastok Markets", "Bastok Mines", "Metalworks",
    "Aht Urhgan Whitegate", "Nashmau",
	"Rabao",
    "Selbina", "Mhaura", "Norg",  "Kazham", "Tavanazian Safehold",
    "Eastern Adoulin", "Western Adoulin", "Celennia Memorial Library", "Mog Garden"
}

local CastJobs = S{"BLM", "RDM", "SCH", "GEO"}

local defaults = {
	enabled = true,
	leader = false,
	use_aja = false,
	send_target = false,
	send_messages = false,
	use_messages = false,
	useMyrkr = false,
	myrkrTp = 1000,
	myrkrMpPercent = 40,
	enableClick = false,
	tierDelays = T{1.0, 2.0, 3.0, 4.1, 4.6, 5.0, 5.0},
	leaderBurstDelay = 3.0,
	corQuickDrawDelay = 0.25,
	tellsList = T{},
	mppWarning = 40.0,
	debuff="",
	shard_reporting = false,
	elements = {
		Light = 'Fire',
		Darkness = 'Stone',
		Fusion = 'Fire',
		Distortion = 'Blizzard',
		Gravitation = 'Stone',
		Fragmentation = 'Thunder',
		Liquefaction = 'Fire',
		Detonation = 'Aero',
		Impaction = 'Thunder',
		Induration = 'Blizzard',
		Reverberation = 'Water',
		Scission='Stone'
	},
	show_display = false,
	display = {
		bg = {
			visible=true,
			alpha=64,
		},
		font = "Consolas",
		font_size = 10,
		padding = 2,
		pos = {x=100,y=240},
		stroke = {
			width = 1,
		},
		text = {
			size=10,
			font='Consolas'
		}
	}
}

local SendLockOn = false

local SentMpWarning = false
local MpAboveWarning = true

local LeaderNotDoingSC = 0
local InTown = false
local DefaultDelay = 0.8
local LastCheckTime = 0
local TimeDelay = DefaultDelay
local LastId = 0
local Settings = T{}

local BurstElement = "Fire"
BurstDelay = 1.0
local NextTier = 4
local BurstCount = 0
BurstActive = false
local BurstTime = 0
local UseHelix = false

local ShouldCastMeteor = false
local MeteorTime = 0

function SliceTable(originalTable, startIndex, endIndex)
    local slicedTable = {}
    for i = startIndex, endIndex do
        table.insert(slicedTable, originalTable[i])
    end
    return slicedTable
end

function IsCastingJob(JobName)
	return CastJobs:contains(JobName)
end

function GetMagicRecast(Name)
    --add_to_chat(123,Res.spells:with('name',Name).recast_id)
    return res.spells:with('name',Name).recast_id
end
---------------------------------------------------------------------------------------------------------------------
function GetMagicMP(Name)
    --add_to_chat(123,Res.spells:with('name',Name).recast_id)
    return res.spells:with('name',Name).mp_cost
end

function IsSpellReady(Spell)
	local player = windower.ffxi.get_player()
	if windower.ffxi.get_spell_recasts()[GetMagicRecast(Spell)] < 1 and player.vitals.mp > GetMagicMP(Spell) then
		return true
	end
	return false
end

function TriggerPotency()
	local player = windower.ffxi.get_player()
	if player.main_job == "SCH" or player.sub_job == "SCH" then
		windower.send_command('input /ja Ebullience <me>')
	elseif player.main_job == "GEO" then
		windower.send_command('input /ja "Collimated Fervor" <me>')
	end
end

function StartMeteor()
	local player = windower.ffxi.get_player()
	if player.main_job == "BLM" then
		windower.send_command('input /ja "Elemental Seal" <me>')
		ShouldCastMeteor = true
		MeteorTime = os.clock()
	end
end

function CastMeteor()
	local player = windower.ffxi.get_player()
	if player.main_job == "BLM" then
		windower.send_command('input /ma "Meteor" <t>')
		ShouldCastMeteor = false
		MeteorTime = 0
	end
end

function CastAspir()
	local player = windower.ffxi.get_player()

	if not IsCastingJob(player.main_job) then
		return
	end

	if player.main_job == 'BLM' or player.main_job == 'GEO' then
		if IsSpellReady("Aspir III") then
			windower.send_command('input /ma "Aspir III" <t>')
			return
		end
	end

	if IsSpellReady("Aspir II") then
		windower.send_command('input /ma "Aspir II" <t>')
	elseif IsSpellReady("Aspir") then
		windower.send_command('input /ma "Aspir" <t>')
	end
end

function StatusReport()
	local player = windower.ffxi.get_player()
	if player.main_job == 'SCH' or player.sub_job == 'SCH' then
		windower.send_command('input /p <recast="stratagems">')
	end
end

function CastNuke(Spell, Tier)
	local player = windower.ffxi.get_player()
   
	if not IsCastingJob(player.main_job) then
		return
	end

	if UseHelix and player.main_job == 'SCH' then
		local HelixSpell = SpellHelixMap[Spell]
		if IsSpellReady(HelixSpell) then
			UseHelix = false
			windower.send_command('input /ma "'..HelixSpell..'" <t>')
			UpdateDisplay()
			return
		end
	end

	if Tier ~= nil then
		if Tier == 'aja' or TierMap[tonumber(Tier)] == 'aja' then
			if player.main_job=="BLM" and Settings.use_aja and IsSpellReady(SpellAjaMap[Spell]) then
				windower.send_command('input /ma "'..SpellAjaMap[Spell]..'" <t>')
				return
			end
		else
			local TierString = TierMap[tonumber(Tier)]
			if IsSpellReady(Spell..TierString) then
				windower.send_command('input /ma "'..Spell..TierString..'" <t>')
				return
			end
		end
	end

   if player.main_job=="BLM" and Settings.use_aja and windower.ffxi.get_spell_recasts()[GetMagicRecast(SpellAjaMap[Spell])] < 1 and player.vitals.mp > GetMagicMP(SpellAjaMap[Spell]) then
		windower.send_command('input /ma "'..SpellAjaMap[Spell]..'" <t>')
   elseif IsSpellReady(Spell.." VI") and player.main_job=="BLM" then
		windower.send_command('input /ma "'..Spell..' VI" <t>')
   elseif IsSpellReady(Spell.." V") then
		windower.send_command('input /ma "'..Spell..' V" <t>')
   elseif IsSpellReady(Spell.." IV") then
		windower.send_command('input /ma "'..Spell..' IV" <t>')
   elseif IsSpellReady(Spell.." III") then
		windower.send_command('input /ma "'..Spell..' III" <t>')
   elseif IsSpellReady(Spell.." II") then
		windower.send_command('input /ma "'..Spell..' II" <t>')   
   elseif IsSpellReady(Spell) then
		windower.send_command('input /ma "'..Spell..'" <t>') 		   
   end
end

function CastAoE(Spell)
	local player = windower.ffxi.get_player()
	if not IsCastingJob(player.main_job) then
		return
	end

	if player.main_job ~= 'BLM' and player.sub_job ~= 'BLM' then
		-- only blm gets access to ga spells
		return
	end

	local GaSpell = ElementToGa[Spell]
	
	if player.main_job=="BLM" and IsSpellReady(SpellAjaMap[Spell]) then
		windower.send_command('input /ma "'..SpellAjaMap[Spell]..'" <t>')
	elseif IsSpellReady(GaSpell.." III") then
		windower.send_command('input /ma "'..GaSpell..' III" <t>')
	elseif IsSpellReady(GaSpell.." II") then
		windower.send_command('input /ma "'..GaSpell..' II" <t>')   
	elseif IsSpellReady(GaSpell) then
		windower.send_command('input /ma "'..GaSpell..'" <t>') 		   
   	end
end

function CancelBurst()
	if BurstActive then
		BurstActive = false
		TimeDelay = DefaultDelay
	end
end

function StartBurst(SkillChainOrElement, IgnoreLeader)
	if BurstActive then
		atc("IgnoringBurstAlreadyActive")
		return
	end

	BurstElement = Settings.elements[SkillChainOrElement]
	if BurstElement == nil then
		BurstElement = SkillChainOrElement
	end
	local player = windower.ffxi.get_player()
	BurstTime = os.clock()
	TimeDelay = 0.1

	if player.main_job == "COR" then
		-- trigger matching elemental shot on cor to be timed with first MBs hitting
		BurstDelay = Settings.corQuickDrawDelay
		BurstCount = 1
		BurstActive = true
		return
	end

	local start_tier = 5
	if player.main_job=="BLM" then
		if Settings.use_aja then
			start_tier = 7
		else
			start_tier = 6
		end
	end
	
	if Settings.leader and (IgnoreLeader <= 0) then
		-- delay a bit assuming leader is doing sch SC
		NextTier = start_tier
		-- only do 2 bursts, since can't hit 3 being the one doing SC
		BurstCount = 1
		BurstDelay = Settings.leaderBurstDelay
		BurstActive = true
	else
		CastNuke(BurstElement, start_tier)
		BurstCount = 1
		BurstActive = true
		BurstDelay = Settings.tierDelays[start_tier]
		NextTier = start_tier - 1
		if start_tier >= 6 then
			NextTier = 4
		end
	end
end

function NextBurst()
	local player = windower.ffxi.get_player()
	if player.main_job == "COR" then
		windower.send_command('input /ja "'..ElementToQuickDraw[BurstElement]..'" <t>')
		BurstActive = false
		TimeDelay = DefaultDelay
		return
	end

	CastNuke(BurstElement, NextTier)
	BurstTime = os.clock()
	BurstCount = BurstCount + 1
	BurstActive = BurstCount < 3
	BurstDelay = Settings.tierDelays[NextTier]
	NextTier = NextTier - 1

	if NextTier >= 6 then
		NextTier = 4
	end

	if BurstActive == false then
		TimeDelay = DefaultDelay
	end
end

function SplitString(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end


local function tchelper(first, rest)
    return first:upper()..rest:lower()
end

function TitleCase(str)
    if (str == nil) then
        return str
    end
    str = str:gsub("(%a)([%w_']*)", tchelper)
    return str
end

function SaveSettings()
	Settings:save('all')
	atcf('Settings Saved')
end

function LoadSettings()
	local player = windower.ffxi.get_player()
	Settings = config.load("data/"..player.name..".xml", defaults)
end

function GetElementsString()
	local ele_string = ""
	for index, value in pairs(Settings.elements) do
    	ele_string = ele_string .. "\n" .. index .. ": " .. value
	end
	return ele_string
end

LoadSettings()
local display = texts.new('${addon_title}', Settings.display, Settings)
function InitDisplay() 
	display.addon_title = Settings.enabled and ("--- Houdini "):text_color(0,255,0) or ("--- Houdini "):text_color(255,0,0)
	
	display:appendline('Enabled: ${enabled|0}')
	display.enabled = Settings.enabled and tostring('On') or tostring('Off')

	display:appendline('Leader: ${leader|0}')
	display.leader = Settings.leader and tostring('On') or tostring('Off')
	
	display:appendline('Aja: ${use_aja|0}')
	display.use_aja = Settings.use_aja and tostring('On') or tostring('Off')

	display:appendline('Send Target: ${sendTarget|0}')
	display.sendTarget = Settings.send_target and tostring('On') or tostring('Off')

	display:appendline('Send Messages: ${sendMessages|0}')
	display.sendMessages = Settings.send_messages and tostring('On') or tostring('Off')

	display:appendline('Use Messages: ${useMessages|0}')
	display.useMessages = Settings.use_messages and tostring('On') or tostring('Off')

	display:appendline('Use Helix: ${useHelix|0}')
	display.useHelix = UseHelix and tostring('On') or tostring('Off')

	display:appendline('Myrkr: ${myrkr|0}')
	display.myrkr = (Settings.useMyrkr and tostring('On') or tostring('Off')) ..tostring('\n\t TP: ')..tostring(Settings.myrkrTp)..tostring('MP: ')..tostring(Settings.myrkrMpPercent)

	display:appendline('Debuff: ${debuff|0}')
	display.debuff = Settings.debuff

	display:appendline('')
	display:appendline('Elements: ${elements}')
	display.elements = tostring(GetElementsString())

	if Settings.show_display == true then
		display:show()
	end
end

InitDisplay()

local hoveredButton = ''
function colorize(rowName, str)
    if rowName ~= hoveredButton then return str end
    return (str):text_color(0, 255, 0)
end

function UpdateDisplay()
	if Settings.enabled and BurstActive then
		display.addon_title = ("--- Houdini(Bursting) "):text_color(0,0,255)
	elseif Settings.enabled then
		display.addon_title = ("--- Houdini "):text_color(0,255,0)
	else
		display.addon_title = ("--- Houdini "):text_color(255,0,0)
	end

	display.enabled = colorize('enabled', Settings.enabled and tostring('On') or tostring('Off'))
	display.leader = colorize('leader', Settings.leader and tostring('On') or tostring('Off'))
	display.use_aja = colorize('use_aja', Settings.use_aja and tostring('On') or tostring('Off'))
	display.sendTarget = colorize('send_target', Settings.send_target and tostring('On') or tostring('Off'))
	display.sendMessages = colorize('send_messages', Settings.send_messages and tostring('On') or tostring('Off'))
	display.useMessages = colorize('use_messages',Settings.use_messages and tostring('On') or tostring('Off'))
	display.useHelix = colorize('helix', UseHelix and tostring('On') or tostring('Off'))
	display.myrkr = colorize('UseMyrkr', (Settings.useMyrkr and tostring('On') or tostring('Off')) ..tostring('\n\t TP: ')..tostring(Settings.myrkrTp)..tostring('MP: ')..tostring(Settings.myrkrMpPercent))
	display.debuff = Settings.debuff
	display.elements = tostring(GetElementsString())
end

function UpdateSkillchainElementFromReact(Element)
	local ElementToSCMap = {Water="Distortion", Blizzard="Distortion", Thunder="Fragmentation", Aero="Fragmentation"}
	local skillchain = ElementToSCMap[Element]
	local element = Element
	if Settings.elements[skillchain] ~= nil then
		if ElementSpellNames:contains(element) then
			Settings.elements[skillchain] = element
			--SaveSettings()
			--PrintStatus()
			if Settings.show_display then
				UpdateDisplay()
			end
		end
	end
end

-- Reaction table, auto-populated from sidecar files in reactions/
-- Each file in reactions/*.lua must `return` a table mapping name -> function(args),
-- e.g. `return { Degei = function(args) ... end, Aita = 'Degei' }` where a string
-- value aliases that name to another key defined anywhere in reactions/.
-- Reaction functions run with Houdini's globals in scope (CastNuke, CastAoE,
-- TitleCase, UpdateSkillchainElementFromReact, ElementToQuickDraw, ElementToStorm, etc).
local Reactions = T{}

local reactions_path = windower.addon_path..'reactions/'
function LoadReactions()
	Reactions = T{}
	local aliases = T{}

	for _, filename in pairs(windower.get_dir(reactions_path)) do
		if filename:sub(-4) == '.lua' then
			local success, result = pcall(dofile, reactions_path..filename)
			if success and type(result) == 'table' then
				for name, value in pairs(result) do
					if type(value) == 'function' then
						Reactions[name] = value
					elseif type(value) == 'string' then
						aliases[name] = value
					end
				end
			else
				atcf('Error loading reaction file %s: %s', filename, tostring(result))
			end
		end
	end

	for name, target in pairs(aliases) do
		if Reactions[target] ~= nil then
			Reactions[name] = Reactions[target]
		else
			atcf('Error: reaction alias %s points to unknown reaction %s', name, target)
		end
	end
end

LoadReactions()
-- end reactions

function MaybeUpdateElements(command, args)
	if #args <= 0 then
		return false
	end
	local Skillchain = ''
	if S{'dist', 'distortion'}:contains(command) then
		Skillchain = "Distortion"
	elseif S{'frag', 'fragmentation'}:contains(command) then
		Skillchain = 'Fragmentation'
	elseif command == 'light' then
		Skillchain = "Light"
	elseif S{'dark', "darkenss"}:contains(command) then
		Skllchain = "Darkness"
	end

	if Settings.elements[Skillchain] ~= nil then
		local element = TitleCase(args[1])
		if ElementSpellNames:contains(element) then
			Settings.elements[Skillchain] = element
			return true
		end
	end
	return false
end

windower.register_event('addon command', function (command,...)
	command = command and command:lower() or 'help'
	local args = T{...}
	local arg_str = windower.convert_auto_trans(' ':join(args))
	local argsLowerCase = T{}
	for i, str in ipairs(args) do
    	argsLowerCase[i] = str:lower()
	end

	if S{'reload','unload'}:contains(command) then
		windower.send_command('lua %s %s':format(command, _addon.name))
	elseif S{'enable','on','start'}:contains(command) then
		Settings.enabled = true
		PrintStatus()
	elseif S{'disable','off','stop'}:contains(command) then
		Settings.enabled = false
		PrintStatus()
	elseif command == 'toggle' then
		Settings.enabled = not Settings.enabled
		PrintStatus()
	elseif command == 'leader' then
		LeaderNotDoingSC = 0
		if #args == 1 then
			if args[1] == 'off' then
				Settings.leader = false
			elseif args[1] == '1' then
				LeaderNotDoingSC = 1
			end
		else
			Settings.leader = not Settings.leader
			if Settings.leader == true then
				windower.send_command('send @others houdini leader off')
			end
		end
		-- reset target ID so new leader will update it
		LastId = 0
		PrintStatus()
		SaveSettings()
	elseif command == 'element' and #args == 2 then
		local skillchain = TitleCase(argsLowerCase[1])
		local element = TitleCase(argsLowerCase[2])
		if Settings.elements[skillchain] ~= nil then
			if ElementSpellNames:contains(element) then
				Settings.elements[skillchain] = element
				SaveSettings()
				PrintStatus()
			end
		end
	elseif MaybeUpdateElements(command, argsLowerCase) then
		if Settings.leader then
			windower.send_command('send @others ho '..command..' '..arg_str)
			if Settings.send_messages then
				windower.send_command('input /p '..command..' '..arg_str)
			end
		end
		SaveSettings()
		PrintStatus()
	elseif command == 'status' then
		PrintStatus()
	elseif command == 'display' then
		Settings.show_display = not Settings.show_display
		if Settings.show_display == true then
			display:show()
		else
			display:hide()
		end
		SaveSettings()
	elseif S{'send_target', 'sendtarget', 'sendtar'}:contains(command) then
		Settings.send_target = not Settings.send_target
		SaveSettings()
		PrintStatus()
	elseif S{'send_messages', 'sendmessage', 'sendmsg'}:contains(command) then
		Settings.send_messages = not Settings.send_messages
		SaveSettings()
		PrintStatus()
	elseif S{'use_messages', 'usemessages', 'usemsg'}:contains(command) then
		Settings.use_messages = not Settings.use_messages
		PrintStatus()
		SaveSettings()
	elseif command == 'click' then
		Settings.enableClick = not Settings.enableClick
		SaveSettings()
		PrintStatus()
	elseif S{'shard_reporting', 'shards', 'shard'}:contains(command) then
		Settings.shard_reporting = not Settings.shard_reporting
		SaveSettings()
		PrintStatus()
	elseif S{'use_aja', 'useaja', 'aja'}:contains(command) then
		Settings.use_aja = not Settings.use_aja
		PrintStatus()
		SaveSettings()
	elseif command == 'pos' and #args == 2 then
		Settings.display.pos.x = args[1]
		Settings.display.pos.y = args[2]
		SaveSettings()
		windower.send_command('lua reload %s':format(_addon.name))
	elseif command == 'debuff' then
		Settings.debuff = args[1]
		SaveSettings()
	elseif command == 'dodebuff' then
		if Settings.debuff ~= '' then
			windower.send_command('input /ma "'..Settings.debuff..'" <t>')
		end
		if Settings.leader then
			windower.send_command('send @others ho dodebuff ')
			if Settings.send_messages then
				windower.send_command('input /p dodebuff')
			end
		end
	elseif command == 'nuke' and #args >= 1 then
		CastNuke(TitleCase(args[1]), args[2])
		if Settings.leader then
			windower.send_command('send @others ho nuke '..arg_str)
			if Settings.send_messages then
				windower.send_command('input /p nuke '..arg_str)
			end
		end
	elseif command == 'aoe' and #args >= 1 then
		CastAoE(TitleCase(args[1]))
		if Settings.leader then
			windower.send_command('send @others ho aoe '..arg_str)
			if Settings.send_messages then
				windower.send_command('input /p aoe '..arg_str)
			end
		end
	elseif command == 'burst' and #args >= 1 then
		local ignoreLeader = 0
		if args[2] ~= nil then
			ignoreLeader = tonumber(args[2])
		end
		StartBurst(TitleCase(args[1]), ignoreLeader + LeaderNotDoingSC)
		if Settings.leader then
			windower.send_command('send @others ho burst '..args[1])
			if Settings.send_messages then
				windower.send_command('input /p burst '..args[1])
			end
		end
	elseif command == 'cancelburst' then
		CancelBurst()
		if Settings.leader then
			windower.send_command('send @others ho cancelburst')
			if Settings.send_messages then
				windower.send_command('input /p cancelburst ')
			end
		end
	elseif command == 'enableburst' then
		windower.send_command('gs c activate Burst Mode')
		if Settings.leader then
			windower.send_command('send @others gs c activate Burst Mode')
			if Settings.send_messages then
				windower.send_command('input /p enableBurst ')
			end
		end
	elseif command == 'disableburst' then
		windower.send_command('gs c deactivate Burst Mode')
		if Settings.leader then
			windower.send_command('send @others gs c deactivate Burst Mode')
			if Settings.send_messages then
				windower.send_command('input /p disableBurst ')
			end
		end
	elseif command == 'myrkr' then
		if #args == 0 then
			Settings.useMyrkr = not Settings.useMyrkr
		else
			Settings.useMyrkr = true
			Settings.myrkrTp = tonumber(args[1])
			Settings.myrkrMpPercent = tonumber(args[2])
		end

		if Settings.useMyrkr then
			windower.send_command('gs c lock staff')
		else
			windower.send_command('gs c unlock staff')
		end

		PrintStatus()
		SaveSettings()
	elseif command == 'mpwarning' then
		Settings.mppWarning = tonumber(args[1])
		SaveSettings()
	elseif command == 'helix' then
		UseHelix = not UseHelix
	elseif command == 'addtell' then
		table.insert(Settings.tellsList, args[1])
		SaveSettings()
	elseif command == 'cleartells' then
		Settings.tellsList = T{}
		SaveSettings()
	elseif command == 'removetell' then
		for index, value in ipairs(Settings.tellsList) do
        	if value == args[1] then
				table.remove(Settings.tellsList, index)
				break
			end
    	end
		SaveSettings()
	elseif command == 'react' then
		if Reactions[TitleCase(argsLowerCase[1])] ~= nil then
			Reactions[TitleCase(argsLowerCase[1])](argsLowerCase)
			if Settings.leader then
				windower.send_command('send @others ho react '..arg_str)
				if Settings.send_messages then
					windower.send_command('input /p react '..arg_str)
				end
			end
		end
	elseif command == "aspir" then
		CastAspir()
		if Settings.leader then
			windower.send_command('send @others ho aspir')
			if Settings.send_messages then
					windower.send_command('input /p doaspir')
			end
		end
	elseif command == "potency" then
		if Settings.leader == false or LeaderNotDoingSC > 0 then
			TriggerPotency()
		end
		if Settings.leader == true then
			windower.send_command('send @others ho potency')
			if Settings.send_messages then
					windower.send_command('input /p potency+')
			end
		end
	elseif command == "meteor" then
		StartMeteor()
		if Settings.leader then
			windower.send_command('send @others ho meteor')
			if Settings.send_messages then
					windower.send_command('input /p someteor')
			end
		end
	elseif command == 'report' then
		StatusReport()
	elseif S{'help','--help'}:contains(command) then
		PrintHelp()
	else
		atc('Error: Unknown command '..arg_str)
	end
	
	if Settings.show_display then
		UpdateDisplay()
	end
	
end)

windower.register_event('chat message',function(message, player ,mode,isGM)
	if Settings.use_messages and Settings.enabled then
		local char = windower.ffxi.get_player()
		local str = string.match(message, "%w+")
		-- tell or party
		if mode == 3 or mode == 4 then
			local args = SplitString(message, ' ')
			if args[1] == 'nuke' and #args >= 2 then
				CastNuke(TitleCase(args[2]), args[3])
			elseif args[1] == 'burst' and #args == 2 then
				StartBurst(TitleCase(args[2]), LeaderNotDoingSC)
			elseif args[1] == 'cancelburst' then
				CancelBurst()
			elseif args[1] == 'enableBurst' then
				windower.send_command('gs c activate Burst Mode')
			elseif args[1] == 'disableBurst' then
				windower.send_command('gs c deactivate Burst Mode')
			elseif args[1] == 'aoe' and #args >= 2 then
				CastAoE(TitleCase(args[2]))
			elseif args[1] == 'target' and #args >= 2 then
				windower.send_command('sat target '..args[2])
				LastCheckTime = os.clock()
				SendLockOn = true
			elseif args[1] == 'react' then
				if Reactions[TitleCase(args[2])] ~= nil then
					Reactions[TitleCase(args[2])](SliceTable(args, 2, #args))		
				end
			elseif args[1] == 'element' then
				local skillchain = TitleCase(args[2])
				local element = TitleCase(args[3])
				if Settings.elements[skillchain] ~= nil then
					if ElementSpellNames:contains(element) then
						Settings.elements[skillchain] = element
						SaveSettings()
						PrintStatus()
					end
				end
			elseif MaybeUpdateElements(args[1], SliceTable(args, 2, #args)) then
				PrintStatus()
			elseif args[1] == 'potency+' then
				TriggerPotency()
			elseif args[1] == 'doaspir' then
				CastAspir()
			elseif args[1] == 'dometeor' then
				StartMeteor()
			elseif args[1] == 'report' then
				StatusReport()
			elseif args[1] == 'dodebuff' then
				if Settings.debuff ~= '' then
					windower.send_command('input /ma "'..Settings.debuff..'" <t>')
				end
			end

			if Settings.show_display then
				UpdateDisplay()
			end
		end
	end
end)

windower.register_event('load', function()
	if not _libs.lor then
		windower.add_to_chat(39,'ERROR: .../Windower/addons/libs/lor/ not found! Please download: https://github.com/lorand-ffxi/lor_libs')
	end
	atcc(262, 'Welcome to Houdini!')
	LastCheckTime = os.clock()
	LoadSettings()
	PrintStatus()
	InTown = IsInTown()
end)



function IsInTown()
    local info = windower.ffxi.get_info()
    local zone_id = info.zone
    local zone_name = res.zones[zone_id].name

    -- Check if the zone name matches any of the main cities
    return Town:contains(zone_name)
end

-- Ra'Kaznar Shard tracking
local RaKaznarShards = T{
	['Ra\'Kaznar Shard #A'] = false,
	['Ra\'Kaznar Shard #B'] = false,
	['Ra\'Kaznar Shard #C'] = false,
	['Ra\'Kaznar Shard #D'] = false,
}

function CheckRaKaznarShards()
	local items = windower.ffxi.get_items()
	local shards_found = T{}

	-- Check all bags for Ra'Kaznar Shards
	for bag_id, bag_name in pairs(bags) do
		local bag = items[bag_name]
		if bag and bag.enabled then
			for _, item in ipairs(bag) do
				if item.id ~= 0 then
					local item_name = res.items[item.id].name
					if RaKaznarShards:containskey(item_name) then
						shards_found[item_name] = true
					end
				end
			end
		end
	end

	-- Check temporary items
	if items.temporary then
		for _, item in ipairs(items.temporary) do
			if item.id ~= 0 then
				local item_name = res.items[item.id].name
				if RaKaznarShards:containskey(item_name) then
					shards_found[item_name] = true
				end
			end
		end
	end

	return shards_found
end

function ReportMissingShards(obtained_shard)
	local shards_found = CheckRaKaznarShards()
	local missing_shards = T{}

	-- Find which shards are missing
	for shard_name, _ in pairs(RaKaznarShards) do
		if not shards_found[shard_name] then
			-- Extract just the letter (A, B, C, or D)
			local letter = shard_name:match('Shard #([ABCD])')
			if letter then
				missing_shards:append(letter)
			end
		end
	end

	-- Report to party chat
	if #missing_shards > 0 then
		local msg = 'Ra\'Kaznar Shards still needed: ' .. missing_shards:concat(', ')
		windower.send_command('input /p ' .. msg)
	else
		windower.send_command('input /p All Ra\'Kaznar Shards obtained! Double Check yours to confirm!')
		windower.send_command('ho usemsg')
	end
end

windower.register_event('add item', function(bag, index, id, count)
	if not Settings.shard_reporting then return end
	if not res.items[id] then return end

	local item_name = res.items[id].name

	-- Check if this is a Ra'Kaznar Shard
	if RaKaznarShards:containskey(item_name) then
		ReportMissingShards(item_name)
	end
end)

windower.register_event('logout', function()
	windower.send_command('lua unload houdini')
end)


windower.register_event('zone change', function(new_id, old_id)
	LastCheckTime = os.clock() + 15
	InTown = IsInTown()
end)


windower.register_event('job change', function()
	--settings.enabled = false
end)


windower.register_event('prerender', function()
	if Settings.enabled and InTown == false then
		local now = os.clock()
		if (now - LastCheckTime) >= TimeDelay then
			local player = windower.ffxi.get_player()
			if Settings.leader and Settings.send_target then
				local mob = windower.ffxi.get_mob_by_target()
				if SendLockOn then
					windower.send_command('send @others /lockon')
					SendLockOn = false
				end

				local target = windower.ffxi.get_mob_by_target('t')
				if target ~= nil and LastId ~= target.id and target.id >= 0x01000000 then
					windower.send_command('sat youtarget @others')
					if Settings.send_messages and next(Settings.tellsList) ~= nil then
						for index, value in ipairs(Settings.tellsList) do
							windower.send_command('input /t '..value..' target '..tostring(target.id))
						end
					end
					SendLockOn = true
					LastId = target.id
				end
			elseif SendLockOn then
				windower.send_command('input /lockon')
				SendLockOn = false
			end

			if BurstActive and (now - BurstTime) >= BurstDelay then
				NextBurst()
				if Settings.show_display then
					UpdateDisplay()
				end
			end

			if ShouldCastMeteor and (now - MeteorTime) >= 1.0 then
				CastMeteor()
			end
			
			-- check for mrykr usage
			if player.status ~= 'Casting' then
				if not BurstActive and Settings.useMyrkr and player.vitals.tp >= Settings.myrkrTp and player.vitals.mpp <= Settings.myrkrMpPercent then
					local items = windower.ffxi.get_items()
					local i,bag = items.equipment.main, items.equipment.main_bag
					local skill = 'Hand-to-Hand'
					if i ~= 0 then  --0 => nothing equipped
						skill = res.skills[res.items[items[bags[bag]][i].id].skill].en
					end
					if skill == "Staff" then
						windower.send_command('input /ws Myrkr <me>')
					end
				end
			end

			-- check for mp warning
			if IsCastingJob(player.main_job) then
				if not SentMpWarning and player.vitals.mpp <= Settings.mppWarning and MpAboveWarning then
					windower.send_command('input /p MP Below '..tostring(Settings.mppWarning)..'%!!!!')
					SentMpWarning = true
					MpAboveWarning = false
				end

				if SentMpWarning then
					-- check if we're back above warning level to reset warning
					if player.vitals.mpp > Settings.mppWarning then
						SentMpWarning = false
						MpAboveWarning = true
					end
				end
			end

			LastCheckTime = now
		end
	end
end)


function PrintStatus()
	local enabled = Settings.enabled and 'ON' or 'OFF'
	local leader = Settings.leader and 'ON' or 'OFF'
	local sat = Settings.send_target and 'ON' or 'OFF'
	local message = Settings.send_messages and 'ON' or 'OFF'
	local listen = Settings.use_messages and 'ON' or 'OFF'
	local myrkryOn = Settings.useMyrkr and 'ON' or 'OFF'
	local shardReport = Settings.shard_reporting and 'ON' or 'OFF'
	atcf('Enabled %s, Leader %s send_target %s send_messages %s use_messages %s', enabled, leader, sat, message, listen)
	atcf('Myrkr: %s, TP: %s MP: %s', myrkryOn, tostring(Settings.myrkrTp), tostring(Settings.myrkrMpPercent))
	atcf('Shard Reporting: %s', shardReport)
end


function PrintHelp()
	local help = T{
		['[on|off|toggle] : '] = 'Enable / disable Houdini',
		['leader'] = 'toggles if this characters is sc leader',
		['send_target (sendtarget, sendtar)'] = 'toggles if leader send target to others',
		['send_messages (sendmessage, sendmsg)'] = 'toggles if leader should send party messages',
		['use_messages (usemessages, usemsg)'] = 'toggles if this character uses party/tell messages for commands',
		['use_aja (useaja, aja)'] = 'toggles if this character uses aja spells(for blm)',
		['mpWarning mpPercent'] = 'Sets MP percent to send warning at, set to 0 to disable',
		['enable/disableBurst'] = 'enables/disables burst mode in gearswap, sends to all characters if done on leader',
		['element skillchain Elementname '] = 'Set the element to cast for the provided skillchain',
		['dist/frag/light/dark Element'] = 'Shorthand to set element for Distortion/Fragmentation/Light/Darkness',
		['debuff SpellName'] = 'Sets the debuff spell to use with dodebuff command',
		['dodebuff'] = 'Casts the configured debuff spell on current target',
		['shard_reporting (shards, shard)'] = 'Toggle Ra\'Kaznar Shard tracking and party reporting',
		['nuke Element Tier(optional) '] = 'Casts the provided element and tier on current target',
		['burst SkillChainOrElement ignoreLeader(optional)'] = 'Starts a 3 hit MB(2 for leader unless ingoreLeader > 0) for the provided skillchain or element',
		['cancelburst'] = 'Stops the active burst it one is active',
		['aspir'] = 'Casts highest possible tier aspir on current target',
		['meteor'] = 'Triggers BLMs to use elemental seal, then start casting Meteor on current target',
		['potency'] = 'Triggers Ebullience on, if used on leader will be sent to others but not triggerd on leader',
		['aoe Element'] = 'Casts provided element -aga spell, starting with highest tier',
		['myrkr tp mp'] = 'Toggle myrkr usage on/off with no arguments, otherwise enables and sets tp usage and mp percent, will aslo send gs c lock/unlock staff so gs can lock main/sub slots',
		['status'] = 'prints current status',
		['display'] = 'toggles display'
	}
	--local mwwidth = max(unpack(map(string.wlen, table.keys(help))))
	local mwwidth = col_width(help:keys())
	atcc(262, 'Houdini commands:')
	for cmd,desc in opairs(help) do
		atc(cmd:rpad(' ', (mwwidth * 0.75)):colorize(263), desc:colorize(1))
	end
end

local buttons = {'enabled', 'leader', 'use_aja', 'send_target', 'send_messages', 'use_messages', 'helix', 'UseMyrkr'}
function mouse_event(type, x, y, delta, blocked)

	if not Settings.enableClick then
		return
	end

    if display:hover(x, y) and display:visible() then
        local lines = display:text():count('\n') + 1
        local _, _y = display:extents()
        local pos_y = y - Settings.display.pos.y
        local off_y = _y / lines
        local upper = 1
        local lower = off_y

        for row, button in ipairs(buttons) do
            if pos_y > upper and pos_y < lower then
				hoveredButton = button
                if type == 2 then
                    if button == helix then
						UseHelix = not UseHelix
                    else
                        Settings[button] = not Settings[button]
                    end
                    return true
                end
				UpdateDisplay()
            end
            upper = lower
            lower = lower + off_y
        end
    end
end

windower.register_event('mouse', mouse_event)
