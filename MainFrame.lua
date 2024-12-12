UiMainFramne = {}
UiMainFramne.__index = UiMainFramne

UserSettings = UserSettings or {}


local function addDropdownMenu(self, text, filerId, filterName)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.func = function()
        self.activeFilter = filerId
        UIDropDownMenu_SetText(self.dropdown, filterName)
    end
    UIDropDownMenu_AddButton(info, 1)
end

-- Инициализация выпадающего меню
local function InitializeDropdown(self, level)
    addDropdownMenu(self, "Фильтр по имени", "name", "Фильтр: Имя");
    addDropdownMenu(self, "Фильтр по классу", "class", "Фильтр: Класс");
    addDropdownMenu(self, "Фильтр по фракции", "fraction", "Фильтр: Фракция");
    addDropdownMenu(self, "Фильтр по расе", "race", "Фильтр: Раса");
    addDropdownMenu(self, "Фильтр по уровню", "level", "Фильтр: Уровень");
    addDropdownMenu(self, "Фильтр по локации", "zone", "Фильтр: Локация");
    addDropdownMenu(self, "Фильтр по убийце", "killerName", "Фильтр: Убийца");
    addDropdownMenu(self, "Фильтр по времени", "deathTime", "Фильтр: Время");
end

local function creteMainFrameUi()
    -- Основной фрейм
local frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(1050, 450)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetFrameStrata("MEDIUM")

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlightLarge")
frame.title:SetPoint("TOP", frame, "TOP", 0, -2)
frame.title:SetText("Тетрадь смерти")
return frame
end

