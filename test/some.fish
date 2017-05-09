set -g event_api \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

set -g elasticsearch \
  (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_elasticsearch_1") | .value.IPv4Address | split("/")[0]')

function es -a request -a path
  if test $request = "PUT" -o $request = "POST"
    set input "--header" "Content-Type: application/json" "--data" "@-"
  end
  # echo curl --request "$request" $input -sS "http://$elasticsearch:9200/$path"
  curl --request "$request" $input --globoff -sS "http://$elasticsearch:9200/$path"
end

function api -a request -a path
  if test $request = "PUT" -o $request = "POST"
    set input "--header" "Content-Type: application/json" "--data" "@-"
  end
  jq -c '.' | curl --request "$request" $input --globoff -sS "http://$event_api:5000/$path"
end

# FIXME test connection to elasticsearch and api first

echo 'delete index "events"'
# curl --request DELETE -sfS "$elasticsearch:9200/events" | jq '.' > /dev/null
es DELETE events | jq -c '.'
  # > /dev/null

# basename
# set current_dir (dirname (basename (realpath (status --current-filename))))
# echo "\$current_dir: $current_dir"

set current_dir "./test"

echo 'create index "events" with schema'
cat "$current_dir/fixtures/events_schema.json" | \
  es PUT events | jq -c '.'
  # > /dev/null

# es GET events | jq '.' > /dev/null

# store
# cat "$DIRNAME/fixtures/events.jsonl" | while read -l event
#   echo "$event" \
#     | es POST events/event | jq -c '.'
#     # > /dev/null
# end
sleep 1

# fetch fixtures
# set -g test_events (cat "$current_dir/fixtures/events_for_api.json" | jq -c '.[]')
set -g test_schemaorg_events \
  (cat "$current_dir/fixtures/schemaorg-events.json" | jq -c '.[]')

set -g test_schemaorg_scraper_events \
  (cat "$current_dir/fixtures/schemaorg-scraper-events.json" | jq -c '.[]')

set -g test_schemaorg_sculpture_events \
  (cat "$current_dir/fixtures/schemaorg-sculpture-events.json" | jq -c '.[]')

# function setup
# end

# function -S teardown
#     pass "$TESTNAME: teardown is called after running tests"
# end

# test "$TESTNAME: get ten results"
#     # 10 -eq (curl -sfS "$event_api:5000/v0/events?lat=51.961&lon=7.614" | jq '. | length')
#     10 -eq (curl -sfS "$event_api:5000/v0/events" | jq '. | length')
#     # FIXME not length, but hits.total
# end
#

# test "$TESTNAME: fail"
#   400 -eq (echo "$test_events[1]" | api POST v0/events | jq -c '.status')
# end
#
# test "$TESTNAME: ok"
#   123 -eq (echo "$test_events[2]" | api POST v0/events | jq -c '.code')
# end

for event in $test_schemaorg_events
  test "$TESTNAME: POST v0/events ("(echo "$event" | jq '.name')")"
    123 -eq (echo "$event" | api POST v0/events | jq -c '.code')
  end
end

sleep 1

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
