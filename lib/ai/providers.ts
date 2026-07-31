import { deepseek } from "@ai-sdk/deepseek";
import {
  customProvider,
  extractReasoningMiddleware,
  wrapLanguageModel,
} from "ai";
import { isTestEnvironment } from "../constants";

const MODEL_ID_MAP: Record<string, string> = {
  "chat-model": "chat-model",
  "chat-model-reasoning": "chat-model-reasoning",
  "deepseek/chat-model": "chat-model",
  "deepseek/chat-model-reasoning": "chat-model-reasoning",
  "deepseek/deepseek-v3.2": "chat-model",
  "moonshotai/kimi-k2.5": "chat-model",
};

const productionProvider = customProvider({
  languageModels: {
    "artifact-model": deepseek("deepseek-chat"),
    "chat-model": deepseek("deepseek-chat"),
    "chat-model-reasoning": wrapLanguageModel({
      middleware: extractReasoningMiddleware({ tagName: "think" }),
      model: deepseek("deepseek-reasoner"),
    }),
    "title-model": deepseek("deepseek-chat"),
  },
});

export const myProvider = isTestEnvironment
  ? (() => {
      const {
        chatModel,
        titleModel: mockTitleModel,
      } = require("./models.mock");
      return customProvider({
        languageModels: {
          "chat-model": chatModel,
          "title-model": mockTitleModel,
        },
      });
    })()
  : productionProvider;

function resolveProviderKey(modelId: string) {
  return MODEL_ID_MAP[modelId] ?? modelId;
}

export function getLanguageModel(modelId: string) {
  return myProvider.languageModel(resolveProviderKey(modelId));
}

export function getTitleModel() {
  return myProvider.languageModel("title-model");
}
