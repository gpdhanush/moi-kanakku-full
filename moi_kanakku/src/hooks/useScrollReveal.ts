import { useEffect, useRef } from "react";
import { revealOnScroll } from "@/animations/reveal";

export function useScrollReveal<T extends HTMLElement>() {
  const ref = useRef<T>(null);

  useEffect(() => {
    if (!ref.current) return;
    revealOnScroll(ref.current);
  }, []);

  return ref;
}
