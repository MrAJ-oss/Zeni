import base64
import json
import os
import tempfile
from pathlib import Path

import numpy as np
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from resemblyzer import VoiceEncoder, preprocess_wav

app = FastAPI(title="Zeni Voice Auth")
encoder = VoiceEncoder()
API_KEY = os.environ.get("VOICE_AUTH_API_KEY")

# Enrollments persist as plain JSON on disk — this is a v1 store, not a
# production database. Fine for one user's own devices; would need a real
# DB (and encryption at rest) before ever serving more than that.
STORE_PATH = Path(__file__).parent / "enrollments.json"
VERIFY_THRESHOLD = 0.75  # cosine similarity — resemblyzer's typical same-speaker range


def load_store():
    if STORE_PATH.exists():
        return json.loads(STORE_PATH.read_text())
    return {}


def save_store(store):
    STORE_PATH.write_text(json.dumps(store))


def check_auth(authorization):
    if API_KEY and authorization != f"Bearer {API_KEY}":
        raise HTTPException(status_code=401, detail="invalid credentials")


def audio_to_embedding(audio_base64: str) -> np.ndarray:
    audio_bytes = base64.b64decode(audio_base64)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=True) as f:
        f.write(audio_bytes)
        f.flush()
        wav = preprocess_wav(f.name)
    return encoder.embed_utterance(wav)


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


class EnrollRequest(BaseModel):
    userId: str
    audio: str  # base64 WAV


class VerifyRequest(BaseModel):
    userId: str
    audio: str


@app.get("/health")
def health():
    return {"ok": True, "enrolled_users": len(load_store())}


@app.post("/enroll")
def enroll(req: EnrollRequest, authorization: str = Header(default=None)):
    check_auth(authorization)
    try:
        embedding = audio_to_embedding(req.audio)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"could not process audio: {e}")

    store = load_store()
    store[req.userId] = embedding.tolist()
    save_store(store)
    return {"ok": True, "enrolled": True}


@app.post("/verify")
def verify(req: VerifyRequest, authorization: str = Header(default=None)):
    check_auth(authorization)
    store = load_store()
    if req.userId not in store:
        return {"ok": True, "verified": False, "reason": "NOT_ENROLLED"}

    try:
        candidate_embedding = audio_to_embedding(req.audio)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"could not process audio: {e}")

    enrolled_embedding = np.array(store[req.userId])
    similarity = cosine_similarity(candidate_embedding, enrolled_embedding)

    return {
        "ok": True,
        "verified": similarity >= VERIFY_THRESHOLD,
        "confidence": similarity,
    }
