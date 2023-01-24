## How to use

This driver is intended to work with devices that use **0xEF00** Tuya Cluster

### Install the driver

1. Accept the invitation ( ${{ env.INVITATION_LINK }} )
2. Enroll the hub
3. List available drivers
4. Install the driver ( Personal Tuya Devices )

### Pair the device

1. Open SmartThings App
2. Search for nearby devices
3. Set the device in pairing mode

<img src="resources/pairing_1.jpeg" height="300"/> <img src="resources/pairing_2.jpeg" height="300"/> <img src="resources/pairing_3.jpeg" height="300"/> <img src="resources/dashboard_1.jpeg" height="300"/>

### Configure datapoints

1. Open the detail view of the device
2. Open configurations
3. Fill the fields that meets the specified for the device
   - Search the internet about your device details (manufacturer and model)
   - You will find the same device or very similar ones working on other systems (Home Assistant, Hubitat, old Groovy DTHs, ...)
   - Similar devices usually use the same datapoints
   - There are configurations for some stock capabilities<br />
     Currently: switch, switchLevel, airQualitySensor, button, carbonDioxideMeasurement, contactSensor, doorControl, formaldehydeMeasurement, illuminanceMeasurement, motionSensor, occupancySensor, presenceSensor, relativeHumidityMeasurement, temperatureMeasurement, tvocMeasurement, valve and waterSensor
   - Also, there are configurations for generic Tuya Data Types<br />
     Currently: boolean (switch/sensors), enumeration, value, string, bitmap and raw
   - For example:
     - If you know the datapoint 1 is for a writable boolean, then add it to "Datapoints for switches"
     - If you know the datapoint 2 is for a read-only boolean, then add it to any sensor

<img src="resources/detailView_1.jpeg" height="300"/> <img src="resources/configuration_1.jpeg" height="300"/> <img src="resources/configuration_2.jpeg" height="300"/> <img src="resources/dashboard_2.jpeg" height="300"/> <img src="resources/child_detailView_2.jpeg" height="300"/>

### Contribute with your integration

1. Once you know exactly how your device works with each available datapoints, consider forking the repository and adding the code needed to make it a little more user friendly.
2. Create or use existing model name file at `/models`<br />
   - The model name must be the value reported by the device as seen in the screenshot above, not what is labeled in the box.
   - If model name file doesn't exist:<br />
     1. Duplicate `/models/TEMPLATE.yaml` and rename it with the model name.
   - If model name file already exists:<br />
     1. Map the datapoints of the device at `/models/MODEL.yaml`. Possible commands are at `/src/commands.lua`
     2. Create a profile that represents the device at `/profiles/normal-XXXXXXXXXXXXXXXXX-vX.yaml`
     3. Add fingerprint that represents the device at `/fingerprints.yaml`
3. Pull request your modification

#### Examples of including stock capabilities:

- https://github.com/w35l3y/EdgeDrivers/commit/1c6708f6c48790cae2be812ad668a01c71884836
- https://github.com/w35l3y/EdgeDrivers/commit/013d41ca525106162134223fb2cd826b5bc01918
- https://github.com/w35l3y/EdgeDrivers/commit/cdf8a6f023cd4b54fcc60136f3c9885164bae14f

### Current devices tested with this driver

| Model  | Manufacturer      | Description      |
| ------ | ----------------- | ---------------- |
| TS0601 | \_TZE200_1n2kyphz | 4 multi switches |
| TS0601 | \_TZE200_8ygsuhe1 | air quality      |
| TS0601 | \_TZE200_9mahtqtg | 6 multi switches |
| TS0601 | \_TZE200_dwcarsat | air quality      |
| TS0601 | \_TZE200_e3oitdyu | 2 multi dimmers  |
| TS0601 | \_TZE200_r731zlxk | 6 multi switches |
| TS0601 | \_TZE200_wfxuhoea | garage door      |
| TS0601 | \_TZE200_ikvncluo | presence sensor  |
| TS0601 | \_TZE200_yvx5lh6k | air quality      |
| TS0601 | \_TZE200_ztc6ggyl | presence sensor  |
| TS0601 | \_TZE204_ztc6ggyl | presence sensor  |

### Known issues

- **Some child devices weren't created**<br />
  Sometimes, when modifying configurations, some child devices aren't created.<br />
  It seems there is a reason to name the function as `driver:try_create_device(...)`<br />
  The driver can't do much about it, but try again.<br />
  Just change datapoint orders to force updating configuration.<br />
  For example, something like "1,2" to "2,1"

  <img src="resources/configuration_3.jpeg" height="300"/>

- **Child dashboard/detail view didn't load properly**<br />
  The driver doesn't know the datapoints until user inform them.<br />
  It will update as soon as it receives data from the device.<br />
  If there are some physical interface with the device (like switches, buttons, sensors, ...), consider triggering it.<br />
  It should make the device send informations to the driver.<br />
  I still don't know how to request data without modifying it as a side effect. Ideas are welcome.

  <img src="resources/child_detailView_1.jpeg" height="300"/>

- **Profile didn't change**<br />
  Sometimes, when modifying profile, it doesn't update properly.<br />
  It seems there is a reason to name the function as `device:try_update_metadata(...)`<br />
  The driver can't do much about it, but try again.<br />
  Just change to other profile and revert to force updating profile.

  <img src="resources/configuration_4.jpeg" height="300"/>

### Currently untested configurations

- Air Quality Sensor
- Door Control
- Formaldehyde Sensor
- Humidity Sensor
- Illuminance Sensor
- Motion Sensor
- Occupancy Sensor
- VOC Sensor
- Water Valve
- Water Sensor
- String Tuya Data Type
- Bitmap Tuya Data Type
- Raw Tuya Data Type