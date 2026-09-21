import { MessageCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { whatsappMessages } from "@/data/company";
import { getWhatsAppUrl } from "@/utils/whatsapp";

export function WhatsAppButton({ message = whatsappMessages.general, compact = false }: { message?: string; compact?: boolean }) {
  return (
    <Button asChild size={compact ? "icon" : "default"} className={compact ? "size-12 rounded-full bg-whatsapp text-whatsapp-foreground shadow-cinematic" : "rounded-full bg-whatsapp text-whatsapp-foreground hover:bg-whatsapp/90"}>
      <a href={getWhatsAppUrl(message)} target="_blank" rel="noreferrer" aria-label="Start WhatsApp chat with G.K Tech">
        <MessageCircle aria-hidden="true" />
        {!compact && <span>WhatsApp</span>}
      </a>
    </Button>
  );
}
