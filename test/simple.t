#!/bin/sh

test_description="Simple test of the event api"

docker_network="eventapi_default"

event_api=$(docker network inspect $docker_network \
  | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

elasticsearch=$(docker network inspect $docker_network \
  | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')


function curl_json {
  IFS=$' \t\n' # '
  request="$1"
  url="$2"
  input=""
  if test "$request" = "PUT" -o "$request" = "POST"; then
    input="--header Content-Type:application/json --data @-"
  fi
  # echo "DEBUG curl --request $request $input --globoff -sS $url"  1>&2
  curl --request "$request" $input --globoff -sS "$url" | jq '.'
  # echo
}


echo 'delete index "events"'
curl_json DELETE "$elasticsearch:9200/events"

echo 'create index "events" with schema'
cat "./fixtures/events_schema.json" | \
  curl_json PUT "$elasticsearch:9200/events"


IFS=$'\n' # '
test_schemaorg_sculpture_events=$(cat "./fixtures/schemaorg-sculpture-events.json" | jq -c '.[]')


. ./sharness.sh

echo "running tests"

for event in ${test_schemaorg_sculpture_events}; do
  test_expect_success "post event" "
      test 123 = $(echo ${event} | curl_json POST $event_api:5000/v0/events | jq '.code')
  "
done
sleep 1

test_expect_success "get all results" "
    test 9 = $(curl_json GET $event_api:5000/v0/events | jq '. | length')
"

test_done
