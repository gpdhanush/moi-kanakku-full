import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import "react-quill/dist/quill.snow.css";
import { unregisterServiceWorkersInDev } from "./lib/serviceWorker";

// Fire-and-forget — do not delay first paint (waiting caused a blank→flash).
void unregisterServiceWorkersInDev();

createRoot(document.getElementById("root")!).render(<App />);
