local isNearPump = false
local isFueling = false
local currentFuel = 0.0
local fuelSynced = false
local inBlacklisted = false

function ManageFuelUsage(vehicle)
	if not DecorExistOn(vehicle, Config.FuelDecor) then
		SetFuel(vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
		SetFuel(vehicle, GetFuel(vehicle))

		fuelSynced = true
	end

	if IsVehicleEngineOn(vehicle) then
		SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - Config.FuelUsage[Round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.Classes[GetVehicleClass(vehicle)] or 1.0) / 10)
	end
end

Citizen.CreateThread(function()
	DecorRegister(Config.FuelDecor, 1)

	for index = 1, #Config.Blacklist do
		if type(Config.Blacklist[index]) == 'string' then
			Config.Blacklist[GetHashKey(Config.Blacklist[index])] = true
		else
			Config.Blacklist[Config.Blacklist[index]] = true
		end
	end

	for index = #Config.Blacklist, 1, -1 do
		table.remove(Config.Blacklist, index)
	end

	while true do
		Citizen.Wait(1000)

		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped)

			if Config.Blacklist[GetEntityModel(vehicle)] then
				inBlacklisted = true
			else
				inBlacklisted = false
			end

			if not inBlacklisted and GetPedInVehicleSeat(vehicle, -1) == ped then
				ManageFuelUsage(vehicle)
			end
		else
			if fuelSynced then
				fuelSynced = false
			end

			if inBlacklisted then
				inBlacklisted = false
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(250)

		local pumpObject, pumpDistance = FindNearestFuelPump()

		if pumpDistance < 2.5 then
			isNearPump = pumpObject
		else
			isNearPump = false

			Citizen.Wait(math.ceil(pumpDistance * 20))
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()

		if not isFueling and ((isNearPump and GetEntityHealth(isNearPump) > 0) or (GetSelectedPedWeapon(ped) == 883325847 and not isNearPump)) then
			if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
				local pumpCoords = GetEntityCoords(isNearPump)

				DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, "Veuillez sortir du véhicule pour faire le plein")
			else
				local vehicle = GetPlayersLastVehicle()
				local vehicleCoords = GetEntityCoords(vehicle)

				if DoesEntityExist(vehicle) and GetDistanceBetweenCoords(GetEntityCoords(ped), vehicleCoords) < 2.5 then
					if not DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) then
						local stringCoords = GetEntityCoords(isNearPump)
						local canFuel = true

						if GetSelectedPedWeapon(ped) == 883325847 then
							stringCoords = vehicleCoords

							if GetAmmoInPedWeapon(ped, 883325847) < 100 then
								canFuel = false
							end
						end

						if GetVehicleFuelLevel(vehicle) < 95 and canFuel then
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "~g~E ~w~pour faire le plein du véhicule")

							if IsControlJustReleased(0, 38) then
								TriggerServerEvent('fuel-vehicle:RequestPaid', isNearPump, ped, vehicle)
							end
						elseif not canFuel then
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "Le bidon d'essence est vide")
						else
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "Le réservoir est plein")
						end
					end
				elseif isNearPump then
					local stringCoords = GetEntityCoords(isNearPump)
					if not HasPedGotWeapon(ped, 883325847) then
						DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "~g~E ~w~ acheter un bidon d'essence pour ~g~$" .. Config.PrixBidonEssence)

						if IsControlJustReleased(0, 38) then
							TriggerServerEvent('fuel-bidon:RequestPaid', Config.PrixBidonEssence)
						end
					else
						DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "~g~E ~w~ pour remplir le bidon d'essence")

						if IsControlJustReleased(0, 38) then
							TriggerServerEvent('fuel-bidon:RequestFill', Config.PrixBidonEssence)
						end
					end
				else
					Citizen.Wait(250)
				end
			end
		else
			Citizen.Wait(250)
		end

		Citizen.Wait(0)
	end
end)


--> Show all station blip :
Citizen.CreateThread(function()
	for _, v in pairs(Config.GasStations) do
		CreateBlip(v)
	end
end)

---------------------------------------------------------------------
							--HUD--
---------------------------------------------------------------------

local fuel = 0
local enableHud = false
local isPaused = false
local playerWantDisableHUD = false
Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped) and not (Config.RemoveHUDForBlacklistedVehicle and inBlacklisted) then
			local vehicle = GetVehiclePedIsIn(ped)
			fuel = tostring(math.ceil(GetVehicleFuelLevel(vehicle)))
			if not isPaused and playerWantDisableHUD == false then
				enableHud = true
			end
		else
			enableHud = false

			Citizen.Wait(500)
		end

		Citizen.Wait(50)
	end
end)

-- FUNCTIONS
--Chargement en boucle pour actualisé vos status Faim/Soif
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(300)
		SendNUIMessage({
			type = "vfuel",
			data_hudOn = enableHud,
			data_newFuel = fuel
		})
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(300)
		if IsPauseMenuActive() and not isPaused then
			isPaused = true
			enableHud = false
		elseif not IsPauseMenuActive() and isPaused then
			isPaused = false
			enableHud = true
		end
	end
