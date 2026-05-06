from flask import Flask, request
import librosa
import numpy as np

app = Flask(__name__)

@app.route("/emotion", methods=["GET"])
def emotion():
    try:
        y, sr = librosa.load("temp.wav")

        energy = np.mean(librosa.feature.rms(y=y))
        pitch = np.mean(librosa.yin(y, fmin=50, fmax=300))

        if energy < 0.02:
            return "sad"
        elif energy > 0.05:
            return "angry"
        elif pitch > 200:
            return "happy"
        else:
            return "neutral"

    except Exception as e:
        return "neutral"

if __name__ == "__main__":
    app.run(port=5001)