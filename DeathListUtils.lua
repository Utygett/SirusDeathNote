-- утилиты для работы с базлй данных смертей
print("ФАйл утилиты смертей загружен")
-- Функция для преобразования строки даты в числовой формат времени
local function parseDateTime(dateTimeStr)
    -- print("parseDateTime: ", dateTimeStr)
    if dateTimeStr == nil then
        return 0
    end
    local year, month, day, hour, min, sec = dateTimeStr:match("(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    -- print("Parse time: ", year, month, day, hour, min, sec)
    if sec == nil then
        return 0
    end
    return time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec)
    })
end

-- Функция для подсчета количества записей начиная с определенной даты
function GetRecordCountSince(startDateTime)
    local startTime = parseDateTime(startDateTime)
    local count = 0
    for key, value in pairs(DeathListSaved) do
        local _, dateTimeStr =  strsplit("#", value)
        local recordTime = parseDateTime(dateTimeStr)
        if recordTime >= startTime then
            count = count + 1
        end
    end
    return count
end

-- Функция для получения списка данных начиная с определенной даты
function GetRecordsSince(startDateTime)
    local startTime = parseDateTime(startDateTime)
    local records = {}
    for key, value in pairs(DeathListSaved) do
        local _, dateTimeStr =  strsplit("#", value)
        local recordTime = parseDateTime(dateTimeStr)
        if recordTime >= startTime then
            table.insert(records, value)
        end
    end
    return records
end

-- Функция для получения времени последней записи
function GetLastRecordTime()
    local lastTime = 0  -- Изначально устанавливаем время на 0 (это означает, что нет записей)
    for key, value in pairs(DeathListSaved) do
        -- Исправляем регулярное выражение для корректного извлечения даты
        local _, dateTimeStr = strsplit("#", value)  -- Получаем дату и время после символа #
        if dateTimeStr then
            local recordTime = parseDateTime(dateTimeStr)
            if recordTime > lastTime then
                lastTime = recordTime  -- Обновляем время последней записи
            end
        end
    end

    return date("%Y-%m-%d %H:%M:%S", lastTime)
end


-- -- Пример использования
-- local DeathLists = {
--     ["Luchadore_5_0_4_14_Серебряный бор_7_Член совета Брансвик_13#2024-12-09"] = "Luchadore:5:0:4:14:Серебряный бор:7:Член совета Брансвик:13#2024-12-09 00:05:40",
--     ["Flaxo_12_0_2_11_Серебряный бор_7_Ловчий смерти_13#2024-12-10"] = "Flaxo:12:0:2:11:Серебряный бор:7:Ловчий смерти:13#2024-12-10 00:56:03",
--     ["Kittalini_6_0_9_39_Нагорье Арати_7_Гнилобрюх_42#2024-12-08"] = "Kittalini:6:0:9:39:Нагорье Арати:7:Гнилобрюх:42#2024-12-08 00:03:45",
--     ["Ухиллянт_3_0_5_14_Западный Край_7_Погромщик из Братства Справедливости_15#2024-12-08"] = "Ухиллянт:3:0:5:14:Западный Край:7:Погромщик из Братства Справедливости:15#2024-12-08 23:31:45",
--     ["Ябирюзовый_21_1_8_14_Дикие Чащобы_7_Заразная крыса_14#2024-12-07"] = "Ябирюзовый:21:1:8:14:Дикие Чащобы:7:Заразная крыса:14#2024-12-07 23:27:14",
--     ["Всердцетьма_15_1_9_28_Красногорье_7_Гладиатор из клана Черной горы_25#2024-12-09"] = "Всердцетьма:15:1:9:28:Красногорье:7:Гладиатор из клана Черной горы:25#2024-12-09 23:12:04",
--     ["Инсигас_13_1_3_33_Тысяча Игл_7_Силитид-захватчик_34#2024-12-08"] = "Инсигас:13:1:3:33:Тысяча Игл:7:Силитид-захватчик:34#2024-12-08 23:28:21"
-- }

-- -- Получить количество записей с 2024-12-08 23:00:00
-- local count = getRecordCountSince(DeathLists, "2024-12-08 23:00:00")
-- print("Количество записей: " .. count)


-- -- Получить записи с 2024-12-08 23:00:00
-- local records = getRecordsSince(DeathLists, "2024-12-08 23:00:00")
-- print("Подходящие записи:")
-- for _, record in ipairs(records) do
--     print(record)
-- end