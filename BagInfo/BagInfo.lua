--[[
BagInfo - Inventory Space & Currency Display
Shows current/max item counts for various inventory bags and currency amounts

Commands:
    //bag toggle <bag>      - Toggle bag display on/off
    //bag currency <name>   - Toggle currency display on/off
    //bag all               - Show all bags
    //bag allcurrency       - Show all currencies
    //bag none              - Hide all bags except inventory
    //bag nocurrency        - Hide all currencies
    //bag pos <x> <y>       - Set display position
    //bag help              - Show help

Author: EvilPotat0 + Claude Code
Version: 2.0.0
]]

_addon.name = 'BagInfo'
_addon.author = 'EvilPotat0 + Claude Code'
_addon.version = '2.0.0'
_addon.commands = {'bag', 'baginfo'}

require('logger')
local config = require('config')
local texts = require('texts')
local packets = require('packets')

-- Default settings
local defaults = {
    pos = {x = 0, y = 500},
    show_bags = {
        inventory = true,
        safe = false,
        storage = false,
        temporary = false,
        locker = false,
        satchel = false,
        sack = false,
        case = false,
        wardrobe = false,
        wardrobe2 = false,
        wardrobe3 = false,
        wardrobe4 = false,
        wardrobe5 = false,
        wardrobe6 = false,
        wardrobe7 = false,
        wardrobe8 = false,
    },
    show_currencies = {
        gil = false,
        bayld = false,
        sparks = false,
        unity_accolades = false,
        hallmarks = false,
        gallantry = false,
        capacity_points = false,
        login_points = false,
        conquest_points = false,
        imperial_standing = false,
        allied_notes = false,
        cruor = false,
        resistance_credits = false,
        dominion_notes = false,
        coalition_imprimaturs = false,
        plasm = false,
        escha_silt = false,
        escha_beads = false,
    }
}

-- Load settings
local settings = config.load(defaults)

-- Bag ID mapping
local bag_ids = {
    inventory = 0,
    safe = 1,
    storage = 2,
    temporary = 3,
    locker = 4,
    satchel = 5,
    sack = 6,
    case = 7,
    wardrobe = 8,
    wardrobe2 = 10,
    wardrobe3 = 11,
    wardrobe4 = 12,
    wardrobe5 = 13,
    wardrobe6 = 14,
    wardrobe7 = 15,
    wardrobe8 = 16,
}

-- Display names for bags
local bag_names = {
    inventory = 'Inventory',
    safe = 'Safe',
    storage = 'Storage',
    temporary = 'Temporary',
    locker = 'Locker',
    satchel = 'Satchel',
    sack = 'Sack',
    case = 'Case',
    wardrobe = 'Wardrobe',
    wardrobe2 = 'Wardrobe 2',
    wardrobe3 = 'Wardrobe 3',
    wardrobe4 = 'Wardrobe 4',
    wardrobe5 = 'Wardrobe 5',
    wardrobe6 = 'Wardrobe 6',
    wardrobe7 = 'Wardrobe 7',
    wardrobe8 = 'Wardrobe 8',
}

-- Currency key mapping (packet field names)
local currency_keys = {
    gil = 'gil',
    bayld = 'bayld',
    sparks = 'spark',
    unity_accolades = 'unity_accolades',
    hallmarks = 'hallmarks',
    gallantry = 'gallantry',
    capacity_points = 'capacity_points',
    login_points = 'login_points',
    conquest_points = 'conquest_points',
    imperial_standing = 'imperial_standing',
    allied_notes = 'allied_notes',
    cruor = 'cruor',
    resistance_credits = 'resistance_credits',
    dominion_notes = 'dominion_notes',
    coalition_imprimaturs = 'coalition_imprimaturs',
    plasm = 'mweya_plasm',
    escha_silt = 'escha_silt',
    escha_beads = 'escha_beads',
}

