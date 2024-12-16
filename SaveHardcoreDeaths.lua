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

-- Таблица для хранения объектов событий
local deathList = {}
local parsedDeathList = {}
-- Загрузка данных
local function LoadSavedEvents()
        for key, record in pairs(DeathListSaved) do
            -- print("--------------------recordIS:", record)
            -- local death = Death:FromTable(DeserializeRecord(record))
            -- table.insert(deathList, death)
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


FrameUi = UiMainFramne:new(parsedDeathList)

-- Регистрация обрабатываемых событий
FrameUi.frame:RegisterEvent("PLAYER_LOGIN")
FrameUi.frame:RegisterEvent("PLAYER_LOGOUT")
FrameUi.frame:RegisterEvent("CHAT_MSG_ADDON")

FrameUi.frame:SetScript("OnEvent", function(_, event, prefix, message)
    if event == "PLAYER_LOGIN" then
        print("Аддон SaveHardcoreDeaths загружен! Используйте команды: /shd show")
        LoadSavedEvents()
        FrameUi.InitSettings(FrameUi)
    elseif event == "PLAYER_LOGOUT" then
        SaveEvents()
    elseif event == "CHAT_MSG_ADDON" and prefix == "ASMSG_HARDCORE_DEATH" then
        local death, parsedDeath = Death:new(message, date("%Y-%m-%d %H:%M:%S"))
        if death ~= nil then
            AddToMap(DeathListSaved, death)
            table.insert(parsedDeathList, parsedDeath)    
        end
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
