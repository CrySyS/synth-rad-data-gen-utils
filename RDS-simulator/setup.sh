#!/bin/bash
########################################################
# Setup script for Radiation Detection System Simulation
########################################################

if [ $# -eq 0 ]; then
    echo "Usage: ./setup.sh <config.json>"
    exit 1
fi

CONFIG="$1"

# Variables
SENSOR_NUM=`jq -r '.sensors | length' $CONFIG`
RUNTIME=`jq -r '.runtime_hours' $CONFIG`
INFLUXDB_TOKEN=`jq -r '.influxdb.token' $CONFIG`
INFLUXDB_ORG=`jq -r '.influxdb.org' $CONFIG`
INFLUXDB_BUCKET=`jq -r '.influxdb.bucket' $CONFIG`
USER=`jq -r '.user.username' $CONFIG`
PASSWD=`jq -r '.user.password' $CONFIG`
SENSOR_NAME=`jq -r '.containernames.sensor' $CONFIG`
RECEIVER_NAME=`jq -r '.containernames.receiver' $CONFIG`
INFLUXDB_NAME=`jq -r '.containernames.influxdb' $CONFIG`
GRAFANA_NAME=`jq -r '.containernames.grafana' $CONFIG`
ATTACKER_NAME=`jq -r '.containernames.attacker' $CONFIG`
MAP_PROVIDER_NAME=`jq -r '.containernames.mapprovider' $CONFIG`

# ---------------------------------
# Building the docker images
#----------------------------------

## Create docker network
docker network create --attachable -d bridge rds-network

## Building the sensor image
if [ -z "$(docker images -q sensor:latest 2> /dev/null)" ]; then

    echo "Building docker image for sensor..."
    docker run -d --name build-sensor python:3.9 sleep infinity
    docker exec build-sensor mkdir -p app

    for file in ./src/sensor/*; do
        docker cp "$file" build-sensor:/app/
    done

    docker cp "./src/requirements.txt" build-sensor:/app
    docker exec build-sensor pip install -r /app/requirements.txt

    docker commit --change='ENTRYPOINT ["python3", "/app/sensor.py"]' build-sensor sensor
    docker rm -f build-sensor
fi


## Building the receiver image
if [ -z "$(docker images -q receiver:latest 2> /dev/null)" ]; then
    echo "Building the receiver image..."
    docker run -d --name build-receiver python:3.9 sleep infinity
    docker exec build-receiver mkdir -p app
    docker cp "./src/receiver/sensor_receiver.py" build-receiver:/app
    docker exec build-receiver pip install influxdb-client
    
    docker commit --change='ENTRYPOINT ["python3", "/app/sensor_receiver.py"]' build-receiver receiver
    docker rm -f build-receiver
fi

## pulling the grafana image
if [ -z "$(docker images -q grafana/grafana-oss:12.1.0-ubuntu 2> /dev/null)" ]; then
    echo "Pulling the grafana image..."
    docker image pull grafana/grafana-oss:12.1.0-ubuntu
fi

## Pulling the influxDB image
if [ -z "$(docker images -q influxdb:2.7 2> /dev/null)" ]; then
    echo "Pulling the influxDB image..."
    docker image pull influxdb:2.7
fi


## Bulding attacker image
if [ -z "$(docker images -q attacker:latest 2> /dev/null)" ]; then
  if jq -e '.attacker' $CONFIG > /dev/null; then
    
    echo "Building docker image for attacker..."
    docker run -d --name build-attacker python:3.9 sleep infinity
    docker exec build-attacker mkdir -p app

    for file in ./src/attacker/*; do
        docker cp "$file" build-attacker:/app/
    done

    docker cp "./src/attacker/requirements.txt" build-attacker:/app
    docker exec build-attacker pip install -r /app/requirements.txt

    docker commit --change='ENTRYPOINT ["python3", "/app/attacker.py"]' build-attacker attacker
    docker rm -f build-attacker

  fi
fi

## Building the Anshar Map Provider image
if [ -z "$(docker images -q map-provider:latest 2> /dev/null)" ]; then
  echo "Building the map provider image..."
  docker run -d --name build-map-provider python:3.9 sleep infinity
  docker exec build-map-provider mkdir -p app
  docker exec build-map-provider mkdir -p /app/map
  docker cp ./src/map/State-of-Anshar.jpeg build-map-provider:/app/map/map.jpeg

  docker commit --change='ENTRYPOINT ["python3", "-m", "http.server", "3001", "--directory", "/app/map"]' build-map-provider map-provider
  docker rm -f build-map-provider

fi

# ------------------------------
# CREATE GRAFANA JSON DASHBOARD
# ------------------------------
MAP='
{
  "background": {
    "color": {
      "fixed": "#D9D9D9"
    },
    "image": {
      "fixed": "http://localhost:3001/map.jpeg",
      "mode": "fixed"
    }
  },
  "border": {
    "color": {
      "fixed": "dark-green"
    }
  },
  "config": {
    "align": "center",
    "color": {
      "fixed": "#000000"
    },
    "valign": "middle"
  },
  "constraint": {
    "horizontal": "left",
    "vertical": "top"
  },
  "links": [],
  "name": "Element 2",
  "placement": {
    "height": 412,
    "left": 0,
    "rotation": 0,
    "top": 0,
    "width": 512
  },
  "type": "rectangle"
}
'
CANVAS_PANEL='
{
  "datasource": {
    "type": "influxdb",
    "uid": "rds-influxdb-ds"
  },
  "fieldConfig": {
    "defaults": {
      "color": {
        "mode": "thresholds"
      },
      "mappings": [],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {
            "color": "green",
            "value": 0
          },
          {
            "color": "red",
            "value": 200
          }
        ]
      }
    },
    "overrides": []
  },
  "gridPos": {
    "h": 13,
    "w": 11,
    "x": 0,
    "y": 0
  },
  "id": 7,
  "options": {
    "infinitePan": false,
    "inlineEditing": false,
    "panZoom": false,
    "root": {
      "background": {
        "color": {
          "fixed": "transparent"
        },
        "image": {
          "field": "",
          "fixed": "",
          "mode": "fixed"
        }
      },
      "border": {
        "color": {
          "fixed": "dark-green"
        }
      },
      "constraint": {
        "horizontal": "left",
        "vertical": "top"
      },
      "elements": [],
      "name": "Element 1760341855846",
      "placement": {
        "height": 100,
        "left": 0,
        "rotation": 0,
        "top": 0,
        "width": 100
      },
      "type": "frame"
    },
    "showAdvancedTypes": true
  },
  "pluginVersion": "12.1.0",
  "targets": [],
  "title": "Anshar map",
  "type": "canvas"
}
'

# assemble canvas panel

## adding map
CANVAS_PANEL=$(jq --argjson element "$MAP" '.options.root.elements += [$element]' <<< "$CANVAS_PANEL")

## adding targets
for ((i=1; i <= SENSOR_NUM; i++))
do
NEW_TARGET=$(cat <<EOF
{
  "datasource": {
    "type": "influxdb",
    "uid": "rds-influxdb-ds"
  },
  "hide": false,
  "query": "from(bucket: \"rds-test-bucket\")\n  |> range(start: -10m)\n  |> filter(fn: (r) => r._measurement == \"rad_dr\" and r._field == \"rad_measurement\" and r.id == \"$i\")\n  |> last()\n |> fill(value: 0.0)",
  "refId": "Q$i"
}
EOF
)
  CANVAS_PANEL=$(jq --argjson target "$NEW_TARGET" '.targets += [$target]' <<< "$CANVAS_PANEL")
done

## adding dots
for ((i=1; i <= SENSOR_NUM; i++))
do

idx=$((i - 1))
LEFT=$(jq --arg i "$idx" -r '.sensors[$i | tonumber].longitude' $CONFIG)
TOP=$(jq --arg i "$idx" -r '.sensors[$i | tonumber].latitude' $CONFIG)

  NEW_DOT=$(cat <<EOF
{
  "background": {
    "color": {
      "field": "rad_measurement $i",
      "fixed": "dark-green"
    }
  },
  "border": {
    "color": {
      "fixed": "dark-green"
    }
  },
  "config": {
    "align": "center",
    "color": {
      "fixed": "#000000"
    },
    "size": 9,
    "text": {
      "fixed": "sensor$i"
    },
    "valign": "middle"
  },
  "connections": [],
  "constraint": {
    "horizontal": "left",
    "vertical": "top"
  },
  "links": [],
  "name": "Element $i",
  "placement": {
    "height": 15,
    "left": $LEFT,
    "top": $TOP,
    "width": 15
  },
  "type": "ellipse"
}
EOF
)

  CANVAS_PANEL=$(jq --argjson element "$NEW_DOT" '.options.root.elements += [$element]' <<< "$CANVAS_PANEL")
done

## adding measurements
for ((i=1; i <= SENSOR_NUM; i++))
do

idx=$((i - 1))
LEFT=$(jq --arg i "$idx" -r '.sensors[$i | tonumber].longitude' $CONFIG)
TOP_BASE=$(jq --arg i "$idx" -r '.sensors[$i | tonumber].latitude' $CONFIG)
TOP=$(echo "$TOP_BASE + 10.0" | bc)


NEW_MEASUREMENT=$(cat <<EOF
{
  "background": {
    "color": {
      "fixed": "transparent"
    }
  },
  "border": {
    "color": {
      "fixed": "dark-green"
    }
  },
  "config": {
    "align": "center",
    "color": {
      "fixed": "#000000"
    },
    "size": 9,
    "text": {
      "field": "rad_measurement $i",
      "fixed": "0.0",
      "mode": "field"
    },
    "valign": "middle"
  },
  "constraint": {
    "horizontal": "left",
    "vertical": "top"
  },
  "links": [],
  "name": "Element $i",
  "placement": {
    "height": 20,
    "left": $LEFT,
    "rotation": 0,
    "top": $TOP,
    "width": 40
  },
  "type": "text"
}
EOF
)

  CANVAS_PANEL=$(jq --argjson element "$NEW_MEASUREMENT" '.options.root.elements += [$element]' <<< "$CANVAS_PANEL")

done

# create panels
NEW_PANELS='[]'

NEW_PANELS=$(jq --argjson panel "$CANVAS_PANEL" '. += [$panel]' <<< "$NEW_PANELS")

# Create a timeseries panel for each sensor
for ((i=1; i <= SENSOR_NUM; i++))
do
    NEW_SENSOR=$(cat <<EOF 
{
  "datasource": {
    "type": "influxdb",
    "uid": "rds-influxdb-ds"
  },
  "fieldConfig": {
    "defaults": {
      "color": {
        "mode": "palette-classic"
      },
      "custom": {
        "axisBorderShow": false,
        "axisCenteredZero": false,
        "axisColorMode": "text",
        "axisLabel": "",
        "axisPlacement": "auto",
        "barAlignment": 0,
        "barWidthFactor": 0.6,
        "drawStyle": "line",
        "fillOpacity": 0,
        "gradientMode": "none",
        "hideFrom": {
          "legend": false,
          "tooltip": false,
          "viz": false
        },
        "insertNulls": false,
        "lineInterpolation": "linear",
        "lineWidth": 1,
        "pointSize": 5,
        "scaleDistribution": {
          "type": "linear"
        },
        "showPoints": "auto",
        "spanNulls": false,
        "stacking": {
          "group": "A",
          "mode": "none"
        },
        "thresholdsStyle": {
          "mode": "line+area"
        }
      },
      "mappings": [],
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {
            "color": "green",
            "value": null
          },
          {
            "color": "red",
            "value": 200
          }
        ]
      }
    },
    "overrides": []
  },
  "gridPos": {
    "h": 8,
    "w": 12,
    "x": 0,
    "y": 16
  },
  "id": $i,
  "options": {
    "legend": {
      "calcs": [],
      "displayMode": "list",
      "placement": "bottom",
      "showLegend": true
    },
    "tooltip": {
      "hideZeros": false,
      "mode": "single",
      "sort": "none"
    }
  },
  "pluginVersion": "12.2.0-258092",
  "targets": [
      {
        "query": "from(bucket:\"rds-test-bucket\") \n  |> range(start: -24h)\n  |> filter(fn: (r) => r._field == \"rad_measurement\")\n  |> filter(fn: (r) => r.id == \"$i\")",
        "refId": "A"
      }
  ],
  "title": "Sensor $i",
  "type": "timeseries"
}
EOF
)

    NEW_PANELS=$(jq --argjson panel "$NEW_SENSOR" '. + [$panel]' <<< "$NEW_PANELS")

done

# Write current panels into dashboard.json
jq --argjson new_panel "$NEW_PANELS" \
    '.panels = $new_panel' \
    ./src/grafana/base-template.json > ./src/grafana/dashboard.json

# Calcualte and write start and end times into dashboard.json
CURRENT_TIME=`date -u +"%Y-%m-%dT%H:%M:%S.000Z"`
jq --arg from "$CURRENT_TIME" '.time.from = $from' ./src/grafana/dashboard.json > ./src/grafana/dashboard.tmp.json
mv ./src/grafana/dashboard.tmp.json ./src/grafana/dashboard.json

END_TIME=$(date -u -d "+$RUNTIME hour" +"%Y-%m-%dT%H:%M:%S.000Z")
jq --arg to "$END_TIME" '.time.to = $to' ./src/grafana/dashboard.json > ./src/grafana/dashboard.tmp.json

mv ./src/grafana/dashboard.tmp.json ./src/grafana/dashboard.json
echo "Grafana dashboard template initialized."

# create influxDB init script
INFLUXDB_INIT_TEMPLATE=$(cat <<EOF
#!/bin/bash
SENSORNUM=$SENSOR_NUM

for ((i=1; i <= SENSORNUM; i++));
do
  influx write \
    --bucket $INFLUXDB_BUCKET \
    --org $INFLUXDB_ORG \
    "rad_dr,id=\$i rad_measurement=-1.0 \$(date +%s%N)"
done
EOF
)
echo "$INFLUXDB_INIT_TEMPLATE" > ./src/influxDB/init.sh

# DONE
echo "Setup done!"

###############################
## Starting the RDS
###############################

# create map provider
docker run -d --name $MAP_PROVIDER_NAME \
  --network rds-network \
  -p 3001:3001 \
  -v ./src/map/State-of-Anshar.jpeg:/app/map/map.jpeg \
  map-provider:latest &&

# create influxDB
docker run -d --name $INFLUXDB_NAME \
    --network rds-network \
    -e DOCKER_INFLUXDB_INIT_MODE=setup \
    -e DOCKER_INFLUXDB_INIT_USERNAME=$USER \
    -e DOCKER_INFLUXDB_INIT_PASSWORD=$PASSWD \
    -e DOCKER_INFLUXDB_INIT_ORG=$INFLUXDB_ORG \
    -e DOCKER_INFLUXDB_INIT_BUCKET=$INFLUXDB_BUCKET \
    -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$INFLUXDB_TOKEN \
    -v ./src/influxDB/init.sh:/docker-entrypoint-initdb.d/init.sh \
    influxdb:latest &&

# create receiver server
docker run  -d --name $RECEIVER_NAME \
    --network rds-network \
    receiver:latest \
    --org $INFLUXDB_ORG \
    --bucket $INFLUXDB_BUCKET \
    --token $INFLUXDB_TOKEN \
    --influxdbip "http://$INFLUXDB_NAME:8086"  &&

# create grafana
docker run -d --name $GRAFANA_NAME \
    --network rds-network \
    -p 3000:3000 \
    -e GF_SECURITY_ADMIN_USER=$USER \
    -e GF_SECURITY_ADMIN_PASSWORD=$PASSWD \
    -v ./src/grafana/grafana.ini:/etc/grafana/grafana.ini \
    -v ./src/grafana/dashboard.yml:/etc/grafana/provisioning/dashboards/dashboard.yml \
    -v ./src/grafana/dashboard.json:/etc/grafana/dashboards/general/dashboard.json \
    -v ./src/grafana/influxdb.yml:/etc/grafana/provisioning/datasources/influxdb.yml \
    grafana/grafana-oss:12.1.0-ubuntu &&

# create sensors
for ((i=1; i<=SENSOR_NUM; i++));
do
    docker run -d --name $SENSOR_NAME-$i \
        -v ./src/sensor-seeds:/app/sensor-seed \
        -v ./src/sensor/output:/app/output \
        --network rds-network \
        sensor:latest \
        --id $i \
        --runtime $RUNTIME \
        --serverip "http://$RECEIVER_NAME" \
        --loclon "$(jq -r ".sensors[$((i-1))].longitude" "$CONFIG")" \
        --loclat "$(jq -r ".sensors[$((i-1))].latitude" "$CONFIG")" 
done

# Create attacker container
if jq -e '.attacker' $CONFIG > /dev/null; then
  docker run -d --name $ATTACKER_NAME \
  -v ./src/attacker/output:/app/output \
  --network rds-network \
  attacker:latest \
  --serverip "http://$RECEIVER_NAME" \
  --jsondata $(jq -c '.attacker' $CONFIG)
fi

echo "Started up RDS simulation. You can see the grafana dashboard on localhost:3000."