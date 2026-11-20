import { useMemo, useRef, useState, type PointerEvent as ReactPointerEvent } from "react";
import PhoneFrame from "./PhoneFrame";
import type { Building, HubDoc, HubLook, SideRailItem, SideRailLayout } from "../types/content";
import { DEFAULT_HUB_LOOK, DEFAULT_SIDE_RAIL_LAYOUT } from "../types/content";

type Selection =
  | { kind: "building"; id: string }
  | { kind: "rail"; id: string }
  | null;

type Props = {
  hub: HubDoc;
  selected: Selection;
  onSelect: (s: Selection) => void;
  onMoveBuilding: (id: string, x: number, y: number) => void;
  onResizeBuilding: (id: string, w: number, h: number) => void;
};

const VIEW_W = 1080;
const VIEW_H = 1920;
const TOP_H = 96;
const BOTTOM_H = 110;

function lookOf(hub: HubDoc): HubLook {
  return { ...DEFAULT_HUB_LOOK, ...(hub.look || {}) };
}

function railLayoutOf(hub: HubDoc): SideRailLayout {
  return { ...DEFAULT_SIDE_RAIL_LAYOUT, ...(hub.side_rail_layout || {}) };
}

export default function HubPhonePreview({
  hub,
  selected,
  onSelect,
  onMoveBuilding,
  onResizeBuilding,
}: Props) {
  const look = lookOf(hub);
  const railLayout = railLayoutOf(hub);
  const world = hub.world || { width: 1080, height: 2400 };
  const scrollRef = useRef<HTMLDivElement>(null);
  const [drag, setDrag] = useState<{
    id: string;
    mode: "move" | "resize";
    ox: number;
    oy: number;
    startX: number;
    startY: number;
    startW: number;
    startH: number;
  } | null>(null);

  const ambientFilter = useMemo(() => {
    const a = Math.max(0.4, Math.min(1.2, look.ambient));
    return `brightness(${a})`;
  }, [look.ambient]);

  function localPoint(clientX: number, clientY: number) {
    const sc = scrollRef.current;
    if (!sc) return { x: 0, y: 0 };
    const rect = sc.getBoundingClientRect();
    const scale = rect.width / VIEW_W;
    const x = (clientX - rect.left) / scale;
    const y = (clientY - rect.top + sc.scrollTop) / scale;
    return {
      x: Math.round(Math.max(40, Math.min(world.width - 40, x))),
      y: Math.round(Math.max(40, Math.min(world.height - 40, y))),
    };
  }

  function onPointerMove(e: ReactPointerEvent) {
    if (!drag || e.buttons !== 1) return;
    const p = localPoint(e.clientX, e.clientY);
    if (drag.mode === "move") {
      onMoveBuilding(drag.id, p.x - drag.ox, p.y - drag.oy);
    } else {
      const w = Math.max(120, Math.min(420, drag.startW + (p.x - drag.startX)));
      const h = Math.max(100, Math.min(360, drag.startH + (p.y - drag.startY)));
      onResizeBuilding(drag.id, Math.round(w), Math.round(h));
    }
  }

  const sky = `linear-gradient(180deg, ${look.sky_top} 0%, ${look.sky_mid} 42%, ${look.sky_bottom} 100%)`;
  const bands = hub.parallax?.far_bands ?? 4;
  const hills = hub.parallax?.mid_hills ?? 6;
  const pathW = hub.parallax?.path_width ?? 160;

  return (
    <PhoneFrame>
      <div className="godot-shell" style={{ width: VIEW_W, height: VIEW_H }}>
        {look.show_shell ? (
          <div className="godot-topbar">
            <div className="godot-avatar">L</div>
            <div className="godot-currencies">
              <span>◆ 12 450</span>
              <span>◇ 320</span>
            </div>
            <div className="godot-shop">Магазин</div>
          </div>
        ) : null}

        <div
          className="godot-content"
          style={{
            top: look.show_shell ? TOP_H : 0,
            bottom: look.show_shell ? BOTTOM_H : 0,
          }}
        >
          <div
            ref={scrollRef}
            className="hub-scroll"
            onPointerMove={onPointerMove}
            onPointerUp={() => setDrag(null)}
            onPointerLeave={() => setDrag(null)}
            onPointerDown={() => onSelect(null)}
          >
            <div
              className="hub-world"
              style={{
                width: world.width,
                height: world.height,
                background: sky,
                filter: ambientFilter,
              }}
            >
              {Array.from({ length: bands }).map((_, i) => {
                const t = i / Math.max(1, bands);
                return (
                  <div
                    key={`band-${i}`}
                    className="hub-sky-band"
                    style={{
                      top: i * 480,
                      height: 500,
                      background: `rgba(20, 40, 70, ${0.12 + t * 0.08})`,
                    }}
                  />
                );
              })}
              {Array.from({ length: hills }).map((_, i) => (
                <div
                  key={`hill-${i}`}
                  className="hub-hill"
                  style={{
                    left: (i * 190) % 900 - 40,
                    top: 400 + i * 280,
                    width: 420 + (i % 3) * 80,
                    height: 180,
                    background: look.mid_color,
                    opacity: 0.85,
                  }}
                />
              ))}
              <div
                className="hub-path"
                style={{
                  width: pathW,
                  left: world.width * 0.5 - pathW / 2,
                  background: look.path_color,
                }}
              />

              {hub.buildings.map((b) => (
                <BuildingNode
                  key={b.id}
                  building={b}
                  glow={look.glow}
                  selected={selected?.kind === "building" && selected.id === b.id}
                  onSelect={() => onSelect({ kind: "building", id: b.id })}
                  onDragStart={(mode, e) => {
                    e.stopPropagation();
                    const w = b.size?.w ?? 200;
                    const h = b.size?.h ?? 160;
                    const p = localPoint(e.clientX, e.clientY);
                    setDrag({
                      id: b.id,
                      mode,
                      ox: mode === "move" ? p.x - b.x : 0,
                      oy: mode === "move" ? p.y - b.y : 0,
                      startX: p.x,
                      startY: p.y,
                      startW: w,
                      startH: h,
                    });
                    onSelect({ kind: "building", id: b.id });
                  }}
                />
              ))}

              <div
                className="hub-vignette"
                style={{ opacity: look.vignette }}
                aria-hidden
              />
            </div>
          </div>

          <div
            className="hub-side-rail"
            style={{
              right: railLayout.offset_right,
              top: railLayout.offset_top,
              gap: railLayout.gap,
            }}
            onPointerDown={(e) => e.stopPropagation()}
          >
            {hub.side_rail.map((item) => (
              <RailButton
                key={item.id}
                item={item}
                size={item.size ?? railLayout.button_size}
                selected={selected?.kind === "rail" && selected.id === item.id}
                onSelect={() => onSelect({ kind: "rail", id: item.id })}
              />
            ))}
          </div>
        </div>

        {look.show_shell ? (
          <div className="godot-bottomnav">
            {["Карта", "Герои", "Главная", "Битва"].map((t, i) => (
              <div key={t} className={`godot-tab${i === 2 ? " active" : ""}`}>
                {t}
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </PhoneFrame>
  );
}

function BuildingNode({
  building,
  glow,
  selected,
  onSelect,
  onDragStart,
}: {
  building: Building;
  glow: number;
  selected: boolean;
  onSelect: () => void;
  onDragStart: (mode: "move" | "resize", e: ReactPointerEvent) => void;
}) {
  const w = building.size?.w ?? 200;
  const h = building.size?.h ?? 160;
  return (
    <div
      className={`hub-building${selected ? " selected" : ""}${building.locked ? " locked" : ""}`}
      style={{
        left: building.x - w / 2,
        top: building.y - h / 2,
        width: w,
        height: h,
        borderColor: building.color,
        boxShadow: `0 0 ${24 * glow}px ${building.color}66`,
        background: `linear-gradient(160deg, ${building.color}40, #101820ee)`,
      }}
      onPointerDown={(e) => {
        e.stopPropagation();
        onSelect();
        onDragStart("move", e);
      }}
    >
      <div className="hub-building-glow" style={{ background: building.color, opacity: glow * 0.35 }} />
      <div className="hub-building-title">
        {building.locked ? "🔒 " : ""}
        {building.name}
      </div>
      {selected ? (
        <div
          className="hub-resize-handle"
          onPointerDown={(e) => {
            e.stopPropagation();
            onDragStart("resize", e);
          }}
          title="Размер"
        />
      ) : null}
    </div>
  );
}

function RailButton({
  item,
  size,
  selected,
  onSelect,
}: {
  item: SideRailItem;
  size: number;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      className={`hub-rail-btn${selected ? " selected" : ""}`}
      style={{
        width: size,
        height: size,
        borderColor: item.color,
        color: item.color,
      }}
      title={item.tip}
      onPointerDown={(e) => {
        e.stopPropagation();
        onSelect();
      }}
    >
      {item.icon}
    </button>
  );
}
