QBCore = exports['qb-core']:GetCoreObject()
PlayerData = QBCore.Functions.GetPlayerData() or {}
IsLoggedIn = LocalPlayer.state.isLoggedIn
local inHelicopter, inGarage, inPrompt = false, false, false

----------
-- Blip --
----------

CreateThread(function()
	if Config.UseBlips then
		blip = AddBlipForCoord(-597.89, -929.95, 24.0)
		SetBlipSprite(blip, 459)
		SetBlipDisplay(blip, 4)
		SetBlipScale(blip, 1.0)	
		SetBlipColour(blip, 1)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Weazel News HQ")
		EndTextCommandSetBlipName(blip)
	end
end)

--------------
-- Handlers --
--------------

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()

    if PlayerData.job.onduty then
        if PlayerData.job.name == "reporter" then
            TriggerServerEvent("QBCore:ToggleDuty")
        end
    end

    IsLoggedIn = true
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    if JobInfo.name == 'reporter' and PlayerData.job.name ~= 'reporter' then
        if JobInfo.onduty then
            TriggerServerEvent("QBCore:ToggleDuty")
        end
    end

    PlayerData.job = JobInfo
end)

---------------
-- Functions --
---------------

local function TakeOutVehicle(vehicleInfo)
    if not inGarage then return end
    if PlayerData.job.name == "reporter" and PlayerData.job.onduty then
        local coords = Config.Locations.vehicle.coords
        if not coords then
            local plyCoords = GetEntityCoords(cache.ped)
            coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, GetEntityHeading(cache.ped))
        end
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleNumberPlateText(veh, "WZNW"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            if Config.Fuel then
                exports[Config.Fuel]:SetFuel(veh, 100.0)
            else
                exports['LegacyFuel']:SetFuel(veh, 100.0)
            end
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
            SetVehicleLivery(veh, 2)
            CurrentPlate = QBCore.Functions.GetPlate(veh)
        end, vehicleInfo, coords, true)
    end
end

local function MenuGarage()
    local vehicleMenu = {}

    local Vehicles = Config.Vehicles[PlayerData.job.grade.level]
    for veh, label in pairs(Vehicles) do
        vehicleMenu[#vehicleMenu + 1] = {
            title = label,
            image = "https://media.discordapp.net/attachments/434167856993927178/1092449480781082724/Weazel-news-rumpo-white-front-gtav.png",
            onSelect = function()
                TakeOutVehicle(veh)
            end,
        }
    end

    lib.registerContext({
        id = "weazel_news_vehicle_menu",
        title = "Weazel News Vehicles",
        onExit = function()
            lib.hideContext()
        end,
        position = "top-right",
        options = vehicleMenu
    })
    lib.showContext('weazel_news_vehicle_menu')
end

local function TakeOutHelicopters(vehicleInfo)
    if not inHelicopter then return end
    if PlayerData.job.name == "reporter" and PlayerData.job.onduty then
        local coords = Config.Locations.heli.coords
        if not coords then
            local plyCoords = GetEntityCoords(cache.ped)
            coords = vec4(plyCoords.x, plyCoords.y, plyCoords.z, GetEntityHeading(cache.ped))
        end
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleLivery(veh, 2)
            SetVehicleNumberPlateText(veh, "WZNW"..tostring(math.random(1000, 9999)))
            SetEntityHeading(veh, coords.w)
            if Config.Fuel then
                exports[Config.Fuel]:SetFuel(veh, 100.0)
            else
                exports['LegacyFuel']:SetFuel(veh, 100.0)
            end
            TaskWarpPedIntoVehicle(cache.ped, veh, -1)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
        end, vehicleInfo, coords, true)
    end
end

local function MenuHeliGarage()
    local vehicleMenu = {}

    local Helicopters = Config.Helicopters[PlayerData.job.grade.level]
    for veh, label in pairs(Helicopters) do
        vehicleMenu[#vehicleMenu + 1] = {
            title = label,
            image = 'https://media.discordapp.net/attachments/434167856993927178/1092454561475727392/Frogger-GTAV-front.png?width=1246&height=701',
            onSelect = function()
                TakeOutHelicopters(veh)
            end,
        }
    end

    lib.registerContext({
        id = "news_heli_menu",
        title = "Weazel News Helicopter",
        onExit = function()
            lib.hideContext()
        end,
        options = vehicleMenu
    })
    lib.showContext('news_heli_menu')
