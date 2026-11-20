import { useEffect, useState } from "react";
import { api } from "../api/client";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import { DOC_LABELS } from "../types/content";

export default function PackagesPage() {
  const { versions, active, version, setVersion, reload, data, publish } = usePackage();
  const [newVer, setNewVer] = useState("0.1.1");
  const [from, setFrom] = useState(version);
  const [diffOther, setDiffOther] = useState(active);
  const [diff, setDiff] = useState<Array<{ doc: string; status: string }>>([]);
  const [history, setHistory] = useState<Array<Record<string, unknown>>>([]);

  useEffect(() => {
    api.history().then((h) => setHistory(h.history || [])).catch(() => setHistory([]));
  }, [active, version]);

  return (
    <div>
      <VersionBar
        title="Пакеты · publish / diff / rollback"
        subtitle="Черновик → публикация active → откат. Клиент читает только active."
      />
      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Версии</h3>
          <table className="table">
            <thead>
              <tr>
                <th>Версия</th>
                <th>Статус</th>
                <th />
              </tr>
            </thead>
            <tbody>
              {versions.map((v) => (
                <tr key={v}>
                  <td>{v}</td>
                  <td>{v === active ? <span className="badge ok">active</span> : <span className="badge">draft</span>}</td>
                  <td>
                    <button className="btn secondary" type="button" onClick={() => setVersion(v)}>
                      открыть
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="toolbar">
            <select value={from} onChange={(e) => setFrom(e.target.value)}>
              {versions.map((v) => (
                <option key={v} value={v}>
                  from {v}
                </option>
              ))}
            </select>
            <input value={newVer} onChange={(e) => setNewVer(e.target.value)} />
            <button
              className="btn secondary"
              type="button"
              onClick={async () => {
                await api.createVersion(from, newVer);
                await reload();
                setVersion(newVer);
              }}
            >
              Клонировать
            </button>
          </div>
          <p className="muted" style={{ marginBottom: 10 }}>
            После «Опубликовать» клиенты с OTA сами скачают пакет с{" "}
            <code>/cdn/active.json</code> (без новой APK). Нужен доступный{" "}
            <code>cdn_base</code> в <code>content/update_config.json</code>.
          </p>
          <div className="toolbar">
            <button
              className="btn"
              type="button"
              onClick={async () => {
                const msg = await publish();
                alert(msg);
                const h = await api.history();
                setHistory(h.history || []);
              }}
            >
              Опубликовать {version} → CDN
            </button>
            <button
              className="btn danger"
              type="button"
              onClick={async () => {
                const r = await api.rollback();
                alert(r.message);
                await reload();
              }}
            >
              Откат на previous
            </button>
          </div>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Diff</h3>
          <div className="toolbar">
            <span className="muted">
              {version} vs
            </span>
            <select value={diffOther} onChange={(e) => setDiffOther(e.target.value)}>
              {versions.map((v) => (
                <option key={v} value={v}>
                  {v}
                </option>
              ))}
            </select>
            <button
              className="btn secondary"
              type="button"
              onClick={async () => {
                const r = await api.diff(version, diffOther);
                setDiff(r.changes);
              }}
            >
              Сравнить
            </button>
          </div>
          <ul className="list">
            {diff.map((c) => (
              <li key={c.doc}>
                {DOC_LABELS[c.doc] || c.doc}: <strong>{c.status}</strong>
              </li>
            ))}
          </ul>
          <h4>История публикаций</h4>
          <ul className="list">
            {history.slice(0, 8).map((h, i) => (
              <li key={i}>
                {String(h.version)} ← {String(h.previous || "—")} · {String(h.published_at || "")}
              </li>
            ))}
          </ul>
          <h4>Манифест {version}</h4>
          <pre style={{ whiteSpace: "pre-wrap", fontSize: 12, color: "var(--muted)" }}>
            {JSON.stringify(data?.manifest || {}, null, 2)}
          </pre>
        </div>
      </div>
    </div>
  );
}
