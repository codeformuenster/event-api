# Open Events Database API (Built with Connexion)

# Install

Install Connexion Framework

    pip install connexion

Just for reference, Infos about Connextion API Generator

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

set eventapi (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

curl "http://$eventapi:8080/v1/events?lat=0&lon=0"
```
