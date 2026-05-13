// меняй линк свой
local DB_URL = "https://yourlink.firebasedatabase.app/radar.json"

local UPDATE_INTERVAL = 0.5 
local last_update = 0
local is_busy = false

local cached_mb_class = nil
local mb_was_alive = false
local next_mb_respawn = 600 -- 10 минут (600 сек) для первоначального спавна

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

-- Умная проверка статуса мидбосса
local function check_midboss_alive()
    if cached_mb_class and entity_list then
        local ents = entity_list.by_class_name(cached_mb_class)
        if ents and ents[1] then
            return ents[1]:is_alive()
        end
        return false
    end
    
    if entity_list then
        for _, ent in ipairs(entity_list.get_all()) do
            local cls = ent:get_class_name()
            if cls and string.find(cls:lower(), "midboss") then
                cached_mb_class = cls
                return ent:is_alive()
            end
        end
    end
    return false
end

callback.on_draw:set(function()
    if not ui_radar_enable:Get() then return end
    if not HERO_LIB.is_lp_valid then return end
    
    local current_time = global_vars.curtime()
    if (current_time - last_update < UPDATE_INTERVAL) or is_busy then return end
    last_update = current_time

    local lp = HERO_LIB.lp
    
    -- Получаем внутриигровое время, которое замирает во время пауз
    local gt = 0
    if game_rules and game_rules.game_time then
        gt = game_rules.game_time()
    else
        gt = current_time
    end

    local is_midboss_alive = check_midboss_alive()

    -- Логика таймера
    if is_midboss_alive then
        mb_was_alive = true
        next_mb_respawn = 0
    else
        if mb_was_alive then
            -- Босса только что убили
            mb_was_alive = false
            next_mb_respawn = gt + 420 -- 7 минут (420 сек) от текущего времени
        end
    end

    -- Страховка для старта матча (пока босс еще ни разу не появлялся)
    if gt < 600 and not is_midboss_alive and not mb_was_alive then
        next_mb_respawn = 600
    end

    -- Считаем оставшееся время
    local rem = next_mb_respawn - gt
    if rem < 0 then rem = 0 end

    local radar_payload = {
        ["local"] = get_hero_data(lp),
        allies = {},
        enemies = {},
        sent_at = os.time(),
        is_sapphire = (lp.m_iTeamNum == Enum.TeamNum.TEAM_DIRE),
        mb = {
            a = is_midboss_alive,
            rem = math.floor(rem) -- Отправляем точное количество оставшихся секунд
        }
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
