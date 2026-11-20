import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";

type Offer = { id: string; name: string; desc: string; limit: string };
type EventItem = { id: string; name: string; timer: string; state: string };
type QuestItem = { id: string; title: string; progress: string; goto: string };
type FeaturesDoc = {
  shop_offers: Offer[];
  events: EventItem[];
  quests: Record<string, QuestItem[]>;
  mail: Array<{ id: string; category: string; title: string; unread: boolean }>;
  vip: { level: number; progress: number; next: number };
  battle_pass: { season: string; level: number; free_ready: number; premium_ready: number };
  afk: { seconds_default: number; gold_per_10s: number; cap_gold: number };
  summon: { banner: string; cost_x1: number; weights: Record<string, number> };
};

export default function FeaturesEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<FeaturesDoc | null>(null);
  const [dirty, setDirty] = useState(false);
  const [raw, setRaw] = useState("");

  useEffect(() => {
    if (data?.features) {
      const cloned = structuredClone(data.features) as FeaturesDoc;
      setDoc(cloned);
      setRaw(JSON.stringify(cloned, null, 2));
      setDirty(false);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка features…</p>;

  return (
    <div>
      <VersionBar
        title="Фичи и офферы"
        subtitle="Магазин, квесты, почта, VIP, пропуск, AFK, призыв — демо-контент пакета."
      />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            let parsed: FeaturesDoc;
            try {
              parsed = JSON.parse(raw) as FeaturesDoc;
            } catch {
              alert("JSON невалиден");
              return;
            }
            await saveDoc("features", parsed);
            setDoc(parsed);
            setDirty(false);
            alert("features.json сохранён");
          }}
        >
          Сохранить features.json
        </button>
        {dirty ? <span className="warn">Есть несохранённые изменения</span> : <span className="badge ok">сохранено</span>}
      </div>
      <div className="grid-2">
        <div className="panel">
          <h3>Быстрый обзор</h3>
          <p className="muted">Офферы: {doc.shop_offers?.length ?? 0}</p>
          <p className="muted">События: {doc.events?.length ?? 0}</p>
          <p className="muted">Письма: {doc.mail?.length ?? 0}</p>
          <p className="muted">
            VIP {doc.vip?.level ?? 0} · BP «{doc.battle_pass?.season ?? "—"}» · баннер «
            {doc.summon?.banner ?? "—"}»
          </p>
          <ul className="list">
            {(doc.shop_offers || []).map((o) => (
              <li key={o.id}>
                <strong>{o.name}</strong> — {o.desc} ({o.limit})
              </li>
            ))}
          </ul>
        </div>
        <div className="panel">
          <h3>JSON (features.json)</h3>
          <textarea
            className="code-area"
            value={raw}
            onChange={(e) => {
              setRaw(e.target.value);
              setDirty(true);
            }}
            spellCheck={false}
          />
        </div>
      </div>
    </div>
  );
}
