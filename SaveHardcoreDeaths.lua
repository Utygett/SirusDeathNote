-- Глобальная переменная, которую мы будем сохранять
MySavedVariable = MySavedVariable or {}

DeathListSaved = DeathListSaved or {}   





-- Создание функции для отображения сообщения
function ShowDeathMessage(textMessage)
    -- Создаем фрейм для отображения текста
    local deathMessageFrame = CreateFrame("Frame", nil, UIParent)
    deathMessageFrame:SetSize(300, 50) -- Ширина и высота фрейма
    deathMessageFrame:SetPoint("CENTER", UIParent, "CENTER") -- Позиция по центру экрана

    -- Устанавливаем фон через текстуру
    deathMessageFrame.texture = deathMessageFrame:CreateTexture(nil, "BACKGROUND")
    deathMessageFrame.texture:SetTexture(0, 0, 0, 0.5) -- Полупрозрачный черный фон
    deathMessageFrame.texture:SetAllPoints(deathMessageFrame) -- Занимаем всю площадь фрейма

    -- Добавляем текстовое поле
    deathMessageFrame.text = deathMessageFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    deathMessageFrame.text:SetPoint("CENTER", deathMessageFrame, "CENTER")
    deathMessageFrame.text:SetText(textMessage) -- Формат текста

    -- Таймер для скрытия фрейма через 3 секунды
    local elapsed = 0
    deathMessageFrame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= 10 then
            self:Hide()
            self:SetScript("OnUpdate", nil) -- Отключаем обработчик OnUpdate
        end
    end)
end







-- local classColor ={
--     ["Hunter"] = { r = 0.67, g = 0.83, b = 0.45, a=1 },
--     ["Warlock"] = { r = 0.58, g = 0.51, b = 0.79, a=1 },
--     ["Priest"] = { r = 1.0, g = 1.0, b = 1.0, a=1 },
--     ["Paladin"] = { r = 0.96, g = 0.55, b = 0.73, a=1 },
--     ["Mage"] = { r = 0.41, g = 0.8, b = 0.94, a=1 },
--     ["Rogue"] = { r = 1.0, g = 0.96, b = 0.41, a=1 },
--     ["Druid"] = { r = 1.0, g = 0.49, b = 0.04, a=1 },
--     ["Shaman"] = { r = 0.14, g = 0.35, b = 1.0, a=1 },
--     ["Warrior"] = { r = 0.78, g = 0.61, b = 0.43, a=1 },
--     ["DeathKnight"] = { r = 0.77, g = 0.12, b = 0.23, a=1 },
--     ["Evoker"] = { r = 0.7, g = 0.1, b = 0.1, a=1 },
--     ["DemonHunter"] = { r = 0.63, g = 0.58, b = 0.24, a=1 }
-- }


-- Таблица для хранения объектов событий
local deathList = {}
local parsedDeathList = {}
-- Загрузка данных
local function LoadSavedEvents()
        for key, record in pairs(DeathListSaved) do
            local parsedDeath = Death:ParseHardcoreDeath(record)
            if parsedDeath.name == nil then
                DeathListSaved[key] = nil;
            else
                table.insert(parsedDeathList, parsedDeath)
            end
        end
        print("Сохранённые события загружены!")

end

-- Сохранение данных
local function SaveEvents()
    MySavedVariable = {}
    for _, event in ipairs(deathList) do
        local deathSerealize = SerializeRecord(event)
        -- print("-------------------Serealized death:", deathSerealize)
        AddToMap(DeathListSaved, deathSerealize);
    end
    print("События сохранены!")
end




-- local function SendSendAllRecordsToSender(targetPlayer)
--     for _, record in ipairs(deathList) do
--         local serialized = SerializeRecord(record)
--         SendMessageToPlayerOnSameServer("MyAddon", serialized, "WHISPER", targetPlayer)
--     end
-- end

-- local function AddRecordToMyList(record)
--     print("AddRecordToMyList: ", record)
--     local death =  Death:ParseHardcoreDeath(record)
-- end


-- Обработчик событий
-- deathEventFrame:

