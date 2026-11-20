import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import DocJsonPanel from "../components/DocJsonPanel";
import { usePackage } from "../state/PackageContext";

type Currency = { id: string; name: string; premium?: boolean };
type Offer = {
  sku: string;
  title: string;
  nominal_price_rub?: number;
  payable_price_rub?: number;
  type?: string;
  grants?: Array<{ resource_id: string; amount: number }>;
  limits?: Record<string, number>;
};
type VipLevel = { level: number; xp?: number; perks?: string[] };
type Sub = { id: string; name: string; days?: number; payable_price_rub?: number };
type EconomyDoc = {
  mode?: string;
  disclaimer?: string;
  currencies?: Currency[];
  offers?: Offer[];
  subscriptions?: Sub[];
  vip_levels?: VipLevel[];
  battle_pass?: { max_level?: number; season?: string; [k: string]: unknown };
  [k: string]: unknown;
};

type Tab = "overview" | "currencies" | "offers" | "vip" | "json";

export default function EconomyEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<EconomyDoc | null>(null);
  const [dirty, setDirty] = useState(false);
  const [tab, setTab] = useState<Tab>("overview");

  useEffect(() => {
    const eco = (data as Record<string, unknown> | null)?.economy as EconomyDoc | undefined;
    if (eco) {
      setDoc(structuredClone(eco));
      setDirty(false);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка economy.json…</p>;

  const tabs: Array<[Tab, string]> = [
    ["overview", "Обзор"],
    ["currencies", "Валюты"],
    ["offers", "Офферы"],
    ["vip", "VIP / подписки"],
    ["json", "JSON"],
  ];

  return (
    <div>
      <VersionBar
        title="Экономика"
        subtitle="VIRTUAL_FREE · валюты, SKU, VIP, подписки, battle pass. Не платёжный сервер."
      />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("economy", doc);
            setDirty(false);
            alert("economy.json сохранён");
          }}
        >
          Сохранить economy.json
        </button>
        {dirty ? <span className="warn">Есть несохранённые изменения</span> : <span className="badge ok">сохранено</span>}
        <span className="badge">mode · {doc.mode ?? "—"}</span>
      </div>
      <div className="toolbar" style={{ gap: 8 }}>
        {tabs.map(([id, label]) => (
          <button
            key={id}
            type="button"
            className={`btn secondary${tab === id ? " active" : ""}`}
            onClick={() => setTab(id)}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === "overview" && (
        <div className="grid-2">
          <div className="panel">
            <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Сводка</h3>
            <ul className="muted">
              <li>Валюты: {doc.currencies?.length ?? 0}</li>
              <li>Офферы: {doc.offers?.length ?? 0}</li>
              <li>VIP уровней: {doc.vip_levels?.length ?? 0}</li>
              <li>Подписки: {doc.subscriptions?.length ?? 0}</li>
              <li>BP max: {doc.battle_pass?.max_level ?? "—"}</li>
            </ul>
            {doc.disclaimer ? <p className="warn">{doc.disclaimer}</p> : null}
          </div>
          <div className="panel">
            <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Правило VIRTUAL_FREE</h3>
            <p className="muted">
              Все <code>payable_price_rub</code> должны быть 0. Реальные платежи — только после CORE-01.
            </p>
            <ul className="list">
              {(doc.offers || []).slice(0, 6).map((o) => (
                <li key={o.sku}>
                  <strong>{o.sku}</strong> · {o.title} · {o.payable_price_rub ?? "?"} ₽
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      {tab === "currencies" && (
        <div className="panel">
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Имя</th>
                <th>Premium</th>
              </tr>
            </thead>
            <tbody>
              {(doc.currencies || []).map((c, idx) => (
                <tr key={c.id}>
                  <td>
                    <code>{c.id}</code>
                  </td>
                  <td>
                    <input
                      value={c.name}
                      onChange={(e) => {
                        const currencies = [...(doc.currencies || [])];
                        currencies[idx] = { ...c, name: e.target.value };
                        setDoc({ ...doc, currencies });
                        setDirty(true);
                      }}
                    />
                  </td>
                  <td>{c.premium ? "yes" : "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "offers" && (
        <div className="panel">
          <table className="table">
            <thead>
              <tr>
                <th>SKU</th>
                <th>Title</th>
                <th>Payable ₽</th>
                <th>Type</th>
                <th>Grants</th>
              </tr>
            </thead>
            <tbody>
              {(doc.offers || []).map((o, idx) => (
                <tr key={o.sku}>
                  <td>
                    <code>{o.sku}</code>
                  </td>
                  <td>
                    <input
                      value={o.title}
                      onChange={(e) => {
                        const offers = [...(doc.offers || [])];
                        offers[idx] = { ...o, title: e.target.value };
                        setDoc({ ...doc, offers });
                        setDirty(true);
                      }}
                    />
                  </td>
                  <td>
                    <input
                      type="number"
                      value={o.payable_price_rub ?? 0}
                      onChange={(e) => {
                        const offers = [...(doc.offers || [])];
                        offers[idx] = { ...o, payable_price_rub: Number(e.target.value) };
                        setDoc({ ...doc, offers });
                        setDirty(true);
                      }}
                      style={{ width: 72 }}
                    />
                  </td>
                  <td>{o.type}</td>
                  <td className="muted" style={{ fontSize: 12 }}>
                    {(o.grants || []).map((g) => `${g.resource_id}×${g.amount}`).join(", ")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {tab === "vip" && (
        <div className="grid-2">
          <div className="panel">
            <h3 style={{ marginTop: 0, color: "var(--gold)" }}>VIP 0–11</h3>
            <ul className="list">
              {(doc.vip_levels || []).map((v) => (
                <li key={v.level}>
                  L{v.level}
                  {v.xp != null ? ` · xp ${v.xp}` : ""}
                  {v.perks?.length ? ` · ${v.perks.join(", ")}` : ""}
                </li>
              ))}
            </ul>
          </div>
          <div className="panel">
            <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Подписки</h3>
            <ul className="list">
              {(doc.subscriptions || []).map((s) => (
                <li key={s.id}>
                  <strong>{s.id}</strong> · {s.name} · {s.days ?? "?"}д · {s.payable_price_rub ?? 0} ₽
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}

      {tab === "json" && (
        <div className="panel">
          <DocJsonPanel
            value={doc}
            onChange={(next) => {
              setDoc(next as EconomyDoc);
              setDirty(true);
            }}
            height={520}
          />
        </div>
      )}
    </div>
  );
}
