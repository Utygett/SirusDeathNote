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
    obj.syncWithFriendsCheckbox:SetChecked(UserSettings.SyncWithFriends == 1)
    obj.syncWithFriendsCheckbox:SetScript("OnClick", function(obj)
        UserSettings.SyncWithFriends = obj.syncWithFriendsCheckbox.GetChecked()
        print("Синхронизация с друзьями: " .. tostring(UserSettings.SyncWithFriends))
    end)

    -- Чекбокс 2: Синхронизация записей с согильдейцами
    obj.syncWithGuildCheckbox = CreateFrame("CheckButton", "SyncWithGuildCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithGuildCheckbox:SetPoint("TOPLEFT", 20, -80)
    obj.syncWithGuildCheckbox.text = obj.syncWithGuildCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithGuildCheckbox.text:SetPoint("LEFT", obj.syncWithGuildCheckbox, "RIGHT", 5, 0)
    obj.syncWithGuildCheckbox.text:SetText("Синхронизация записей с согильдейцами")
    obj.syncWithGuildCheckbox:SetChecked(UserSettings.SyncWithGuild == 1)
    obj.syncWithGuildCheckbox:SetScript("OnClick", function(obj)
        UserSettings.SyncWithGuild = obj.syncWithGuildCheckbox.GetChecked()
        print("Синхронизация с согильдейцами: " .. tostring(UserSettings.SyncWithGuild))
    end)

    obj.dateInput = nil
    obj.timeInput = nil
    obj.picker, obj.dateInput, obj.timeInput = CreateDateTimePicker(obj.frame, "Выберите дату и время", date("%Y-%m-%d %H:%M:%S"), function(selectedDateTime)
        --  selectedDateTime
        print("Выбранная дата и время: " .. selectedDateTime)
    end)

    -- Кнопка для открытия виджета
    obj.openPickerButton = CreateFrame("Button", nil, obj.frame, "UIPanelButtonTemplate")
    obj.openPickerButton:SetSize(100, 25)
    obj.openPickerButton:SetPoint("TOPLEFT", 100, -120)
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

-- Обновляем дату и время в лейбле и виджете выбора даты и времени
function SettingsWidget:UpdateSettingDatePickerText(dateTime)
    --TODO добавить лейбл перед кнопкой (показывает текущее выбранную дату и время синхронизации)
    self.dateInput:SetText(dateTime:match("^(%d+-%d+-%d+)")) -- Устанавливаем дату
    self.timeInput:SetText(dateTime:match("(%d+:%d+:%d+)$")) -- Устанавливаем время
end

function SettingsWidget:setHandlerForSynchButton(sycnhFunction)
    self.startSyncButton:SetScript("OnClick", sycnhFunction)
end