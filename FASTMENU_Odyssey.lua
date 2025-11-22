script_name("FastRUN")
script_author("Odyssey")

require("lib.moonloader")
local imgui = require("mimgui")
local inicfg = require("inicfg")
local encoding = require("encoding")
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local new = imgui.new

local walkSpeed = new.float(1.0)
local runSpeed = new.float(1.0)
local aimSpeed = new.float(1.0)
local windowVisible = new.bool(false)

local default_config = {
    fastrun = {
        walk = 1.0,
        run = 1.0,
        aim = 1.0
    }
}

local config_file = "FastRun_Config"
local config = inicfg.load(default_config, config_file)

walkSpeed[0] = config.fastrun.walk
runSpeed[0] = config.fastrun.run
aimSpeed[0] = config.fastrun.aim

local animsWalk = {
    "WALK_PLAYER", "WALK_CIVI", "WALK_ARMED", "WALK_DRUNK", "WALK_FAT", "WALK_FATOLD",
    "WALK_GANG1", "WALK_GANG2", "WALK_OLD", "WALK_SHUFFLE", "WALK_START", "WALK_WUZI",
    "WOMAN_WALKNORM", "WOMAN_WALKOLD", "WOMAN_WALKSEXY", "WOMAN_WALKSHOP", "WOMAN_WALKPRO", "WOMAN_WALKBUSY"
}

local animsRun = {
    "RUN_PLAYER", "RUN_CIVI", "RUN_GANG1", "RUN_GANG2", "RUN_FAT", "RUN_FATOLD",
    "RUN_ROCKET", "RUN_ARMED", "RUN_1ARMED"
}

local animsAim = {
    "GUNMOVE_L", "GUNMOVE_R", "GUNMOVE_FWD", "GUNMOVE_BWD"
}

local function applyAnimSpeeds()
    for _, anim in ipairs(animsWalk) do
        setCharAnimSpeed(PLAYER_PED, anim, walkSpeed[0])
    end
    for _, anim in ipairs(animsRun) do
        setCharAnimSpeed(PLAYER_PED, anim, runSpeed[0])
    end
    for _, anim in ipairs(animsAim) do
        setCharAnimSpeed(PLAYER_PED, anim, aimSpeed[0])
    end
end

local function saveConfig()
    config.fastrun.walk = walkSpeed[0]
    config.fastrun.run = runSpeed[0]
    config.fastrun.aim = aimSpeed[0]
    inicfg.save(config, config_file)
    sampAddChatMessage("{FFFFFF}Configuracion guardada correctamente.", -1)
end

local function applyTheme()
    local style = imgui.GetStyle()
    style.WindowRounding = 10
    style.FrameRounding = 6
    style.WindowPadding = imgui.ImVec2(15, 15)
    style.FramePadding = imgui.ImVec2(8, 6)
end

imgui.OnFrame(
    function() return windowVisible[0] end,
    function()
        applyTheme()

        local resX, resY = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(370, 220), imgui.Cond.FirstUseEver)

        imgui.Begin(u8"FastRUN Configuracion", windowVisible, imgui.WindowFlags.NoCollapse)

        imgui.SliderFloat(u8"Velocidad Caminar", walkSpeed, 1.0, 70.0, u8"%.2f")
        imgui.SliderFloat(u8"Velocidad Correr", runSpeed, 1.0, 70.0, u8"%.2f")
        imgui.SliderFloat(u8"Velocidad Apuntar", aimSpeed, 1.0, 70.0, u8"%.2f")
        imgui.Spacing()

        if imgui.Button(u8"Guardar configuracion", imgui.ImVec2(-1, 35)) then
            saveConfig()
        end

        imgui.End()
    end
)

function main()
    repeat wait(0) until isSampAvailable()

    sampRegisterChatCommand("fast", function()
        windowVisible[0] = not windowVisible[0]
        sampAddChatMessage("Menu " .. (windowVisible[0] and "ON" or "OFF"), -1)
    end)

    sampAddChatMessage("Usa /fast para abrir el menu.", -1)

    while true do
        wait(0)
        applyAnimSpeeds()
    end
end