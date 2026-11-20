import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import PhoneFrame from "../components/PhoneFrame";
import { usePackage } from "../state/PackageContext";
import type { ShellDoc } from "../types/content";

export default function ShellEditor() {
  const { data, saveDoc } = usePackage();
  const [shell, setShell] = useState<ShellDoc | null>(null);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.shell) {
      setShell(structuredClone(data.shell) as ShellDoc);
      setDirty(false);
    }
  }, [data]);

  if (!shell) return <p className="muted">Загрузка shell.json…</p>;
  const tabs = shell.bottom_nav.tabs;
  const tb = shell.top_bar as Record<string, any>;

  return (
    <div>
      <VersionBar title="Shell & навигация" subtitle="TopBar, вкладки, welcome toast — как в GameShell." />
      <div className="toolbar">
        <button
          className="btn"
          disabled={!dirty}
          type="button"
          onClick={async () => {
            await saveDoc("shell", shell);
            setDirty(false);
            alert("shell.json сохранён");
          }}
        >
          Сохранить shell.json
        </button>
        {dirty ? <span className="warn">несохранено</span> : <span className="badge ok">ok</span>}
      </div>
      <div className="visual-editor-layout">
        <div className="panel visual-preview-panel">
          <PhoneFrame>
            <div className="godot-shell" style={{ width: 1080, height: 1920, background: "#0b1220" }}>
              <div
                className="godot-topbar"
                style={{
                  height: Number(tb.height || 96),
                  background: String(tb.bg || "#132038"),
                  borderBottom: `2px solid ${String(tb.border || "#3A4A68")}`,
                }}
              >
                {tb.show_profile !== false ? <div className="godot-avatar">L</div> : null}
                <div className="godot-currencies">
                  {tb.show_gold !== false ? <span>◈ 12 450</span> : null}
                  {tb.show_diamonds !== false ? <span>◆ 320</span> : null}
                </div>
                {tb.show_shop !== false ? <div className="godot-shop">{String(tb.shop_label || "Магазин")}</div> : null}
              </div>
              <div className="godot-content" style={{ top: Number(tb.height || 96), bottom: shell.bottom_nav.height }}>
                <div style={{ padding: 48, color: "#b8c0d0", fontSize: 32 }}>Контент вкладки</div>
              </div>
              <div
                className="godot-bottomnav"
                style={{
                  height: shell.bottom_nav.height,
                  background: shell.bottom_nav.bg,
                  borderTop: `2px solid ${shell.bottom_nav.border}`,
                }}
              >
                {tabs
                  .filter((t) => t.enabled)
                  .map((t, i) => (
                    <div key={t.id} className={`godot-tab${i === 2 ? " active" : ""}`}>
                      <div style={{ fontSize: 34 }}>{t.icon}</div>
                      <div>{t.label}</div>
                    </div>
                  ))}
              </div>
            </div>
          </PhoneFrame>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>TopBar</h3>
          {(["show_profile", "show_gold", "show_diamonds", "show_vip", "show_shop", "show_settings"] as const).map(
            (k) => (
              <label key={k} className="check-row">
                <input
                  type="checkbox"
                  checked={Boolean(tb[k])}
                  onChange={(e) => {
                    setShell({ ...shell, top_bar: { ...tb, [k]: e.target.checked } });
                    setDirty(true);
                  }}
                />
                {k}
              </label>
            )
          )}
          <div className="field">
            <label>Текст магазина</label>
            <input
              value={String(tb.shop_label || "")}
              onChange={(e) => {
                setShell({ ...shell, top_bar: { ...tb, shop_label: e.target.value } });
                setDirty(true);
              }}
            />
          </div>
          <h3 style={{ color: "var(--gold)" }}>Вкладки</h3>
          {tabs.map((t, idx) => (
            <div key={t.id} className="field" style={{ borderBottom: "1px solid var(--border)", paddingBottom: 8 }}>
              <strong>{t.id}</strong>
              <div className="field-row">
                <input
                  value={t.icon}
                  onChange={(e) => {
                    const next = [...tabs];
                    next[idx] = { ...t, icon: e.target.value };
                    setShell({ ...shell, bottom_nav: { ...shell.bottom_nav, tabs: next } });
                    setDirty(true);
                  }}
                />
                <input
                  value={t.label}
                  onChange={(e) => {
                    const next = [...tabs];
                    next[idx] = { ...t, label: e.target.value };
                    setShell({ ...shell, bottom_nav: { ...shell.bottom_nav, tabs: next } });
                    setDirty(true);
                  }}
                />
                <label className="check-row">
                  <input
                    type="checkbox"
                    checked={t.enabled}
                    onChange={(e) => {
                      const next = [...tabs];
                      next[idx] = { ...t, enabled: e.target.checked };
                      setShell({ ...shell, bottom_nav: { ...shell.bottom_nav, tabs: next } });
                      setDirty(true);
                    }}
                  />
                  on
                </label>
              </div>
            </div>
          ))}
          <div className="field">
            <label>Welcome toast</label>
            <input
              value={shell.welcome_toast}
              onChange={(e) => {
                setShell({ ...shell, welcome_toast: e.target.value });
                setDirty(true);
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
