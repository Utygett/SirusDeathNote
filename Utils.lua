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