"""
Open events JSON Rest API
Uses Conexxion to serve REST API via SWAGGER file
"""

import os
import sys
import logging
import elasticsearch

ELASTICSEARCH_URL = os.environ.get("ELASTICSEARCH_URL", "http://elasticsearch:9200/")
es = elasticsearch.Elasticsearch([ELASTICSEARCH_URL])

ES_INDEX_NAME = os.environ.get("ES_INDEX_NAME", "events")
ES_DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


def search(**kwargs):
    """Return events"""

    query = {}

    if "startDate" in kwargs:
        start_date = {"query": {"bool": {"must": [{"range": {
            "startDate": {"gte": kwargs["startDate"]}
        }}]}}}
        query = {**query, **start_date}

    if "endDate" in kwargs:
        end_date = {"query": {"bool": {"must": [{"range": {
            "startDate": {"lte": kwargs["endDate"]}
        }}]}}}
        query = {**query, **end_date}

    if "geoDistance" in kwargs:
        # logging.info(f"{kwargs['geoDistance']}")
        geo_distance = {"query": {"bool": {"filter": {"geo_distance": {
            "location.x-es-geopoint": [
                float(kwargs["geoDistance"][0]),
                float(kwargs["geoDistance"][1])
            ],
            "distance": kwargs["geoDistance"][2]
        }}}}}
        query = {**query, **geo_distance}


    if "query" in kwargs:
        querystring = kwargs.get("query")
        query_string = {"query": {"bool": {
            "should": [
                {"match": {"name": querystring}},
                {"match": {"description": querystring}},
                {"match": {"location.name": querystring}},
                {"match": {"organizer.name": querystring}},
                {"match": {"x-tags": querystring}},
                {"match": {"x-category": querystring}}
            ],
            "minimum_should_match": 1
        }}}
        query = {**query, **query_string}

    logging.info(f"query: {query}")
    res = es.search(index=ES_INDEX_NAME, body=query)
    logging.info("\nGot %d Hits.", res['hits']['total'])

    # for hit in res['hits']['hits']:
    #     logging.info(hit['_source'])

    response = [hit['_source'] for hit in res['hits']['hits']]
    return response
    # or https://tools.ietf.org/html/rfc7807#section-3.1


def post(event):
    """Create  event"""
    return put(None, event)
    # return {"code": 321, "message": "Event was created"}


def get(id):
    """Return single event"""

    pet = es.get(index=ES_INDEX_NAME, doc_type='event', id=id)
    return pet or ('Not found', 404)


def put(id, event):
    """update event"""

    if event.get("location", {}).get("geo"):
        event["location"]["x-es-geopoint"] = [
            float(event["location"]["geo"]["longitude"]),
            float(event["location"]["geo"]["latitude"])
        ]
        event["location"]["x-es-geoshape"] = {
            "type": "point",
            "coordinates": [
                float(event["location"]["geo"]["longitude"]),
                float(event["location"]["geo"]["latitude"])
            ]
        }

    # logging.info(f"event: {event}")

    result = {}
    try:
        result = es.index(index=ES_INDEX_NAME, doc_type='event', id=id,
                          body=event)
    except elasticsearch.ElasticsearchException as err:
        logging.info(f"elasticsearch.ElasticsearchException: {err}")
    except:
        logging.info("Unexpected error:", sys.exc_info()[0])

    message = ""
    if "created" in result:
        message = f"Creating event {id}"
        # event['created_date'] = datetime.utcnow()
    else:
        message = f"Updating event {id}"

    return {"code": 123, "message": message}, (201 if "created" in result else 200)
    # see https://tools.ietf.org/html/rfc7807#section-3.1
