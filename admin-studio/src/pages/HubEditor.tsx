import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import HubPhonePreview from "../components/HubPhonePreview";
import { usePackage } from "../state/PackageContext";
import type { Building, HubDoc, HubLook, SideRailItem, SideRailLayout } from "../types/content";
import { DEFAULT_HUB_LOOK, DEFAULT_SIDE_RAIL_LAYOUT } from "../types/content";

type Selection =
  | { kind: "building"; id: string }
  | { kind: "rail"; id: string }
  | null;

function ensureHub(raw: HubDoc): HubDoc {
  return {
    ...raw,
    look: { ...DEFAULT_HUB_LOOK, ...(raw.look || {}) },
    side_rail_layout: { ...DEFAULT_SIDE_RAIL_LAYOUT, ...(raw.side_rail_layout || {}) },
    parallax: {
      far_bands: 4,
      mid_hills: 6,
      path_width: 160,
      far_factor: 0.35,
      mid_factor: 0.18,
      ...(raw.parallax || {}),
    },
    buildings: (raw.buildings || []).map((b) => ({
      ...b,
      size: { w: b.size?.w ?? 200, h: b.size?.h ?? 160 },
    })),
  };
}

export default function HubEditor() {
  const { data, saveDoc } = usePackage();
  const [hub, setHub] = useState<HubDoc | null>(null);
  const [selected, setSelected] = useState<Selection>(null);
  const [dirty, setDirty] = useState(false);
  const [tab, setTab] = useState<"object" | "look" | "rail">("object");

  useEffect(() => {
    if (data?.hub) {
      setHub(ensureHub(structuredClone(data.hub)));
      setDirty(false);
    }
  }, [data]);

  const selectedBuilding = useMemo(() => {
    if (!hub || selected?.kind !== "building") return null;
    return hub.buildings.find((b) => b.id === selected.id) || null;
  }, [hub, selected]);

  const selectedRail = useMemo(() => {
    if (!hub || selected?.kind !== "rail") return null;
    return hub.side_rail.find((b) => b.id === selected.id) || null;
  }, [hub, selected]);

  if (!hub) return <p className="muted">Загрузка хаба…</p>;

  function patch(mutator: (prev: HubDoc) => HubDoc) {
    setHub((prev) => (prev ? mutator(prev) : prev));
    setDirty(true);
  }

  return (
    <div>
      <VersionBar
        title="Визуальный редактор 2.0"
        subtitle="Предпросмотр 9:16 как в Godot: здания, фон, свет, размеры и кнопки прямо на экране."
      />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("hub", hub);
            setDirty(false);
            alert("hub.json сохранён — клиент Godot прочитает после перезапуска / reload пакета");
          }}
        >
          Сохранить hub.json
        </button>
        <button
          className="btn secondary"
          type="button"
          onClick={() =>
            patch((prev) => ({
              ...prev,
              look: { ...DEFAULT_HUB_LOOK, ...(prev.look || {}), show_shell: !prev.look?.show_shell },
            }))
          }
        >
          {hub.look?.show_shell ? "Скрыть Shell" : "Показать Shell"}
        </button>
        {dirty ? <span className="warn">Есть несохранённые изменения</span> : <span className="badge ok">сохранено</span>}
      </div>

      <div className="visual-editor-layout">
        <div className="panel visual-preview-panel">
          <HubPhonePreview
            hub={hub}
            selected={selected}
            onSelect={(s) => {
              setSelected(s);
              if (s?.kind === "building" || s?.kind === "rail") setTab("object");
            }}
            onMoveBuilding={(id, x, y) =>
              patch((prev) => ({
                ...prev,
                buildings: prev.buildings.map((b) => (b.id === id ? { ...b, x, y } : b)),
              }))
            }
            onResizeBuilding={(id, w, h) =>
              patch((prev) => ({
                ...prev,
                buildings: prev.buildings.map((b) =>
                  b.id === id ? { ...b, size: { w, h } } : b
                ),
              }))
            }
          />
        </div>

        <div className="panel visual-inspector">
          <div className="inspector-tabs">
            {(
              [
                ["object", "Объект"],
                ["look", "Фон / свет"],
                ["rail", "Кнопки"],
              ] as const
            ).map(([id, label]) => (
              <button
                key={id}
                type="button"
                className={`inspector-tab${tab === id ? " active" : ""}`}
                onClick={() => setTab(id)}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "object" ? (
            selectedBuilding ? (
              <BuildingForm
                building={selectedBuilding}
                onChange={(next) =>
                  patch((prev) => ({
                    ...prev,
                    buildings: prev.buildings.map((b) => (b.id === next.id ? next : b)),
                  }))
                }
              />
            ) : selectedRail ? (
              <RailForm
                item={selectedRail}
                onChange={(next) =>
                  patch((prev) => ({
                    ...prev,
                    side_rail: prev.side_rail.map((r) => (r.id === next.id ? next : r)),
                  }))
                }
              />
            ) : (
              <p className="muted">Кликните здание или кнопку на экране телефона.</p>
            )
          ) : null}

          {tab === "look" ? (
            <LookForm
              look={hub.look || DEFAULT_HUB_LOOK}
              parallax={hub.parallax || {}}
              world={hub.world}
              onLook={(look) => patch((prev) => ({ ...prev, look }))}
              onParallax={(parallax) => patch((prev) => ({ ...prev, parallax }))}
              onWorld={(world) => patch((prev) => ({ ...prev, world }))}
            />
          ) : null}

          {tab === "rail" ? (
            <RailLayoutForm
              layout={hub.side_rail_layout || DEFAULT_SIDE_RAIL_LAYOUT}
              items={hub.side_rail}
              selectedId={selected?.kind === "rail" ? selected.id : ""}
              onSelect={(id) => setSelected({ kind: "rail", id })}
              onLayout={(side_rail_layout) => patch((prev) => ({ ...prev, side_rail_layout }))}
              onItems={(side_rail) => patch((prev) => ({ ...prev, side_rail }))}
            />
          ) : null}
        </div>
      </div>
    </div>
  );
}

