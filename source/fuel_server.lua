RegisterServerEvent('fuel-bidon:RequestPaid')
AddEventHandler('fuel-bidon:RequestPaid', function(price)
	local source = source	
    local license = GetPlayerIdentifiers(source)[1]
	local amount = Round(price)

	TriggerEvent('GTA_Inventaire:GetItemQty', source, "cash", function(qtyItem, itemid)
		if qtyItem >= amount then
			TriggerEvent('GTA:RetirerArgentPropre', source, tonumber(amount))
			TriggerClientEvent('Fuel-Bidon:OnSuccessPaid', source)
		else
			TriggerClientEvent("GTAO:NotificationIcon", source, "CHAR_BANK_MAZE", "Maze Bank", "Paiement refuser", "vous n'avez pas assez d'argent sur vous.")
		end
	end)
end)

RegisterServerEvent('fuel-bidon:RequestFill')
AddEventHandler('fuel-bidon:RequestFill', function(price)
	local source = source	
    local license = GetPlayerIdentifiers(source)[1]
	local amount = Round(price)

	TriggerEvent('GTA_Inventaire:GetItemQty', source, "cash", function(qtyItem, itemid)
		if qtyItem >= amount then
			TriggerEvent('GTA:RetirerArgentPropre', source, tonumber(amount))
			TriggerClientEvent('Fuel-Bidon:OnSuccessFill', source)
		else
			TriggerClientEvent("GTAO:NotificationIcon", source, "CHAR_BANK_MAZE", "Maze Bank", "Paiement refuser", "vous n'avez pas assez d'argent sur vous.")
		end
	end)
end)

RegisterServerEvent('fuel-vehicle:RequestPaid')
AddEventHandler('fuel-vehicle:RequestPaid', function(isNearPump, ped, vehicle)
	local source = source	
    local license = GetPlayerIdentifiers(source)[1]

	local extraCost = Config.PrixPleinEssence / 2 * Config.MultiplicateurDeCouts
	local amount = Round(extraCost)

	TriggerEvent('GTA_Inventaire:GetItemQty', source, "cash", function(qtyItem, itemid)
		if qtyItem >= amount then
			TriggerEvent('GTA:RetirerArgentPropre', source, tonumber(amount))
			TriggerClientEvent('fuel-vehicle:onSuccessPaid', source, isNearPump, ped, vehicle)
		else
			TriggerClientEvent('fuel-vehicle:onFailPaid', source)
			TriggerClientEvent("GTAO:NotificationIcon", source, "CHAR_BANK_MAZE", "Maze Bank", "Paiement refuser", "vous n'avez pas assez d'argent sur vous.")
		end
	end)
end)