import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import PhoneFrame from "../components/PhoneFrame";
import { usePackage } from "../state/PackageContext";
import type { ThemeDoc } from "../types/content";

const PALETTE_KEYS = [
  "bg_deep",
  "bg_mid",
  "bg_panel",
  "gold",
  "gold_bright",
  "cyan",
  "crimson",
  "emerald",
  "amber",
  "text_primary",
  "text_muted",
  "button_normal",
  "nav_active",
  "frame_outer",
];

export default function ThemeStudio() {
  const { data, saveDoc } = usePackage();
  const [theme, setTheme] = useState<ThemeDoc | null>(null);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.theme) {
      setTheme(structuredClone(data.theme));
      setDirty(false);
    }
  }, [data]);

  if (!theme) return <p className="muted">Загрузка theme.json…</p>;
  const p = theme.palette;

  return (
    <div>
      <VersionBar title="Theme Studio" subtitle="Палитра, радиусы, кнопки — живой превью 9:16." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("theme", theme);
            setDirty(false);
            alert("theme.json сохранён");
          }}
        >
          Сохранить theme.json
        </button>
        {dirty ? <span className="warn">несохранено</span> : <span className="badge ok">ok</span>}
      </div>
      <div className="visual-editor-layout">
        <div className="panel visual-preview-panel">
          <PhoneFrame label="UI Kit · 9:16">
            <div
              className="theme-preview-root"
              style={{
                background: `linear-gradient(180deg, ${p.bg_mid}, ${p.bg_deep})`,
                color: p.text_primary,
              }}
            >
              <div className="theme-preview-bar" style={{ background: p.bg_panel, borderColor: p.frame_outer }}>
                <span style={{ color: p.gold_bright }}>LUNEX</span>
                <span style={{ color: p.gold }}>◈ 12K</span>
              </div>
              <div className="theme-preview-body">
                <div
                  className="theme-preview-card"
                  style={{
                    background: p.bg_panel,
                    borderColor: p.gold,
                    borderRadius: theme.radius.lg,
                  }}
                >
                  <strong style={{ color: p.gold_bright }}>Карточка героя</strong>
                  <p style={{ color: p.text_muted, margin: "8px 0 0" }}>Превью панели и текста</p>
                </div>
                <button
                  type="button"
                  className="theme-preview-btn"
                  style={{
                    background: p.button_normal,
                    borderColor: p.gold,
                    color: p.text_primary,
                    borderRadius: theme.radius.md,
                    minHeight: theme.components.button_height,
                  }}
                >
                  Обычная кнопка
                </button>
                <button
                  type="button"
                  className="theme-preview-btn gold"
                  style={{
                    background: "#5A4318",
                    borderColor: p.gold_bright,
                    color: p.gold_bright,
                    borderRadius: theme.radius.lg,
                    minHeight: theme.components.gold_button_height,
                  }}
                >
                  Золотая кнопка
                </button>
              </div>
              <div className="theme-preview-nav" style={{ background: p.bg_deep, borderColor: p.frame_outer }}>
                {["Карта", "Герои", "Главная", "Битва"].map((t, i) => (
                  <span key={t} style={{ color: i === 2 ? p.nav_active : p.text_muted }}>
                    {t}
                  </span>
                ))}
              </div>
            </div>
          </PhoneFrame>
        </div>
        <div className="panel">
          <div className="field">
            <label>Название темы</label>
            <input
              value={theme.title}
              onChange={(e) => {
                setTheme({ ...theme, title: e.target.value });
                setDirty(true);
              }}
            />
          </div>
          <h4 style={{ color: "var(--cyan)" }}>Палитра</h4>
          <div className="palette-grid">
            {PALETTE_KEYS.map((key) => (
              <label key={key} className="palette-item">
                <span>{key}</span>
                <input
                  type="color"
                  value={normalizeHex(p[key] || "#ffffff")}
                  onChange={(e) => {
                    setTheme({
                      ...theme,
                      palette: { ...theme.palette, [key]: e.target.value },
                    });
                    setDirty(true);
                  }}
                />
              </label>
            ))}
          </div>
          <h4 style={{ color: "var(--cyan)" }}>Радиусы / кнопки</h4>
          <div className="field-row">
            {(["sm", "md", "lg"] as const).map((k) => (
              <div className="field" key={k}>
                <label>r.{k}</label>
                <input
                  type="number"
                  value={theme.radius[k]}
                  onChange={(e) => {
                    setTheme({ ...theme, radius: { ...theme.radius, [k]: Number(e.target.value) } });
                    setDirty(true);
                  }}
                />
              </div>
            ))}
          </div>
          <div className="field-row">
            <div className="field">
              <label>Высота кнопки</label>
              <input
                type="number"
                value={theme.components.button_height}
                onChange={(e) => {
                  setTheme({
                    ...theme,
                    components: { ...theme.components, button_height: Number(e.target.value) },
                  });
                  setDirty(true);
                }}
              />
            </div>
            <div className="field">
              <label>Золотая кнопка</label>
              <input
                type="number"
                value={theme.components.gold_button_height}
                onChange={(e) => {
                  setTheme({
                    ...theme,
                    components: { ...theme.components, gold_button_height: Number(e.target.value) },
                  });
                  setDirty(true);
                }}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function normalizeHex(c: string) {
  return /^#[0-9a-fA-F]{6}/.test(c) ? c.slice(0, 7) : "#ffffff";
}