-- Display names for currencies
local currency_names = {
    gil = 'Gil',
    bayld = 'Bayld',
    sparks = 'Sparks',
    unity_accolades = 'Unity Accolades',
    hallmarks = 'Hallmarks',
    gallantry = 'Gallantry',
    capacity_points = 'Capacity Points',
    login_points = 'Login Points',
    conquest_points = 'Conquest Points',
    imperial_standing = 'Imperial Standing',
    allied_notes = 'Allied Notes',
    cruor = 'Cruor',
    resistance_credits = 'Resistance Credits',
    dominion_notes = 'Dominion Notes',
    coalition_imprimaturs = 'Coalition Imprimaturs',
    plasm = 'Mweya Plasm',
    escha_silt = 'Escha Silt',
    escha_beads = 'Escha Beads',
}

-- Currency display order
local currency_order = {
    'gil', 'bayld', 'sparks', 'unity_accolades',
    'hallmarks', 'gallantry', 'capacity_points', 'login_points',
    'conquest_points', 'imperial_standing', 'allied_notes',
    'cruor', 'resistance_credits', 'dominion_notes',
    'coalition_imprimaturs', 'plasm', 'escha_silt', 'escha_beads',
}

-- Currency values storage (populated from network packets)
-- Packet 0x113 (Currency Info I): sparks, imperial_standing, conquest_points, allied_notes, cruor, resistance_credits, dominion_notes
-- Packet 0x118 (Currency Info II): bayld, coalition_imprimaturs, plasm, escha_beads, escha_silt, hallmarks, gallantry
-- Packet 0x061 (Character Info): unity_accolades
-- Packet 0x063 (Character Stats): capacity_points
-- Gil: Available directly from windower.ffxi.get_items()
-- Note: login_points not yet implemented (packet source unknown)
local currency_values = {
    gil = 0,
    bayld = 0,
    sparks = 0,
    unity_accolades = 0,
    hallmarks = 0,
    gallantry = 0,
    capacity_points = 0,
    login_points = 0,
    conquest_points = 0,
    imperial_standing = 0,
    allied_notes = 0,
    cruor = 0,
    resistance_credits = 0,
    dominion_notes = 0,
    coalition_imprimaturs = 0,
    plasm = 0,
    escha_silt = 0,
    escha_beads = 0,
}

-- On-screen display
local display = texts.new('${content}', {
    pos = {x = settings.pos.x, y = settings.pos.y},
    bg = {alpha = 200, red = 0, green = 0, blue = 0},
    flags = {right = false, bold = true, draggable = true},
    text = {size = 10, font = 'Consolas', alpha = 255, red = 255, green = 255, blue = 255}
})

-- Get bag info
local function get_bag_info(bag_name)
    local bag_id = bag_ids[bag_name]
    if not bag_id then return nil end

    local bag = windower.ffxi.get_bag_info(bag_id)
    if not bag then return nil end

    return {
        count = bag.count,
        max = bag.max,
        enabled = bag.enabled
    }
end

-- Get currency info
local function get_currency_info(currency_name)
    -- Return from currency_values table (populated by packet handlers)
    if currency_name == 'gil' then
        -- Gil is available directly from items
        local items = windower.ffxi.get_items()
        if items and items.gil then
            return items.gil
        end
    end

    return currency_values[currency_name]
end

-- Format number with commas
local function format_number(num)
    if not num then return '0' end
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Update display
local function update_display()
    local lines = {}

    -- Display bags horizontally
    local bag_order = {
        'inventory',
        'satchel', 'sack', 'case',
        'wardrobe', 'wardrobe2', 'wardrobe3', 'wardrobe4',
        'wardrobe5', 'wardrobe6', 'wardrobe7', 'wardrobe8',
        'safe', 'storage', 'locker', 'temporary'
    }

    local bag_parts = {}
    for _, bag_name in ipairs(bag_order) do
        if settings.show_bags[bag_name] then
            local info = get_bag_info(bag_name)
            if info and info.enabled then
                local display_name = bag_names[bag_name]
                local color_code

                -- Color code based on fullness
                local percent = (info.count / info.max) * 100
                if percent >= 90 then
                    color_code = '\\cs(255,100,100)' -- Red
                elseif percent >= 75 then
                    color_code = '\\cs(255,200,100)' -- Orange
                else
                    color_code = '\\cs(200,255,200)' -- Green
                end

                table.insert(bag_parts, string.format('%s%s: %d/%d\\cr',
                    color_code, display_name, info.count, info.max))
            end
        end
    end

    -- Display currencies horizontally
    local currency_parts = {}
    for _, currency_name in ipairs(currency_order) do
        if settings.show_currencies[currency_name] then
            local amount = get_currency_info(currency_name)
            if amount then
                local display_name = currency_names[currency_name]
                local formatted_amount = format_number(amount)
                table.insert(currency_parts, string.format('\\cs(255,255,150)%s: %s\\cr',
                    display_name, formatted_amount))
            end
        end
    end

    local all_parts = {}
    for _, p in ipairs(bag_parts) do table.insert(all_parts, p) end
    if #bag_parts > 0 and #currency_parts > 0 then
        table.insert(all_parts, '\\cs(100,100,100)|\\cr')
    end
    for _, p in ipairs(currency_parts) do table.insert(all_parts, p) end

    if #all_parts > 0 then
        table.insert(lines, table.concat(all_parts, '  '))
    else
        table.insert(lines, 'No bags/currencies enabled')
    end

    display.content = table.concat(lines, '\n')
    display:show()
