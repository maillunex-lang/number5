import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { BattleModesDoc, BattlePortal } from "../types/content";

const SCALE = 0.38;

export default function BattleModesEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<BattleModesDoc | null>(null);
  const [selected, setSelected] = useState("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.battle_modes) {
      setDoc(structuredClone(data.battle_modes));
      setDirty(false);
    }
  }, [data]);

  const portal = useMemo(() => doc?.portals.find((p) => p.id === selected) || null, [doc, selected]);
  if (!doc) return <p className="muted">Загрузка…</p>;

  return (
    <div>
      <VersionBar title="Режимы битвы" subtitle="Интерактивная карта порталов PvE/PvP (PVE-UI-001 C)." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("battle_modes", doc);
            setDirty(false);
            alert("battle_modes.json сохранён");
          }}
        >
          Сохранить battle_modes.json
        </button>
      </div>
      <div className="grid-2">
        <div className="panel">
          <div
            className="canvas-wrap"
            onPointerMove={(e) => {
              if (e.buttons !== 1 || !selected) return;
              const rect = (e.currentTarget as HTMLDivElement).getBoundingClientRect();
              const x = Math.round((e.clientX - rect.left) / SCALE);
              const y = Math.round((e.clientY - rect.top) / SCALE);
              setDoc((prev) =>
                prev
                  ? {
                      ...prev,
                      portals: prev.portals.map((p) => (p.id === selected ? { ...p, x, y } : p)),
                    }
                  : prev
              );
              setDirty(true);
            }}
          >
            {doc.portals.map((p) => (
              <div
                key={p.id}
                className={`portal-node${selected === p.id ? " selected" : ""}`}
                style={{ left: p.x * SCALE, top: p.y * SCALE, borderColor: p.color }}
                onPointerDown={(e) => {
                  e.preventDefault();
                  setSelected(p.id);
                }}
              >
                {p.name}
              </div>
            ))}
          </div>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Портал</h3>
          {portal ? (
            <PortalForm
              portal={portal}
              onChange={(next) => {
                setDoc({
                  ...doc,
                  portals: doc.portals.map((p) => (p.id === next.id ? next : p)),
                });
                setDirty(true);
              }}
            />
          ) : (
            <p className="muted">Выберите портал</p>
          )}
        </div>
      </div>
    </div>
  );
}

function PortalForm({ portal, onChange }: { portal: BattlePortal; onChange: (p: BattlePortal) => void }) {
  return (
    <div>
      <div className="field">
        <label>Название</label>
        <input value={portal.name} onChange={(e) => onChange({ ...portal, name: e.target.value })} />
      </div>
      <div className="field">
        <label>Маршрут</label>
        <input value={portal.route} onChange={(e) => onChange({ ...portal, route: e.target.value })} />
      </div>
      <div className="field">
        <label>Цвет</label>
        <input value={portal.color} onChange={(e) => onChange({ ...portal, color: e.target.value })} />
      </div>
      <div className="field">
        <label>X / Y</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input type="number" value={portal.x} onChange={(e) => onChange({ ...portal, x: Number(e.target.value) })} />
          <input type="number" value={portal.y} onChange={(e) => onChange({ ...portal, y: Number(e.target.value) })} />
        </div>
      </div>
    </div>
  );
}
