--[[
    lc_fuel - Bridge File
    این فایل نوتیف‌ها رو به apex_notify و target رو به apex_target وصل می‌کنه
]]

-----------------------------------------------------------------------------------------------------------------------------------------
-- apex_notify Override
-- همه نوتیف‌های exports['lc_utils']:notify رو با apex_notify جایگزین می‌کنیم
-----------------------------------------------------------------------------------------------------------------------------------------

-- Override تابع notify از lc_utils
local originalLcUtils = exports['lc_utils']

-- تابع کمکی برای ارسال نوتیف با apex_notify
function LC_Notify(notifType, message)
    -- map کردن تایپ‌های lc_utils به apex_notify
    local typeMap = {
        ["success"] = "success",
        ["error"]   = "error",
        ["info"]    = "primary",
        ["warning"] = "warning",
    }
    local qbType = typeMap[notifType] or "primary"
    exports['apex_notify']:Custom({
        title = "⛽ پمپ بنزین",
        description = message,
        type = qbType,
        duration = 5000,
    })
end

-----------------------------------------------------------------------------------------------------------------------------------------
-- OX_TARGET برای پمپ‌های بنزین
-- این بخش جایگزین createGasMarkersThread و createElectricMarkersThread میشه
-----------------------------------------------------------------------------------------------------------------------------------------

function createOxTargetForGasPumps()
    local pumpModels = {}
    for _, v in pairs(Config.GasPumpProps) do
        table.insert(pumpModels, v.prop)
    end

    exports['apex_target']:addModel(pumpModels, {
        {
            label = Utils.translate('target.open_refuel'),
            icon = "fas fa-gas-pump",
            iconColor = "#a42100",
            onSelect = function(data)
                if not canOpenPumpUiTargetCallback() then return end
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)
                local pump, pumpModel = GetClosestPump(playerCoords, false)
                if pump then
                    clientOpenUI(pump, pumpModel, false)
                else
                    LC_Notify("error", Utils.translate("pump_not_found"))
                end
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canOpenPumpUiTargetCallback() and not mainUiOpen and not DoesEntityExist(fuelNozzle)
            end,
        },
        {
            label = Utils.translate('target.return_nozzle'),
            icon = "fas fa-rotate-left",
            iconColor = "#a42100",
            onSelect = function(data)
                if not canReturnNozzleTargetCallback() then return end
                returnNozzle()
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canReturnNozzleTargetCallback()
            end,
        },
    })
end

function createOxTargetForElectricChargers()
    if not Config.Electric or not Config.Electric.enabled then return end

    local chargerModels = {}
    for _, v in pairs(Config.Electric.chargersProps) do
        table.insert(chargerModels, v.prop)
    end

    exports['apex_target']:addModel(chargerModels, {
        {
            label = Utils.translate('target.open_refuel'),
            icon = "fas fa-bolt",
            iconColor = "#00a4e4",
            onSelect = function(data)
                if not canOpenPumpUiTargetCallback() then return end
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)
                local pump, pumpModel = GetClosestPump(playerCoords, true)
                if pump then
                    clientOpenUI(pump, pumpModel, true)
                else
                    LC_Notify("error", Utils.translate("pump_not_found"))
                end
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canOpenPumpUiTargetCallback() and not mainUiOpen and not DoesEntityExist(fuelNozzle)
            end,
        },
        {
            label = Utils.translate('target.return_nozzle'),
            icon = "fas fa-rotate-left",
            iconColor = "#00a4e4",
            onSelect = function(data)
                if not canReturnNozzleTargetCallback() then return end
                returnNozzle()
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canReturnNozzleTargetCallback()
            end,
        },
    })
end

-- apex_target برای تعامل با خودرو (اتصال و قطع شلنگ)
function createOxTargetForVehicleInteraction()
    local boneList = vehicleCapBoneList()

    exports['apex_target']:addGlobalVehicle({
        {
            label = Utils.translate("target.start_refuel"),
            icon = "fas fa-fill-drip",
            iconColor = "#a42100",
            bones = boneList,
            onSelect = function(data)
                if not canAttachNozzleTargetCallback(data.entity, data.distance) then return end
                executeRefuelActionFromTarget()
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canAttachNozzleTargetCallback(entity, distance)
            end,
        },
        {
            label = Utils.translate("target.stop_refuel"),
            icon = "fas fa-stop",
            iconColor = "#333",
            bones = boneList,
            onSelect = function(data)
                if not canDetachNozzleTargetCallback(data.entity, data.distance) then return end
                stopRefuelAction()
            end,
            canInteract = function(entity, distance, coords, name, bone)
                return canDetachNozzleTargetCallback(entity, distance)
            end,
        },
    })
end
