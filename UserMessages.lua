-- Определение класса Death
UserMessages = {}
UserMessages.__index = UserMessages

-- Конструктор класса
function UserMessages:new()
    local obj = setmetatable({}, UserMessages)
    obj.addonName = "MyAddon";
    return obj
end

function UserMessages:SendGetCountDeathRecordFromDate()
    print("Начинаем синхронизацию...") -- Пустой обработчик
    -- Пример использования функции
    local onlineFriends = GetOnlineFriends()
    for _, name in ipairs(onlineFriends) do
        local lastRecordTime = GetLastRecordTime(DeathListSaved);
        print("Справшиваем у " .. name .. " количество записей от " .. lastRecordTime);
        local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime;
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", name);
    end    
end

function UserMessages:HandleGetCountDeathRecordFromDate(sender, messagedata)
    local countRecord = GetRecordCountSince(DeathListSaved, messagedata)
    local returnCmd = "GET_COUNT_DEATH_RECORDS_FROM_DATE_RESULT";
    local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. countRecord
    SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
end

function UserMessages:HandleGetCountDeathRecordFromDateResult(sender, messagedata)
    if tonumber(messagedata) > 0 then
        local lastRecordTime = GetLastRecordTime(DeathListSaved);
        local returnCmd = "GET_DEATH_RECORDS_FROM_DATE_RESULT";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. lastRecordTime
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
    end
end

function UserMessages:HandleSendDeathRecord(sender, messagedata, deathList, parsedDeathList)
    print("Получена запись:", messagedata, " от игрока: ", sender);
    local death = DeserializeRecord(messagedata);
    table.insert(deathList, death)
    local parsedDeath = Death:ParseHardcoreDeath(death)
    table.insert(parsedDeathList, parsedDeath)
end


function UserMessages:HandleGetDeathRecordsFromDateResult(sender, messagedata, deathList)
    local records = GetRecordsSince(deathList, messagedata)
    for _, record in ipairs(records) do
        local returnCmd = "SEND_DEATH_RECORD";
        local messageToReturn = UnitName("player") .. "@"..returnCmd .."@" .. record
        SendMessageToPlayerOnSameServer(self.addonName, messageToReturn, "WHISPER", sender)
    end
end

