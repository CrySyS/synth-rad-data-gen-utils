import json
import time
import math
import datetime
import requests
import argparse
from data_to_json import data_to_json

def run_attacks(input_data, serverip):
    time_between_attacks = input_data["time_between_attacks_minutes"]
    initial_delay = input_data["initial_delay_minutes"]

    time.sleep(60 * initial_delay)

    for attack in input_data["attacks"]:
        target_id = attack["target_id"]
        attack_length = attack["attack_length_minutes"]
        attack_frequency = attack["attack_frequency_seconds"]
        values_to_send = attack["values_to_send"]
        num_of_values = len(attack["values_to_send"])

        attack_num = math.floor((attack_length * 60) / attack_frequency)

        for i in range(attack_num):
            attack_value = values_to_send[i % num_of_values]
            json_to_send = data_to_json("./app/output", 1, attack_value, datetime.datetime.now(), "rad_dr", target_id, i)
            requests.post(serverip, json=json_to_send)
            # sleep between packets sent
            time.sleep(attack_frequency)


        # sleep between attacks
        time.sleep(time_between_attacks * 60)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", "--serverip", type=str)
    parser.add_argument("-j", "--jsondata", type=str)
    args = parser.parse_args()

    input_data = json.loads(args.jsondata)
    run_attacks(input_data, args.serverip)
