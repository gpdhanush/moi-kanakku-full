export function getMagneticTransform(event: React.PointerEvent<HTMLElement>, strength = 0.18) {
  const rect = event.currentTarget.getBoundingClientRect();
  const x = (event.clientX - rect.left - rect.width / 2) * strength;
  const y = (event.clientY - rect.top - rect.height / 2) * strength;
  return `translate3d(${x}px, ${y}px, 0)`;
}
