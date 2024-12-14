--Глобальные функции, утилиты
function SerializeRecord(record)
    -- Соединяем DeathMessage и DeathTime в одну строку
    return record.DeathMessage .. "#" .. record.DeathTime
end

function DeserializeRecord(serializedString)
    -- Разделяем строку на DeathMessage и DeathTime
    local deathMessage, deathTime = strsplit("#", serializedString)
    -- print("deathMessage: ", deathMessage)
    -- print("deathTime: ", deathTime)
    -- Создаём запись
    return {
        DeathMessage = deathMessage,
        DeathTime = deathTime,
    }
end

-- Генерация ключа
function GenerateKey(inputString)
    local keySource = string.sub(inputString, 1, -10) -- Убираем последние 8 символов
    local keyHash = string.gsub(keySource, ":", "_") -- Преобразуем для удобства
    return keyHash
end


-- Добавление записи в карту
function AddToMap(map, record)
    local key = GenerateKey(record)
    map[key] = record
end


-- Проверка существования ключа
function KeyExists(map, key)
    return map[key] ~= nil
end

function SendMessageToPlayerOnSameServer(prefix, message, channel, targetPlayer)
    if channel == "WHISPER" then
        SendAddonMessage(prefix, message, channel, targetPlayer)
    else
        SendAddonMessage(prefix, message, channel)
    end
end
-- Получить список друзей онлайн
function GetOnlineFriends()
    local onlineFriends = {}
    -- Получаем общее количество друзей
    local numFriends = GetNumFriends() -- WOW API
    -- Перебираем список друзей
    for i = 1, numFriends do
        local name, _, _, _, connected = GetFriendInfo(i) -- WOW API
        if connected then
            table.insert(onlineFriends, name)
        end
    end
    return onlineFriends
end

-- Таблица цветов для русских названий классов
CLASS_COLORS_RU = {
    ["Воин"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["Маг"] = { r = 0.41, g = 0.80, b = 0.94 },
    ["Разбойник"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["Друид"] = { r = 1.00, g = 0.49, b = 0.04 },
    ["Охотник"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["Шаман"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["Жрец"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["Чернокнижник"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["Паладин"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["Рыцарь смерти"] = { r = 0.77, g = 0.12, b = 0.23 },
}

function GetTextRGBColorFromClassName(className)
    -- Получаем цвет из таблицы
    local color = CLASS_COLORS_RU[className]
    if color then
        return color.r, color.g, color.b;
    else
        -- Если класс не найден в таблице, устанавливаем белый цвет по умолчанию
        return 1, 1, 1
    end
end