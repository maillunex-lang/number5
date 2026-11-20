import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { Building, HubDoc } from "../types/content";

const SCALE = 0.38; // 1080 -> ~410

export default function HubEditor() {
  const { data, saveDoc } = usePackage();
  const [hub, setHub] = useState<HubDoc | null>(null);
  const [selected, setSelected] = useState<string>("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.hub) {
      setHub(structuredClone(data.hub));
      setDirty(false);
    }
  }, [data]);

  const selectedBuilding = useMemo(
    () => hub?.buildings.find((b) => b.id === selected) || null,
    [hub, selected]
  );

  if (!hub) return <p className="muted">Загрузка хаба…</p>;

  function onDrag(id: string, clientX: number, clientY: number, rect: DOMRect) {
    const x = Math.round((clientX - rect.left) / SCALE);
    const y = Math.round((clientY - rect.top) / SCALE);
    setHub((prev) => {
      if (!prev) return prev;
      return {
        ...prev,
        buildings: prev.buildings.map((b) => (b.id === id ? { ...b, x, y } : b)),
      };
    });
    setDirty(true);
  }

  return (
    <div>
      <VersionBar title="Редактор хаба" subtitle="Перетаскивайте здания на портретном холсте 9:16." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("hub", hub);
            setDirty(false);
            alert("hub.json сохранён");
          }}
        >
          Сохранить hub.json
        </button>
        {dirty ? <span className="warn">Есть несохранённые изменения</span> : <span className="badge ok">сохранено</span>}
      </div>
      <div className="grid-2">
        <div className="panel">
          <div
            className="canvas-wrap"
            onPointerMove={(e) => {
              if (e.buttons !== 1 || !selected) return;
              const rect = (e.currentTarget as HTMLDivElement).getBoundingClientRect();
              onDrag(selected, e.clientX, e.clientY, rect);
            }}
          >
            {hub.buildings.map((b) => (
              <div
                key={b.id}
                className={`building-node${selected === b.id ? " selected" : ""}`}
                style={{
                  left: b.x * SCALE,
                  top: b.y * SCALE,
                  borderColor: b.color,
                  opacity: b.locked ? 0.55 : 1,
                }}
                onPointerDown={(e) => {
                  e.preventDefault();
                  setSelected(b.id);
                }}
              >
                {b.locked ? "🔒 " : ""}
                {b.name}
              </div>
            ))}
          </div>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Свойства</h3>
          {selectedBuilding ? (
            <BuildingForm
              building={selectedBuilding}
              onChange={(next) => {
                setHub((prev) =>
                  prev
                    ? {
                        ...prev,
                        buildings: prev.buildings.map((b) => (b.id === next.id ? next : b)),
                      }
                    : prev
                );
                setDirty(true);
              }}
            />
          ) : (
            <p className="muted">Выберите здание на холсте</p>
          )}
          <h4 style={{ color: "var(--cyan)" }}>Боковой ряд иконок</h4>
          <ul className="muted">
            {hub.side_rail.map((s) => (
              <li key={s.id}>
                {s.icon} {s.tip} → {s.route}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

function BuildingForm({ building, onChange }: { building: Building; onChange: (b: Building) => void }) {
  return (
    <div>
      <div className="field">
        <label>Название</label>
        <input value={building.name} onChange={(e) => onChange({ ...building, name: e.target.value })} />
      </div>
      <div className="field">
        <label>Маршрут</label>
        <input value={building.route} onChange={(e) => onChange({ ...building, route: e.target.value })} />
      </div>
      <div className="field">
        <label>Цвет</label>
        <input value={building.color} onChange={(e) => onChange({ ...building, color: e.target.value })} />
      </div>
      <div className="field">
        <label>X / Y</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input
            type="number"
            value={building.x}
            onChange={(e) => onChange({ ...building, x: Number(e.target.value) })}
          />
          <input
            type="number"
            value={building.y}
            onChange={(e) => onChange({ ...building, y: Number(e.target.value) })}
          />
        </div>
      </div>
      <label style={{ display: "flex", gap: 8, alignItems: "center" }}>
        <input
          type="checkbox"
          checked={building.locked}
          onChange={(e) => onChange({ ...building, locked: e.target.checked })}
        />
        Закрыто
      </label>
      {building.locked ? (
        <div className="field">
          <label>Условие</label>
          <input value={building.req} onChange={(e) => onChange({ ...building, req: e.target.value })} />
        </div>
      ) : null}
    </div>
  );
}
