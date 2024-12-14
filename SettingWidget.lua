print("---------------------Файл SettingWidget загружен.")

SettingsWidget = {}
SettingsWidget.__index = SettingsWidget

--Конструктор 
function SettingsWidget:new()
    local obj = setmetatable({}, SettingsWidget)
    obj.frame = CreteMainFrameUi("SettingsFrame", 300, 200, "HIGH", "Настройки");

    -- Чекбокс 1: Синхронизация записей с друзьями
    obj.syncWithFriendsCheckbox = CreateFrame("CheckButton", "SyncWithFriendsCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithFriendsCheckbox:SetPoint("TOPLEFT", 20, -40)
    obj.syncWithFriendsCheckbox.text = obj.syncWithFriendsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithFriendsCheckbox.text:SetPoint("LEFT", obj.syncWithFriendsCheckbox, "RIGHT", 5, 0)
    obj.syncWithFriendsCheckbox.text:SetText("Синхронизация записей с друзьями")
    obj.syncWithFriendsCheckbox:SetScript("OnClick", function(self)
        UserSettings.SyncWithFriends = self:GetChecked() == true;
        print("Синхронизация с друзьями: " .. tostring(UserSettings.SyncWithFriends))
    end)

    -- Чекбокс 2: Синхронизация записей с согильдейцами
    obj.syncWithGuildCheckbox = CreateFrame("CheckButton", "SyncWithGuildCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithGuildCheckbox:SetPoint("TOPLEFT", 20, -80)
    obj.syncWithGuildCheckbox.text = obj.syncWithGuildCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithGuildCheckbox.text:SetPoint("LEFT", obj.syncWithGuildCheckbox, "RIGHT", 5, 0)
    obj.syncWithGuildCheckbox.text:SetText("Синхронизация записей с согильдейцами")
    
    obj.syncWithGuildCheckbox:SetScript("OnClick", function(self)
        UserSettings.SyncWithGuild = self:GetChecked() == true;
        print("Синхронизация с согильдейцами: " .. tostring(UserSettings.SyncWithGuild))
    end)

    obj.dateInput = nil
    obj.timeInput = nil
    obj.picker, obj.dateInput, obj.timeInput = CreateDateTimePicker(obj.frame, "Выберите дату и время", date("%Y-%m-%d %H:%M:%S"), function(selectedDateTime)
        -- Сохраняем дату и время начало синхронизации в настройки
        UserSettings.dateTimeForSynch = selectedDateTime;
        obj.UpdateSyncDateLabel(obj, selectedDateTime)
        print("Выбранная дата и время с которой начинаем синхронизацию: " .. selectedDateTime)
    end)


    -- Создаем FontString для отображения даты
    obj.syncDateLabel = obj.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    obj.syncDateLabel:SetPoint("TOPLEFT", 15, -126) -- Центрируем текст
    obj.syncDateLabel:SetText("2024-12-10 00:56:03") -- Устанавливаем текст


    -- Кнопка для открытия виджета
    obj.openPickerButton = CreateFrame("Button", nil, obj.frame, "UIPanelButtonTemplate")
    obj.openPickerButton:SetSize(110, 25)
    obj.openPickerButton:SetPoint("TOPLEFT", 165, -120)
    obj.openPickerButton:SetText("Установить дату")
    obj.openPickerButton:SetScript("OnClick", function()
        obj.picker:Show()
    end)

    -- Кнопка "Начать синхронизацию"
    obj.startSyncButton = CreateFrame("Button", "StartSyncButton", obj.frame, "UIPanelButtonTemplate")
    obj.startSyncButton:SetSize(140, 25)
    obj.startSyncButton:SetText("Начать синхронизацию")
    obj.startSyncButton:SetPoint("BOTTOM", obj.frame, "BOTTOM", 0, 10)

    return obj
end

-- Функция для обновления текста с текущей датой синхронизации
function SettingsWidget:UpdateSyncDateLabel(dateString)
    self.syncDateLabel:SetText(dateString)
end

-- Обновляем дату и время в лейбле и виджете выбора даты и времени
function SettingsWidget:UpdateSettingDatePickerText(dateTime)
    UserSettings.dateTimeForSynch = dateTime;
    self.UpdateSyncDateLabel(self, dateTime)
    self.dateInput:SetText(dateTime:match("^(%d+-%d+-%d+)")) -- Устанавливаем дату
    self.timeInput:SetText(dateTime:match("(%d+:%d+:%d+)$")) -- Устанавливаем время
end

function SettingsWidget:setHandlerForSynchButton(sycnhFunction)
    self.startSyncButton:SetScript("OnClick", sycnhFunction)
end

function SettingsWidget:Init()
    -- Ставим дату последней записи для обновления при инициализации
    self.UpdateSettingDatePickerText(self, GetLastRecordTime())
    self.syncWithGuildCheckbox:SetChecked(UserSettings.SyncWithGuild)
    self.syncWithFriendsCheckbox:SetChecked(UserSettings.SyncWithFriends)
end