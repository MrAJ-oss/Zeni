// services/ai/modelRouter.js
// Decides WHICH model handles a request and handles fallback if the primary fails.
// AIService calls this; this calls the provider. Provider-specific code never
// leaks above this layer.

import { config } from '../../config/index.js';
import { callOpenRouter } from './openRouterProvider.js';
import { createLogger } from '../../utils/logger.js';

const logger = createLogger('model-router');

export async function routeRequest({ messages, tools, maxTokens, temperature, preferredModel }) {
  const primary = preferredModel || config.ai.defaultModel;

  let result = await callOpenRouter({ model: primary, messages, tools, maxTokens, temperature });

  if (!result.ok && result.status !== 'NOT_IMPLEMENTED') {
    logger.warn('primary model failed, trying fallback', { primary, error: result.error });
    result = await callOpenRouter({
      model: config.ai.fallbackModel,
      messages, tools, maxTokens, temperature,
    });
    if (result.ok) result.usedFallback = true;
  }

  return result;
}