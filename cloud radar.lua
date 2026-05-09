local DB_URL = "https://yourlink.firebasedatabase.app/radar.json"

local UPDATE_INTERVAL = 0.5 
local last_update = 0
local is_busy = false

local menu_parent = Menu.Create("Miscellaneous", "Utility", "Cloud Radar", "Skeet Visuals", "Cloud Radar")
local ui_radar_enable = menu_parent:Switch("Enable Radar", true)

local function get_hero_data(hero_obj)
    local pos = hero_obj:get_origin()
    if not pos then return nil end
    local map_p = utils.world_to_map(pos)
    
    return {
        x = map_p.x,
        y = map_p.y,
        id = HERO_LIB.get_hero_id(hero_obj) or 0
    }
end

callback.on_draw:set(function()
    if not ui_radar_enable:Get() then return end
    if not HERO_LIB.is_lp_valid then return end
    
    local current_time = global_vars.curtime()
    if (current_time - last_update < UPDATE_INTERVAL) or is_busy then return end
    last_update = current_time

    local lp = HERO_LIB.lp
    local radar_payload = {
        ["local"] = get_hero_data(lp),
        allies = {},
        enemies = {},
        sent_at = os.time()
    }

    local allies = HERO_LIB.get_all_heroes(lp, false, true, false, true)
    for _, ally in ipairs(allies) do
        local data = get_hero_data(ally)
        if data then table.insert(radar_payload.allies, data) end
    end

    local enemies = HERO_LIB.get_all_heroes(lp, false, false, true, true)
    for _, enemy in ipairs(enemies) do
        local data = get_hero_data(enemy)
        if data then table.insert(radar_payload.enemies, data) end
    end

    is_busy = true
    http.request(DB_URL)
        :post()
        :header("X-HTTP-Method-Override", "PUT")
        :json(radar_payload)
        :send(function(status, body, success) 
            is_busy = false 
        end)
end)