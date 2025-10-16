if [ $# -eq 0 ]; then
    echo "Usage: ./setup.sh <config.json>"
    exit 1
fi

CONFIG="$1"

SENSOR_NUM=`jq -r '.sensors | length' $CONFIG`
SENSOR_NAME=`jq -r '.containernames.sensor' $CONFIG`
RECEIVER_NAME=`jq -r '.containernames.receiver' $CONFIG`
INFLUXDB_NAME=`jq -r '.containernames.influxdb' $CONFIG`
GRAFANA_NAME=`jq -r '.containernames.grafana' $CONFIG`
ATTACKER_NAME=`jq -r '.containernames.attacker' $CONFIG`
MAP_PROVIDER_NAME=`jq -r '.containernames.mapprovider' $CONFIG`

docker stop $GRAFANA_NAME
docker stop $INFLUXDB_NAME
docker stop $RECEIVER_NAME
docker stop $ATTACKER_NAME
docker stop $MAP_PROVIDER_NAME

for ((i=1; i <= SENSOR_NUM; i++))
do
    docker stop $SENSOR_NAME-$i
done

docker rm $GRAFANA_NAME
docker rm $INFLUXDB_NAME
docker rm $RECEIVER_NAME
docker rm $ATTACKER_NAME
docker rm $MAP_PROVIDER_NAME

for ((i=1; i <= SENSOR_NUM; i++))
do
    docker rm $SENSOR_NAME-$i
done

