"""
This is the main sensor executable file.
"""

from synth_data_generator import generate_data
from data_to_json import data_to_json
import tarfile
import pickle
import time
from datetime import datetime
import requests
import argparse

MODEL_TAR_PATH = "./app/sensor-seed/rds1.tar"
#RUNTIME = 0.5 # hours
VERSION = 1
#LOC_LON = 40.2
#LOC_LAT = 35.6
TYPE = "rad_dr"
UNIT = "nSv/h"
#DEVICE = 27
OUTPUT_LOCATION = "./app/output"
#SERVER_IP = "http://localhost:8000"

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--id", type=int)
    parser.add_argument("-t", "--runtime", type=int)
    parser.add_argument("-a", "--loclat", type=float, default=35.6)
    parser.add_argument("-o", "--loclon", type=float, default=40.2)
    parser.add_argument("-s", "--serverip", type=str)

    args = parser.parse_args()

    archive = tarfile.open(MODEL_TAR_PATH)
    try:
        model_pickle = archive.extractfile('model.pkl')
        scaler_pickle = archive.extractfile('scaler.pkl')
        other_pkl = archive.extractfile('other.pkl')

        if other_pkl is not None:
            other_data: dict = pickle.load(other_pkl)

            if model_pickle is not None and scaler_pickle is not None:
                generated_data = generate_data(model_pickle, scaler_pickle, other_data, args.runtime)
                if generated_data is not None:
                    print("\n")
                    print(f"The number of measurements during this run will be: {len(generated_data)}")
                    print("---------------------------------------")
                    for i in range(len(generated_data)):
                        next_date = datetime.now()
                        generated_json = data_to_json(OUTPUT_LOCATION, VERSION, generated_data[i], next_date, TYPE, args.id, i, args.loclon, args.loclat)
                        print("Measurmenet {}:\t{} : {}".format((i+1), next_date, generated_data[i]))
                        print("---------------------------------")
                        requests.post(args.serverip, json=generated_json)
                        time.sleep(60 * other_data["time_step"]) # time_increment minutes

    finally:
        archive.close()
        print("Program exited gracefully")
