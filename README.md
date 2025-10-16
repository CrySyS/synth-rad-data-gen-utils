# Synthetic radiation data generation utilities 
This project contains various utilities that can be used to generate synthetic background radiotion time series data, imitate a real radiation sensor and simulate cyber-attacks on radiation detection scenarios.

## Ydata-syntbetic
For the synthetic time series data generation, this project utilizes the ydata-synthetic library:

https://pypi.org/project/ydata-synthetic/


## Python prerequisites

### Notice
The scripts were tested using Python 3.9

### Enviroment setup
All applications in this repositry need the same enviroment. So you only need to create it once and you can use it for all of them.

For the application to work, first you have to set up the virtual enviroment:

#### Creating the venv
```dos
> python pip install venv
> python -m venv venv
```
#### Activating the venv

Windows:

```dos
> venv\Scripts\activate.bat
```

Linux:

```bash
$ source venv/bin/activate
```

#### Installing the dependencies
After your venv is active, you have to isntall the project dependencies.
```dos
pip install -r requirements.txt
```

## Data format
To have the data in a unified, easily readable format throughout the project, included is the specification for a JSON based data format in the `Data format proposal` folder.

The repository contains a utility which can convert our JSON data format into IEEE/ANSI N42, which is an xml based data format for radiation measurements. This can be found the `N42-convert` folder. It is important that this **converter works only on best-effort bases**, the generated xml does conform to the N42 standard, but because our JSON data format doesn't represent everything the N42 requires, there are fields that are insufficiently filled in.

All parts of the repository use the current version of the JSON data format specification, which at the time of writing is `v2.1`. You can find examples of this data format in the `Data format proposal/v.X.X/example` folders.

## Seeds
The idea of a generator "seed" is that if we have such a seed, it can be simply plugged into any of the data generation tools, and the generator will produce synthetic data according to that seed. For example, if we want to generate data that resemlbes background radiation, or weather data, we have the seed for each different data type, and the generaton code is the same for all of them.

These seeds are in the format of a `.tar` archive. This archive contains all the necessary data for the generator code to produce the required sytnthetic data. It contains the following:
- trained model, 
- scaler values,
- elapesed time between two measuements
- the batch size used for training the model
- sequence lenght used at training
- the dimension of the training data

You don't have to understand the seed to use these programs. If you follow the descriptions on how to fill in the parameters, the seed you get out will work.

## Standalone data generator
With the files inside the `stand-alone` folder, you can step-by-step train a model on your data, generate synthetic data with it, and format the raw data in our JSON format. Instructions on how to use the utilitie can be found in `/stand-alone/README.md`.

## Sensor imitator
If you want to have a background radiotion sensor for your experiments, you can use the sensor imitator. You can train your own models, create your own seeds for it, or use the `rds1.tar` seed which was trained on data from a real radiation sensor, and takes a measuement every 10 minutes. The sensor will behave just like a real device would. While running, in intervals it will send measurmenets in JSON form, to a given HTTP server. A more thourough description on how to use it can be found in `sensor-imitator/README.md`.

## Attack simulator
This tool is designed for creating large databases, for AI training and research. If you have large quantities of real or synthetic data in our JSON format, you can run them through the attack simulator, to get data as if it was attacked while the measuerements were taken. These attacks can be broadly categoriesed into two types:

- Attacks that create radiation alarms where there were none
- Attacks that conceal a real radiation alarm.

Further information on this tool can be found at `attack-simulator/README.md`.

## RDS simulator
This tool is designed to provide a highly customizable simulation of a Radiation Detection System. You can define sensors on a map, introduce an attacker with specified attacks, and monitor the state of the system through Grafana dashboard. For further information see `RDS-simulator/README.md`.