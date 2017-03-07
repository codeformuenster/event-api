# Connexion api

First you need to start elasticsearch:

    sudo sysctl -w vm.max_map_count=262144
    sudo docker run -p 9200:9200 -p 9300:9300 -v "$PWD/esdata":/usr/share/elasticsearch/data elasticsearch


Then run the Connexion Events API with:

    python app.py


Or for development mode with auto reload, run with:

    nodemon app.py




## Docker Compose Notes

```bash
# fish shell

docker-compose up

set eventapi (docker network inspect eventapi_default | jq -r '.[].Containers | to_entries | .[] | select(.value.Name == "eventapi_api_1") | .value.IPv4Address | split("/")[0]')

curl "http://$eventapi:8080/v1/events?lat=0&lon=0"
```