end

-- Save settings
local function save_settings()
    settings:save('all')
end

-- Show help
local function show_help()
    log('=== BagInfo Help ===')
    log('//bag toggle <bag>      - Toggle bag display')
    log('//bag currency <name>   - Toggle currency display')
    log('//bag all               - Show all available bags')
    log('//bag allcurrency       - Show all currencies')
    log('//bag none              - Hide all bags except inventory')
    log('//bag nocurrency        - Hide all currencies')
    log('//bag pos <x> <y>       - Set display position')
    log('//bag status            - Show current settings')
    log('//bag debug             - Debug currency data')
    log('//bag help              - Show this help')
    log('')
    log('Available bags:')
    log('  inventory, safe, storage, temporary, locker')
    log('  satchel, sack, case, wardrobe, wardrobe2-8')
    log('')
    log('Available currencies:')
    log('  gil, bayld, sparks, unity_accolades, hallmarks, gallantry')
    log('  capacity_points, login_points, conquest_points, imperial_standing')
    log('  allied_notes, cruor, resistance_credits, dominion_notes')
    log('  coalition_imprimaturs, plasm, escha_silt, escha_beads')
    log('')
    log('Examples:')
    log('  //bag toggle satchel')
    log('  //bag currency gil')
    log('  //bag currency bayld')
end

-- Show current settings
local function show_status()
    log('=== BagInfo Status ===')
    log('Visible bags:')
    local any_bags = false
    for bag_name, visible in pairs(settings.show_bags) do
        if visible then
            local info = get_bag_info(bag_name)
            if info and info.enabled then
                log('  %s: %d/%d', bag_names[bag_name], info.count, info.max)
                any_bags = true
            end
        end
    end
    if not any_bags then
        log('  (none)')
    end

    log('')
    log('Visible currencies:')
    local any_currencies = false
    for currency_name, visible in pairs(settings.show_currencies) do
        if visible then
            local amount = get_currency_info(currency_name)
            if amount then
                log('  %s: %s', currency_names[currency_name], format_number(amount))
                any_currencies = true
            end
        end
    end
    if not any_currencies then
        log('  (none)')
    end
end

-- Debug: Show all available currency data
local function debug_currencies()
    local player = windower.ffxi.get_player()
    local info = windower.ffxi.get_info()
    local items = windower.ffxi.get_items()

    local debug_path = windower.addon_path .. 'currency_debug.txt'
    local debug_file = io.open(debug_path, 'w')

    if not debug_file then
        log('Error: Could not create debug file')
        return
    end

    debug_file:write('=== Currency Debug ===\n\n')

    -- Check player object
    if player then
        debug_file:write('Player object exists\n')
        debug_file:write('Player keys:\n')
        local player_keys = {}
        for key, _ in pairs(player) do
            table.insert(player_keys, key)
        end
        table.sort(player_keys)
        for _, key in ipairs(player_keys) do
            debug_file:write(string.format('  %s = %s\n', key, tostring(player[key])))
        end
    else
        debug_file:write('player object is nil\n')
    end

    debug_file:write('\n--- Info Object ---\n')
    if info then
        debug_file:write('Info keys:\n')
        local info_keys = {}
        for key, _ in pairs(info) do
            table.insert(info_keys, key)
        end
        table.sort(info_keys)
        for _, key in ipairs(info_keys) do
            debug_file:write(string.format('  %s = %s\n', key, tostring(info[key])))
        end
    else
        debug_file:write('info object is nil\n')
    end

    debug_file:write('\n--- Items Object ---\n')
    if items then
        debug_file:write('All items keys (non-table values):\n')
        local items_keys = {}
        for key, value in pairs(items) do
            if type(value) ~= 'table' then
                table.insert(items_keys, key)
            end
        end
        table.sort(items_keys)
        for _, key in ipairs(items_keys) do
            local value = items[key]
            debug_file:write(string.format('  %s = %s\n', key, tostring(value)))
        end

        debug_file:write('\nTable keys (bags):\n')
        for key, value in pairs(items) do
            if type(value) == 'table' then
                debug_file:write(string.format('  %s = <table>\n', key))
            end
        end
    else
        debug_file:write('items object is nil\n')
    end

    debug_file:close()
    log('Currency debug written to: %s', debug_path)
