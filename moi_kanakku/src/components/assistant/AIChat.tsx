import { useMemo, useState } from "react";
import { Bot, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AIInput } from "./AIInput";
import { AIMessage, type ChatMessage } from "./AIMessage";
import { AIQuickAction } from "./AIQuickAction";

const quickActions = [
  "Build a website",
  "Build a mobile app",
  "Develop custom software",
  "AI & automation",
  "Learn about our products",
  "Get a project estimate",
  "Book a meeting",
  "Talk to G.K Tech",
];

function getMockResponse(message: string) {
  const lower = message.toLowerCase();
  if (lower.includes("moi") || lower.includes("product")) {
    return "Moi Kanakku is G.K Tech’s function-gift money tracking product. You can explore it on the product page or start a WhatsApp conversation for details.";
  }
  if (lower.includes("meeting") || lower.includes("book")) {
    return "You can use the Book Meeting action to choose a service, date and time. This prototype shows the meeting confirmation flow.";
  }
  if (lower.includes("mobile")) {
    return "G.K Tech builds mobile applications for business workflows, digital products and customer-facing experiences.";
  }
  if (lower.includes("ai") || lower.includes("automation")) {
    return "G.K Tech can design AI assistants, automation flows and practical AI solutions connected to your business process.";
  }
  return "G.K Tech can help with websites, mobile apps, custom software, UI/UX, backend APIs, cloud, databases, AI and automation. Share your idea and we can guide the next step.";
}

export function AIChat({ onClose }: { onClose: () => void }) {
  const initialMessages = useMemo<ChatMessage[]>(
    () => [
      {
        id: "intro",
        role: "assistant",
        content: "G.K Tech AI — How can we help? Choose a quick action or ask about services, products, estimates or meetings.",
      },
    ],
    [],
  );
  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);

  const send = (content: string) => {
    const userMessage: ChatMessage = { id: `user-${Date.now()}`, role: "user", content };
    const assistantMessage: ChatMessage = {
      id: `assistant-${Date.now()}`,
      role: "assistant",
      content: getMockResponse(content),
    };
    setMessages((current) => [...current, userMessage, assistantMessage]);
  };

  return (
    <section className="fixed bottom-24 right-4 z-50 flex h-[32rem] w-[calc(100vw-2rem)] max-w-md flex-col rounded-lg border border-border bg-popover shadow-cinematic sm:right-6" aria-label="G.K Tech AI assistant">
      <header className="flex items-center justify-between border-b border-border p-4">
        <div className="flex items-center gap-3">
          <div className="flex size-10 items-center justify-center rounded-full bg-primary text-primary-foreground">
            <Bot aria-hidden="true" />
          </div>
          <div>
            <h2 className="font-semibold text-popover-foreground">G.K Tech AI</h2>
            <p className="text-xs text-muted-foreground">Frontend prototype</p>
          </div>
        </div>
        <Button type="button" variant="ghost" size="icon" onClick={onClose} aria-label="Close AI assistant">
          <X aria-hidden="true" />
        </Button>
      </header>
      <div className="flex-1 space-y-3 overflow-y-auto p-4">
        {messages.map((message) => <AIMessage key={message.id} message={message} />)}
      </div>
      <div className="border-t border-border p-4">
        <div className="mb-3 flex flex-wrap gap-2">
          {quickActions.slice(0, 4).map((action) => <AIQuickAction key={action} label={action} onSelect={send} />)}
        </div>
        <AIInput onSend={send} />
      </div>
    </section>
  );
}
