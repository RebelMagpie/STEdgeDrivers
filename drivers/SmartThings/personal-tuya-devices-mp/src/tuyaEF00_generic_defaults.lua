local log = require "log"
local utils = require "st.utils"

local zcl_clusters = require "st.zigbee.zcl.clusters"
local tuya_types = require "st.zigbee.generated.zcl_clusters.TuyaEF00.types"
local device_lib = require "st.device"

local tuyaEF00_defaults = require "tuyaEF00_defaults"
local myutils = require "utils"
local commands = require "commands"

local capabilities = require "st.capabilities"
local info = capabilities["valleyboard16460.info"]

local datapoint_types_to_fn = {
  switchDatapoints = commands.switch,
  switchLevelDatapoints = commands.switchLevel,
  airQualitySensDatapoints = commands.airQualitySensor,
  buttonDatapoints = commands.button,
  carbonDioxideMDatapoints = commands.carbonDioxideMeasurement,
  contactSensorDatapoints = commands.contactSensor,
  doorControlDatapoints = commands.doorControl,
  formaldehydeMeDatapoints = commands.formaldehydeMeasurement,
  humidityMeasurDatapoints = commands.relativeHumidityMeasurement,
  illuminanceMeaDatapoints = commands.illuminanceMeasurement,
  motionSensorDatapoints = commands.motionSensor,
  occupancySensoDatapoints = commands.occupancySensor,
  presenceSensorDatapoints = commands.presenceSensor,
  temperatureMeaDatapoints = commands.temperatureMeasurement,
  tvocMeasuremenDatapoints = commands.tvocMeasurement,
  valveDatapoints = commands.valve,
  waterSensorDatapoints = commands.waterSensor,
  enumerationDatapoints = commands.enum,
  valueDatapoints = commands.value,
  stringDatapoints = commands.string,
  bitmapDatapoints = commands.bitmap,
  rawDatapoints = commands.raw,
}

local child_types_to_profile = {
  switchDatapoints = "child-switch-v1",
  switchLevelDatapoints = "child-switchLevel-v1",
  airQualitySensDatapoints = "child-airQualitySensor-v1",
  buttonDatapoints = "child-button-v1",
  carbonDioxideMDatapoints = "child-carbonDioxideMeasurement-v1",
  contactSensorDatapoints = "child-contactSensor-v1",
  doorControlDatapoints = "child-doorControl-v1",
  formaldehydeMeDatapoints = "child-formaldehydeMeasurement-v1",
  humidityMeasurDatapoints = "child-relativeHumidityMeasurement-v1",
  illuminanceMeaDatapoints = "child-illuminanceMeasurement-v1",
  motionSensorDatapoints = "child-motionSensor-v1",
  occupancySensoDatapoints = "child-occupancySensor-v1",
  presenceSensorDatapoints = "child-presenceSensor-v1",
  temperatureMeaDatapoints = "child-temperatureMeasurement-v1",
  tvocMeasuremenDatapoints = "child-tvocMeasurement-v1",
  valveDatapoints = "child-valve-v1",
  waterSensorDatapoints = "child-waterSensor-v1",
  enumerationDatapoints = "child-enum-v1",
  stringDatapoints = "child-string-v1",
  valueDatapoints = "child-value-v1",
  bitmapDatapoints = "child-bitmap-v1",
  rawDatapoints = "child-raw-v1",
}

local type_to_configuration = {
  [tuya_types.DatapointSegmentType.BOOLEAN] = "switchDatapoints",
  [tuya_types.DatapointSegmentType.VALUE] = "valueDatapoints",
  [tuya_types.DatapointSegmentType.STRING] = "stringDatapoints",
  [tuya_types.DatapointSegmentType.ENUM] = "enumerationDatapoints",
  [tuya_types.DatapointSegmentType.BITMAP] = "bitmapDatapoints",
  [tuya_types.DatapointSegmentType.RAW] = "rawDatapoints",
}

