import { useId, useState } from "react";
import { Link } from "@tanstack/react-router";
import { Minus, Plus } from "lucide-react";
import { useLang } from "@/lib/lang";
import { cn } from "@/lib/utils";
import homeFaqs from "@/data/faq.json";

export type FaqItemData = {
  id: string;
  questionEn: string;
  questionTa: string;
  answerEn: string;
  answerTa: string;
  hasReadMore: boolean;
};

function FaqRow({
  item,
  open,
  onToggle,
}: {
  item: FaqItemData;
  open: boolean;
  onToggle: () => void;
}) {
  const { lang } = useLang();
  const panelId = useId();
  const question = lang === "ta" ? item.questionTa : item.questionEn;
  const answer = lang === "ta" ? item.answerTa : item.answerEn;
  const readMoreLabel = lang === "ta" ? "மேலும் அறிய" : "Read more";

  return (
    <div className="border-b border-[#EAEAF5] last:border-b-0">
      <button
        type="button"
        onClick={onToggle}
        aria-expanded={open}
        aria-controls={panelId}
        className="flex w-full items-center justify-between gap-4 py-5 text-left sm:py-6"
      >
        <span className="pr-2 text-base font-semibold tracking-tight text-[#1D2D35] sm:text-lg">
          {question}
        </span>
        <span
          className={cn(
            "flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#E8F1F3] text-[#005F73] transition-transform duration-300",
            open && "rotate-180",
          )}
          aria-hidden
        >
          <span className="relative grid place-items-center">
            <Plus
              className={cn(
                "absolute h-4 w-4 transition-all duration-300",
                open ? "scale-50 rotate-90 opacity-0" : "scale-100 rotate-0 opacity-100",
              )}
            />
            <Minus
              className={cn(
                "h-4 w-4 transition-all duration-300",
                open ? "scale-100 rotate-0 opacity-100" : "scale-50 -rotate-90 opacity-0",
              )}
            />
          </span>
        </span>
      </button>

      <div
        id={panelId}
        className={cn(
          "grid transition-[grid-template-rows] duration-300 ease-out",
          open ? "grid-rows-[1fr]" : "grid-rows-[0fr]",
        )}
      >
        <div className="overflow-hidden">
          <div className="pb-6 pt-0">
            <p className="text-sm leading-[1.6] text-[#1D2D35]/85 sm:text-[15px]">{answer}</p>
            {item.hasReadMore && (
              <Link
                to="/moi-app"
                className="mt-5 inline-flex items-center rounded-full border border-[#005F73]/35 bg-transparent px-4 py-1.5 text-xs font-semibold text-[#005F73] transition-colors hover:border-[#005F73] hover:bg-[#005F73]/8 hover:text-white"
              >
                {readMoreLabel}
              </Link>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export function FaqAccordion({
  items = homeFaqs as FaqItemData[],
  className,
}: {
  items?: FaqItemData[];
  className?: string;
}) {
  const [openId, setOpenId] = useState<string | null>(items[0]?.id ?? null);
  const { lang } = useLang();

  return (
    <section
      id="faq"
      className={cn("border-t border-b border-[#EAEAF5] bg-[#FAF8F5] py-16 md:py-24", className)}
    >
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <div className="mb-10 text-center sm:mb-12">
          <h2 className="text-2xl font-extrabold tracking-tight text-[#1D2D35] sm:text-3xl">
            {lang === "ta" ? "அடிக்கடி கேட்கப்படும் கேள்விகள்" : "Frequently asked questions"}
          </h2>
        </div>

        <div className="rounded-[5px] border border-[#EAEAF5] bg-white/70 px-4 sm:px-6">
          {items.map((item) => (
            <FaqRow
              key={item.id}
              item={item}
              open={openId === item.id}
              onToggle={() => setOpenId((id) => (id === item.id ? null : item.id))}
            />
          ))}
        </div>
      </div>
    </section>
  );
}
