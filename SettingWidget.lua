print("---------------------Файл SettingWidget загружен.")

SettingsWidget = {}
SettingsWidget.__index = SettingsWidget

--Конструктор 
function SettingsWidget:new()
    local obj = setmetatable({}, SettingsWidget)
    obj.frame = CreteMainFrameUi("SettingsFrame", 300, 200, "HIGH", "Настройки");
    return obj
end

