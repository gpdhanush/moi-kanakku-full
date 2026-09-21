import { useEffect, useState } from "react";

export type AppLogoVariant = "icon" | "wordmark" | "full";

type AppLogoProps = {
  variant?: AppLogoVariant;
  className?: string;
  priority?: boolean;
};

const logoSources = {
  light: {
    icon: "/images/light-logo.png",
    wordmark: "/images/label-dark.png",
  },
  dark: {
    icon: "/images/dark-logo.png",
    wordmark: "/images/light-text.png",
  },
} as const;

export function AppLogo({ variant = "full", className = "", priority = false }: AppLogoProps) {
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    const root = document.documentElement;
    const updateTheme = () => setIsDark(root.classList.contains("dark"));
    updateTheme();

    const observer = new MutationObserver(updateTheme);
    observer.observe(root, { attributes: true, attributeFilter: ["class"] });
    return () => observer.disconnect();
  }, []);

  const theme = isDark ? logoSources.dark : logoSources.light;

  if (variant === "icon") {
    return (
      <img
        src={theme.icon}
        alt="Moi Kanakku"
        className={className}
        loading={priority ? "eager" : "lazy"}
      />
    );
  }

  if (variant === "wordmark") {
    return (
      <img
        src={theme.wordmark}
        alt="Moi Kanakku"
        className={className}
        loading={priority ? "eager" : "lazy"}
      />
    );
  }

  return (
    <span className={`inline-flex items-center gap-3 ${className}`}>
      <img
        src={theme.icon}
        alt=""
        aria-hidden="true"
        className="size-9 object-contain"
        loading={priority ? "eager" : "lazy"}
      />
      <img
        src={theme.wordmark}
        alt="Moi Kanakku"
        className="h-7 w-auto max-w-[10rem] object-contain"
        loading={priority ? "eager" : "lazy"}
      />
    </span>
  );
}
