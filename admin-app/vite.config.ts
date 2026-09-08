import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => ({
  // Base public path when served in production
  // Use "/" for root deployment, or "/subdirectory/" for subdirectory deployment
  // Can be overridden with VITE_BASE_URL environment variable
  base: process.env.VITE_BASE_URL || "/",
  server: {
    host: "::",
    port: 8080,
  },
  plugins: [react(), mode === "development" && componentTagger()].filter(
    Boolean
  ),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
    // Ensure React is properly resolved
    dedupe: ["react", "react-dom"],
  },
  build: {
    cssCodeSplit: true,
    // Disable source maps in production to prevent reverse engineering
    sourcemap: mode === "development",
    // Increase chunk size warning limit
    chunkSizeWarningLimit: 1000,
    // Use Vite's built-in Oxc minifier
    minify: "oxc",
    // Target modern browsers for better optimization
    target: "esnext",
    // CommonJS options for better compatibility
    commonjsOptions: {
      include: [/node_modules/],
      transformMixedEsModules: true,
    },
    // Optimize code splitting
    rollupOptions: {
      output: {
        // Manual chunk splitting for better caching
        manualChunks: (moduleId) => {
          if (/node_modules\/(react|react-dom|react-router-dom)/.test(moduleId)) {
            return "react-vendor";
          }
          if (/node_modules\/@radix-ui\/(react-dialog|react-dropdown-menu|react-select|react-tabs|react-toast)/.test(moduleId)) {
            return "ui-vendor";
          }
          if (moduleId.includes("node_modules/@tanstack/react-query")) {
            return "query-vendor";
          }
          if (/node_modules\/(react-hook-form|@hookform\/resolvers|zod)/.test(moduleId)) {
            return "form-vendor";
          }
          if (moduleId.includes("node_modules/recharts")) {
            return "chart-vendor";
          }
          if (/node_modules\/(date-fns|react-day-picker)/.test(moduleId)) {
            return "date-vendor";
          }
        },
        // Optimize chunk file names
        chunkFileNames: "assets/js/[name]-[hash].js",
        entryFileNames: "assets/js/[name]-[hash].js",
        assetFileNames: "assets/[ext]/[name]-[hash].[ext]",
      },
    },
  },
  // Optimize dependencies
  optimizeDeps: {
    include: [
      "react",
      "react-dom",
      "react-router-dom",
      "@tanstack/react-query",
    ],
  },
}));
