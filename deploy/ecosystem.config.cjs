"use strict";
/** @type {import('pm2').StartOptions} */
module.exports = {
  apps: [
    {
      cwd: "/var/www/chatbot",
      env: {
        HOSTNAME: "0.0.0.0",
        NODE_ENV: "production",
        NODE_OPTIONS: "--max-old-space-size=512",
        PORT: "3001",
      },
      exec_mode: "fork",
      instances: 1,
      max_memory_restart: "768M",
      name: "chatbot",
      script: "server.js",
      watch: false,
    },
  ],
};
