script_name("AntiBhop")
script_author("Deprau")

require 'lib.moonloader'
local events = require 'lib.samp.events'
local inicfg = require 'inicfg'

local config = inicfg.load({settings = {antibhop = true}}, "antibhop_deprau.ini")
local antibhop = config.settings.antibhop

function saveConfig()
    local data = {settings = {antibhop = antibhop}}
    inicfg.save(data, "antibhop_deprau.ini")
end

function main()
    while not isSampAvailable() do wait(0) end

    sampAddChatMessage("DEPRAU > {00ffcc}AntiBhop {ffffff}Loaded", -1)

    sampRegisterChatCommand("anb", function()
        antibhop = not antibhop
        saveConfig()
        sampAddChatMessage("DEPRAU > {00ffcc}AntiBhop {ffffff}" .. (antibhop and "ON" or "OFF"), -1)
    end)

    while true do wait(0) end
end

function events.onSendPlayerSync(data)
    if antibhop and data.keysData == 40 then
        data.keysData = 0
    end
end
