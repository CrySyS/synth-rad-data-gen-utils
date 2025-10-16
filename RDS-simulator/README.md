# Dockerized Radiation Detection System Simulator
This projects aimes to provide an highly customizable enviroment for simulating a Radiation Detection System. Using this simulator it is possible to create and place multiple sensors on the map, that will simulate a real sensors by periodically sending radiation measurements. All measurements are in nSv/h. The simulator also allows for introducing an attacker into the system, the attacker is configurable to target multiple sensors, with different attacks.

## Enviroment setup
The simulator uses docker containers. It was tested on Linux operating system, and on Windows, using the Windows Subsystem for Linux (WSL). On windows, WSL can be configured to use the docker instance installed on Windows. However the `setup.sh` and `stop.sh` scripts should be run inside WSL. 


## Map
In order to avoid any unwanted implications, in this project instead of the real world, we used the imaginary map of the State of Anshar and its neighbouring countries. You can place sensors on the map of Anshar using pixel coordinates: the upper left corner of the map corresponds to (0, 0) and the bottom righ corner to (512, 412).

![Anshar map](./src/map/State-of-Anshar.jpeg)

The map Of Anshar was created with the help of [Azgaar's Fantasy Map Generator](https://azgaar.github.io/Fantasy-Map-Generator/)


## Usage
### Configuration
You can set up your simulation by defining its configuration in a `.json` file. 

The most important configuration options:
- `runtime_hours`: How long (for how many hours) should the simulation run (meaining: how long should the sensors broadcast new measurements.)
- `Creating sensors`: What defines a sensor in the simulation is its position on the map. You only need to provide a longitude and a latitude value to create a new sensor
```json
"sensors": [
        {
            "latitude": 170.0,
            "longitude": 290.0
        },
        {
            "latitude": 140.0,
            "longitude": 260.0
        }
]
```
- If you would like, you can introduce an attacker into the simulation. There are a couple parameters you have to give that concern the attacker in general:
    - `initial_delay_minutes`: Here you can tell the simulation how much time (in minutes) should pass before the attacker becomse active.
    - `time_between_attacks_minutes`: If you have defined multiple attacks, how much time (in minutes) should pass between each different attack. 
    - You can define attacks in the following way:
        - `target_id`: which sensor the attack should target. (sensors are indexed starting with 1)
        - `attack_length_minutes`: How many minutes the attack should be active for.
        - `attack_frequency_seconds`: How much time (in seconds) should ellapse between each step of the attack.
        - `values_to_send`: The attack itself. This is a list of floating-point numbers, which the attacker will inject into the target sensor`s measure between. You can define a multiple a singelle value, then it will repeatedly inject that, or a list of valuues, in this case the pattern will repeat during the length of the attakck.
        ```json
            "attacker": {
                "initial_delay_minutes": 2,
                "time_between_attacks_minutes": 5,
                "attacks": [
                    {
                        "target_id": 1,
                        "attack_length_minutes": 2,
                        "attack_frequency_seconds": 10,
                        "values_to_send": [
                            200.4,
                            210.5
                        ]
                    },
                    {
                        "target_id": 3,
                        "attack_length_minutes": 3,
                        "attack_frequency_seconds": 3,
                        "values_to_send": [
                            213.4
                        ]
                    }
                ]
            }
        ``` 

Additionaly, if you would like, you can change the credentials used by grafana, the actual names of the containers created, and also some influxDB internal varibles, but the example configuration will get you a working system out of the box.

Here is an example configuration:
```json
{
    "runtime_hours": 3,
    "influxdb": {
        "org": "rds-test-org",
        "token": "rds-test-token",
        "bucket": "rds-test-bucket"
    },
    "user": {
        "username": "admin",
        "password": "admin123"
    },
    "containernames": {
        "sensor": "rds-sensor",
        "receiver": "rds-receiver",
        "influxdb": "rds-influxdb",
        "grafana": "rds-grafana",
        "attacker": "rds-attacker",
        "mapprovider": "rds-map-provider"
    },
    "sensors": [
        {
            "latitude": 170.0,
            "longitude": 290.0
        },
        {
            "latitude": 140.0,
            "longitude": 260.0
        },
        {
            "latitude": 250.0,
            "longitude": 200.0
        },
        {
            "latitude": 200.0,
            "longitude": 270.0
        },
        {
            "latitude": 320.0,
            "longitude": 190.0
        }

    ],
    "attacker": {
        "initial_delay_minutes": 2,
        "time_between_attacks_minutes": 5,
        "attacks": [
            {
                "target_id": 1,
                "attack_length_minutes": 2,
                "attack_frequency_seconds": 10,
                "values_to_send": [
                    200.4,
                    210.5
                ]
            },
            {
                "target_id": 3,
                "attack_length_minutes": 3,
                "attack_frequency_seconds": 3,
                "values_to_send": [
                    213.4
                ]
            }
        ]
    }
}
```
### Running the simulation
Once you have your configuration `json` file, you can start up the simulation by running the `setup.sh` script. The first time you run this, it will pull and build the necessary docker images/continers. Once you have the images on your system, starting a new simulation is much faster. Here is how you start the simulation:
```bash
./setup.sh config.json
```
Once the simulation started the grafana dsahboard can be opend in the web browser at `http://localhost:3000`

Once you want to shut the simulation down, you can do so with the `stop.sh` script. You also need to give it **the same** configuration file with which you started the simulation:
```bash
./stop.sh config.json
```

### The data generated
While the simulation is running, each sensor will log its "measurements" into `./src/sensor/ouput`. Similarly the attacker logs the attacks sent into `./src/attacker/output`.