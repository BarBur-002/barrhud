local vehiclesKHM = {}

Citizen.CreateThread(function()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), "vehicles.json")
    vehiclesKHM = json.decode(loadFile)

end)


RegisterServerEvent("ym-hud:server:vehiclesKHM")
AddEventHandler("ym-hud:server:vehiclesKHM", function(plate,kmh)
    if plate and kmh and type(vehiclesKHM) == 'table' then
        vehiclesKHM[plate] = kmh
        SaveResourceFile(GetCurrentResourceName(), "vehicles.json", json.encode(vehiclesKHM), -1)
        TriggerClientEvent("ym-hud:client:vehiclesKHM", -1, plate,kmh)
    end
end)

RegisterServerEvent("ym-hud:server:requestTable")
AddEventHandler("ym-hud:server:requestTable", function()
    TriggerClientEvent("ym-hud:client:vehiclesKHMTable", source, vehiclesKHM)
end)