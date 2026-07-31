import { initBotId } from "botid/client/core";

// BotId uses crypto.subtle, which browsers only expose in secure contexts (HTTPS/localhost).
if (typeof window !== "undefined" && window.isSecureContext) {
  initBotId({
    protect: [
      {
        method: "POST",
        path: "/api/chat",
      },
    ],
  });
}
