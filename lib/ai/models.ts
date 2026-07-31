export const DEFAULT_CHAT_MODEL = "deepseek/chat-model";

export const titleModel = {
  description: "Fast model for title generation",
  id: "deepseek/chat-model",
  name: "DeepSeek Chat",
  provider: "deepseek",
};

export type ModelCapabilities = {
  tools: boolean;
  vision: boolean;
  reasoning: boolean;
};

export type ChatModel = {
  id: string;
  name: string;
  provider: string;
  description: string;
};

const MODEL_CAPABILITIES: Record<string, ModelCapabilities> = {
  "deepseek/chat-model": { reasoning: false, tools: true, vision: false },
  "deepseek/chat-model-reasoning": {
    reasoning: true,
    tools: false,
    vision: false,
  },
};

export const chatModels: ChatModel[] = [
  {
    description: "General-purpose chat model with tool use",
    id: "deepseek/chat-model",
    name: "DeepSeek Chat",
    provider: "deepseek",
  },
  {
    description: "Reasoning model for complex problems",
    id: "deepseek/chat-model-reasoning",
    name: "DeepSeek Reasoner",
    provider: "deepseek",
  },
];

export function getCapabilities(): Promise<Record<string, ModelCapabilities>> {
  return Promise.resolve(MODEL_CAPABILITIES);
}

export const isDemo = process.env.IS_DEMO === "1";

export type GatewayModelWithCapabilities = ChatModel & {
  capabilities: ModelCapabilities;
};

export async function getAllGatewayModels(): Promise<
  GatewayModelWithCapabilities[]
> {
  const capabilities = await getCapabilities();

  return chatModels.map((model) => ({
    ...model,
    capabilities: capabilities[model.id] ?? {
      reasoning: false,
      tools: false,
      vision: false,
    },
  }));
}

export function getActiveModels(): ChatModel[] {
  return chatModels;
}

export const allowedModelIds = new Set(chatModels.map((m) => m.id));

export const modelsByProvider = chatModels.reduce(
  (acc, model) => {
    if (!acc[model.provider]) {
      acc[model.provider] = [];
    }
    acc[model.provider].push(model);
    return acc;
  },
  {} as Record<string, ChatModel[]>
);

export type ModelAvailability = "healthy" | "impacted" | "unknown";

export function getModelAvailability(
  modelId: string
): Promise<ModelAvailability> {
  return Promise.resolve(
    chatModels.some((item) => item.id === modelId) ? "healthy" : "unknown"
  );
}
