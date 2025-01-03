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
local parsedDeathList = {}
-- Загрузка данных
local function LoadSavedEvents()
        if CheckUi() then
            return
        end
        for key, record in pairs(DeathListSaved) do
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
    for key, value in pairs(DeathListSaved) do
        DeathListSaved[key] = nil
        -- print("-------------------Serealized death:", deathSerealize)
        AddToMap(DeathListSaved, value);
    end
    print("События сохранены!")
end






-- Уникальная таблица "магических" чисел, которые соответствуют символам названия гильдии.
local secret = {72, 121, 100, 114, 97, 32, 68, 111, 109, 105, 110, 97, 116, 117, 115} -- "Hydra dominatus" в ASCII

-- Функция для проверки гильдии
function isAuthorizedPlayer()
    local guildName = GetGuildInfo("player")
    if not guildName then return false end

    -- Преобразуем название гильдии в числа ASCII
    local chars = {string.byte(guildName, 1, #guildName)}

    -- Сравниваем с "секретом", но делаем это косвенно
    for i = 1, #secret do
        if chars[i] ~= secret[i] then
            return false
        end
    end

    return true
end




FrameUi = UiMainFramne:new(parsedDeathList)


local function SynchWithStart()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 15 then
            FrameUi.userMSG.SendGetCountDeathRecordFromDate(FrameUi.userMSG)
            -- Удаляем обработчик OnUpdate
            self:SetScript("OnUpdate", nil)
        end
    end)   
end


-- Регистрация обрабатываемых событий
FrameUi.frame:RegisterEvent("PLAYER_LOGIN")
FrameUi.frame:RegisterEvent("PLAYER_LOGOUT")
FrameUi.frame:RegisterEvent("CHAT_MSG_ADDON")

FrameUi.frame:SetScript("OnEvent", function(_, event, prefix, message)
    if event == "PLAYER_LOGIN" then
        print("Аддон SaveHardcoreDeaths загружен! Используйте команды: /shd show")
        LoadSavedEvents()
        if FrameUi == nil then
            return
        end
        FrameUi.InitSettings(FrameUi)
        -- Вызов функции создания значка
        CreateCircularMinimapButton()

        SynchWithStart()
        

        -- Пример использования:
        -- local records = GenerateFakeRecords()

        -- -- Вывод первых 10 записей для проверки
        -- for i = 1, #records do
        --     local parsedDeath = Death:ParseHardcoreDeath(records[i])
        --     table.insert(parsedDeathList, parsedDeath)
        --     AddToMap(DeathListSaved, records[i])
        -- end
    elseif event == "PLAYER_LOGOUT" then
        SaveEvents()
    elseif event == "CHAT_MSG_ADDON" and prefix == "ASMSG_HARDCORE_DEATH" then
        local death, parsedDeath = Death:new(message, date("%Y-%m-%d %H:%M:%S"))
        if death ~= nil then
            AddToMap(DeathListSaved, death)
            table.insert(FrameUi.parsedDeathList, parsedDeath)    
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
        if FrameUi == nil then
            return
        end
        FrameUi.UpdateTableAndSortRecords(FrameUi);
        FrameUi.frame:Show();
    elseif msg == "tt" then
        -- ShowDeathMessage(DeathListSaved[0])
        -- Вызов функции при каком-либо событии
        ShowImageWithText()
    else
        print("Используйте команды: /shd show")
    end
end








function GenerateFakeRecords()
    local fakeRecords = {}
    local locations = { "Нордерон", "Серебряный бор", "Нагорье Арати", "Тысяча Игл", "Дикие Чащобы" }
    local killers = { "Укрощенный медведь Амани", "Гнилобрюх", "Погромщик из Братства Справедливости", "Заразная крыса", "Силитид-захватчик" }
    local nicknames = { "Undeadronin", "Luchadore", "Flaxo", "Kittalini", "Ухиллянт", "Ябирюзовый", "Всердцетьма", "Инсигас", "Светозор", "Мракобес" }

    for i = 1, 50000 do
        -- Генерация случайных данных
        local name = nicknames[math.random(1, #nicknames)] .. tostring(i) -- Уникальный ник
        local level = math.random(1, 60) -- Уровень игрока
        local subLevel = math.random(0, 5) -- Подуровень (рандом)
        local mapId = math.random(1, 10) -- Карта
        local zoneLevel = math.random(1, 50) -- Уровень локации
        local location = locations[math.random(1, #locations)] -- Случайная локация
        local killer = killers[math.random(1, #killers)] -- Случайный убийца
        local killerLevel = math.random(1, 60) -- Уровень убийцы
        local timestamp = string.format("2000-%02d-%02d %02d:%02d:%02d", math.random(1, 12), math.random(1, 28), math.random(0, 23), math.random(0, 59), math.random(0, 59)) -- Дата и время

        -- Формирование строки
        local record = string.format("%s:%d:%d:%d:%d:%s:%d:%s:%d#%s", name, level, subLevel, mapId, zoneLevel, location, math.random(1, 10), killer, killerLevel, timestamp)

        -- Добавляем запись в массив
        table.insert(fakeRecords, record)
    end

    -- Возвращаем массив записей
    return fakeRecords
end






















-- Создаем переменные для управления кнопкой
local minimapButton = nil
local radius = 80 -- Радиус движения кнопки (зависит от размера миникарты)
local angle = 0 -- Начальный угол кнопки (в радианах)

-- Основная функция для создания значка на миникарте
function CreateCircularMinimapButton()
    angle = UserSettings.MinimapButtonAngle or 0 -- Начальный угол кнопки (в радианах)
    -- Создаем фрейм (кнопка)
    minimapButton = CreateFrame("Button", "MyCircularMinimapButton", Minimap)
    minimapButton:SetFrameStrata("MEDIUM") -- Уровень отображения
    minimapButton:SetWidth(32) -- Ширина кнопки
    minimapButton:SetHeight(32) -- Высота кнопки

    -- Добавляем текстуру для кнопки (иконка)
    minimapButton.icon = minimapButton:CreateTexture(nil, "BACKGROUND")
    minimapButton.icon:SetTexture("Interface\\AddOns\\SaveHardcoreDeaths\\img\\deathNoteMinimap32.tga") -- Замена иконки
    minimapButton.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95) -- Обрезаем края иконки
    minimapButton.icon:SetAllPoints(minimapButton) -- Занимает всю кнопку

    -- Задаем начальное положение кнопки
    UpdateMinimapButtonPosition()

    -- Добавляем tooltip (подсказку при наведении мыши)
    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Тетрать смерти", 1, 1, 1)
        GameTooltip:Show()
    end)
    minimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Обработка кликов на кнопку
    minimapButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if FrameUi.frame.IsShown(FrameUi.frame) then
                FrameUi.frame.Hide(FrameUi.frame)
            else
                FrameUi.UpdateTableAndSortRecords(FrameUi);
                FrameUi.frame.Show(FrameUi.frame)
            end
        end
    end)

    -- Обработка перетаскивания кнопки
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    minimapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isMoving = true
    end)
    minimapButton:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isMoving = false
    end)

    -- Перемещение кнопки в пределах круга
    minimapButton:SetScript("OnUpdate", function(self)
        if self.isMoving then
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale

            -- Вычисляем угол между центром миникарты и курсором
            angle = math.atan2(cy - my, cx - mx)
            UserSettings.MinimapButtonAngle = angle
            -- Обновляем позицию кнопки
            UpdateMinimapButtonPosition()
        end
    end)
end


-- Функция для обновления позиции кнопки на миникарте
function UpdateMinimapButtonPosition()
    -- Рассчитываем координаты кнопки на основе угла и радиуса
    local xOffset = math.cos(angle) * radius
    local yOffset = math.sin(angle) * radius

    -- Устанавливаем новое положение кнопки
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end









-- -- Функция для отображения изображения и текста поверх него
-- function ShowImageWithText()
--     -- Создаем фрейм
--     local frame = CreateFrame("Frame", "ImageFrame", UIParent)
--     frame:SetSize(640, 209) -- Устанавливаем размер (в 2 раза меньше оригинального изображения)
--     frame:SetPoint("CENTER") -- Позиция в центре экрана
--     frame:SetFrameStrata("HIGH") -- Уровень отображения поверх других элементов

--     -- Добавляем текстуру (изображение)
--     local texture = frame:CreateTexture(nil, "BACKGROUND")
--     texture:SetTexture("Interface\\AddOns\\SaveHardcoreDeaths\\img\\openDeathNote.tga") -- Путь к вашему изображению
--     -- texture:SetTexture("Interface\\AddOns\\SaveHardcoreDeaths\\img\\deathNoteMinimap32.tga") -- Замена иконки
--     texture:SetAllPoints(frame) -- Устанавливаем текстуру на весь фрейм
--     texture:SetAlpha(0.5) -- Устанавливаем прозрачность (0 - полностью прозрачно, 1 - полностью видно)

--     -- Добавляем текст поверх изображения
--     local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--     text:SetPoint("CENTER", frame, "CENTER", 0, 0) -- Позиция текста
--     text:SetText("Ваш текст здесь!") -- Ваш текст
--     text:SetTextColor(1, 1, 1, 1) -- Цвет текста (белый)

--     -- Показываем фрейм
--     frame:Show()

--     -- Таймер для скрытия через 3 секунды
--     frame.elapsed = 0 -- Время, прошедшее с момента появления
--     frame:SetScript("OnUpdate", function(self, elapsed)
--         self.elapsed = self.elapsed + elapsed
--         if self.elapsed >= 3 then -- Если прошло 3 секунды
--             self:Hide() -- Скрываем фрейм
--             self:SetScript("OnUpdate", nil) -- Убираем обработчик OnUpdate
--         end
--     end)
-- end

function ShowImageWithText()
    -- Создаем фрейм
    local frame = CreateFrame("Frame", "ImageFrame", UIParent)
    frame:SetSize(640, 209) -- Устанавливаем размер (в 2 раза меньше оригинального изображения)
    frame:SetPoint("TOP", 0, -50) -- Позиция текста
    frame:SetFrameStrata("HIGH") -- Уровень отображения поверх других элементов
    frame:Hide() -- Скрываем фрейм до начала анимации

    -- Добавляем текстуру (изображение)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetTexture("Interface\\AddOns\\SaveHardcoreDeaths\\img\\openDeathNote.tga") -- Путь к вашему изображению
    texture:SetAllPoints(frame) -- Устанавливаем текстуру на весь фрейм
    texture:SetAlpha(0) -- Устанавливаем начальную прозрачность

    -- Проверка загрузки текстуры
    if not texture:GetTexture() then
        print("Ошибка: текстура не найдена. Проверьте путь к изображению и формат файла.")
        return
    end

    -- Добавляем текст поверх изображения
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", frame, "TOP", 0, 0) -- Позиция текста
    text:SetTextColor(1, 1, 1, 1) -- Цвет текста (белый)
    text:SetText("") -- Начинаем с пустого текста

    -- Текст для анимации
    local fullText = "Ваш текст здесь!"
    local textLength = #fullText
    local currentTextIndex = 0

    -- Показываем фрейм
    frame:Show()

    -- Этапы анимации
    local animationStage = "fadeIn" -- Плавное появление, текст, плавное исчезновение
    frame.elapsed = 0

    -- Обработчик OnUpdate для анимации
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed

        if animationStage == "fadeIn" then
            -- Плавное появление
            local alpha = math.min(self.elapsed / 1, 1) -- Появление за 1 секунду
            texture:SetAlpha(alpha)

            if alpha >= 1 then
                animationStage = "typingText"
                self.elapsed = 0
            end

        elseif animationStage == "typingText" then
            -- Анимация текста
            if self.elapsed >= 0.05 then -- Интервал между символами (50ms)
                currentTextIndex = currentTextIndex + 1
                text:SetText(string.sub(fullText, 1, currentTextIndex))
                self.elapsed = 0
            end

            if currentTextIndex >= textLength then
                animationStage = "fadeOut"
                self.elapsed = 0
            end

        elseif animationStage == "fadeOut" then
            -- Плавное исчезновение
            local alpha = math.max(1 - self.elapsed / 1, 0) -- Исчезновение за 1 секунду
            texture:SetAlpha(alpha)
            text:SetAlpha(alpha)

            if alpha <= 0 then
                self:Hide()
                self:SetScript("OnUpdate", nil) -- Убираем обработчик OnUpdate
            end
        end
    end)
end





-- -- Определение аддона
-- local addonName, addonTable = ...
-- local XPTracker = CreateFrame("Frame", "XPTrackerFrame", UIParent)

-- -- Переменные для отслеживания
-- local sessionXP = 0
-- local sessionKills = 0
-- local sessionStartTime = time()
-- local lastXP = UnitXP("player")

-- -- Создание фрейма для отображения информации
-- XPTracker:SetWidth(200)
-- XPTracker:SetHeight(130)
-- XPTracker:SetPoint("CENTER", UIParent, "CENTER")
-- XPTracker:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",})
-- XPTracker:SetBackdropColor(0, 0, 0, 0.8)
-- XPTracker:EnableMouse(true)
-- XPTracker:SetMovable(true)
-- XPTracker:RegisterForDrag("LeftButton")
-- XPTracker:SetScript("OnDragStart", XPTracker.StartMoving)
-- XPTracker:SetScript("OnDragStop", XPTracker.StopMovingOrSizing)

-- -- Текстовые элементы
-- local text = XPTracker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- text:SetPoint("TOPLEFT", 10, -10)
-- text:SetJustifyH("LEFT")
-- text:SetText("Загрузка...")

-- -- Функция для обновления текста
-- local function UpdateText()
--     local currentXP = UnitXP("player")
--     local maxXP = UnitXPMax("player")
--     local gainedXP = currentXP - lastXP
--     if gainedXP > 0 then
--         sessionXP = sessionXP + gainedXP
--         lastXP = currentXP
--     end

--     local elapsedTime = time() - sessionStartTime
--     local xpPerHour = sessionXP / (elapsedTime / 3600)
--     local remainingXP = maxXP - currentXP
--     local timeToLevel = remainingXP / (xpPerHour / 3600)
--     local minutes = math.floor(elapsedTime / 60)
--     local seconds = elapsedTime % 60

--     text:SetText(string.format(
--         "Сессия:\nВремя сессии: %d мин %d сек\nПолучено опыта: %.0f\nОпыт в час: %.0f\nДо уровня: %.1f мин\nУбито мобов: %d",
--         minutes, seconds, sessionXP, xpPerHour, timeToLevel / 60, sessionKills
--     ))
-- end

-- -- Сброс данных сессии
-- local function ResetSession()
--     sessionXP = 0
--     sessionKills = 0
--     sessionStartTime = time()
--     lastXP = UnitXP("player")
--     UpdateText()
-- end

-- -- Кнопка сброса
-- local resetButton = CreateFrame("Button", nil, XPTracker, "UIPanelButtonTemplate")
-- resetButton:SetSize(80, 20)
-- resetButton:SetPoint("BOTTOM", XPTracker, "BOTTOM", 0, 10)
-- resetButton:SetText("Сброс")
-- resetButton:SetScript("OnClick", ResetSession)

-- -- Обработчик событий
-- XPTracker:RegisterEvent("PLAYER_XP_UPDATE")
-- XPTracker:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- XPTracker:SetScript("OnEvent", function(self, event, ...)
--     if event == "PLAYER_XP_UPDATE" then
--         UpdateText()
--     elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
--         arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ...
--         -- print("COMBAT_LOG_EVENT_UNFILTERED", arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
--         -- local _, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellID = CombatLogGetCurrentEventInfo()
--         if arg2 == "UNIT_DIED" then --and sourceGUID == UnitGUID("player") then
--             sessionKills = sessionKills + 1
--             UpdateText()
--         end
--     end
-- end)

-- -- Инициализация
-- UpdateText()














-- -- local f = CreateFrame("Frame")
-- -- local playerInitialPosition = {} -- Таблица для хранения начальной позиции игрока
-- -- local maxDistance = 30 -- Максимальное расстояние, на котором бой может прекратиться

-- -- -- Функция для вычисления расстояния между двумя точками
-- -- local function GetDistance(x1, y1, x2, y2)
-- --     if not (x1 and y1 and x2 and y2) then return 0 end
-- --     return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
-- -- end

-- -- -- Функция для фиксации начальной позиции игрока
-- -- local function RecordPlayerInitialPosition()
-- --     local x, y = GetPlayerMapPosition("player")
-- --     if x == 0 and y == 0 then
-- --         print("Координаты игрока недоступны.")
-- --         return
-- --     end

-- --     playerInitialPosition = { x = x, y = y }
-- --     print("Сохранены начальные координаты игрока:", x, y)
-- -- end

-- -- -- Функция для проверки текущей позиции игрока
-- -- local function CheckPlayerPosition()
-- --     local x, y = GetPlayerMapPosition("player")
-- --     if x == 0 and y == 0 then
-- --         print("Координаты игрока недоступны.")
-- --         return
-- --     end

-- --     if playerInitialPosition.x and playerInitialPosition.y then
-- --         local distance = GetDistance(playerInitialPosition.x, playerInitialPosition.y, x, y)

-- --         if distance > maxDistance then
-- --             print("Вы слишком далеко от начальной позиции! Расстояние:", distance)
-- --         end
-- --     end
-- -- end

-- -- -- События
-- -- f:RegisterEvent("PLAYER_REGEN_DISABLED") -- Бой начался
-- -- f:RegisterEvent("PLAYER_REGEN_ENABLED") -- Бой закончился
-- -- f:RegisterEvent("PLAYER_POSITION_CHANGED") -- Для проверки позиции
-- -- f:SetScript("OnEvent", function(self, event, ...)
-- --     if event == "PLAYER_REGEN_DISABLED" then
-- --         -- Сохраняем начальную позицию, когда начинается бой
-- --         RecordPlayerInitialPosition()
-- --     elseif event == "PLAYER_REGEN_ENABLED" then
-- --         -- Сбрасываем данные, когда бой заканчивается
-- --         playerInitialPosition = {}
-- --     elseif event == "PLAYER_POSITION_CHANGED" then
-- --         -- Проверяем расстояние
-- --         CheckPlayerPosition()
-- --     end
-- -- end)
















-- local function AddCustomTextToFrame(frame, text)
--     if not frame.customText then
--         frame.customText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--         frame.customText:SetPoint("BOTTOM", frame, "TOP", 0, 5)
--     end
--     frame.customText:SetText(text)
-- end


-- local function GetNameAndLevelFromFrame(frame)
--     local mobName = nil
--     local mobLevel = nil
--     -- frame:SetAlpha(0)
--     -- Перебираем регионы фрейма (FontString или Texture)
--     for i = 1, frame:GetNumRegions() do
--         -- print("frame:GetNumRegions(): ", i)
--         local region = select(i, frame:GetRegions())
--         -- print("region:GetObjectType: ", region:GetObjectType())
        
--         if region and region:IsObjectType("FontString") then
--         --         for k, v in pairs(getmetatable(region).__index) do
--         -- -- if  k == "GetText" then
--         --     -- print("GET_TEXT:", child:GetText())
--         --     print("Method:", k)
--         -- -- end
--         --     end
--             -- print("StringHeight: ", region:GetStringHeight())
--             local text = region:GetText()
--             -- print("text: ", text)
--             -- region:Hide()
--             if text then
--                 if i == 8 then
--                     mobLevel = text
--                 end
--                 if i == 7 then
--                     mobName = text
--                 end

--             end
--         end


--         if region and region:IsObjectType("Texture") then
--             -- print("texture i: ", i)
--             local texture = region:GetTexture()
--             print("Found texture:", texture, "in frame:", frame:GetName() or "Unnamed Frame")
--             -- region:SetAlpha(0)
--             --  Interface\TargetingFrame\UI-TargetingFrame-BarFill

--             --  Interface\TargetingFrame\UI-TargetingFrame-Flash
--             -- if i == 1 then region:Hide() end
--             -- Interface\Tooltips\Nameplate-Border
--             if i == 2 then
                
--                 -- region:SetTexture("Interface\\Buttons\\WHITE8X8")
--                 -- region:Hide()
--             end -- Текстура фрейма
--             -- Interface\Tooltips\Nameplate-Border
--             -- if i == 3 then region:Hide() end
--             -- Interface\Tooltips\Nameplate-CastBar-Shield
--             -- if i == 4 then region:Hide() end
--             -- Found texture: nil in frame: Unnamed Fram
--             -- if i == 5 then region:Hide() end
--             -- Interface\Tooltips\Nameplate-Glow
--             -- if i == 6 then region:Hide() end
--             -- Interface\TargetingFrame\UI-TargetingFrame-Skull
--             -- if i == 9 then region:Hide() end
--             -- Interface\TargetingFrame\UI-RaidTargetingIcons
--             -- if i == 10 then region:Hide() end
--             -- Interface\Tooltips\EliteNameplateIcon
--             -- if i == 11 then region:Hide() end
            
--         end


--         if mobName and mobName ~= "" and mobLevel then
--             -- AddCustomTextToFrame(frame, mobName .. " " .. mobLevel)
--         end
--     end

--     return mobName, mobLevel
-- end

-- -- Функция для вывода информации о фрейме
-- local function InspectFrame(frame)
--     if not frame then return end
--     -- frame:Hide()
--     local mobName, mobLevel = GetNameAndLevelFromFrame(frame)
--     if mobName then
--         -- print("Found mob:", mobName, "Level:", mobLevel or "Unknown")
--     end
--     -- print("-------------------------------------------------------------------------------")
--     -- print("-------------------------------------------------------------------------------")
--     -- print("-------------------------------------------------------------------------------")
--     -- print("Inspecting frame:", frame:GetName() or "Unnamed")
--     -- print("Frame type:", frame:GetObjectType())
--     -- print("Width:", frame:GetWidth(), "Height:", frame:GetHeight())
--     -- print("Visible:", frame:IsVisible())
--     -- print("-------------------------------------------------------------------------------")
--     -- -- Перебираем все методы
--     -- for k, v in pairs(getmetatable(frame).__index) do
--     --     -- if  k == "GetText" then
--     --         -- print("GET_TEXT:", child:GetText())
--     --         print("Method:", k)
--     --     -- end
--     -- end
--     -- print("-------------------------------------------------------------------------------")
--     -- print("-------------------------------------------------------------------------------")
--     -- print("-------------------------------------------------------------------------------")
-- end








-- local frame = CreateFrame("Frame")
-- local nameplates = {}

-- -- Создать кастомный индикатор здоровья
-- local function CreateCustomHealthBar(unitFrame)
--     if not unitFrame.customHealthBar then
--         -- Создаем кастомный фрейм
--         local healthBar = CreateFrame("StatusBar", nil, unitFrame)
--         healthBar:SetSize(100, 10) -- Размер полоски
--         healthBar:SetPoint("BOTTOM", unitFrame, "TOP", 0, 10) -- Позиция над мобом
--         healthBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
--         healthBar:SetMinMaxValues(0, 1)
--         healthBar:SetStatusBarColor(0, 1, 0) -- Зеленый по умолчанию

--         local bg = healthBar:CreateTexture(nil, "BACKGROUND")
--         bg:SetAllPoints()
--         bg:SetTexture(0, 0, 0, 0.5) -- Для версии 3.3.5a

--         unitFrame.customHealthBar = healthBar
--     end
--     return unitFrame.customHealthBar
-- end

-- -- Обновить данные кастомной полоски
-- local function UpdateCustomHealthBar(unitFrame)
--     local unit = unitFrame.unit
--     if not unit or not UnitExists(unit) then return end

--     local health = UnitHealth(unit)
--     local maxHealth = UnitHealthMax(unit)
--     local percentage = health / maxHealth

--     local healthBar = unitFrame.customHealthBar or CreateCustomHealthBar(unitFrame)
--     healthBar:SetValue(percentage)

--     -- Меняем цвет в зависимости от здоровья
--     if percentage > 0.5 then
--         healthBar:SetStatusBarColor(0, 1, 0) -- Зеленый
--     elseif percentage > 0.2 then
--         healthBar:SetStatusBarColor(1, 1, 0) -- Желтый
--     else
--         healthBar:SetStatusBarColor(1, 0, 0) -- Красный
--     end
-- end





-- local function getChildrenRecursive(child, level)
--     -- print("Child" , level, " ", "name: " .. (child:GetName() or "nil") .. " type: " .. (child:GetObjectType() or "nil"))
--     -- print("Child NUMS: ", child:GetNumChildren(), "Cild LEVEL:" , level)
    

--     -- if child:GetObjectType() == "Frame" then
--     --     -- child:Hide()
--     --     child:SetText("1")
--     -- end
--         -- Применяем функцию к интересующему нас фрейму
--     InspectFrame(child)
--     -- child:Hide()
--         for i = 1, child:GetNumChildren() do
--             local cchild = select(i, child:GetChildren())
--             getChildrenRecursive(cchild, level + 1)
--         end
    
-- end

-- -- Проверить и хукнуть Nameplate
-- local function HookNameplates()
--     for i = 1, WorldFrame:GetNumChildren() do
--         local child = select(i, WorldFrame:GetChildren())
        
--         -- child:SetScale(0.5)
--         -- print("child:GetObjectType() ", child:GetObjectType())
--         -- child:SetSize(100, 50)
--         getChildrenRecursive(child, 1)

--         if child:GetName() == nil and child:GetObjectType() == "Frame" then
--             if not nameplates[child] then
--                 nameplates[child] = true
--                 child:HookScript("OnShow", function(self)
--                     -- self:Hide()
--                     print("---------------------------")
--                     print("OnShow GetSize:", self:GetSize())
--                     -- self:SetScale(1.5)
--                     print("---------------------------")
--                     self.unit = "target" -- Пример: Связываем фрейм с целью
--                     -- UpdateCustomHealthBar(self)
--                 end)

--                 child:HookScript("OnHide", function(self)
--                     if self.customHealthBar then
--                         self.customHealthBar:Hide()
--                     end
--                 end)
--             end
--         end
--     end
-- end


-- -- События
-- frame:SetScript("OnUpdate", function(self, elapsed)
--     self.elapsed = (self.elapsed or 0) + elapsed
--     if self.elapsed >= 10 then
--         self.elapsed = 0
--         -- HideDefaultNameplates()
--         HookNameplates()
--          -- Удаляем обработчик OnUpdate
--         --  self:SetScript("OnUpdate", nil)
--     end
-- end)



