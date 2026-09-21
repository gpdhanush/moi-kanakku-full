import gsap from "gsap";
import { registerScrollAnimations, shouldReduceMotion } from "./scroll";

export function revealOnScroll(scope: ParentNode = document) {
  registerScrollAnimations();
  if (shouldReduceMotion()) return;

  const elements = Array.from(scope.querySelectorAll<HTMLElement>("[data-reveal]"));

  elements.forEach((element) => {
    gsap.fromTo(
      element,
      { autoAlpha: 0, y: 32 },
      {
        autoAlpha: 1,
        y: 0,
        duration: 0.8,
        ease: "power3.out",
        scrollTrigger: {
          trigger: element,
          start: "top 82%",
        },
      },
    );
  });
}
