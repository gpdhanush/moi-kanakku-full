import { useState } from "react";
import { Calendar, Plus, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AIButton } from "@/components/assistant/AIButton";
import { AIChat } from "@/components/assistant/AIChat";
import { WhatsAppButton } from "./WhatsAppButton";

export function FloatingActions() {
  const [assistantOpen, setAssistantOpen] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
      {assistantOpen && <AIChat onClose={() => setAssistantOpen(false)} />}
      <div className="fixed bottom-6 right-6 z-40 hidden flex-col gap-3 md:flex" aria-label="Quick actions">
        <AIButton onClick={() => setAssistantOpen((open) => !open)} />
        <WhatsAppButton compact />
        <Button asChild size="icon" className="size-12 rounded-full bg-secondary text-secondary-foreground shadow-cinematic" aria-label="Book a meeting">
          <a href="#meeting"><Calendar aria-hidden="true" /></a>
        </Button>
      </div>
      <div className="fixed bottom-5 right-5 z-40 md:hidden">
        {mobileOpen && (
          <div className="mb-3 grid gap-3">
            <AIButton onClick={() => setAssistantOpen((open) => !open)} />
            <WhatsAppButton compact />
            <Button asChild size="icon" className="size-12 rounded-full bg-secondary text-secondary-foreground shadow-cinematic" aria-label="Book a meeting">
              <a href="#meeting"><Calendar aria-hidden="true" /></a>
            </Button>
          </div>
        )}
        <Button type="button" size="icon" className="size-13 rounded-full bg-primary text-primary-foreground shadow-cinematic" onClick={() => setMobileOpen((open) => !open)} aria-label="Toggle quick actions">
          {mobileOpen ? <X aria-hidden="true" /> : <Plus aria-hidden="true" />}
        </Button>
      </div>
    </>
  );
}