-- Инициализация таблицы

FrameUi = UiMainFramne:new(parsedDeathList)
-- Фрейм для обработки событий
-- local deathEventFrame = CreateFrame("Frame")

-- Событие, которое срабатывает при входе в игру
FrameUi.frame:RegisterEvent("PLAYER_LOGIN")
FrameUi.frame:RegisterEvent("PLAYER_LOGOUT")
FrameUi.frame:RegisterEvent("CHAT_MSG_ADDON")

FrameUi.frame:SetScript("OnEvent", function(_, event, prefix, message)
    if event == "PLAYER_LOGIN" then
        print("Аддон SaveHardcoreDeaths загружен! Используйте команды: /shd show")
        LoadSavedEvents()
        FrameUi.InitSettings(FrameUi)
        -- Пример использования функции
        -- FrameUi.frame:Show();
        -- print("Check UserSettings.dateTimeForSynch: ", UserSettings.dateTimeForSynch)
        
        -- print("Check UserSettings.SyncWithGuild: ", UserSettings.SyncWithGuild)
        -- print("Check UserSettings.SyncWithFriends: ", UserSettings.SyncWithFriends)
        -- Регистрируем префикс
        -- RegisterPrefix("MyAddon")
        -- Пример использования
        -- SendMessageToPlayerOnSameServer("MyAddon", "Hello!", "WHISPER", "Ещёпятьминут")
        -- SendMessageToPlayerOnSameServer("MyAddon", "GET_ALL_DEATH_RECORDS@Нумампожал", "WHISPER", "Ещёпятьминут")
    elseif event == "PLAYER_LOGOUT" then
        SaveEvents()
    elseif event == "CHAT_MSG_ADDON" and prefix == "ASMSG_HARDCORE_DEATH" then
        -- print("--------CHAT_MSG_ADDON: ", message)
        local death, parsedDeath = Death:new(message, date("%Y-%m-%d %H:%M:%S"))
        if death ~= nil then
            AddToMap(DeathListSaved, death)
            table.insert(parsedDeathList, parsedDeath)    
        end
        
        -- Пример использования функции 
        -- ShowDeathMessage(death.GetDescription(death))
        -- print("Событие добавлено: " .. event:GetDescription())
        -- local deathSerealize = SerializeRecord(event)
        -- print("-------------------Serealized death:", deathSerealize)
        -- AddToMap(DeathListSaved, deathSerealize);
    elseif event == "CHAT_MSG_ADDON"  and prefix == "MyAddon" then      -- ///вынести в отдельную функцию
        -- print("Аддон ивент: ", event)
        -- print("Аддон префикс: ", prefix)
        -- print("Аддон сообщение: ", message)
        local sender, command, messagedata = string.match(message, "([^@]+)@([^@]+)@([^@]+)")
        -- print("Команда:", command)
        -- print("Отправитель:", sender)
        -- print("Данные:", messagedata)

        if command == "GET_COUNT_DEATH_RECORDS_FROM_DATE" then
            FrameUi.userMSG.HandleGetCountDeathRecordFromDate(FrameUi.userMSG, sender, messagedata);
        elseif command == "GET_COUNT_DEATH_RECORDS_FROM_DATE_RESULT" then
            FrameUi.userMSG.HandleGetCountDeathRecordFromDateResult(FrameUi.userMSG, sender, messagedata);
        elseif command == "SEND_DEATH_RECORD" then
            FrameUi.userMSG.HandleSendDeathRecord(FrameUi.userMSG, sender, messagedata, parsedDeathList)
        elseif command == "GET_DEATH_RECORDS_FROM_DATE_RESULT" then
            FrameUi.userMSG.HandleGetDeathRecordsFromDateResult(FrameUi.userMSG, sender, messagedata)
        end
    end
end)
-- UiMainFramne:UpdateTable()
-------------------------------------------------------------------------

