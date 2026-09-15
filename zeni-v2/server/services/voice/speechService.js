import { config } from '../../config/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('speech-service');

// Language hint helps Whisper accuracy for non-English audio significantly —
// pass an ISO-639-1 code when the client knows it, omit for auto-detect.
export async function transcribeAudio({ audioBase64, format = 'wav', language = null }) {
  if (!config.ai.openRouterApiKey) {
    return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'OPENROUTER_API_KEY not configured' };
  }

  try {
    const res = await fetch(`${config.ai.openRouterBaseUrl}/audio/transcriptions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.ai.openRouterApiKey}`,
      },
      body: JSON.stringify({
        model: config.voice.sttModel,
        input_audio: { data: audioBase64, format },
        ...(language ? { language } : {}),
      }),
    });

    if (!res.ok) {
      const text = await res.text();
      logger.error('transcription failed', { status: res.status });
      return { ok: false, status: 'PROVIDER_ERROR', detail: text };
    }

    const data = await res.json();
    return { ok: true, text: data.text, usage: data.usage };
  } catch (err) {
    logger.error('transcription request threw', { message: err.message });
    return { ok: false, status: 'PROVIDER_UNREACHABLE', error: err.message };
  }
}

async function synthesizeViaElevenLabs(text, languageCode) {
  const res = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${config.voice.elevenLabsVoiceId}`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': config.voice.elevenLabsApiKey,
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_v3',
        ...(languageCode ? { language_code: languageCode } : {}),
      }),
    }
  );

  if (!res.ok) {
    const detail = await res.text();
    return { ok: false, status: 'PROVIDER_ERROR', detail };
  }

  const arrayBuffer = await res.arrayBuffer();
  return { ok: true, audioBase64: Buffer.from(arrayBuffer).toString('base64'), format: 'mp3' };
}

async function synthesizeViaOpenRouter(text) {
  const res = await fetch(`${config.ai.openRouterBaseUrl}/audio/speech`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.ai.openRouterApiKey}`,
    },
    body: JSON.stringify({
      model: config.voice.openRouterTtsModel,
      input: text,
      voice: config.voice.openRouterTtsVoice,
      response_format: 'mp3', // must be explicit — this endpoint defaults to raw pcm otherwise
    }),
  });

  if (!res.ok) {
    const detail = await res.text();
    return { ok: false, status: 'PROVIDER_ERROR', detail };
  }

  const arrayBuffer = await res.arrayBuffer();
  return { ok: true, audioBase64: Buffer.from(arrayBuffer).toString('base64'), format: 'mp3' };
}

// languageCode is an ElevenLabs-style code (e.g. 'mr' for Marathi, 'hi', 'ja')
// — only used on the ElevenLabs path; OpenRouter's TTS models don't take one.
export async function synthesizeSpeech(text, languageCode = null) {
  if (config.voice.elevenLabsApiKey && config.voice.elevenLabsVoiceId) {
    try {
      return await synthesizeViaElevenLabs(text, languageCode);
    } catch (err) {
      logger.error('elevenlabs request threw, falling back to openrouter', { message: err.message });
    }
  }

  if (!config.ai.openRouterApiKey) {
    return { ok: false, status: 'NOT_IMPLEMENTED', reason: 'No TTS provider configured' };
  }

  try {
    return await synthesizeViaOpenRouter(text);
  } catch (err) {
    logger.error('openrouter tts request threw', { message: err.message });
    return { ok: false, status: 'PROVIDER_UNREACHABLE', error: err.message };
  }
}