end

-- Command handler
windower.register_event('addon command', function(command, ...)
    local args = {...}
    command = command and command:lower()

    if not command or command == 'help' or command == 'h' then
        show_help()

    elseif command == 'status' or command == 's' then
        show_status()

    elseif command == 'toggle' or command == 't' then
        if #args == 0 then
            error('Specify a bag name to toggle')
            return
        end

        local bag_name = args[1]:lower()

        if not bag_ids[bag_name] then
            error('Unknown bag: ' .. bag_name)
            log('Valid bags: inventory, satchel, sack, case, wardrobe, wardrobe2-8, safe, storage, locker, temporary')
            return
        end

        settings.show_bags[bag_name] = not settings.show_bags[bag_name]
        log('%s display: %s', bag_names[bag_name], settings.show_bags[bag_name] and 'ON' or 'OFF')
        save_settings()
        update_display()

    elseif command == 'currency' or command == 'c' then
        if #args == 0 then
            error('Specify a currency name to toggle')
            return
        end

        local currency_name = args[1]:lower()

        if not currency_keys[currency_name] then
            error('Unknown currency: ' .. currency_name)
            log('Valid currencies: gil, bayld, sparks, unity_accolades, hallmarks, gallantry,')
            log('  capacity_points, login_points, conquest_points, imperial_standing,')
            log('  allied_notes, cruor, resistance_credits, dominion_notes,')
            log('  coalition_imprimaturs, plasm, escha_silt, escha_beads')
            return
        end

        settings.show_currencies[currency_name] = not settings.show_currencies[currency_name]
        log('%s display: %s', currency_names[currency_name], settings.show_currencies[currency_name] and 'ON' or 'OFF')
        save_settings()
        update_display()

    elseif command == 'all' then
        for bag_name, _ in pairs(bag_ids) do
            local info = get_bag_info(bag_name)
            if info and info.enabled then
                settings.show_bags[bag_name] = true
            end
        end
        log('Showing all available bags')
        save_settings()
        update_display()

    elseif command == 'allcurrency' then
        for currency_name, _ in pairs(currency_keys) do
            settings.show_currencies[currency_name] = true
        end
        log('Showing all currencies')
        save_settings()
        update_display()

    elseif command == 'none' then
        for bag_name, _ in pairs(settings.show_bags) do
            settings.show_bags[bag_name] = false
        end
        settings.show_bags.inventory = true
        log('Showing only inventory')
        save_settings()
        update_display()

    elseif command == 'nocurrency' then
        for currency_name, _ in pairs(settings.show_currencies) do
            settings.show_currencies[currency_name] = false
        end
        log('Hiding all currencies')
        save_settings()
        update_display()

    elseif command == 'pos' or command == 'position' then
        if #args < 2 then
            error('Usage: //bag pos <x> <y>')
            return
        end

        local x = tonumber(args[1])
        local y = tonumber(args[2])

        if not x or not y then
            error('Invalid position values')
            return
        end

        settings.pos.x = x
        settings.pos.y = y
        display:pos(x, y)
        save_settings()
        log('Display position set to (%d, %d)', x, y)

    elseif command == 'debug' then
        debug_currencies()

    else
        error('Unknown command: ' .. command)
        show_help()
    end
end)

