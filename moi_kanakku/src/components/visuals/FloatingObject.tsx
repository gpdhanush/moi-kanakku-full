import { useEffect, useRef, useState } from "react";
import gsap from "gsap";
import { registerScrollAnimations, shouldReduceMotion } from "@/animations/scroll";
import coreImage from "@/assets/gktech-cinematic-core.jpg";
import { cn } from "@/lib/utils";

export function FloatingObject({ className }: { className?: string }) {
  const wrapRef = useRef<HTMLDivElement>(null);
  const imageRef = useRef<HTMLImageElement>(null);
  const [pointer, setPointer] = useState({ x: 0, y: 0 });

  useEffect(() => {
    if (!wrapRef.current || !imageRef.current || shouldReduceMotion()) return;
    registerScrollAnimations();

    const float = gsap.to(imageRef.current, {
      y: -18,
      rotateZ: 1.5,
      duration: 4.8,
      yoyo: true,
      repeat: -1,
      ease: "sine.inOut",
    });

    const scroll = gsap.to(imageRef.current, {
      scale: 1.12,
      rotateY: 8,
      rotateX: -5,
      ease: "none",
      scrollTrigger: {
        trigger: wrapRef.current,
        start: "top top",
        end: "bottom top",
        scrub: true,
      },
    });

    return () => {
      float.kill();
      scroll.scrollTrigger?.kill();
      scroll.kill();
    };
  }, []);

  return (
    <div
      ref={wrapRef}
      className={cn("relative mx-auto aspect-square w-full max-w-2xl perspective-dramatic", className)}
      onPointerMove={(event) => {
        const rect = event.currentTarget.getBoundingClientRect();
        setPointer({
          x: (event.clientX - rect.left - rect.width / 2) / rect.width,
          y: (event.clientY - rect.top - rect.height / 2) / rect.height,
        });
      }}
      onPointerLeave={() => setPointer({ x: 0, y: 0 })}
    >
      <div className="absolute inset-8 rounded-full bg-hero-glow blur-3xl" aria-hidden="true" />
      <img
        ref={imageRef}
        src={coreImage}
        width={1600}
        height={1200}
        alt="Abstract G.K Tech digital product core"
        className="relative z-10 h-full w-full object-contain mix-blend-screen transition-transform duration-500 ease-out"
        style={{ transform: `rotateX(${pointer.y * -10}deg) rotateY(${pointer.x * 12}deg)` }}
      />
    </div>
  );
}
