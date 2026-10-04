import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

export type Lang = "ta" | "en";
const Ctx = createContext<{ lang: Lang; setLang: (l: Lang) => void }>({ lang: "ta", setLang: () => {} });

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>("ta");
  useEffect(() => {
    const fromQuery = new URLSearchParams(window.location.search).get("lang");
    const s =
      fromQuery === "en" || fromQuery === "ta"
        ? fromQuery
        : localStorage.getItem("preferred-language") || localStorage.getItem("moi-lang");
    if (s === "en" || s === "ta") setLangState(s);
  }, []);
  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.classList.toggle("lang-ta", lang === "ta");
    document.documentElement.classList.toggle("lang-en", lang === "en");
    document.body.classList.toggle("lang-ta", lang === "ta");
    document.body.classList.toggle("lang-en", lang === "en");
  }, [lang]);
  const setLang = (l: Lang) => {
    setLangState(l);
    localStorage.setItem("preferred-language", l);
    localStorage.setItem("moi-lang", l);
  };
  return <Ctx.Provider value={{ lang, setLang }}>{children}</Ctx.Provider>;
}

export const useLang = () => useContext(Ctx);

export function T({ ta, en }: { ta: ReactNode; en: ReactNode }) {
  const { lang } = useLang();
  return <>{lang === "ta" ? ta : en}</>;
}

export function useT() {
  const { lang } = useLang();
  return (ta: string, en: string) => (lang === "ta" ? ta : en);
}
