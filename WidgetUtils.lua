print("---------------------Файл WidgetUtils загружен.")

function CreteMainFrameUi(frameName, width, height, frameStrate, title)
    local frame = CreateFrame("Frame", frameName, UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide() -- Скрываем окно по умолчанию
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata(frameStrate)

    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -2)
    frame.title:SetText(title)
    return frame
end

function DebugPrint(msg)
    if UserSettings.debugPrint == true then
        print(msg)
    end
end