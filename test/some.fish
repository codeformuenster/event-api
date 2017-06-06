set docker_network "eventapi_default"

set -g event_api \
  (docker network inspect $docker_network | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

set -g elasticsearch \
  (docker network inspect $docker_network | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')

function http
  docker run --network $docker_network -i dockerhttpie_api:latest \
    http --pretty=all --body $argv
  echo ""
end

set current_dir "./test"

# FIXME test connection to elasticsearch and api first?

echo 'delete index "events"'
http delete "$elasticsearch:9200/events"

echo 'create index "events" with schema'
cat "$current_dir/fixtures/events_schema.json" | \
  http put "$elasticsearch:9200/events"


sleep 1

# read fixtures
set -g test_schemaorg_events \
  (cat "$current_dir/fixtures/schemaorg-events.json" | jq -c '.[]')

set -g test_schemaorg_scraper_events \
  (cat "$current_dir/fixtures/schemaorg-scraper-events.json" | jq -c '.[]')

set -g test_schemaorg_sculpture_events \
  (cat "$current_dir/fixtures/schemaorg-sculpture-events.json" | jq -c '.[]')

# FIXME for event in $test_schemaorg_sculpture_events $test_schemaorg_scraper_events ??

for event in $test_schemaorg_sculpture_events
  echo "\$event: $event"
  echo "$event | http post $event_api:5000/v0/events"
  echo "$event" | http post $event_api:5000/v0/events
  #  | jq -c '.code'
  echo "test"
end

exit

# function setup
# end

# function -S teardown
#     pass "$TESTNAME: teardown is called after running tests"
# end

# echo http get $event_api/v0/events
# http get $event_api:5000/v0/events
#
# exit


for event in $test_schemaorg_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | http post $event_api:5000/v0/events | jq -c '.code')
  end
end

for event in $test_schemaorg_scraper_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | http post $event_api:5000/v0/events | jq -c '.code')
  end
end

for event in $test_schemaorg_sculpture_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | http post $event_api:5000/v0/events | jq -c '.code')
  end
end

sleep 1

exit

test "$TESTNAME: get all results"
  6 -eq (api GET v0/events | jq '. | length')
end

test "$TESTNAME: startDate"
  0 -eq (api GET "v0/events?startDate=2017-04-15T19:03:31Z" | jq '. | length')
end

test "$TESTNAME: endDate"
  6 -eq (api GET "v0/events?endDate=2017-04-15T19:03:31Z" | jq '. | length')
end

test "$TESTNAME: geoDistance fail"
  0 -eq (api GET "v0/events?geoDistance=1,2,3km" | jq '. | length')
end

test "$TESTNAME: geoDistance"
  2 -eq (api GET "v0/events?geoDistance=-104.987733,39.716331,10km" | jq '. | length')
end


for event in $test_schemaorg_scraper_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | api POST v0/events | jq -c '.code')
  end
end



for event in $test_schemaorg_sculpture_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | api POST v0/events | jq -c '.code')
  end
end
