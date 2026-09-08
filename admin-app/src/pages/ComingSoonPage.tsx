import { type LucideIcon } from "lucide-react";
import { PageTitle } from "@/components/ui/page-title";
import { usePageMeta } from "@/hooks/usePageMeta";

interface ComingSoonPageProps {
  title: string;
  description: string;
  icon: LucideIcon;
}

export function ComingSoonPage({ title, description, icon }: ComingSoonPageProps) {
  const metaElement = usePageMeta({ title, description });

  return (
    <>
      {metaElement}
      <div className="space-y-6 animate-fade-in">
        <PageTitle title={title} icon={icon} description={description} />
        <div className="glass-card rounded-xl p-8 text-center">
          <p className="text-muted-foreground">
            This module will be connected once the API details are provided.
          </p>
        </div>
      </div>
    </>
  );
}
