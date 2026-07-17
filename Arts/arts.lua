_addon.name = 'Arts'
_addon.author = 'EvilPotat0'
_addon.commands = {'arts', 'ar'}
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

local Enabled = false
local TargetArts = "Light"
local LastTime = 0.0
local TimeDelay = 1.0

---------------------------------------------------------------------------------------------------------------------
-- Returns the remaining time in seconds for a buff on the player
-- @param buff_name string The name of the buff to check (e.g., "Light Arts", "Haste", "Protect")
-- @return number Returns remaining time in seconds if buff is active, 0 if not active
function GetBuffRemainingTime(buff_name)
	-- Get the player's current buffs
	local player = windower.ffxi.get_player()
	if not player then
		return 0
	end

	-- Check if player has this buff active
	local has_buff = false
	for _, active_buff_id in ipairs(player.buffs) do
		if res.buffs[active_buff_id].en == buff_name then
			has_buff = true
			break
		end
	end

	if not has_buff then
		return 0
	end

	-- Get the buff packet data (0x063) to find duration
	local data = windower.packets.last_incoming(0x063)
	if not data or data:byte(0x05) ~= 0x09 then
		-- No buff packet data available, but we know the buff is active
		-- Return -1 to indicate buff is active but duration unknown
		return -1
	end

	-- Parse buff data from packet
	for i = 1, 32 do
		local packet_buff_id = data:unpack('H', i * 2 + 7)
		if packet_buff_id == buff_id then
			-- Found our buff, get the timestamp
			local timestamp = data:unpack('I', i * 4 + 0x45) / 60 + 501079520 + 1009810800
			local remaining = timestamp - os.time()
            local result =  math.max(0, remaining)
			return result
		end
	end

	-- Buff is active but not found in packet (shouldn't happen)
	return -1
end


windower.register_event('logout', function()
	windower.send_command('lua unload arts')
end)


windower.register_event('zone change', function(new_id, old_id)
	LastTime = os.clock() + 15
end)


windower.register_event('job change', function()
	Enabled = false
end)

function PrintStatus()
	local enabled = Enabled and 'ON' or 'OFF'
	atcf('Enabled %s, Mode: %s', enabled, TargetArts)
end

function PrintHelp()
	local help = T{
		['[on|off] : '] = 'Enable / disable Arts',
		['Light'] = 'Sets target arts/addendum to light/white',
		['Dark'] = 'Sets target arts/addendum to dark/black',
	}
	--local mwwidth = max(unpack(map(string.wlen, table.keys(help))))
	local mwwidth = col_width(help:keys())
	atcc(262, 'Arts commands:')
	for cmd,desc in opairs(help) do
		atc(cmd:rpad(' ', (mwwidth * 0.75)):colorize(263), desc:colorize(1))
	end
end

windower.register_event('addon command', function (command,...)
	command = command and command:lower() or 'help'
	local args = T{...}
	local arg_str = windower.convert_auto_trans(' ':join(args))

    if command == 'on' then
        Enabled = true
        PrintStatus()
    elseif command == 'off' then
        Enabled = false
        PrintStatus()
    elseif S{'Light','light'}:contains(command) then
        TargetArts = 'Light'
        PrintStatus()
    elseif S{'Dark','dark'}:contains(command) then
        TargetArts = 'Dark'
        PrintStatus()
	else
		PrintHelp()
	end

end)


windower.register_event('prerender', function()
    if Enabled then
		local now = os.clock()
		if (now - LastTime) >= TimeDelay then
            local player = windower.ffxi.get_player()
            if player.main_job == "SCH" or player.sub_job == "SCH" then
                local ArtsName = "Light Arts"
                local AddendumName = "Addendum: White"
                if TargetArts == 'Dark' then
                    ArtsName = "Dark Arts"
                    AddendumName = "Addendum: Black"
                end

                if GetBuffRemainingTime(ArtsName) == 0 then
                    if GetBuffRemainingTime(AddendumName) == 0 then
                        -- addendum overwrites arts buff, so if no addendum as well, need arts
                        windower.send_command('input /ja "'..ArtsName..'" <me>')
                    end
                elseif GetBuffRemainingTime(AddendumName) == 0 then
                    windower.send_command('input /ja "'..AddendumName..'" <me>')
                end
            end

            LastTime = now
        end
    end
end)