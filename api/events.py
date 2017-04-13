from elasticsearch import Elasticsearch
from datetime import date, timedelta, datetime
import logging
import os

elasticsearch_url = os.environ.get("ELASTICSEARCH_URL", "http://elasticsearch:9200/")
es = Elasticsearch([elasticsearch_url])

ES_INDEX_NAME = os.environ.get("ES_INDEX_NAME", "events")
ES_DATE_FORMAT = '%Y-%m-%dT%H:%M:%SZ'


def search(lat, lon, radius=10, start_date="", end_date="", query="",
               category=""):
    """Return events"""

    querystring = query

    if not start_date:
        today = date.today()
        start_date = today.strftime(ES_DATE_FORMAT)
        logging.info("start_date %s", start_date)

    if not end_date:
        future = date.today() + timedelta(days=120)
        end_date = future.strftime(ES_DATE_FORMAT)
        logging.info("end_date %s", end_date)

    query = {
        "query": {
            "bool": {
                "must": [
                    {
                        "range": {
                            "start_date": {
                                "gte": start_date,
                                "lte": end_date
                            }
                        }
                    }
                ],
                "filter": {
                    "geo_distance": {
                        "distance": "%dkm" % radius,
                        "venue.location": {
                            "lat": lat,
                            "lon": lon
                        }
                    }
                }
            }
        }
    }
    if querystring:
        query["query"]["bool"]["should"] = [
            {"match": {"title": querystring}},
            {"match": {"description": querystring}},
            {"match": {"venue.name": querystring}},
            {"match": {"tags": querystring}},
            {"match": {"category": querystring}}
        ]
        query["query"]["bool"]["minimum_should_match"] = 1

    if category:
        query["query"]["bool"]["must"].append(
            {"match": {"category": category}}
        )

    res = es.search(index=ES_INDEX_NAME, body=query)
    logging.info(query)
    logging.info("\nGot %d Hits.", res['hits']['total'])

    response = []
    # print(res['hits']['hits'])
    for hit in res['hits']['hits']:
        # logging.info(hit)
        # hit["_source"]["location"] = {
        #     "lat": hit["_source"]["location"][1],
        #     "lon": hit["_source"]["location"][0]
        #     # "lat": hit["_source"]["venue"]["location"][1],
        #     # "lon": hit["_source"]["venue"]["location"][0]
        # }
        response.append(hit['_source'])

    return response


def post(event):
    """Create  event"""
    put(None, event)
    return {"code": 321, "message": "Event was created"}


def get(event_id):
    """Return single event"""

    pet = es.get(index=ES_INDEX_NAME, doc_type='event', id=event_id)
    return pet or ('Not found', 404)


def put(event_id, event):
    """update event"""
    result = es.index(index=ES_INDEX_NAME, doc_type='event', id=event_id,
                      body=event)
    logging.info(result)
    created = result['created']

    event['id'] = event_id

    message = "", 0
    if created:
        message = 'Creating event %s..', event_id
        event['created_date'] = datetime.utcnow()
    else:
        message = 'Updating event %s..', event_id

    return {"code": 123, "message": message}, (201 if created else 200)
