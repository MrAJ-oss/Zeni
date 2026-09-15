from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import os

app = FastAPI(title="Zeni NOVA")
analyzer = SentimentIntensityAnalyzer()
API_KEY = os.environ.get("NOVA_API_KEY")


class AnalyzeRequest(BaseModel):
    text: str
    userId: str | None = None


def classify(compound: float) -> str:
    if compound >= 0.5:
        return "positive"
    if compound >= 0.1:
        return "mildly_positive"
    if compound <= -0.5:
        return "negative"
    if compound <= -0.1:
        return "mildly_negative"
    return "neutral"


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/analyze")
def analyze(req: AnalyzeRequest, authorization: str = Header(default=None)):
    if API_KEY:
        expected = f"Bearer {API_KEY}"
        if authorization != expected:
            raise HTTPException(status_code=401, detail="invalid credentials")

    scores = analyzer.polarity_scores(req.text)
    compound = scores["compound"]

    return {
        "state": classify(compound),
        "intensity": abs(compound),
        "confidence": max(scores["pos"], scores["neg"], scores["neu"]),
        "raw": scores,
    }
