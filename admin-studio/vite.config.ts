import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "/afkgame/admin/",
  server: {
    host: "127.0.0.1",
    port: 18789,
    proxy: {
      "/api": "http://127.0.0.1:18788",
    },
  },
});
