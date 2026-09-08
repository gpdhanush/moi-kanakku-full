import { Sparkles } from "lucide-react";
import { useState } from "react";

export const APP_LOGO_SRC = "/logo-new.png";

interface LogoProps {
  className?: string;
  iconSize?: number;
  showText?: boolean;
  text?: string;
  noBox?: boolean;
}

export function Logo({
  className = "",
  iconSize = 24,
  showText = false,
  text = "Moi Kanakku Admin",
  noBox = false,
}: LogoProps) {
  const [logoError, setLogoError] = useState(false);

  const sizeMatch = className.match(/h-(\d+)/);
  const containerSize = sizeMatch ? `h-${sizeMatch[1]} w-${sizeMatch[1]}` : "h-8 w-8";
  const isLarge =
    className.includes("h-24") ||
    className.includes("h-20") ||
    className.includes("h-16") ||
    className.includes("h-12");

  if (noBox) {
    return (
      <div className={`flex items-center gap-2 ${className}`}>
        {!logoError ? (
          <img
            src={APP_LOGO_SRC}
            alt="Moi Kanakku"
            className={className || `h-${iconSize} w-${iconSize} object-contain`}
            style={!className ? { width: iconSize, height: iconSize } : undefined}
            onError={() => setLogoError(true)}
          />
        ) : (
          <Sparkles
            className="text-primary"
            style={{ width: `${iconSize}px`, height: `${iconSize}px` }}
          />
        )}
        {showText && (
          <span className="font-semibold text-foreground">{text}</span>
        )}
      </div>
    );
  }

  return (
    <div className={`flex items-center gap-2 ${className}`}>
      <div
        className={`flex items-center justify-center overflow-hidden rounded-lg bg-black ${containerSize}`}
      >
        {!logoError ? (
          <img
            src={APP_LOGO_SRC}
            alt="Moi Kanakku"
            className={`object-contain ${isLarge ? "p-1" : "h-full w-full p-0.5"}`}
            onError={() => setLogoError(true)}
          />
        ) : (
          <Sparkles
            className="text-primary-foreground"
            style={{ width: `${iconSize}px`, height: `${iconSize}px` }}
          />
        )}
      </div>
      {showText && (
        <span className="font-semibold text-foreground">{text}</span>
      )}
    </div>
  );
}
