-- Определение класса Death
UserMessages = {}
UserMessages.__index = UserMessages

Obj_synchUserMap = {}

-- Конструктор класса
function UserMessages:new()
    local obj = setmetatable({}, UserMessages)
    obj.addonName = "MyAddon";
    Obj_synchUserMap = {} -- Подумать над механизмом получения количества записей от всех пользователей и спрашивать у того у кого их больше.
    obj.synchProcessed = false
    obj.synchGettingRecord = false
    obj.synchSendingRecord = false
    obj.lastGettingRecordTime = 0
    obj.synchCountRecord = 0
    obj.synchNumberOfRecordsReceived = 0
    return obj
end

-- Проверяем пришли ли все запросы на количество записей
function UserMessages:CheckReadyUserGetCountRecord()
    for userName, count in pairs(Obj_synchUserMap) do
        if count < 0 then
            return false;
        end
    end
    return true;
end

-- Нанчинаем синхронизацию
function UserMessages:StartSynch()
    if self.synchProcessed == false then
        return
    end
    self.synchProcessed = false
    
    local usName = nil
    local maxCount = 0

    for userName, count in pairs(Obj_synchUserMap) do
        if maxCount < count then
            maxCount = count
            usName = userName
        end
    end

    
    DebugPrint("Начинаем обмен записями, время: " .. date("%Y-%m-%d %H:%M:%S"))
    if usName and maxCount > 0 then
        self.synchCountRecord = maxCount
        DebugPrint("Обмен записями начался с ".. usName)
        local lastRecordTime = UserSettings.dateTimeForSynch
        local returnCmd = "GET_DEATH_RECORDS_FROM_DATE_RESULT";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", usName)
    end
    Obj_synchUserMap = {}
end


-- Проверям пришли ли все записи и если нет то запускаем повторную синхронизацию
function UserMessages:CheckGettingAllRecordsWithSynch()
    if self.synchGettingRecord == false then
        DebugPrint("Удаляем проверку синхронизации.")
        return
    else
        print("Синхронизация завершилась неудачей!!!")
        print("Получено записей: ", self.synchNumberOfRecordsReceived, " из ", self.synchCountRecord)
        print("-------------------------------------------")
        print("Повторите синхронизацию в ручном режиме!!!!")
        print("-------------------------------------------")
        self.synchGettingRecord = false
    end
end

-- Запуск ожидания всех запросов по таймеру
function UserMessages:AwaitAllUserToSynch()
    if self.synchProcessed == true then
        return
    end 
    self.synchProcessed = true
    DebugPrint("Включаем таймер ожидания получения колисчества записей, время: " .. date("%Y-%m-%d %H:%M:%S"))
    local thisObj = self;
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 5 then
            DebugPrint("Отключаем таймер ожидания получения колисчества записей, время: " .. date("%Y-%m-%d %H:%M:%S"))
            thisObj.StartSynch(thisObj)
            -- Удаляем обработчик OnUpdate
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Запуск ожидания всех запросов по таймеру
function UserMessages:AwaitAllRecordsToSynch()
    self.synchGettingRecord = true
    DebugPrint("Включаем таймер ожидания получения записей, время: " .. date("%Y-%m-%d %H:%M:%S"))
    local thisObj = self;
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        local currentTime = GetTime();
        if currentTime - thisObj.lastGettingRecordTime >= 10 then
            thisObj.CheckGettingAllRecordsWithSynch(thisObj)
            -- Удаляем обработчик OnUpdate
            self:SetScript("OnUpdate", nil)
            DebugPrint("Отключаем таймер ожидания получения записей, время: " .. date("%Y-%m-%d %H:%M:%S"))
        end
    end)
end


function UserMessages:SendGetCountDeathRecordFromDate()
    DebugPrint("Начинаем синхронизацию...")

    if UserSettings.SyncWithFriends == false and UserSettings.SyncWithGuild == false then
        print("Синхронизация не выполнена, включите синхронизацию с друзьями или согильдейцами.")
        return
    end

    local onlineFriends = GetOnlineFriends()
    -- Очищаем мапу перед синхронизацией
    Obj_synchUserMap = {}

    if UserSettings.SyncWithFriends then
        
        for _, name in ipairs(onlineFriends) do
            -- Проставляет всем в списке значение в -1, потом будем проверять если не -1 значит пришёл результат
            Obj_synchUserMap[name] = -1;
        end
    end

    if UserSettings.SyncWithGuild then
        -- Обновляем список гильдии, чтобы получить актуальные данные
        GuildRoster()
        -- Получаем количество согильдейцев
        local numMembers = GetNumGuildMembers()
        local playerName = UnitName("player")
        for i = 1, numMembers do
            -- Получаем информацию о каждом члене гильдии
            local name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(i)
            -- Проверяем, онлайн ли игрок
            if online then
                -- Проверяем что это не мы (чтобы не спрашивать у себя)
                if name ~= playerName then
                    Obj_synchUserMap[name] = -1
                end
            end
        end      
    end

        -- Итерация по всей мапе и вывод ключей
    for name, _ in pairs(Obj_synchUserMap) do
        local lastRecordTime = UserSettings.dateTimeForSynch
        DebugPrint("Справшиваем у " .. name .. " количество записей от " .. lastRecordTime);
        local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime;
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", name);
    end
    -- Объявляем время начала синхронизации
    self.lastGettingRecordTime = GetTime()
    self.AwaitAllRecordsToSynch(self)
