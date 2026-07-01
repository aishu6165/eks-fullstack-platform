import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// In production, CloudFront routes /api/* to the ALB, so the app calls a
// relative /api and needs no API URL baked in.
// For local dev only, uncomment the proxy and point it at the ALB (or a
// local backend) so `npm run dev` can reach the API.
export default defineConfig({
  plugins: [react()],
  // server: {
  //   proxy: {
  //     "/api": { target: "http://<alb-dns>", changeOrigin: true },
  //   },
  // },
});