local function get_datapoints_from_device (device)
  local output,num = {},0
  for name, def in pairs(datapoint_types_to_fn) do
    if device.preferences[name] ~= nil then
      for dpid in device.preferences[name]:gmatch("[^,]+") do
        local ndpid = tonumber(dpid, 10)
        if output[ndpid] == nil then
          num=num+1
        end
        output[ndpid] = def({group=ndpid})
      end
    end
  end
  return output,num
end

local function get_datapoints_from_messages (list)
  local output,num = {},0
  for _, zb_rx in pairs(list) do
    local body = zb_rx.body.zcl_body.data
    if output[body.dpid.value] == nil then
      num=num+1
    end
    output[body.dpid.value] = datapoint_types_to_fn[type_to_configuration[body.type.value]]({group=body.dpid.value})
  end
  return output,num
end

local temporary_datapoints = {}

local function send_command(fn, driver, device, ...)
  local datapoints,total = get_datapoints_from_device(device.parent_assigned_child_key ~= nil and device:get_parent_device() or device)
  if total > 0 then
    fn(datapoints)(driver, device, ...)
  end
end

local lifecycle_handlers = {}

function lifecycle_handlers.added(driver, device, event, ...)
  if device.network_type == device_lib.NETWORK_TYPE_CHILD then
  -- if device.parent_assigned_child_key ~= nil then
    local tmp = temporary_datapoints[device.parent_device_id]
    local dpid = tonumber(device.parent_assigned_child_key, 16)
    if tmp ~= nil and tmp[dpid] ~= nil then
      send_command(tuyaEF00_defaults.command_response_handler, driver, device:get_parent_device(), tmp[dpid])
    else
      log.warn("Unable to update status of newly added child device", device.parent_assigned_child_key, device.parent_device_id, tmp ~= nil)
    end
  end
end

function lifecycle_handlers.infoChanged (driver, device, event, args)
  if args.old_st_store.preferences.profile ~= device.preferences.profile then
    device:try_update_metadata({
      profile = device.preferences.profile:gsub("_", "-")
    })
  end

  if device.network_type == device_lib.NETWORK_TYPE_ZIGBEE then
    for name, value in pairs(device.preferences) do
      local profile = child_types_to_profile[name]
      if profile ~= nil and value and value ~= args.old_st_store.preferences[name] then
        for ndpid in value:gmatch("[^,]+") do
          myutils.create_child(driver, device, tonumber(ndpid, 10), profile)
        end
      end
    end
  end
end

-- devices that use 0xEF00 but doesn't expose it
local exceptions = {
  "_TZE200_znbl8dj5"
}

local function in_exception_list (device)
  for _,mfr in ipairs(exceptions) do
    if mfr == device:get_manufacturer() then
      return true
    end
  end
  return false
end

local defaults = {
  lifecycle_handlers = lifecycle_handlers
}

function defaults.can_handle (opts, driver, device, ...)
  return device:supports_server_cluster(zcl_clusters.tuya_ef00_id) or in_exception_list(device)
end

function defaults.command_response_handler(driver, device, zb_rx)
  if temporary_datapoints[device.id] == nil then
    temporary_datapoints[device.id] = {}
  end
  if device.preferences ~= nil and device.preferences.updateInfo then
    local ndpid = zb_rx.body.zcl_body.data.dpid.value
    -- local _type = zb_rx.body.zcl_body.data.type
    -- local value = zb_rx.body.zcl_body.data.value.value
    temporary_datapoints[device.id][ndpid] = zb_rx
    device:emit_event(info.value(tostring(myutils.info(device, temporary_datapoints[device.id])), { visibility = { displayed = false } }))
  end

  send_command(tuyaEF00_defaults.command_response_handler, driver, device, zb_rx)
end

function defaults.capability_handler(...)
  send_command(tuyaEF00_defaults.capability_handler, ...)
end

function defaults.register_for_default_handlers(driver, capabilities)
  driver.capability_handlers = driver.capability_handlers or {}
  for _,cap in ipairs(capabilities) do
    driver.capability_handlers[cap.ID] = driver.capability_handlers[cap.ID] or {}
    for _,command in pairs(cap.commands) do
      driver.capability_handlers[cap.ID][command.NAME] = driver.capability_handlers[cap.ID][command.NAME] or defaults.capability_handler
    end
  end
end

return defaults