-- Конструктор класса
function UiMainFramne:new(parsedDeathList)
    local obj = setmetatable({}, UiMainFramne)
    obj.frame = creteMainFrameUi()
    obj.data = parsedDeathList
    obj.parsedDeathList = parsedDeathList

    obj.userMSG = UserMessages:new();--Класс обмена сообщениями
    
    -- Заголовки таблицы
    -- name, class, fraction, race, level, zone, unknowValue, killerName, killerLevel, deathTime)
    obj.headers =     {"Имя", "Класс", "Фракция","Раса", "lvl", "Локация", "Кто убил", "lvl уб..", "Время смерти"}
    obj.headersSize = {85,       95  ,    70,      75,     30,     130,        320,         50,              120}
    obj.sortColumn = nil
    obj.sortAscending = true
    obj.headerFrames = {}
    -- Переменная для текущего фильтра
    obj.activeFilter = "name" -- По умолчанию фильтруем по имени

        -- Создание ScrollFrame для прокрутки
    obj.scrollFrame = CreateFrame("ScrollFrame", nil, obj.frame, "UIPanelScrollFrameTemplate")
    obj.scrollFrame:SetSize(1000, 350)
    obj.scrollFrame:SetPoint("TOPLEFT", obj.frame, "TOPLEFT", 10, -80)

    obj.scrollChild = CreateFrame("Frame") -- Контейнер для содержимого
    obj.scrollChild:SetSize(980, 1) -- Ширина фиксированная, высота будет изменяться
    obj.scrollFrame:SetScrollChild(obj.scrollChild)

    -- Создание выпадающего меню
    obj.dropdown = CreateFrame("Frame", "FilterDropdown", obj.frame, "UIDropDownMenuTemplate")
    obj.dropdown:SetPoint("TOPLEFT", obj.frame, "TOPLEFT", 200, -25)
    UIDropDownMenu_Initialize(obj.dropdown, function(...) InitializeDropdown(obj, ...) end)
    UIDropDownMenu_SetText(obj.dropdown, "Фильтр: Имя") -- Устанавливаем начальный текст

        -- Создание заголовков с кнопками для сортировки
    local headersSizeAccamulate = 0
    for i, headerText in ipairs(obj.headers) do
        local button = CreateFrame("Button", nil, obj.frame)
        button:SetSize(obj.headersSize[i], 20)
        button:SetPoint("TOPLEFT", obj.frame, "TOPLEFT", headersSizeAccamulate + 10, -50)
        headersSizeAccamulate = headersSizeAccamulate + obj.headersSize[i] 
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("CENTER")
        text:SetText(headerText)

        button:SetScript("OnClick", function()
            -- Определяем, какой столбец сортировать
            if i == 1 then
                obj.SortBy(obj, "name")
            elseif i == 2 then
                obj.SortBy(obj, "class")
            elseif i == 3 then
                obj.SortBy(obj, "fraction")
            elseif i == 4 then
                obj.SortBy(obj, "race")  
            elseif i == 5 then
                obj.SortBy(obj, "level")  
            elseif i == 6 then
                obj.SortBy(obj, "zone")  
            elseif i == 7 then
                obj.SortBy(obj, "killerName")  
            elseif i == 8 then
                obj.SortBy(obj, "killerLevel")  
            elseif i == 9 then
                obj.SortBy(obj, "deathTime")  
            end
        end)
        obj.headerFrames[i] = button
    end
        -- Создание строки поиска
    obj.searchBox = CreateFrame("EditBox", nil, obj.frame, "InputBoxTemplate")
    obj.searchBox:SetSize(200, 20)
    obj.searchBox:SetPoint("TOPLEFT", obj.frame, "TOPLEFT", 15, -28)
    obj.searchBox:SetAutoFocus(false)
    obj.searchBox:SetScript("OnTextChanged", function(self)
        local searchText = obj.searchBox:GetText()
        print("obj.searchBox: ", searchText)
        obj.FilterData(obj, searchText)
    end)

        -- Создание основной кнопки "Настройки"
    local settingsButton = CreateFrame("Button", "SettingsButton", obj.frame, "UIPanelButtonTemplate")
    settingsButton:SetSize(100, 25) -- Размер кнопки
    settingsButton:SetText("Настройки")
    settingsButton:SetPoint("TOPRIGHT", -23, 2) -- Позиция сверху справа
    settingsButton:SetScript("OnClick", function()
        if not SettingsFrame:IsShown() then
            SettingsFrame:Show()
        else
            SettingsFrame:Hide()
        end
    end)

    -- Создание окна настроек
    local SettingsFrame = CreateFrame("Frame", "SettingsFrame", nil, "BasicFrameTemplateWithInset")
    SettingsFrame:SetSize(300, 200) -- Размер окна
    SettingsFrame:SetPoint("CENTER") -- Центр экрана
    SettingsFrame:Hide() -- Скрываем окно по умолчанию
    SettingsFrame.title = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SettingsFrame.title:SetPoint("TOP", SettingsFrame, "TOP", 0, -5)
    SettingsFrame.title:SetText("Настройки синхронизации")
    SettingsFrame:SetMovable(true)
    SettingsFrame:EnableMouse(true)
    SettingsFrame:SetFrameStrata("HIGH")
    SettingsFrame:RegisterForDrag("LeftButton")
    SettingsFrame:SetScript("OnDragStart", SettingsFrame.StartMoving)
    SettingsFrame:SetScript("OnDragStop", SettingsFrame.StopMovingOrSizing)


    -- Чекбокс 1: Синхронизация записей с друзьями
    local SyncWithFriendsCheckbox = CreateFrame("CheckButton", "SyncWithFriendsCheckbox", SettingsFrame, "UICheckButtonTemplate")
    SyncWithFriendsCheckbox:SetPoint("TOPLEFT", 20, -40)
    SyncWithFriendsCheckbox.text = SyncWithFriendsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SyncWithFriendsCheckbox.text:SetPoint("LEFT", SyncWithFriendsCheckbox, "RIGHT", 5, 0)
    SyncWithFriendsCheckbox.text:SetText("Синхронизация записей с друзьями")
    SyncWithFriendsCheckbox:SetChecked(UserSettings.SyncWithFriends)
    SyncWithFriendsCheckbox:SetScript("OnClick", function(self)
        UserSettings.SyncWithFriends = self:GetChecked()
        print("Синхронизация с друзьями: " .. tostring(UserSettings.SyncWithFriends))
    end)

    -- Чекбокс 2: Синхронизация записей с согильдейцами
    local SyncWithGuildCheckbox = CreateFrame("CheckButton", "SyncWithGuildCheckbox", SettingsFrame, "UICheckButtonTemplate")
    SyncWithGuildCheckbox:SetPoint("TOPLEFT", 20, -80)
    SyncWithGuildCheckbox.text = SyncWithGuildCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    SyncWithGuildCheckbox.text:SetPoint("LEFT", SyncWithGuildCheckbox, "RIGHT", 5, 0)
    SyncWithGuildCheckbox.text:SetText("Синхронизация записей с согильдейцами")
    SyncWithGuildCheckbox:SetChecked(UserSettings.SyncWithGuild)
    SyncWithGuildCheckbox:SetScript("OnClick", function(self)
        UserSettings.SyncWithGuild = self:GetChecked()
        print("Синхронизация с согильдейцами: " .. tostring(UserSettings.SyncWithGuild))
    end)

    obj.dateInput = nil
    obj.timeInput = nil
    obj.picker, obj.dateInput, obj.timeInput = CreateDateTimePicker(SettingsFrame, "Выберите дату и время", date("%Y-%m-%d %H:%M:%S"), function(selectedDateTime)
        --  selectedDateTime
        print("Выбранная дата и время: " .. selectedDateTime)
    end)
    obj.picker:Hide()

    -- Кнопка для открытия виджета
    local openPickerButton = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
    openPickerButton:SetSize(100, 25)
    openPickerButton:SetPoint("TOPLEFT", 100, -120)
    openPickerButton:SetText("Установить дату")
    openPickerButton:SetScript("OnClick", function()
        obj.picker:Show()
    end)

    -- Кнопка "Начать синхронизацию"
    local StartSyncButton = CreateFrame("Button", "StartSyncButton", SettingsFrame, "UIPanelButtonTemplate")
    StartSyncButton:SetSize(140, 25)
    StartSyncButton:SetText("Начать синхронизацию")
    StartSyncButton:SetPoint("BOTTOM", SettingsFrame, "BOTTOM", 0, 10)
    StartSyncButton:SetScript("OnClick", function()
        obj.userMSG.SendGetCountDeathRecordFromDate(obj.userMSG)
    end)
    return obj
