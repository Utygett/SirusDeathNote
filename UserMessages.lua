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
    obj.synchCountRecord = 0
    obj.synchNumberOfRecordsReceived = 0
    return obj
end

-- Проверяем пришли ли все запросы на количество записей
function UserMessages:CheckReadyUserGetCountRecord()
    print("CheckReadyUserGetCountRecord")
    for userName, count in pairs(Obj_synchUserMap) do
        print("CheckReadyUserGetCountRecord username:", userName , count )
        if count < 0 then
            print("CheckReadyUserGetCountRecord return false")
            return false;
        end
    end
    print("CheckReadyUserGetCountRecord return true")
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

    
    print("Начинаем обмен записями, время: ", date("%Y-%m-%d %H:%M:%S"))
    if usName and maxCount > 0 then
        self.synchCountRecord = maxCount
        print("Обмен записями начался с ", usName)
        local lastRecordTime = UserSettings.dateTimeForSynch
        local returnCmd = "GET_DEATH_RECORDS_FROM_DATE_RESULT";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", usName)
    end
    Obj_synchUserMap = {}
end


-- Проверям пришли ли все записи и если нет то запускаем повторную синхронизацию
function UserMessages:CheckGettingAllRecordsWithSynch()
    if UserMessages.synchGettingRecord == false then
        self.synchNumberOfRecordsReceived = 0
        return
    else
        print("Синхронизация завершилась неудачей!!!")
        print("Количесвто ожидаемых записей: ", self.synchCountRecord)
        print("Количесвто полученных записей: ", self.synchNumberOfRecordsReceived)
        print("Повторите синхронизацию в ручном режиме!!!")
        UserMessages.synchGettingRecord = false
    end
end

-- Запуск ожидания всех запросов по таймеру
function UserMessages:AwaitAllUserToSynch()
    print("AwaitAllUserToSynch self.synchProcessed == ", self.synchProcessed)
    if self.synchProcessed == true then
        return
    end 
    self.synchProcessed = true
    print("Включаем таймер, время: ", date("%Y-%m-%d %H:%M:%S"))
    local thisObj = self;
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 5 then
            thisObj.StartSynch(thisObj)
            -- Удаляем обработчик OnUpdate
            self:SetScript("OnUpdate", nil)
        end
    end)
end

-- Запуск ожидания всех запросов по таймеру
function UserMessages:AwaitAllRecordsToSynch()
    self.synchGettingRecord = true
    print("Включаем таймер, время: ", date("%Y-%m-%d %H:%M:%S"))
    local thisObj = self;
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 10 then
            thisObj.CheckGettingAllRecordsWithSynch(thisObj)
        end
    end)
end


function UserMessages:SendGetCountDeathRecordFromDate()
    print("Начинаем синхронизацию...")

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
            print("name")
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
        print("Справшиваем у " .. name .. " количество записей от " .. lastRecordTime);
        local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime;
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", name);
    end

end

function UserMessages:HandleGetCountDeathRecordFromDate(sender, messagedata)
    local countRecord = GetRecordCountSince(messagedata);
    print(sender .." cправшивает количество записей от " .. messagedata .. "... Количество записей: ", countRecord);
    local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE_RESULT";
    local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. countRecord
    SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
end

function UserMessages:HandleGetCountDeathRecordFromDateResult(sender, messagedata)
    print("Получаем от " .. sender .. " количество записей: " .. messagedata);
    Obj_synchUserMap[sender] = tonumber(messagedata);
    print("self.synchProcessed == ", self.synchProcessed)
    if self.synchProcessed == false then
        self.AwaitAllUserToSynch(self)
    end
    print("Проверяем прислали ли все пользователи?")
    if self.CheckReadyUserGetCountRecord(self) then
        print("CheckReadyUserGetCountRecord == true")
        self.StartSynch(self)
    end
end

function UserMessages:HandleSendDeathRecord(sender, messagedata, parsedDeathList)
    self.synchNumberOfRecordsReceived = self.synchNumberOfRecordsReceived + 1
    if self.synchNumberOfRecordsReceived % 1000 == 0 then
        print("Получена запись №" .. tostring(self.synchNumberOfRecordsReceived) .. " из " .. tostring(self.synchCountRecord))
    end
    -- print("Получена запись:", messagedata, " от игрока: ", sender);
    AddToMap(DeathListSaved, messagedata)
    local parsedDeath = Death:ParseHardcoreDeath(messagedata)
    table.insert(parsedDeathList, parsedDeath)
    if self.synchNumberOfRecordsReceived >= self.synchCountRecord then
        self.synchGettingRecord = false;
        self.synchNumberOfRecordsReceived = 0
        self.synchCountRecord = 0
        print("Синхронизация завершена успешно!!!")
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

    -- Заполняем очередь
    for _, record in ipairs(records) do
        local returnCmd = "SEND_DEATH_RECORD"
        local messageToReturn = UnitName("player") .. "@" .. returnCmd .. "@" .. record
        table.insert(queue, messageToReturn)
    end

    -- Таймер-фрейм
    local timerFrame = CreateFrame("Frame")
    timerFrame.timeElapsed = 0
    print("Размер очереди: ", #queue)
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
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)

    timerFrame:Show()
end