-- Initialize
windower.register_event('load', function()
    log('BagInfo v2.0.0 loaded!')
    log('Currencies will populate when you open menus or zone.')
    log('Tip: Open Currency menu (Key Items > Currency) to trigger currency updates.')
    update_display()
end)

-- Zone change event - currencies get updated when zoning
windower.register_event('zone change', function()
    -- Currency packets are sent after zoning, display will auto-update
end)

-- Update on item changes
windower.register_event('add item', function()
    update_display()
end)

windower.register_event('remove item', function()
    update_display()
end)

-- Periodic update (every 5 seconds)
windower.register_event('time change', function()
    update_display()
end)

-- Packet handler for currency updates
windower.register_event('incoming chunk', function(id, data)
    local success, packet = pcall(packets.parse, 'incoming', data)
    if not success then return end

    -- Packet 0x113: Currency Info (Currencies I)
    if id == 0x113 then
        -- Sparks of Eminence
        if packet['Sparks of Eminence'] then
            currency_values.sparks = packet['Sparks of Eminence']
        end

        -- Imperial Standing
        if packet['Imperial Standing'] then
            currency_values.imperial_standing = packet['Imperial Standing']
        end

        -- Conquest Points (using San d'Oria as default, could also check Bastok/Windurst)
        if packet['Conquest Points (San d\'Oria)'] then
            currency_values.conquest_points = packet['Conquest Points (San d\'Oria)']
        end

        -- Allied Notes
        if packet['Allied Notes'] then
            currency_values.allied_notes = packet['Allied Notes']
        end

        -- Cruor (Abyssea)
        if packet['Cruor'] then
            currency_values.cruor = packet['Cruor']
        end

        -- Resistance Credits
        if packet['Resistance Credits'] then
            currency_values.resistance_credits = packet['Resistance Credits']
        end

        -- Dominion Notes
        if packet['Dominion Notes'] then
            currency_values.dominion_notes = packet['Dominion Notes']
        end

        update_display()

    -- Packet 0x118: Currency Info (Currencies 2)
    elseif id == 0x118 then
        -- Bayld
        if packet['Bayld'] then
            currency_values.bayld = packet['Bayld']
        end

        -- Coalition Imprimaturs
        if packet['Coalition Imprimaturs'] then
            currency_values.coalition_imprimaturs = packet['Coalition Imprimaturs']
        end

        -- Mweya Plasm Corpuscles
        if packet['Mweya Plasm Corpuscles'] then
            currency_values.plasm = packet['Mweya Plasm Corpuscles']
        end

        -- Escha Beads
        if packet['Escha Beads'] then
            currency_values.escha_beads = packet['Escha Beads']
        end

        -- Escha Silt
        if packet['Escha Silt'] then
            currency_values.escha_silt = packet['Escha Silt']
        end

        -- Hallmarks
        if packet['Hallmarks'] then
            currency_values.hallmarks = packet['Hallmarks']
        end

        -- Badges of Gallantry
        if packet['Badges of Gallantry'] then
            currency_values.gallantry = packet['Badges of Gallantry']
        end

        -- Domain Points (Note: different from Dominion Notes)
        -- Keeping this mapped to dominion_notes for now as user requested "domain points"
        if packet['Domain Points'] then
            currency_values.dominion_notes = packet['Domain Points']
        end

        update_display()

    -- Packet 0x061: Character Info (includes Unity Accolades)
    elseif id == 0x061 then
        -- Unity Points (Unity Accolades)
        if packet['Unity Points'] then
            currency_values.unity_accolades = packet['Unity Points']
        end

        update_display()

    -- Packet 0x063: Character Stats (includes Capacity Points)
    elseif id == 0x063 then
        -- This packet has multiple subtypes, we need Order 5 for Job Points
        if packet['Order'] == 5 then
            -- Capacity Points are in job-specific fields
            local player = windower.ffxi.get_player()
            if player and player.main_job_full then
                local job = player.main_job_full
                local cp_key = job .. ' Capacity Points'
                if packet[cp_key] then
                    currency_values.capacity_points = packet[cp_key]
                    update_display()
                end
            end
        end
    end
end)

-- Hide on unload
windower.register_event('unload', function()
    display:hide()
end)
