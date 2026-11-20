import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { CampaignDoc, Stage } from "../types/content";

const SCALE = 0.38;

export default function CampaignEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<CampaignDoc | null>(null);
  const [selected, setSelected] = useState("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.campaign) {
      setDoc(structuredClone(data.campaign));
      setDirty(false);
    }
  }, [data]);

  const stage = useMemo(() => doc?.stages.find((s) => s.id === selected) || null, [doc, selected]);
  if (!doc) return <p className="muted">Загрузка кампании…</p>;

  return (
    <div>
      <VersionBar title="Кампания / глава" subtitle="Расстановка этапов и компактные карточки (STAGE-UI-001 A)." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("campaign", doc);
            setDirty(false);
            alert("campaign.json сохранён");
          }}
        >
          Сохранить campaign.json
        </button>
        <input
          value={doc.chapter_name}
          onChange={(e) => {
            setDoc({ ...doc, chapter_name: e.target.value });
            setDirty(true);
          }}
          style={{ minWidth: 260 }}
        />
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
                      stages: prev.stages.map((s) => (s.id === selected ? { ...s, x, y } : s)),
                    }
                  : prev
              );
              setDirty(true);
            }}
          >
            {doc.stages.map((s) => (
              <div
                key={s.id}
                className={`stage-node${selected === s.id ? " selected" : ""}`}
                style={{
                  left: (s.x || 100) * SCALE,
                  top: (s.y || 100) * SCALE,
                  borderColor: s.type === "secret" ? "#b06ae8" : s.type === "side" ? "#3dbe7a" : "#e8c56a",
                }}
                onPointerDown={(e) => {
                  e.preventDefault();
                  setSelected(s.id);
                }}
              >
                {s.state === "locked" ? "🔒 " : s.state === "cleared" ? "✓ " : ""}
                {s.name}
              </div>
            ))}
          </div>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Этап</h3>
          {stage ? (
            <StageForm
              stage={stage}
              onChange={(next) => {
                setDoc({
                  ...doc,
                  stages: doc.stages.map((s) => (s.id === next.id ? next : s)),
                });
                setDirty(true);
              }}
            />
          ) : (
            <p className="muted">Выберите этап</p>
          )}
          <h4>Текущий этап «Продолжить»</h4>
          <select
            value={doc.current_stage}
            onChange={(e) => {
              setDoc({ ...doc, current_stage: e.target.value });
              setDirty(true);
            }}
          >
            {doc.stages.map((s) => (
              <option key={s.id} value={s.id}>
                {s.id} — {s.name}
              </option>
            ))}
          </select>
        </div>
      </div>
    </div>
  );
}

function StageForm({ stage, onChange }: { stage: Stage; onChange: (s: Stage) => void }) {
  return (
    <div>
      <div className="field">
        <label>Название</label>
        <input value={stage.name} onChange={(e) => onChange({ ...stage, name: e.target.value })} />
      </div>
      <div className="field">
        <label>Сила</label>
        <input
          type="number"
          value={stage.power}
          onChange={(e) => onChange({ ...stage, power: Number(e.target.value) })}
        />
      </div>
      <div className="field">
        <label>Тип</label>
        <select value={stage.type} onChange={(e) => onChange({ ...stage, type: e.target.value })}>
          <option value="main">main</option>
          <option value="side">side</option>
          <option value="secret">secret</option>
        </select>
      </div>
      <div className="field">
        <label>Состояние</label>
        <select value={stage.state} onChange={(e) => onChange({ ...stage, state: e.target.value })}>
          <option value="cleared">cleared</option>
          <option value="available">available</option>
          <option value="locked">locked</option>
        </select>
      </div>
      <div className="field">
        <label>Награды (через запятую)</label>
        <input
          value={stage.rewards.join(", ")}
          onChange={(e) =>
            onChange({
              ...stage,
              rewards: e.target.value.split(",").map((x) => x.trim()).filter(Boolean),
            })
          }
        />
      </div>
    </div>
  );
}
