set -g event_api \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

set -g elasticsearch \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')

curl --request DELETE -sfS "$elasticsearch:9200/events" | jq '.' > /dev/null

cat "$DIRNAME/fixtures/events_schema.json" | \
  curl --request PUT --header "Content-Type: application/json" --data @- -sfS "$elasticsearch:9200/events" \
    | jq '.' > /dev/null

cat "$DIRNAME/fixtures/events.jsonl" | while read -l event
  echo "$event" \
    | curl --request POST --header "Content-Type: application/json" --data @- -sfS "$elasticsearch:9200/events/event" \
      | jq '.' > /dev/null
end

sleep 1


# function setup
# end

# function -S teardown
#     pass "$TESTNAME: teardown is called after running tests"
# end

test "$TESTNAME: get ten results"
    10 -eq (curl -sfS "$event_api:5000/v0/events?lat=51.961&lon=7.614" | jq '. | length')
end

# test "$TESTNAME: setup is called once per *every* test"
#     true = true
# end
