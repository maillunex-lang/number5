import type { ReactNode } from "react";

type Props = {
  children: ReactNode;
  /** Logical Godot width (default 1080). */
  designWidth?: number;
  /** Visible phone viewport height in design units (default 1920). */
  designHeight?: number;
  /** On-screen phone width in CSS px. */
  phoneWidth?: number;
  label?: string;
};

/** Device chrome around a true 9:16 Godot viewport. */
export default function PhoneFrame({
  children,
  designWidth = 1080,
  designHeight = 1920,
  phoneWidth = 360,
  label = "Godot 9:16 · 1080×1920",
}: Props) {
  const scale = phoneWidth / designWidth;
  const phoneHeight = phoneWidth * (designHeight / designWidth);

  return (
    <div className="phone-stage">
      <div className="phone-bezel" style={{ width: phoneWidth + 24, height: phoneHeight + 48 }}>
        <div className="phone-notch" aria-hidden />
        <div
          className="phone-screen"
          style={{ width: phoneWidth, height: phoneHeight }}
        >
          <div
            className="phone-design-root"
            style={{
              width: designWidth,
              height: designHeight,
              transform: `scale(${scale})`,
              transformOrigin: "top left",
            }}
          >
            {children}
          </div>
        </div>
        <div className="phone-home" aria-hidden />
      </div>
      <div className="phone-caption">{label}</div>
    </div>
  );
}
