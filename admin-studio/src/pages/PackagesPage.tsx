import { useState } from "react";
import { api } from "../api/client";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";

export default function PackagesPage() {
  const { versions, active, version, reload, data } = usePackage();
  const [newVer, setNewVer] = useState("0.1.1");
  const [from, setFrom] = useState(version);

  return (
    <div>
      <VersionBar
        title="Версионные пакеты"
        subtitle="Создание версий, хеши целостности, публикация active для клиента Godot."
      />
      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Список</h3>
          <table className="table">
            <thead>
              <tr>
                <th>Версия</th>
                <th>Статус</th>
              </tr>
            </thead>
            <tbody>
              {versions.map((v) => (
                <tr key={v}>
                  <td>{v}</td>
                  <td>{v === active ? <span className="badge ok">active</span> : <span className="badge">draft</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <h4>Создать версию (копия)</h4>
          <div className="toolbar">
            <select value={from} onChange={(e) => setFrom(e.target.value)}>
              {versions.map((v) => (
                <option key={v} value={v}>
                  from {v}
                </option>
              ))}
            </select>
            <input value={newVer} onChange={(e) => setNewVer(e.target.value)} placeholder="0.1.1" />
            <button
              className="btn secondary"
              type="button"
              onClick={async () => {
                await api.createVersion(from, newVer);
                await reload();
                alert(`Создан пакет ${newVer}`);
              }}
            >
              Создать
            </button>
          </div>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Манифест {version}</h3>
          <pre style={{ whiteSpace: "pre-wrap", fontSize: 12, color: "var(--muted)" }}>
            {JSON.stringify(data?.manifest || {}, null, 2)}
          </pre>
          <p className="muted">
            Путь клиента: <code>content/packages/{"{version}"}/</code>
            <br />
            Указатель: <code>content/packages/active.json</code>
          </p>
        </div>
      </div>
    </div>
  );
}
