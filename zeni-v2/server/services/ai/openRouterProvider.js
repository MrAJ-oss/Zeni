// services/ai/openRouterProvider.js
// The ONLY file in the entire codebase that talks to OpenRouter's HTTP API.
// If you ever need to call a model directly from somewhere else, that's a bug —
// route it through AIService instead.

import { config } from '../../config/index.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('openrouter-provider');

export async function callOpenRouter({ model, messages, tools, maxTokens = 1024, temperature = 0.8 }) {
  if (!config.ai.openRouterApiKey) {
    return { ok: false, error: 'OPENROUTER_API_KEY not configured', status: 'NOT_IMPLEMENTED' };
  }

  const body = {
    model,
    messages,
    max_tokens: maxTokens,
    temperature,
    ...(tools ? { tools, tool_choice: 'auto' } : {}),
  };

  try {
    const res = await fetch(`${config.ai.openRouterBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.ai.openRouterApiKey}`,
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text();
      logger.error('openrouter request failed', { status: res.status, model });
      return { ok: false, error: `OpenRouter ${res.status}`, detail: text, status: 'PROVIDER_ERROR' };
    }

    const data = await res.json();
    const choice = data.choices?.[0];
    return {
      ok: true,
      content: choice?.message?.content ?? '',
      toolCalls: choice?.message?.tool_calls ?? null,
      annotations: choice?.message?.annotations ?? null,
      model: data.model,
      usage: data.usage,
    };
  } catch (err) {
    logger.error('openrouter request threw', { message: err.message });
    return { ok: false, error: err.message, status: 'PROVIDER_UNREACHABLE' };
  }
}
