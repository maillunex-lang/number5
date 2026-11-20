import { usePackage } from "../state/PackageContext";

export default function VersionBar({ title, subtitle }: { title: string; subtitle?: string }) {
  const { version, versions, active, setVersion, loading, error, publish } = usePackage();
  return (
    <>
      <h1 className="h1">{title}</h1>
      {subtitle ? <p className="muted">{subtitle}</p> : null}
      <div className="toolbar">
        <label className="field" style={{ margin: 0 }}>
          <span className="muted">Версия пакета</span>
          <select value={version} onChange={(e) => setVersion(e.target.value)} disabled={loading}>
            {versions.map((v) => (
              <option key={v} value={v}>
                {v}
                {v === active ? " (active)" : ""}
              </option>
            ))}
          </select>
        </label>
        <button
          className="btn"
          type="button"
          onClick={async () => {
            const msg = await publish();
            alert(msg);
          }}
        >
          Опубликовать для клиента
        </button>
        <span className="badge ok">active: {active}</span>
        {error ? <span className="warn">{error}</span> : null}
      </div>
    </>
  );
}
