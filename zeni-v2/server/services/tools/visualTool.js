import { registerTool } from './toolRegistry.js';

// This tool does not "execute" anything server-side — it has no side effects.
// Its only job is to let the model emit a structured visual payload that the
// client renders. Registering it as a tool (rather than a special-cased field)
// means it goes through the same validation/audit path as every other tool call.
registerTool({
  name: 'show_visual',
  description: 'Display a visual alongside the spoken/text reply when the content is better shown than described: comparisons, stats, lists, status, steps.',
  inputSchema: {
    type: 'object',
    required: ['visualType', 'data'],
    properties: {
      visualType: { type: 'string', enum: ['stat', 'comparison', 'list', 'status', 'steps', 'map'] },
      title: { type: 'string' },
      data: { type: 'object' },
    },
  },
  riskLevel: 'low',
  requiresApproval: false,
  handler: async (args) => {
    return { rendered: true, visualType: args.visualType, title: args.title || null, data: args.data };
  },
});
