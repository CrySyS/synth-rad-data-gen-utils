"""
This is an example for how to recieve the JSON object sent by the sensor.
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
from argparse import ArgumentParser

from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

#ADDR = "localhost"
#PORT = 8000

def send_to_database(json_data):

    to_point = {
        "measurement": json_data["payload"][0]["type"],
        "tags": {
            "id": json_data["payload"][0]["device"]
        },
        "fields": {
            "rad_measurement": json_data["payload"][0]["reading"]
        },
        "time": json_data["payload"][0]["when_captured"]
    }
    point = Point.from_dict(to_point)
    with client.write_api(write_options=SYNCHRONOUS) as write_api:
        write_api.write(bucket=args.bucket, org=args.org, record=point)


class SensorRequestHandler(BaseHTTPRequestHandler):

    def do_POST(self):
        length = int(self.headers['Content-length'])
        data = self.rfile.read1(length)
        json_data = json.loads(data)
        print(json_data)
        send_to_database(json_data)
        self.send_response(200, "OK")
        self.end_headers()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('-t', '--token', type=str)
    parser.add_argument('-o', '--org', type=str)
    parser.add_argument('-b', '--bucket', type=str)
    parser.add_argument('-i', '--influxdbip', type=str)
    args = parser.parse_args()

    client = InfluxDBClient(url=args.influxdbip, token=args.token, org=args.org)
    write_api = client.write_api(write_options=SYNCHRONOUS)

    httpd = HTTPServer(('0.0.0.0', 80), SensorRequestHandler)
    httpd.serve_forever()