function BuildingForm({ building, onChange }: { building: Building; onChange: (b: Building) => void }) {
  const w = building.size?.w ?? 200;
  const h = building.size?.h ?? 160;
  return (
    <div>
      <h3 style={{ marginTop: 0, color: "var(--gold)" }}>{building.name}</h3>
      <div className="field">
        <label>Название</label>
        <input value={building.name} onChange={(e) => onChange({ ...building, name: e.target.value })} />
      </div>
      <div className="field">
        <label>Маршрут</label>
        <input value={building.route} onChange={(e) => onChange({ ...building, route: e.target.value })} />
      </div>
      <div className="field">
        <label>Цвет акцента</label>
        <input type="color" value={normalizeHex(building.color)} onChange={(e) => onChange({ ...building, color: e.target.value })} />
      </div>
      <div className="field">
        <label>Позиция X / Y</label>
        <div className="field-row">
          <input type="number" value={building.x} onChange={(e) => onChange({ ...building, x: Number(e.target.value) })} />
          <input type="number" value={building.y} onChange={(e) => onChange({ ...building, y: Number(e.target.value) })} />
        </div>
      </div>
      <div className="field">
        <label>Размер W / H</label>
        <div className="field-row">
          <input
            type="number"
            value={w}
            onChange={(e) => onChange({ ...building, size: { w: Number(e.target.value), h } })}
          />
          <input
            type="number"
            value={h}
            onChange={(e) => onChange({ ...building, size: { w, h: Number(e.target.value) } })}
          />
        </div>
      </div>
      <label className="check-row">
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

function RailForm({ item, onChange }: { item: SideRailItem; onChange: (i: SideRailItem) => void }) {
  return (
    <div>
      <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Кнопка · {item.tip}</h3>
      <div className="field">
        <label>Иконка</label>
        <input value={item.icon} onChange={(e) => onChange({ ...item, icon: e.target.value })} />
      </div>
      <div className="field">
        <label>Подсказка</label>
        <input value={item.tip} onChange={(e) => onChange({ ...item, tip: e.target.value })} />
      </div>
      <div className="field">
        <label>Маршрут</label>
        <input value={item.route} onChange={(e) => onChange({ ...item, route: e.target.value })} />
      </div>
      <div className="field">
        <label>Цвет</label>
        <input type="color" value={normalizeHex(item.color)} onChange={(e) => onChange({ ...item, color: e.target.value })} />
      </div>
      <div className="field">
        <label>Размер кнопки (px design)</label>
        <input
          type="number"
          value={item.size ?? 64}
          onChange={(e) => onChange({ ...item, size: Number(e.target.value) })}
        />
      </div>
    </div>
  );
}

function LookForm({
  look,
  parallax,
  world,
  onLook,
  onParallax,
  onWorld,
}: {
  look: HubLook;
  parallax: Record<string, number>;
  world: { width: number; height: number };
  onLook: (l: HubLook) => void;
  onParallax: (p: Record<string, number>) => void;
  onWorld: (w: { width: number; height: number }) => void;
}) {
  return (
    <div>
      <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Атмосфера хаба</h3>
      <div className="field">
        <label>Небо · верх / середина / низ</label>
        <div className="field-row">
          <input type="color" value={normalizeHex(look.sky_top)} onChange={(e) => onLook({ ...look, sky_top: e.target.value })} />
          <input type="color" value={normalizeHex(look.sky_mid)} onChange={(e) => onLook({ ...look, sky_mid: e.target.value })} />
          <input type="color" value={normalizeHex(look.sky_bottom)} onChange={(e) => onLook({ ...look, sky_bottom: e.target.value })} />
        </div>
      </div>
      <div className="field">
        <label>Холмы / тропа</label>
        <div className="field-row">
          <input type="color" value={normalizeHex(look.mid_color)} onChange={(e) => onLook({ ...look, mid_color: e.target.value })} />
          <input type="color" value={normalizeHex(look.path_color.slice(0, 7))} onChange={(e) => onLook({ ...look, path_color: e.target.value + "8c" })} />
        </div>
      </div>
      <div className="field">
        <label>Освещение (ambient) · {look.ambient.toFixed(2)}</label>
        <input
          type="range"
          min={0.5}
          max={1.2}
          step={0.01}
          value={look.ambient}
          onChange={(e) => onLook({ ...look, ambient: Number(e.target.value) })}
        />
      </div>
      <div className="field">
        <label>Свечение зданий · {look.glow.toFixed(2)}</label>
        <input
          type="range"
          min={0}
          max={1}
          step={0.01}
          value={look.glow}
          onChange={(e) => onLook({ ...look, glow: Number(e.target.value) })}
        />
      </div>
      <div className="field">
        <label>Виньетка · {look.vignette.toFixed(2)}</label>
        <input
          type="range"
          min={0}
          max={0.7}
          step={0.01}
          value={look.vignette}
          onChange={(e) => onLook({ ...look, vignette: Number(e.target.value) })}
        />
      </div>
      <div className="field">
        <label>Полосы неба / холмы / ширина тропы</label>
        <div className="field-row">
          <input
            type="number"
            value={parallax.far_bands ?? 4}
            onChange={(e) => onParallax({ ...parallax, far_bands: Number(e.target.value) })}
          />
          <input
            type="number"
            value={parallax.mid_hills ?? 6}
            onChange={(e) => onParallax({ ...parallax, mid_hills: Number(e.target.value) })}
          />
          <input
            type="number"
            value={parallax.path_width ?? 160}
            onChange={(e) => onParallax({ ...parallax, path_width: Number(e.target.value) })}
          />
        </div>
      </div>
      <div className="field">
        <label>Мир W × H</label>
        <div className="field-row">
          <input type="number" value={world.width} onChange={(e) => onWorld({ ...world, width: Number(e.target.value) })} />
          <input type="number" value={world.height} onChange={(e) => onWorld({ ...world, height: Number(e.target.value) })} />
        </div>
      </div>
      <label className="check-row">
        <input
          type="checkbox"
          checked={look.show_shell}
          onChange={(e) => onLook({ ...look, show_shell: e.target.checked })}
        />
        Показывать TopBar + BottomNav (как GameShell)
      </label>
    </div>
  );
}

function RailLayoutForm({
  layout,
  items,
  selectedId,
  onSelect,
  onLayout,
  onItems,
}: {
  layout: SideRailLayout;
  items: SideRailItem[];
  selectedId: string;
  onSelect: (id: string) => void;
  onLayout: (l: SideRailLayout) => void;
  onItems: (items: SideRailItem[]) => void;
}) {
  return (
    <div>
      <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Боковой ряд</h3>
      <div className="field">
        <label>Отступ справа / сверху</label>
        <div className="field-row">
          <input
            type="number"
            value={layout.offset_right}
            onChange={(e) => onLayout({ ...layout, offset_right: Number(e.target.value) })}
          />
          <input
            type="number"
            value={layout.offset_top}
            onChange={(e) => onLayout({ ...layout, offset_top: Number(e.target.value) })}
          />
        </div>
      </div>
      <div className="field">
        <label>Размер кнопок / зазор</label>
        <div className="field-row">
          <input
            type="number"
            value={layout.button_size}
            onChange={(e) => onLayout({ ...layout, button_size: Number(e.target.value) })}
          />
          <input
            type="number"
            value={layout.gap}
            onChange={(e) => onLayout({ ...layout, gap: Number(e.target.value) })}
          />
        </div>
      </div>
      <ul className="rail-list">
        {items.map((it, idx) => (
          <li key={it.id} className={selectedId === it.id ? "active" : ""}>
            <button type="button" className="linkish" onClick={() => onSelect(it.id)}>
              {it.icon} {it.tip}
            </button>
            <span className="rail-actions">
              <button
                type="button"
                className="btn secondary"
                disabled={idx === 0}
                onClick={() => {
                  const next = [...items];
                  [next[idx - 1], next[idx]] = [next[idx], next[idx - 1]];
                  onItems(next);
                }}
              >
                ↑
              </button>
              <button
                type="button"
                className="btn secondary"
                disabled={idx === items.length - 1}
                onClick={() => {
                  const next = [...items];
                  [next[idx + 1], next[idx]] = [next[idx], next[idx + 1]];
                  onItems(next);
                }}
              >
                ↓
              </button>
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

function normalizeHex(c: string): string {
  if (/^#[0-9a-fA-F]{6}/.test(c)) return c.slice(0, 7);
  if (/^#[0-9a-fA-F]{8}$/.test(c)) return c.slice(0, 7);
  return "#e8c56a";
}
