"use client";

import React from "react";
import { motion, useMotionValue, useTransform, useSpring } from "framer-motion";
import { ArrowUpRight } from "lucide-react";
import { cn } from "@/lib/utils";

export type GalleryItem = {
  title: string;
  category?: string | undefined;
  image: string;
  objectPosition?: string | undefined;
};

type GenerativeArtCanvasProps = {
  isHovered: boolean;
};

function GenerativeArtCanvas({ isHovered }: GenerativeArtCanvasProps) {
  const canvasRef = React.useRef<HTMLCanvasElement | null>(null);

  React.useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId = 0;
    const numLines = 30;

    class Line {
      x = 0;
      y = 0;
      speed = 0;
      angle = 0;
      length = 0;

      constructor() {
        this.reset();
      }

      reset() {
        this.x = Math.random() * canvas!.width;
        this.y = Math.random() * canvas!.height;
        this.speed = Math.random() * 0.5 + 0.1;
        this.angle = Math.random() * Math.PI * 2;
        this.length = Math.random() * 20 + 5;
      }

      update() {
        this.x += Math.cos(this.angle) * this.speed;
        this.y += Math.sin(this.angle) * this.speed;
        if (
          this.x < 0 ||
          this.x > canvas!.width ||
          this.y < 0 ||
          this.y > canvas!.height
        ) {
          this.reset();
        }
      }

      draw() {
        ctx!.beginPath();
        ctx!.moveTo(this.x, this.y);
        ctx!.lineTo(
          this.x - Math.cos(this.angle) * this.length,
          this.y - Math.sin(this.angle) * this.length,
        );
        ctx!.strokeStyle = `rgba(144, 208, 31, ${Math.random() * 0.35 + 0.12})`;
        ctx!.lineWidth = 1;
        ctx!.stroke();
      }
    }

    const lines: Line[] = [];
    for (let i = 0; i < numLines; i++) {
      lines.push(new Line());
    }

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      if (isHovered) {
        lines.forEach((line) => {
          line.update();
          line.draw();
        });
      }
      animationFrameId = requestAnimationFrame(animate);
    };

    canvas.width = 400;
    canvas.height = 400;
    animate();

    return () => cancelAnimationFrame(animationFrameId);
  }, [isHovered]);

  return (
    <canvas
      ref={canvasRef}
      className="absolute inset-0 h-full w-full opacity-0 transition-opacity duration-500 group-hover:opacity-100"
    />
  );
}

type GalleryCardProps = {
  item: GalleryItem;
  index: number;
  onSelect?: ((index: number) => void) | undefined;
};

function GalleryCard({ item, index, onSelect }: GalleryCardProps) {
  const [isHovered, setIsHovered] = React.useState(false);
  const x = useMotionValue(0);
  const y = useMotionValue(0);

  const mouseXSpring = useSpring(x);
  const mouseYSpring = useSpring(y);

  const rotateX = useTransform(mouseYSpring, [-0.5, 0.5], ["10deg", "-10deg"]);
  const rotateY = useTransform(mouseXSpring, [-0.5, 0.5], ["-10deg", "10deg"]);

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    x.set((e.clientX - rect.left) / rect.width - 0.5);
    y.set((e.clientY - rect.top) / rect.height - 0.5);
  };

  const handleMouseLeave = () => {
    x.set(0);
    y.set(0);
  };

  const cardVariants = {
    offscreen: { y: 50, opacity: 0 },
    onscreen: {
      y: 0,
      opacity: 1,
      transition: { type: "spring" as const, bounce: 0.4, duration: 0.8, delay: index * 0.1 },
    },
  };

  return (
    <motion.div
      variants={cardVariants}
      initial="offscreen"
      whileInView="onscreen"
      viewport={{ once: true, amount: 0.4 }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      onHoverStart={() => setIsHovered(true)}
      onHoverEnd={() => setIsHovered(false)}
      onClick={() => onSelect?.(index)}
      role={onSelect ? "button" : undefined}
      tabIndex={onSelect ? 0 : undefined}
      onKeyDown={
        onSelect
          ? (e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                onSelect(index);
              }
            }
          : undefined
      }
      style={{ rotateX, rotateY, transformStyle: "preserve-3d" }}
      className="group relative h-80 w-full cursor-pointer rounded-xl border-2 border-slate-800 bg-slate-900"
    >
      <div
        style={{ transform: "translateZ(50px)", transformStyle: "preserve-3d" }}
        className="absolute inset-[2px] flex flex-col justify-end overflow-hidden rounded-[10px] p-6"
      >
        <img
          src={item.image}
          alt={item.title}
          className="absolute inset-0 h-full w-full object-cover object-center transition-transform duration-500 group-hover:scale-110"
          style={item.objectPosition ? { objectPosition: item.objectPosition } : undefined}
        />
        <GenerativeArtCanvas isHovered={isHovered} />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent" />

        <div className="relative z-10">
          <motion.h3
            initial={{ y: 8, opacity: 0.95 }}
            animate={{ y: isHovered ? 0 : 4, opacity: 1 }}
            transition={{ type: "spring", stiffness: 200, damping: 15 }}
            className="mb-1 text-xl font-bold text-white"
          >
            {item.title}
          </motion.h3>
          {item.category ? (
            <motion.p
              initial={{ y: 8, opacity: 0 }}
              animate={{ y: isHovered ? 0 : 4, opacity: isHovered ? 1 : 0.85 }}
              transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.05 }}
              className="text-sm text-slate-300"
            >
              {item.category}
            </motion.p>
          ) : null}
        </div>
        <div className="absolute top-4 right-4 text-white opacity-0 transition-opacity duration-300 group-hover:opacity-100">
          <ArrowUpRight />
        </div>
      </div>
    </motion.div>
  );
}

export type GenerativeArtGalleryProps = {
  items: GalleryItem[];
  title?: string | undefined;
  description?: string | undefined;
  showHeader?: boolean | undefined;
  onItemClick?: ((index: number) => void) | undefined;
  className?: string | undefined;
};

export function GenerativeArtGallery({
  items,
  title,
  description,
  showHeader = false,
  onItemClick,
  className,
}: GenerativeArtGalleryProps) {
  return (
    <div
      className={cn(
        "relative flex w-full flex-col items-center justify-center overflow-hidden",
        className,
      )}
    >
      {showHeader && (title || description) ? (
        <div className="relative z-10 mb-12 flex flex-col items-center text-center md:mb-16">
          {title ? (
            <motion.h2
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2, duration: 0.8, ease: "easeInOut" }}
              className="mb-4 text-3xl font-bold tracking-tighter text-teal-900 sm:text-4xl md:text-5xl"
            >
              {title}
            </motion.h2>
          ) : null}
          {description ? (
            <motion.p
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4, duration: 0.8, ease: "easeInOut" }}
              className="max-w-2xl text-base text-slate-600 sm:text-lg"
            >
              {description}
            </motion.p>
          ) : null}
        </div>
      ) : null}

      <div className="relative z-10 grid w-full max-w-6xl grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
        {items.map((item, index) => (
          <GalleryCard
            key={`${item.title}-${index}`}
            item={item}
            index={index}
            onSelect={onItemClick}
          />
        ))}
      </div>
    </div>
  );
}

export default GenerativeArtGallery;
