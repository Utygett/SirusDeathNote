UserSettings = UserSettings or {}


-- Определение класса Death
Death = {}
Death.__index = Death

local fractionName = {
    "Альянс",
    "Орда"
}

local RACE_NAME_FROM_ID = {
    [2] = "Орк",
    [4] = "Ночной эльф",
    [5] = "Нежить",
    [6] = "Таурен",
    [8] = "Тролль",
    [11] = "Дреней",
    [12] = "Ворген",
    [13] = "Нага",
    [14] = "Пандарен",
    [15] = "Высший эльф",
    [17] = "Ночнорожденный",
    [19] = "Вульпера(Альянс)",
    [20] = "Вульпера(орда)",
    [27] = "Драктир",
}

local function getFractionNameFromId (fractionId)
    if fractionId == nil then
        return ""
    end
    return fractionName[tonumber(fractionId) + 1];
end


local function RemoveFactionTags(inputString)
    if inputString == "Озаренный дреней" then
        return "Оз. дреней"
    end
    -- Указываем слова/фразы, которые нужно удалить
    local tagsToRemove = { "%(Альянс%)", "%(Нейтрал%)", "%(Орда%)" } -- `%(` и `%)` экранируют скобки

    -- Перебираем все фразы и удаляем их из строки
    for _, tag in ipairs(tagsToRemove) do
        inputString = inputString:gsub(tag, "") -- Удаляем каждое совпадение
    end

    -- Убираем лишние пробелы (если они остались)
    inputString = inputString:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s%s+", " ")

    return inputString
end

local function getRaceNameFromId (raceId)
    -- Получаем данные о расе
    if raceId == nil then
        return ""
    end
    local raceInfo = C_CreatureInfo.GetRaceInfo(tonumber(raceId))
    if raceInfo == nil then
        return ""
    end
    return RemoveFactionTags(raceInfo.raceName);
end

local function getClassNameFromId (classId)
    -- Получаем данные о классе
    if classId == nil then
        return ""
    end
    local classID = tonumber(classId)
    local classInfo = C_CreatureInfo.GetClassInfo(classID)
    if classInfo == nil then
        return ""
    end
    return classInfo.className;
end

-- Конструктор класса
function Death:new(DeathMessage, DeathTime)
    local obj = setmetatable({}, Death)
    obj.DeathMessage = DeathMessage or "Unknown Death"
    obj.DeathTime = DeathTime or date("%Y-%m-%d %H:%M:%S")
    local serObj = SerializeRecord(obj)
    local parsedDeath = obj.ParseHardcoreDeath(obj, serObj)
    if parsedDeath.name == nil then
        return nil, nil
        end
    return serObj, parsedDeath
end

-- Метод для получения описания события
function Death:GetDescription()
    return string.format("[%s] %s", self.DeathTime, self.DeathMessage)
end

-- Метод для преобразования объекта в таблицу (для сохранения)
function Death:ToTable()
    return {
        DeathMessage = self.DeathMessage,
        DeathTime = self.DeathTime
    }
end

-- Метод для создания объекта из таблицы (при загрузке)
function Death:FromTable(data)
    return Death:new(data.DeathMessage, data.DeathTime)
end

function Death:ParseHardcoreDeath(record)
    -- print("-------------death:", death.DeathMessage)
    local death = DeserializeRecord(record)
    local deathMessage = death.DeathMessage;
    local deathTime = death.DeathTime;
    -- Парсим строку
    local name, race, fraction, class, level, zone, unknowValue, killerName, killerLevel = 
        deathMessage:match("([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
    
    if name == nil then
        name, race, fraction, class, level, zone, killerName = deathMessage:match("([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
        if killerName == "0" then
            killerName = "Устал"
        elseif killerName == "1" then
            killerName = "Утонул"
        elseif killerName == "2" then
            killerName = "Упал"
        elseif killerName == "3" then
            killerName = "Сгорел в лаве"
        elseif killerName == "9" then
            killerName = "Неизвестно"    
        end
    end
    fraction = getFractionNameFromId(fraction)
    class = getClassNameFromId(class)
    race = getRaceNameFromId(race)

    level = tonumber(level)
    killerLevel = tonumber(killerLevel)

    -- Проверяем и преобразуем данные
    if killerLevel == nil then
        killerLevel = 0;
    end
    -- print("------contenct death :", name, class, fraction, race, level, zone, unknowValue, killerName, killerLevel, deathTime)
    return {
        name = name, 
        class = class, 
        fraction = fraction, 
        race = race, 
        level = level, 
        zone = zone, 
        unknowValue = unknowValue, 
        killerName = killerName, 
        killerLevel = killerLevel, 
        deathTime = deathTime,
    }
end
