-- Глобальная переменная, которую мы будем сохранять
MySavedVariable = MySavedVariable or {}

DeathListSaved = DeathListSaved or {}   





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
        for _, record in pairs(DeathListSaved) do
            -- print("--------------------recordIS:", record)
            -- local death = Death:FromTable(DeserializeRecord(record))
            -- table.insert(deathList, death)
            local parsedDeath = Death:ParseHardcoreDeath(record)
            table.insert(parsedDeathList, parsedDeath)
            

            -- local deathSerealize = death.DeathMessage .. "#" .. death.DeathTime
            -- print("-------------------Serealized death:", deathSerealize)
            -- AddToMap(DeathListSaved, deathSerealize);

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
        print("Аддон загружен!")
        LoadSavedEvents()
        FrameUi.InitSettings(FrameUi)
        
        FrameUi.frame:Show();
        print("Check UserSettings.dateTimeForSynch: ", UserSettings.dateTimeForSynch)
        
        print("Check UserSettings.SyncWithGuild: ", UserSettings.SyncWithGuild)
        print("Check UserSettings.SyncWithFriends: ", UserSettings.SyncWithFriends)
        -- Регистрируем префикс
        -- RegisterPrefix("MyAddon")
        -- Пример использования
        -- SendMessageToPlayerOnSameServer("MyAddon", "Hello!", "WHISPER", "Ещёпятьминут")
        -- SendMessageToPlayerOnSameServer("MyAddon", "GET_ALL_DEATH_RECORDS@Нумампожал", "WHISPER", "Ещёпятьминут")
    elseif event == "PLAYER_LOGOUT" then
        SaveEvents()
    elseif event == "CHAT_MSG_ADDON" and prefix == "ASMSG_HARDCORE_DEATH" then
        print("--------CHAT_MSG_ADDON: ", message)
        local event = Death:new(message, date("%Y-%m-%d %H:%M:%S"))
        AddToMap(DeathListSaved, event)
        local parsedDeath = Death:ParseHardcoreDeath(event)
        table.insert(parsedDeathList, parsedDeath)
        -- print("Событие добавлено: " .. event:GetDescription())
        -- local deathSerealize = SerializeRecord(event)
        -- print("-------------------Serealized death:", deathSerealize)
        -- AddToMap(DeathListSaved, deathSerealize);
    elseif event == "CHAT_MSG_ADDON"  and prefix == "MyAddon" then      -- ///вынести в отдельную функцию
        print("Аддон ивент: ", event)
        print("Аддон префикс: ", prefix)
        print("Аддон сообщение: ", message)
        local sender, command, messagedata = string.match(message, "([^@]+)@([^@]+)@([^@]+)")
        print("Команда:", command)
        print("Отправитель:", sender)
        print("Данные:", messagedata)

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
SLASH_MYTESTADDON1 = "/testsave"
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
        FrameUi.UpdateTable(FrameUi);
        FrameUi.frame:Show();
    else
        print("Используйте команды: /testsave add, /testsave list, /testsave clear")
    end
end