end

function UiMainFramne:UpdateSettingDatePickerText(dateTime) 
    self.dateInput:SetText(dateTime:match("^(%d+-%d+-%d+)")) -- Устанавливаем начальную дату
    self.timeInput:SetText(dateTime:match("(%d+:%d+:%d+)$")) -- Устанавливаем начальное время
end

-- Функция для обработки сортировки
function UiMainFramne:SortBy(column)
    if self.sortColumn == column then
        self.sortAscending = not self.sortAscending -- Переключение порядка сортировки
    else
        self.sortColumn = column
        self.sortAscending = true -- По умолчанию сортировка по возрастанию
    end
    table.sort(self.data, function(a, b)
        if self.sortAscending then
            return a[column] < b[column]
        else
            return a[column] > b[column]
        end
    end)
    self.UpdateTable(self)
end


-- Функция для обновления таблицы
function UiMainFramne:UpdateTable()
    -- Очистка предыдущих строк
    if self.scrollChild.rows then
        for _, row in ipairs(self.scrollChild.rows) do
            for _, text in pairs(row) do
                text:Hide()
            end
        end
    else
        self.scrollChild.rows = {}
    end

    -- Высота содержимого будет зависеть от количества строк
    local rowHeight = 20
    local totalHeight = #self.data * rowHeight
    self.scrollChild:SetHeight(totalHeight)

    -- Создание строк таблицы
    for i, row in ipairs(self.data) do
        if not self.scrollChild.rows[i] then
            self.scrollChild.rows[i] = {}

            self.scrollChild.rows[i].name = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].name:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -rowHeight * (i - 1))

            self.scrollChild.rows[i].class = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].class:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 100, -rowHeight * (i - 1))

            self.scrollChild.rows[i].fraction = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].fraction:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 195, -rowHeight * (i - 1))

            self.scrollChild.rows[i].race = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].race:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 250, -rowHeight * (i - 1))

            self.scrollChild.rows[i].level = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].level:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 330, -rowHeight * (i - 1))

            self.scrollChild.rows[i].zone = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].zone:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 360, -rowHeight * (i - 1))

            self.scrollChild.rows[i].killerName = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].killerName:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 520, -rowHeight * (i - 1))

            self.scrollChild.rows[i].killerLevel = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].killerLevel:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 820, -rowHeight * (i - 1))

            self.scrollChild.rows[i].deathTime = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            self.scrollChild.rows[i].deathTime:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 850, -rowHeight * (i - 1))
        end

        self.scrollChild.rows[i].name:SetText(row.name)
        self.scrollChild.rows[i].name:Show()

        self.scrollChild.rows[i].class:SetText(row.class)
        self.scrollChild.rows[i].class:Show()    

        self.scrollChild.rows[i].fraction:SetText(row.fraction)
        self.scrollChild.rows[i].fraction:Show()

        self.scrollChild.rows[i].race:SetText(row.race)
        self.scrollChild.rows[i].race:Show()

        self.scrollChild.rows[i].level:SetText(row.level)
        self.scrollChild.rows[i].level:Show()

        self.scrollChild.rows[i].zone:SetText(row.zone)
        self.scrollChild.rows[i].zone:Show()

        self.scrollChild.rows[i].killerName:SetText(row.killerName)
        self.scrollChild.rows[i].killerName:Show()

        self.scrollChild.rows[i].killerLevel:SetText(row.killerLevel)
        self.scrollChild.rows[i].killerLevel:Show()

        self.scrollChild.rows[i].deathTime:SetText(row.deathTime)
        self.scrollChild.rows[i].deathTime:Show()
    end
end
-- Функция для фильтрации данных
function UiMainFramne:FilterData(searchText)
    self.data = {}
    for _, row in ipairs(self.parsedDeathList) do
        -- Фильтрация по выбранному параметру (activeFilter)
        if tostring(row[self.activeFilter]):lower():find(searchText:lower()) then
            table.insert(self.data, row)
        end
    end
    self.UpdateTable(self)
end
