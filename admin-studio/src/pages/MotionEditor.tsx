import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { MotionDoc } from "../types/content";

export default function MotionEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<MotionDoc | null>(null);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.motion) {
      setDoc(structuredClone(data.motion));
      setDirty(false);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка motion.json…</p>;

  function setNum<K extends keyof MotionDoc>(key: K, value: MotionDoc[K]) {
    setDoc({ ...doc!, [key]: value });
    setDirty(true);
  }

  return (
    <div>
      <VersionBar title="Motion / атмосфера" subtitle="Параллакс, pulse, FX — читает ThemeManager." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("motion", doc);
            setDirty(false);
            alert("motion.json сохранён");
          }}
        >
          Сохранить motion.json
        </button>
      </div>
      <div className="panel" style={{ maxWidth: 640 }}>
        <div className="field">
          <label>transition_ms · {doc.transition_ms}</label>
          <input type="range" min={100} max={500} value={doc.transition_ms} onChange={(e) => setNum("transition_ms", Number(e.target.value))} />
        </div>
        <div className="field">
          <label>hub_pulse_sec · {doc.hub_pulse_sec}</label>
          <input type="range" min={0.4} max={2.5} step={0.05} value={doc.hub_pulse_sec} onChange={(e) => setNum("hub_pulse_sec", Number(e.target.value))} />
        </div>
        <div className="field">
          <label>particle_scale · {doc.particle_scale}</label>
          <input type="range" min={0.2} max={1.5} step={0.05} value={doc.particle_scale} onChange={(e) => setNum("particle_scale", Number(e.target.value))} />
        </div>
        <div className="field">
          <label>max_active_fx</label>
          <input type="number" value={doc.max_active_fx} onChange={(e) => setNum("max_active_fx", Number(e.target.value))} />
        </div>
        <div className="field">
          <label>hub_decor_layers</label>
          <input type="number" value={doc.hub_decor_layers} onChange={(e) => setNum("hub_decor_layers", Number(e.target.value))} />
        </div>
        <div className="field">
          <label>toast_ms</label>
          <input type="number" value={doc.toast_ms} onChange={(e) => setNum("toast_ms", Number(e.target.value))} />
        </div>
        {(
          [
            ["parallax_enabled", "Параллакс"],
            ["hub_pulse", "Пульс зданий"],
            ["building_float", "Float на карте"],
          ] as const
        ).map(([k, label]) => (
          <label key={k} className="check-row">
            <input type="checkbox" checked={Boolean(doc[k])} onChange={(e) => setNum(k, e.target.checked as never)} />
            {label}
          </label>
        ))}
      </div>
    </div>
  );
}
