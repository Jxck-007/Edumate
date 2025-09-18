from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

RASA_API_URL = "http://localhost:5005/webhooks/rest/webhook"

@app.route("/webhook", methods=["POST"])
def webhook():
    user_message = request.json["message"]
    
    # Forward the message to the Rasa server
    rasa_response = requests.post(
        RASA_API_URL,
        json={"sender": "user", "message": user_message}
    )
    
    return jsonify(rasa_response.json())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)