-- Добавляем Slash-команду для добавления и проверки событий
SLASH_MYTESTADDON1 = "/shd"
SlashCmdList["MYTESTADDON"] = function(msg)
    -- if msg == "add" then
    --     -- Добавляем новое событие
    --     local deathInfoMess = "Нумампожалуй@GET_ALL_DEATH_RECORDS"
    --     SendMessageToPlayerOnSameServer("MyAddon", deathInfoMess, "WHISPER", "Ещёпятьминут")
    --     print("Отправлено сообщение:", deathInfoMess)
    -- elseif msg == "list" then
    --     -- Выводим список всех событий
    --     if #deathList > 0 then
    --         print("Список событий:")
    --         for i, event in ipairs(deathList) do
    --             print(string.format("%d. %s", i, event:GetDescription()))
    --         end
    --     else
    --         print("Список событий пуст.")
    --     end

    -- elseif msg == "clear" then
    --     -- Очищаем список событий
    --     deathList = {}
    --     print("Все события очищены.")
    if msg == "show" then
        FrameUi.UpdateTableAndSortRecords(FrameUi);
        FrameUi.frame:Show();
    elseif msg == "testShowMsg" then
        ShowDeathMessage(DeathListSaved[0])
    else
        print("Используйте команды: /shd show")
    end
end



-- -- Создаем текстуру на карте
-- local mapTexture = WorldMapDetailFrame:CreateTexture(nil, "OVERLAY")
-- mapTexture:SetTexture("Interface\\Buttons\\WHITE8x8") -- Белая текстура
-- mapTexture:SetVertexColor(0, 1, 0, 1) -- Зелёный цвет
-- mapTexture:SetSize(200, 2) -- Размер текстуры (длина линии 200 пикселей, толщина 2)
-- mapTexture:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", 100, -100) -- Привязка к карте
-- mapTexture:Show()



-- -- Функция для рисования линии с использованием сегментов
-- local function DrawLineWithSegments(x1, y1, x2, y2, thickness)
--     -- Рассчитываем размеры карты
--     local mapWidth = WorldMapDetailFrame:GetWidth()
--     local mapHeight = WorldMapDetailFrame:GetHeight()

--     -- Переводим координаты в пиксели карты
--     local startX = x1 * mapWidth
--     local startY = -y1 * mapHeight
--     local endX = x2 * mapWidth
--     local endY = -y2 * mapHeight

--     -- Определяем шаг (размер сегмента)
--     local segments = 10 -- Количество точек на линии
--     local stepX = (endX - startX) / segments
--     local stepY = (endY - startY) / segments

--     -- Создаем текстуры для каждого сегмента
--     for i = 0, segments do
--         local segment = WorldMapDetailFrame:CreateTexture(nil, "OVERLAY")
--         segment:SetTexture("Interface\\Buttons\\WHITE8x8") -- Белая текстура
--         segment:SetVertexColor(1, 0, 0, 1) -- Красный цвет
--         segment:SetSize(thickness, thickness) -- Толщина линии

--         -- Вычисляем положение текущего сегмента
--         local segmentX = startX + stepX * i
--         local segmentY = startY + stepY * i

--         -- Устанавливаем точку на карте
--         segment:SetPoint("TOPLEFT", WorldMapDetailFrame, "TOPLEFT", segmentX, segmentY)
--         segment:Show()
--     end
-- end

-- -- Пример использования: рисуем диагональную линию
-- DrawLineWithSegments(0.3, 0.3, 0.7, 0.6, 2) -- Линия от (30%, 30%) до (70%, 60%) толщиной 2 пикселя

-- -----------------------------------------------

-- -- Создаем основной фрейм аддона
-- local RouteTracker = CreateFrame("Frame", "RouteTrackerFrame")
-- RouteTracker:RegisterEvent("PLAYER_LOGIN")
-- RouteTracker:RegisterEvent("ZONE_CHANGED")
-- RouteTracker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
-- RouteTracker:RegisterEvent("PLAYER_ENTERING_WORLD")
-- RouteTracker:RegisterEvent("MINIMAP_UPDATE_ZOOM")

-- -- Хранилище маршрута
-- local routeData = {}
-- local maxDays = 7
-- local updateInterval = 5 -- Обновляем позицию каждые 5 секунд
-- local lastUpdate = 0

