"use strict";
/** @type {import('pm2').StartOptions} */
module.exports = {
  apps: [
    {
      args: "start -p 3000",
      cwd: "/var/www/chatbot",
      env: {
        HOSTNAME: "0.0.0.0",
        NODE_ENV: "production",
        PORT: "3000",
      },
      exec_mode: "fork",
      instances: 1,
      max_memory_restart: "512M",
      name: "chatbot",
      script: "node_modules/next/dist/bin/next",
      watch: false,
    },
  ],
};
