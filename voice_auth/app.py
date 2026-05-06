from flask import Flask, request, jsonify
import numpy as np
import librosa
import os

app = Flask(__name__)

VOICE_PATH = "voice_db/anuj.npy"

def extract(file):
    y, sr = librosa.load(file, sr=16000)
    return np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13), axis=1)

@app.route("/enroll", methods=["POST"])
def enroll():
    file = request.files["audio"]
    file.save("temp.wav")

    feat = extract("temp.wav")
    np.save(VOICE_PATH, feat)

    return jsonify({"status": "saved"})

@app.route("/verify", methods=["POST"])
def verify():
    if not os.path.exists(VOICE_PATH):
        return jsonify({"status": "no_voice"})

    file = request.files["audio"]
    file.save("temp.wav")

    new = extract("temp.wav")
    old = np.load(VOICE_PATH)

    dist = np.linalg.norm(new - old)

    if dist < 50:
        return jsonify({"status": "allowed"})
    else:
        return jsonify({"status": "denied"})

app.run(port=5000)