end

local function uiPrompt(promptType, id)
    if PlayerData.job.name ~= 'reporter' then return end

    CreateThread(function()
        while inPrompt do
            Wait(3)
            if IsLoggedIn then
                if IsControlPressed(0, 38) then
                    if promptType == 'garage' then
                        if not inGarage then return end
                        if cache.vehicle then
                            QBCore.Functions.DeleteVehicle(cache.vehicle)
                            lib.hideTextUI()
                            break
                        else
                            MenuGarage()
                            lib.hideTextUI()
                            break
                        end
                    elseif promptType == 'heli' then
                        if not inHelicopter then return end
                        if cache.vehicle then
                            QBCore.Functions.DeleteVehicle(cache.vehicle)
                            lib.hideTextUI()
                            break
                        else
                            MenuHeliGarage()
                            lib.hideTextUI()
                            break
                        end
                    end
                end
            end
        end
    end)
end

RegisterNetEvent("newsjob:shop", function()
    if not PlayerData.job.onduty then TriggerEvent('QBCore:Notify', "Not clocked in!", 'error') else
        exports.ox_inventory:openInventory("shop", {type = 'reporterShop'})
    end
end)

CreateThread(function()
    for k, v in pairs(Config.Locations.duty) do
        exports['qb-target']:AddBoxZone("Duty_"..k, vector3(v.x, v.y, v.z), 1, 0.8, {
            name = "Duty_"..k,
            heading = 0,
            debugPoly = Config.Debug,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        }, {
            options = {
                {  
                    type = "server",
                    event = "QBCore:ToggleDuty",
                    icon = "far fa-clipboard",
                    label = "Clock On/Off",
                    job = "reporter",
                },
            },
            distance = 1.5
        })
    end
end)

CreateThread(function()
    for k, v in pairs(Config.Locations.shop) do
        exports['qb-target']:AddBoxZone("NewsArmory_"..k, vector3(v.x, v.y, v.z), 1, 5.6, {
            name = "NewsArmory_"..k,
            heading = 0,
            debugPoly = Config.Debug,
            minZ = v.z - 1,
            maxZ = v.z + 1.5,
        }, {
            options = {
                {  
                    type = "client",
                    event = "newsjob:shop",
                    icon = "fas fa-basket-shopping",
                    label = "Open Armory",
                    job = "reporter",
                },
            },
        })
    end
end)

CreateThread(function()
    exports['qb-target']:AddBoxZone("NewsReport", vector3(-591.67, -937.14, 23.88), 1.2, 2.8, {
        name = "NewsReport",
        heading = 0,
        debugPoly = Config.Debug,
        minZ = 23.88 - 1,
        maxZ = 23.88 + 1,
    }, {
        options = {
            {  
                type = "client",
                event = "newspaper:client:openNewspaper",
                icon = "fas fa-newspaper",
                label = "Write Report",
                job = "reporter",
            },
        },
        distance = 1.5
    })
end)

---------------
-- Ox Zoning --
---------------

CreateThread(function()
    -- News Garage
    for k, v in pairs(Config.Locations.vehicle) do
        lib.zones.box({
            coords = v,
            size = vec3(4, 3, 2),
            rotation = 0.0,
            debug = Config.Debug,
            onEnter = function()
                if PlayerData.job.name == 'reporter' then
                    inGarage = true
                    inPrompt = true
                    if cache.vehicle then
                        lib.showTextUI('[E] Store Vehicle')
                    else
                        lib.showTextUI('[E] Vehicle Garage')
                    end
                    uiPrompt('garage')
                end
            end,
            onExit = function()
                inGarage = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end

    -- News Helicopter
    for k, v in pairs(Config.Locations.heli) do
        lib.zones.box({
            coords = v,
            size = vec3(5, 5, 4),
            rotation = 0.0,
            debug = Config.Debug,
            onEnter = function()
                if PlayerData.job.name == 'reporter' then
                    inHelicopter = true
                    inPrompt = true
                    if cache.vehicle then
                        lib.showTextUI('[E] Store Vehicle')
                    else
                        lib.showTextUI('[E] Helicopter Garage')
                    end
                    uiPrompt('heli')
                end
            end,
            onExit = function()
                inHelicopter = false
                inPrompt = false
                lib.hideTextUI()
            end
        })
    end
end)