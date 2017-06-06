import logging
import connexion
from connexion.resolver import RestyResolver
from flask_cors import CORS

logging.basicConfig(level=logging.INFO)
# logging.basicConfig(level=logging.DEBUG)

app = connexion.FlaskApp(__name__)
app.add_api('openapi.yaml',
    arguments={'title': 'RestyResolver Example'},
    resolver=RestyResolver('api'),
    strict_validation=True,
    validate_responses=True)
    # strict_validation=False,
    # validate_responses=False)

# http://flask.pocoo.org/docs/0.12/api/#flask.Flask.default_config
app.app.config["JSON_AS_ASCII"] = False

CORS(app.app)


@app.route('/spec')
def spec():
    return app.app.send_static_file('spec.html')

if __name__ == '__main__':
    app.run(debug=False)
    # app.run(debug=True)
