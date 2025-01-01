SettingsWidget = {}
SettingsWidget.__index = SettingsWidget

--Конструктор 
function SettingsWidget:new()
    local obj = setmetatable({}, SettingsWidget)
    obj.frame = CreteMainFrameUi("SettingsFrame", 300, 300, "HIGH", "Настройки");

    -- Чекбокс 1: Синхронизация записей с друзьями
    obj.syncWithFriendsCheckbox = CreateFrame("CheckButton", "SyncWithFriendsCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithFriendsCheckbox:SetPoint("TOPLEFT", 20, -30)
    obj.syncWithFriendsCheckbox.text = obj.syncWithFriendsCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithFriendsCheckbox.text:SetPoint("LEFT", obj.syncWithFriendsCheckbox, "RIGHT", 5, 0)
    obj.syncWithFriendsCheckbox.text:SetText("Синхронизация записей с друзьями")
    obj.syncWithFriendsCheckbox:SetScript("OnClick", function(self)
        if not UserSettings.SyncWithMe then
            self:SetChecked(false) -- Запретить включение, если третий чекбокс выключен
            print("Невозможно включить синхронизацию с друзьями: разрешение синхронизации отключено")
            return
        end
    
        UserSettings.SyncWithFriends = self:GetChecked() == 1
        print("Синхронизация с друзьями: " .. tostring(UserSettings.SyncWithFriends))
    end)

    -- Чекбокс 2: Синхронизация записей с согильдейцами
    obj.syncWithGuildCheckbox = CreateFrame("CheckButton", "SyncWithGuildCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithGuildCheckbox:SetPoint("TOPLEFT", 20, -60)
    obj.syncWithGuildCheckbox.text = obj.syncWithGuildCheckbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithGuildCheckbox.text:SetPoint("LEFT", obj.syncWithGuildCheckbox, "RIGHT", 5, 0)
    obj.syncWithGuildCheckbox.text:SetText("Синхронизация записей с согильдейцами")
    
    obj.syncWithGuildCheckbox:SetScript("OnClick", function(self)
        if not UserSettings.SyncWithMe then
            self:SetChecked(false) -- Запретить включение, если третий чекбокс выключен
            print("Невозможно включить синхронизацию с согильдейцами: разрешение синхронизации отключено")
            return
        end
        UserSettings.SyncWithGuild = self:GetChecked() == 1;
        print("Синхронизация с согильдейцами: " .. tostring(UserSettings.SyncWithGuild))
    end)


    -- Чекбокс 3: Разрешить синхронизацию со мной
    obj.syncWithMe = CreateFrame("CheckButton", "SyncWithGuildCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.syncWithMe:SetPoint("TOPLEFT", 20, -90)
    obj.syncWithMe.text = obj.syncWithMe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.syncWithMe.text:SetPoint("LEFT", obj.syncWithMe, "RIGHT", 5, 0)
    obj.syncWithMe.text:SetText("Разрешить синхронизацию со мной")
    
    obj.syncWithMe:SetScript("OnClick", function(self)
        UserSettings.SyncWithMe = self:GetChecked() == 1;
        print("Синхронизация со мной: " .. tostring(UserSettings.SyncWithMe))
        if not UserSettings.SyncWithMe then
            -- Отключаем первые два чекбокса, если "синхронизация со мной" выключена
            obj.syncWithFriendsCheckbox:SetChecked(false)
            UserSettings.SyncWithFriends = false
            obj.syncWithGuildCheckbox:SetChecked(false)
            UserSettings.SyncWithGuild = false
    
            print("Синхронизация с друзьями и согильдейцами отключена из-за запрета синхронизации")
        end
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


    -- Чекбокс 4: Сообщения отладки в чат
    obj.debugPrintCheck = CreateFrame("CheckButton", "SyncWithGuildCheckbox", obj.frame, "UICheckButtonTemplate")
    obj.debugPrintCheck:SetPoint("TOPLEFT", 20, -150)
    obj.debugPrintCheck.text = obj.debugPrintCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    obj.debugPrintCheck.text:SetPoint("LEFT", obj.debugPrintCheck, "RIGHT", 5, 0)
    obj.debugPrintCheck.text:SetText("Показывать отладочные сообщения")
    obj.debugPrintCheck:SetScript("OnClick", function(self)
        UserSettings.debugPrint = self:GetChecked() == 1;
    end)


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
    self.syncWithMe:SetChecked(UserSettings.SyncWithMe)
    self.debugPrintCheck:SetChecked(UserSettings.debugPrint)
end