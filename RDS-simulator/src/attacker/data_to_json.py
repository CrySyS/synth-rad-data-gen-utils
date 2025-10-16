"""
This module is responsible for creating a formatted json file from
the generated raw data
"""
import json

def data_to_json(output_location, version, reading, date, meas_type, device, i, loc_lon=None, loc_lat=None, unit=None) -> dict:
    version = version

    payload = []
    new_measurement = {}
    new_measurement["type"] = meas_type
    new_measurement["when_captured"] = date.strftime('%Y-%m-%dT%H:%M:%SZ')
    new_measurement["device"] = device
    new_measurement["reading"] = reading
    if loc_lat != None:
        new_measurement["loc_lat"] = float(loc_lat)
    if loc_lon != None:
        new_measurement["loc_lon"] = float(loc_lon)
    if unit != None:
        new_measurement["unit"] = str(unit)

    payload.append(new_measurement)


    new_json = {}
    new_json["version"] = int(version)
    new_json["payload"] = payload

    output = output_location + '/' + "attacker_" +  str(device) + '-' + meas_type + '-' + str(i) + '.json'

    with open(output, 'w') as jf:
        json.dump(new_json, jf, indent=4)


    return new_json
