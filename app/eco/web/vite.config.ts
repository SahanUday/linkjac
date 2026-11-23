import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import jac from "@jac/vite";

export default defineConfig({
    plugins: [jac(), react()],
});
