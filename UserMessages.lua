-- Определение класса Death
UserMessages = {}
UserMessages.__index = UserMessages

-- Конструктор класса
function UserMessages:new()
    local obj = setmetatable({}, UserMessages)
    obj.addonName = "MyAddon";
    obj.synchUserMap = {} -- Подумать над механизмом получения количества записей от всех пользователей и спрашивать у того у кого их больше.
    obj.synchProcessed = false
    return obj
end

-- Проверяем пришли ли все запросы на количество записей
function UserMessages:CheckReadyUserGetCountRecord()
    local readyToStart = true;
    for userName, count in ipairs(self.synchUserMap) do
        if count < 0 then
            readyToStart = false;
        end
    end
    return readyToStart
end

-- Нанчинаем синхронизацию
function UserMessages:StartSynch()
    if self.synchProcessed == false then
        return
    end
    self.synchProcessed = false
    
    local usName = nil
    local maxCount = 0

    for userName, count in pairs(self.synchUserMap) do
        if maxCount < count then
            maxCount = count
            usName = userName
        end
    end

    
    print("Начинаем обмен записями, время: ", date("%Y-%m-%d %H:%M:%S"))
    if usName and maxCount > 0 then
        print("Обмен записями начался с ", usName)
        local lastRecordTime = UserSettings.dateTimeForSynch
        local returnCmd = "GET_DEATH_RECORDS_FROM_DATE_RESULT";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", usName)
    end
    self.synchUserMap = {}
end

-- Запуск ожидания всех запросов по таймеру
function UserMessages:AwaitAllUserToSynch()
    self.synchProcessed = true
    print("Включаем таймер, время: ", date("%Y-%m-%d %H:%M:%S"))
    local thisObj = self;
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 5 then
            thisObj.StartSynch(thisObj)
        end
    end)
end

function UserMessages:SendGetCountDeathRecordFromDate()
    print("Начинаем синхронизацию...")
    local onlineFriends = GetOnlineFriends()
    if #onlineFriends == 0 then
        print("Нет друзей онлайн...")
    end
    -- Очищаем мапу перед синхронизацией
    self.synchUserMap = {}
    for _, name in ipairs(onlineFriends) do
        -- Проставляет всем в списке значение в -1, потом будем проверять если не -1 значит пришёл результат
        self.synchUserMap[name] = -1;
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
    self.synchUserMap[sender] = tonumber(messagedata);-- TODO
    if self.synchProcessed == false then
        self.AwaitAllUserToSynch(self)
    end
    if self.CheckReadyUserGetCountRecord(self) then
        self.StartSynch(self)
    end
end

function UserMessages:HandleSendDeathRecord(sender, messagedata, parsedDeathList)
    print("Получена запись:", messagedata, " от игрока: ", sender);
    AddToMap(DeathListSaved, messagedata)
    local parsedDeath = Death:ParseHardcoreDeath(messagedata)
    table.insert(parsedDeathList, parsedDeath)
end


function UserMessages:HandleGetDeathRecordsFromDateResult(sender, messagedata)
    local records = GetRecordsSince(messagedata)
    for _, record in ipairs(records) do
        local returnCmd = "SEND_DEATH_RECORD";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. record
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
    end
end
