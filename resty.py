import logging
import connexion
from connexion.resolver import RestyResolver
from flask_cors import CORS

logging.basicConfig(level=logging.INFO)

app = connexion.FlaskApp(__name__)
app.add_api('openapi.yaml',
    arguments={'title': 'RestyResolver Example'},
    resolver=RestyResolver('api'),
    strict_validation=True,
    validate_responses=True)

CORS(app.app)

@app.route('/spec')
def spec():
    return app.app.send_static_file('spec.html')

if __name__ == '__main__':
    app.run(debug=False)
