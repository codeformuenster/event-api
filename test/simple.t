#!/bin/sh

test_description="Simple test of the event api"

docker_network="eventapi_default"

event_api=$(docker network inspect $docker_network \
  | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

elasticsearch=$(docker network inspect $docker_network \
  | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')


function curl_json {
  request="$1"
  url="$2"
  if test "$request" = "PUT" -o "$request" = "POST"; then
    input="--header Content-Type:application/json --data @-"
  fi
  IFS=$' \t\n' # '
  # echo "DEBUG curl --request $request $input --globoff -sS $url"  1>&2
  curl --request "$request" $input --globoff -sS "$url" | jq '.'
}

function echo_cyan {
  echo -e "\e[0;36m$1\e[0m"
}


echo_cyan 'delete index "events"'
curl_json DELETE "$elasticsearch:9200/events"

echo_cyan 'create index "events" with schema'
cat "../events_schema.json" | \
  curl_json PUT "$elasticsearch:9200/events"

# FIXME index should be created by the event-api

echo_cyan 'read test events'
IFS=$'\n' # '
test_schemaorg_sculpture_events=$(cat "./fixtures/schemaorg-sculpture-events.json" | jq -c '.[]')

echo_cyan 'read unims events'
IFS=$'\n' # '
test_schemaorg_unims_events=$(cat "./fixtures/schemaorg-unims-events.jsonl" | jq -c '.')


echo_cyan "run tests"
. ./sharness.sh

for event in ${test_schemaorg_sculpture_events}; do
  test_expect_success "post event" "
      test 123 = $(echo ${event} | curl_json POST $event_api:5000/v0/events | jq '.code')
  "
done
echo_cyan 'wait for events to be indexed'
sleep 1

test_expect_success "get all results" "
    test 9 = $(curl_json GET $event_api:5000/v0/events | jq '. | length')
"

for event in ${test_schemaorg_unims_events}; do
  test_expect_success "post event" "
      test 123 = $(echo ${event} | curl_json POST $event_api:5000/v0/events | jq '.code')
  "
done
# echo_cyan 'wait for events to be indexed'
# sleep 1

echo "###"

for event in ${test_schemaorg_unims_events}; do
  test_expect_success "put event" "
      test 123 = $(echo ${event} | curl_json PUT $event_api:5000/v0/events/test | jq '.code')
  "
done

# FIXME get putted events
# verify count of events in schema

test_done
