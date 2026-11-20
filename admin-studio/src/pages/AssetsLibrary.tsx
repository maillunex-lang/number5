import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import { api } from "../api/client";
import { usePackage } from "../state/PackageContext";
import type { AssetsDoc } from "../types/content";

export default function AssetsLibrary() {
  const { data, version, reload, saveDoc } = usePackage();
  const [doc, setDoc] = useState<AssetsDoc | null>(null);
  const [bindingKey, setBindingKey] = useState("hub.building.summon");
  const [bindTo, setBindTo] = useState("placeholder_building");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.assets) {
      setDoc(structuredClone(data.assets));
      setDirty(false);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка assets.json…</p>;

  return (
    <div>
      <VersionBar
        title="Библиотека ассетов"
        subtitle="Реестр + привязки. Upload PNG/WebP в media/ пакета (без игрового сервера)."
      />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("assets", doc);
            setDirty(false);
            alert("assets.json сохранён");
          }}
        >
          Сохранить assets.json
        </button>
        <label className="btn secondary" style={{ cursor: "pointer" }}>
          Загрузить файл
          <input
            type="file"
            accept="image/*,.svg,.webp,.png,.jpg"
            hidden
            onChange={async (e) => {
              const file = e.target.files?.[0];
              if (!file) return;
              const dataUrl = await new Promise<string>((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => resolve(String(reader.result || ""));
                reader.onerror = () => reject(reader.error);
                reader.readAsDataURL(file);
              });
              const b64 = dataUrl.includes(",") ? dataUrl.split(",")[1] : dataUrl;
              const id = `up_${Date.now()}`;
              await api.uploadAsset(version, {
                id,
                filename: file.name,
                data_base64: b64,
                mime: file.type,
                role: "upload",
              });
              await reload();
              alert(`Загружено как ${id}`);
            }}
          />
        </label>
      </div>
      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Элементы</h3>
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Role</th>
                <th>Path</th>
              </tr>
            </thead>
            <tbody>
              {doc.items.map((it) => (
                <tr key={it.id}>
                  <td>
                    <code>{it.id}</code>
                  </td>
                  <td>{it.role}</td>
                  <td className="muted" style={{ fontSize: 12 }}>
                    {it.path || "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Привязки</h3>
          <ul className="list">
            {Object.entries(doc.bindings).map(([k, v]) => (
              <li key={k}>
                <code>{k}</code> → {v}
              </li>
            ))}
          </ul>
          <div className="field">
            <label>Ключ привязки</label>
            <input value={bindingKey} onChange={(e) => setBindingKey(e.target.value)} />
          </div>
          <div className="field">
            <label>Asset id</label>
            <select value={bindTo} onChange={(e) => setBindTo(e.target.value)}>
              {doc.items.map((it) => (
                <option key={it.id} value={it.id}>
                  {it.id}
                </option>
              ))}
            </select>
          </div>
          <button
            className="btn secondary"
            type="button"
            onClick={() => {
              setDoc({ ...doc, bindings: { ...doc.bindings, [bindingKey]: bindTo } });
              setDirty(true);
            }}
          >
            Привязать
          </button>
        </div>
      </div>
    </div>
  );
}
