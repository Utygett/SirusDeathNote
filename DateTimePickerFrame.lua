-- Функция для создания виджета выбора даты и времени
function CreateDateTimePicker(title, initialDateTime, onConfirm)
    local frame = CreteMainFrameUi("DateTimePicker", 300, 200, "DIALOG", title)
    -- Сохраняем дату и время начало синхронизации в настройки
    UserSettings.dateTimeForSynch = initialDateTime

    -- Поле для ввода даты
    local dateInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    dateInput:SetSize(120, 30)
    dateInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -50)
    dateInput:SetAutoFocus(false)
    dateInput:SetText(initialDateTime:match("^(%d+-%d+-%d+)")) -- Устанавливаем начальную дату
    dateInput:SetScript("OnEscapePressed", dateInput.ClearFocus)

    local dateLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    dateLabel:SetPoint("LEFT", dateInput, "RIGHT", 10, 0)
    dateLabel:SetText("ГГГГ-ММ-ДД")

    -- Поле для ввода времени
    local timeInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    timeInput:SetSize(80, 30)
    timeInput:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -90)
    timeInput:SetAutoFocus(false)
    timeInput:SetText(initialDateTime:match("(%d+:%d+:%d+)$")) -- Устанавливаем начальное время
    timeInput:SetScript("OnEscapePressed", timeInput.ClearFocus)

    local timeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeLabel:SetPoint("LEFT", timeInput, "RIGHT", 10, 0)
    timeLabel:SetText("ЧЧ:ММ:СС")

    -- Кнопка подтверждения
    local confirmButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    confirmButton:SetSize(80, 30)
    confirmButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    confirmButton:SetText("Принять")
    confirmButton:SetEnabled(false) -- По умолчанию кнопка отключена
    confirmButton:SetScript("OnClick", function()
        local date = dateInput:GetText()
        local time = timeInput:GetText()
        local fullDateTime = date .. " " .. time
        if onConfirm then
            onConfirm(fullDateTime) -- Вызываем callback с полной строкой даты
        end
        frame:Hide()
    end)

    -- Кнопка отмены
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(80, 30)
    cancelButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    cancelButton:SetText("Отмена")
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Функция проверки формата даты и времени
    local function ValidateInputs()
        local date = dateInput:GetText()
        local time = timeInput:GetText()

        -- Проверяем формат даты и времени с помощью регулярных выражений
        local dateValid = date:match("^%d%d%d%d%-%d%d%-%d%d$")
        local timeValid = time:match("^%d%d:%d%d:%d%d$")

        if dateValid and timeValid then
            confirmButton:SetEnabled(true) -- Включаем кнопку
        else
            confirmButton:SetEnabled(false) -- Отключаем кнопку
        end
    end

    -- Привязываем проверку к изменениям в полях ввода
    dateInput:SetScript("OnTextChanged", ValidateInputs)
    timeInput:SetScript("OnTextChanged", ValidateInputs)

    return frame, dateInput, timeInput
end
