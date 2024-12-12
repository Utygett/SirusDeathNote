-- Определение класса Death
UserMessages = {}
UserMessages.__index = UserMessages

-- Конструктор класса
function UserMessages:new()
    local obj = setmetatable({}, UserMessages)
    obj.addonName = "MyAddon";
    obj.synchUserMap = {} -- Подумать над механизмом получения количества записей от всех пользователей и спрашивать у того у кого их больше.
    return obj
end

function UserMessages:SendGetCountDeathRecordFromDate()
    print("Начинаем синхронизацию...")
    local onlineFriends = GetOnlineFriends()
    for _, name in ipairs(onlineFriends) do
        self.synchUserMap[name] = -1; -- TODO
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
    self.synchUserMap[sender] = tonumber(messagedata);-- TODO
    print("Получаем от " .. sender .. " количество записей: " .. messagedata);
    if tonumber(messagedata) > 0 then
        local lastRecordTime = GetLastRecordTime();
        local returnCmd = "GET_DEATH_RECORDS_FROM_DATE_RESULT";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
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
