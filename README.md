# Open Events Database API (Built with Connexion)

# Install

Install Connexion Framework

    pip install connexion

Just for reference, Infos about Connexion API Generator

 *  homepage: https://github.com/zalando/connexion
 *  example: https://github.com/hjacobs/connexion-example/blob/master/app.py

# Run it

First you need to start elasticsearch:

    sudo sysctl -w vm.max_map_count=262144 	# <- only on ubuntu
    sudo docker run -p 9200:9200 -p 9300:9300 -v "$PWD/esdata":/usr/share/elasticsearch/data elasticsearch

Then run the Open Events API with:

    python app.py


## Run in development mode

Or for development mode with auto reload, run with:

    nodemon app.py


## Docker Compose Notes

```bash
# fish shell

docker-compose build
docker-compose up

# addr_port

set elasticsearch_api \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')

curl --request DELETE -sS "http://$elasticsearch_api:9200/events"


cat "./test/fixtures/events_schema.json" | \
  curl \
    --request PUT \
    --header "Content-Type: application/json" \
    --data @- \
    --globoff \
    -sS \
      "http://$elasticsearch_api:9200/events"


set event_api \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

# xdg-open "http://$event_api:5000/spec"


set -g test_events (cat "./test/fixtures/schemaorg-events.json" | jq -c '.[]')

for event in $test_events
  echo "$event" \
    | curl \
      --request POST \
      --header "Content-Type: application/json" \
      --data @- \
      --globoff \
      -sS \
        "http://$event_api:5000/v0/events"
end

curl "http://$event_api:5000/v0/events"

curl "http://$event_api:5000/v0/events?geoDistance=7.622457,51.9647714,10km"
```
