from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import librosa
import os

app = Flask(__name__)
CORS(app)

VOICE_DB_PATH = "voice_db"
os.makedirs(VOICE_DB_PATH, exist_ok=True)

def get_voice_path(device_id):
    safe_id = device_id.replace("/", "_").replace("\\", "_").replace(":", "_")
    return os.path.join(VOICE_DB_PATH, f"{safe_id}.npy")

def extract_features(file_path):
    y, sr = librosa.load(file_path, sr=16000)
    mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
    return np.mean(mfcc, axis=1)

@app.route("/", methods=["GET"])
def root():
    return jsonify({"status": "Zeni Voice Auth running"})

@app.route("/enroll", methods=["POST"])
def enroll():
    try:
        device_id = request.form.get("deviceId", "default")

        if "audio" not in request.files:
            return jsonify({"status": "error", "message": "No audio file"}), 400

        file = request.files["audio"]
        temp_path = f"temp_enroll_{device_id}.wav"
        file.save(temp_path)

        features = extract_features(temp_path)
        np.save(get_voice_path(device_id), features)
        os.remove(temp_path)

        return jsonify({"status": "enrolled", "message": "Voice saved"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route("/verify", methods=["POST"])
def verify():
    try:
        device_id = request.form.get("deviceId", "default")
        voice_path = get_voice_path(device_id)

        if not os.path.exists(voice_path):
            return jsonify({"status": "allowed", "message": "No voice enrolled"})

        if "audio" not in request.files:
            return jsonify({"status": "error", "message": "No audio file"}), 400

        file = request.files["audio"]
        temp_path = f"temp_verify_{device_id}.wav"
        file.save(temp_path)

        new_features = extract_features(temp_path)
        saved_features = np.load(voice_path)
        distance = np.linalg.norm(new_features - saved_features)
        os.remove(temp_path)

        if distance < 50:
            return jsonify({"status": "allowed", "distance": float(distance)})
        else:
            return jsonify({"status": "denied", "distance": float(distance)})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)