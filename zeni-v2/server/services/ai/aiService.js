// services/ai/aiService.js
// The abstraction the REST of Zeni talks to. Nothing outside this /ai folder
// should know OpenRouter exists. This is where personality, memory, emotion,
// device context, and tool results get assembled into a single request.

import { routeRequest } from './modelRouter.js';
import { buildSystemPrompt } from '../../config/personality.js';
import { retrieveRelevantMemories } from '../memory/memoryService.js';
import { getRecentMessages, addMessage } from '../conversation/conversationService.js';
import { listToolDefinitions, executeTool } from '../tools/toolRegistry.js';
import { createLogger } from '../../utils/logger.js';
import { config } from '../../config/index.js';

const logger = createLogger('ai-service');
const MAX_TOOL_ITERATIONS = 4; // hard cap so a tool-calling loop can't run forever

export async function getResponse({
  userId,
  conversationId,
  userMessage,
  deviceContext = null,
  emotionalContext = null, // pre-fetched from NOVA, or null if unavailable
  mode = 'default',
}) {
  const memories = retrieveRelevantMemories({ userId, queryText: userMessage, limit: 8 });
  const history = getRecentMessages({ conversationId, limit: 20 });

  const systemPrompt = buildSystemPrompt({
    memories,
    emotionalContext,
    deviceContext,
    mode,
  });

  let messages = [
    { role: 'system', content: systemPrompt },
    ...history,
    { role: 'user', content: userMessage },
  ];

  const tools = listToolDefinitions();
  // Server-side, resolved by OpenRouter itself before the response reaches
  // us — never appears in result.toolCalls, so it never enters the local
  // execute-and-loop path below. It just enriches the model's own reply.
  if (config.ai.webSearchEnabled) {
    tools.push({ type: 'openrouter:web_search' });
  }
  let iterations = 0;
  let finalResult = null;
  let visual = null;
  let contactAction = null;

  while (iterations < MAX_TOOL_ITERATIONS) {
    iterations++;
    const result = await routeRequest({ messages, tools: tools.length ? tools : undefined });

    if (!result.ok) {
      logger.error('AI request failed', { status: result.status, error: result.error });
      return { ok: false, status: result.status || 'AI_UNAVAILABLE', error: result.error };
    }

    if (!result.toolCalls || result.toolCalls.length === 0) {
      finalResult = result;
      break;
    }

    // Model wants to call tool(s) — execute through the registry (validated/authorized),
    // never directly. Append results and loop so the model can respond to them.
    messages.push({ role: 'assistant', content: result.content || '', tool_calls: result.toolCalls });

    for (const call of result.toolCalls) {
      const args = safeParseJson(call.function?.arguments);
      const toolResult = await executeTool({
        name: call.function?.name,
        args,
        userId,
        deviceId: deviceContext?.id,
      });
      if (call.function?.name === 'show_visual' && toolResult.ok) {
        visual = toolResult.result;
      }
      if (call.function?.name === 'call_contact' && toolResult.ok) {
        contactAction = toolResult.result;
      }
      messages.push({
        role: 'tool',
        tool_call_id: call.id,
        content: JSON.stringify(toolResult),
      });
    }
  }

  if (!finalResult) {
    return { ok: false, status: 'TOOL_LOOP_LIMIT', error: 'Exceeded max tool-call iterations' };
  }

  return {
    ok: true,
    content: finalResult.content,
    model: finalResult.model,
    usedFallback: !!finalResult.usedFallback,
    visual,
    citations: extractCitations(finalResult.annotations),
    contactAction,
  };
}

function extractCitations(annotations) {
  if (!annotations) return null;
  const urlCitations = annotations.filter(a => a.url_citation).map(a => ({
    title: a.url_citation?.title, url: a.url_citation?.url,
  }));
  return urlCitations.length ? urlCitations : null;
}

function safeParseJson(str) {
  try { return JSON.parse(str || '{}'); } catch { return {}; }
}

// Proactive, not conversational — nothing preceded this, so there's no user
// message to store. Only the resulting assistant message gets saved, tagged
// so the transcript is honest about what actually triggered it.
export async function generateProactiveMessage({ userId, conversationId, triggerDescription, deviceContext }) {
  const memories = retrieveRelevantMemories({ userId, queryText: triggerDescription, limit: 5 });
  const systemPrompt = buildSystemPrompt({
    memories,
    deviceContext,
    mode: `Proactive trigger: ${triggerDescription}. Greet the user naturally and briefly, like a friend who noticed — don't narrate that a trigger fired.`,
  });

  const result = await routeRequest({
    messages: [{ role: 'system', content: systemPrompt }],
    maxTokens: 200,
    temperature: 0.9,
  });

  if (!result.ok) {
    return { ok: false, status: result.status || 'AI_UNAVAILABLE', error: result.error };
  }

  addMessage({ conversationId, role: 'assistant', content: result.content, metadata: { trigger: triggerDescription } });
  return { ok: true, content: result.content };
}

// Presence trigger — one multimodal call. The vision model and the
// personality are NOT separate systems: the same system prompt (memory,
// personality, boundaries) goes in alongside the image, so she reacts to
// what she sees in her own voice in a single request, not a two-step
// "describe then roleplay" pipeline.
export async function generatePresenceReaction({ userId, conversationId, imageBase64, deviceContext }) {
  const memories = retrieveRelevantMemories({ userId, queryText: 'presence camera trigger', limit: 5 });
  const systemPrompt = buildSystemPrompt({
    memories,
    deviceContext,
    mode: `Camera trigger: the user just came into view. React like a real friend noticing them walk in — direct, no greeting, straight into something real (a callback, a tease, whatever fits). Never narrate that a camera or trigger fired.`,
  });

  const result = await routeRequest({
    messages: [{
      role: 'user',
      content: [
        { type: 'text', text: systemPrompt },
        { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}` } },
      ],
    }],
    preferredModel: config.ai.visionModel,
    maxTokens: 200,
    temperature: 0.9,
  });

  if (!result.ok) {
    return { ok: false, status: result.status || 'AI_UNAVAILABLE', error: result.error };
  }

  addMessage({ conversationId, role: 'assistant', content: result.content, metadata: { trigger: 'camera_presence' } });
  return { ok: true, content: result.content };
}
