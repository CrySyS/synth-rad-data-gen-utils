"""
This module uses the trained modell, to generate syntethic data.
"""

import pickle
from typing import Optional
import math

from ydata_synthetic.synthesizers.timeseries import TimeGAN
from sklearn.preprocessing import MinMaxScaler

def generate_data(model_pkl, scaler_pkl, other_data, runtime) -> Optional[list[float]]:
    print("Generate data...")

    BATCH_SIZE = other_data["batch_size"]
    SEQ_LEN = other_data["sequence_lenght"]
    ONE_HOUR = SEQ_LEN // 24
    if model_pkl is not None:
        synth = TimeGAN.load(model_pkl)

        if scaler_pkl is not None:
            scaler: MinMaxScaler = pickle.load(scaler_pkl)

            batch_gen = math.ceil(runtime / (BATCH_SIZE * ONE_HOUR)) # how many batches to generate?
            synth_data = synth.sample(batch_gen)

            generated_data = []
            days_needed = math.ceil(runtime / 24) # how many days are needed for the asked hours
            for i in range(days_needed):
                scaled_data = scaler.inverse_transform(synth_data[i])
                generated_data.extend(scaled_data.tolist())

            return_data = []
            asked_data_num = int(runtime * ONE_HOUR) # how many data records are needed for the asked hour number
            for i in range(asked_data_num):
                [unpacked_data] = generated_data[i]
                return_data.append(unpacked_data)

            for i in range(len(return_data)):
                return_data[i] = float("{:.2f}".format(return_data[i]))

            return return_data