end)



function GetFuel(vehicle)
	return DecorGetFloat(vehicle, Config.FuelDecor)
end

function SetFuel(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, Config.FuelDecor, GetVehicleFuelLevel(vehicle))
	end
end

function LoadAnimDict(dict)
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)

		while not HasAnimDictLoaded(dict) do
			Citizen.Wait(1)
		end
	end
end

function DrawText3Ds(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)

	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x,_y)
	end
end

function CreateBlip(coords)
	local blip = AddBlipForCoord(coords)

	SetBlipSprite(blip, 361)
	SetBlipScale(blip, 0.9)
	SetBlipColour(blip, 4)
	SetBlipDisplay(blip, 4)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Station Essence")
	EndTextCommandSetBlipName(blip)

	return blip
end

function FindNearestFuelPump()
	local coords = GetEntityCoords(PlayerPedId())
	local fuelPumps = {}
	local handle, object = FindFirstObject()
	local success

	repeat
		if Config.PumpModels[GetEntityModel(object)] then
			table.insert(fuelPumps, object)
		end

		success, object = FindNextObject(handle, object)
	until not success

	EndFindObject(handle)

	local pumpObject = 0
	local pumpDistance = 1000

	for _, fuelPumpObject in pairs(fuelPumps) do
		local dstcheck = GetDistanceBetweenCoords(coords, GetEntityCoords(fuelPumpObject))

		if dstcheck < pumpDistance then
			pumpDistance = dstcheck
			pumpObject = fuelPumpObject
		end
	end

	return pumpObject, pumpDistance
end


RegisterNetEvent("Fuel-Bidon:OnSuccessPaid")
AddEventHandler("Fuel-Bidon:OnSuccessPaid", function()
	local ped = PlayerPedId()
	GiveWeaponToPed(ped, 883325847, 4500, false, true)
end)

RegisterNetEvent("Fuel-Bidon:OnSuccessFill")
AddEventHandler("Fuel-Bidon:OnSuccessFill", function()
	local ped = PlayerPedId()
	SetPedAmmo(ped, 883325847, 4500)
end)


RegisterNetEvent("fuel-vehicle:onSuccessPaid")
AddEventHandler("fuel-vehicle:onSuccessPaid", function(pumpObject, ped, vehicle)
	isFueling = true
	LoadAnimDict("timetable@gardener@filling_can")
	TaskTurnPedToFaceEntity(ped, vehicle, 1000)
	Citizen.Wait(1000)
	SetCurrentPedWeapon(ped, -1569615261, true)
	LoadAnimDict("timetable@gardener@filling_can")
	TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)

	TriggerEvent('fuel:startFuelUpTick', pumpObject, ped, vehicle)

	while isFueling do
		for _, controlIndex in pairs(Config.DisableKeys) do
			DisableControlAction(0, controlIndex)
		end

		local vehicleCoords = GetEntityCoords(vehicle)

		if pumpObject then
			local stringCoords = GetEntityCoords(pumpObject)

			DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, "~g~E ~w~pour annuler.")
			DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, Round(currentFuel, 1) .. "%")
		else
			DrawText3Ds(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 0.5, "~g~E ~w~pour annuler." .. "\nBidon d'essence: ~g~" .. Round(GetAmmoInPedWeapon(ped, 883325847) / 4500 * 100, 1) .. "% | Véhicule: " .. Round(currentFuel, 1) .. "%")
		end

		if not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
			TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
		end

		if IsControlJustReleased(0, 38) or DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) or (isNearPump and GetEntityHealth(pumpObject) <= 0) then
			isFueling = false
		end

		Citizen.Wait(0)
	end

	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
end)

RegisterNetEvent("fuel-vehicle:onFailPaid")
AddEventHandler("fuel-vehicle:onFailPaid", function()
	isFueling = false
end)

AddEventHandler('fuel:startFuelUpTick', function(pumpObject, ped, vehicle)
	currentFuel = GetVehicleFuelLevel(vehicle)

	while isFueling do
		Citizen.Wait(500)

		local oldFuel = DecorGetFloat(vehicle, Config.FuelDecor)
		local fuelToAdd = math.random(10, 20) / 10.0

		if not pumpObject then
			if GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100 >= 0 then
				currentFuel = oldFuel + fuelToAdd

				SetPedAmmo(ped, 883325847, math.floor(GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100))
			else
				isFueling = false
			end
		else
			currentFuel = oldFuel + fuelToAdd
		end

		if currentFuel > 100.0 then
			currentFuel = 100.0
			isFueling = false
		end

		SetFuel(vehicle, currentFuel)
	end
end)


RegisterNetEvent("fuel-vehicle:AfficherHud")
AddEventHandler("fuel-vehicle:AfficherHud", function(bool)
	if bool == true then
		playerWantDisableHUD = false
		enableHud = true
	else
		playerWantDisableHUD = true
		enableHud = false
	end

end)