-- -- Функция для получения текущего времени
-- local function GetCurrentTime()
--     return date("%Y-%m-%d %H:%M:%S")
-- end

-- -- Функция для получения текущего местоположения
-- local function GetPlayerPosition()
--     local mapID = GetCurrentMapAreaID()
--     local x, y = GetPlayerMapPosition("player")
--     return mapID, x, y
-- end

-- -- Сохраняем позицию игрока
-- local function SavePlayerPosition()
--     local timestamp = GetCurrentTime()
--     local mapID, x, y = GetPlayerPosition()
--     print("mapID, x, y", mapID, x, y)
--     if not routeData[timestamp] then
--         routeData[timestamp] = {}
--     end

--     table.insert(routeData[timestamp], {mapID = mapID, x = x, y = y})

--     local cutoffTime = time() - (maxDays * 24 * 60 * 60)
--     for t, _ in pairs(routeData) do
--         -- Преобразуем строку даты в таблицу времени
--         local timeTable = {year = tonumber(strsub(t, 1, 4)), month = tonumber(strsub(t, 6, 7)), day = tonumber(strsub(t, 9, 10)),
--                            hour = tonumber(strsub(t, 12, 13)), min = tonumber(strsub(t, 15, 16)), sec = tonumber(strsub(t, 18, 19))}
--         local timestamp = time(timeTable)
    
--         if timestamp < cutoffTime then
--             routeData[t] = nil
--         end
--     end
-- end

-- -- Создаем линии для маршрута
-- local function DrawRoute()
--     print("Рисумем линии")
--     -- Очищаем предыдущие линии
--     if RouteTracker.lines then
--         for _, line in ipairs(RouteTracker.lines) do
--             print("line", line)
--             line:Hide()
--         end
--     end
--     RouteTracker.lines = {}

--     -- Создаем линии для маршрута
--     for t, positions in pairs(routeData) do
--         print("t", t, positions)
        
--             local p1, p2 = positions[1], positions[2]
           
--             -- Пропускаем, если нет данных о позиции
--             if p1 and p2 then
--                 print("p1, p2", p1, p2)
--                 local line = WorldMapFrame:CreateTexture(nil, "ARTWORK")
--                 line:SetTexture("Interface\\Buttons\\WHITE8x8") -- Белая текстура
--                 line:SetVertexColor(1, 0, 0, 1) -- Красный цвет, непрозрачный

--                 -- Вычисляем начальные и конечные координаты
--                 local x1, y1 = p1.x * WorldMapFrame:GetWidth(), -p1.y * WorldMapFrame:GetHeight()
--                 local x2, y2 = p2.x * WorldMapFrame:GetWidth(), -p2.y * WorldMapFrame:GetHeight()
                
--                 -- Определяем размеры и позицию текстуры
--                 line:ClearAllPoints()
--                 line:SetPoint("TOPLEFT", WorldMapFrame, "TOPLEFT", x1, y1)
--                 line:SetPoint("BOTTOMRIGHT", WorldMapFrame, "TOPLEFT", x2, y2)

--                 line:Show()
--                 table.insert(RouteTracker.lines, line)
--             end
--     end
-- end


-- -- Обработчик событий
-- RouteTracker:SetScript("OnEvent", function(self, event, ...)
--     if event == "PLAYER_LOGIN" then
--         print("RouteTracker загружен. Следим за маршрутом!")
--     elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
--         SavePlayerPosition()
--         print("SavePlayerPosition")
--     end
-- end)

-- -- Обработчик обновления
-- RouteTracker:SetScript("OnUpdate", function(self, elapsed)
--     lastUpdate = lastUpdate + elapsed
--     if lastUpdate >= updateInterval then
--         print("SavePlayerPosition")
--         SavePlayerPosition()
--         lastUpdate = 0
--     end
-- end)

-- -- Отображаем маршрут при открытии карты
-- WorldMapFrame:HookScript("OnShow", function()
--     print("Карта открыта")
--     DrawRoute()
-- end)