end

function UserMessages:HandleGetCountDeathRecordFromDate(sender, messagedata)
    -- Если мы уже посылаем или принимаем записи то не участвуем в новой синхронизации
    if self.synchSendingRecord == true then
        return
    end
    local countRecord = GetRecordCountSince(messagedata);
    DebugPrint(sender .." cправшивает количество записей от " .. messagedata .. "... Количество записей: ", countRecord);
    local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE_RESULT";
    local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. countRecord
    SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
end

function UserMessages:HandleGetCountDeathRecordFromDateResult(sender, messagedata)
    DebugPrint("Получаем от " .. sender .. " количество записей: " .. messagedata);
    Obj_synchUserMap[sender] = tonumber(messagedata);
    if self.synchProcessed == false then
        self.AwaitAllUserToSynch(self)
    end
    if self.CheckReadyUserGetCountRecord(self) then
        self.StartSynch(self)
    end
end

function UserMessages:HandleSendDeathRecord(sender, messagedata, parsedDeathList)
    self.synchNumberOfRecordsReceived = self.synchNumberOfRecordsReceived + 1
    -- обновляем время получения последней записи
    self.lastGettingRecordTime = GetTime()
    if self.synchNumberOfRecordsReceived % 100 == 0 then
        DebugPrint("Получена запись №" .. tostring(self.synchNumberOfRecordsReceived) .. " из " .. tostring(self.synchCountRecord))
    end
    -- print("Получена запись:", messagedata, " от игрока: ", sender);
    AddToMap(DeathListSaved, messagedata)
    if self.synchNumberOfRecordsReceived >= self.synchCountRecord then
        DebugPrint("Синхронизация завершена успешно!!!")
        DebugPrint("Получено записей: " .. tostring(self.synchNumberOfRecordsReceived) .. " из " .. tostring(self.synchCountRecord))
        self.synchGettingRecord = false;
        self.synchNumberOfRecordsReceived = 0
        self.synchCountRecord = 0
        FrameUi.UpdateDataInFrame(FrameUi);
    end
end

-- function UserMessages:HandleGetDeathRecordsFromDateResult(sender, messagedata)
--     local records = GetRecordsSince(messagedata)
--     for _, record in ipairs(records) do
--         local returnCmd = "SEND_DEATH_RECORD";
--         local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. record
--         SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
--     end
-- end

function UserMessages:HandleGetDeathRecordsFromDateResult(sender, messagedata)
    local records = GetRecordsSince(messagedata)
    local queue = {} -- Очередь для сообщений
    local maxMessagesPerSecond = 300
    local delay = 1 / maxMessagesPerSecond
    local addonName = self.addonName
    local selfObj = self
    self.synchSendingRecord = true
    -- Заполняем очередь
    for _, record in ipairs(records) do
        local returnCmd = "SEND_DEATH_RECORD"
        local messageToReturn = UnitName("player") .. "@" .. returnCmd .. "@" .. record
        table.insert(queue, messageToReturn)
    end

    -- Таймер-фрейм
    local timerFrame = CreateFrame("Frame")
    timerFrame.timeElapsed = 0
    DebugPrint("Размер очереди: " .. tostring(#queue))
    timerFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timeElapsed = self.timeElapsed + elapsed

        -- Если прошло достаточно времени, отправляем сообщение
        if self.timeElapsed >= delay and #queue > 0 then
            for i = 1, 5, 1 do
                local messageToSend = table.remove(queue, 1)
                SendMessageToPlayerOnSameServer(addonName, messageToSend, "WHISPER", sender)
                -- print("отправка сообщениея: ",  messageToSend, sender)
                -- Сброс таймера    
            end
            self.timeElapsed = 0
        end

        -- Удаляем фрейм, если очередь пуста
        if #queue == 0 then
            -- Ставим флаг о завершении отправки сообщений
            selfObj.synchSendingRecord = false
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)

    timerFrame:Show()
end