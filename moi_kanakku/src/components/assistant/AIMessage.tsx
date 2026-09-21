import { cn } from "@/lib/utils";

export type ChatMessage = {
  id: string;
  role: "assistant" | "user";
  content: string;
};

export function AIMessage({ message }: { message: ChatMessage }) {
  return (
    <div className={cn("flex", message.role === "user" ? "justify-end" : "justify-start")}>
      <p className={cn("max-w-[85%] rounded-lg px-4 py-3 text-sm leading-6", message.role === "user" ? "bg-primary text-primary-foreground" : "bg-secondary text-secondary-foreground")}>
        {message.content}
      </p>
    </div>
  );
}
