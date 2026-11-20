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
  const [filter, setFilter] = useState("");

  useEffect(() => {
    if (data?.assets) {
      setDoc(structuredClone(data.assets));
      setDirty(false);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка assets.json…</p>;

  const q = filter.trim().toLowerCase();
  const filtered = !q
    ? doc.items
    : doc.items.filter(
        (it) =>
          it.id.toLowerCase().includes(q) ||
          it.role.toLowerCase().includes(q) ||
          (it.status || "").toLowerCase().includes(q) ||
          (it.path || "").toLowerCase().includes(q)
      );
  const shown = filtered.slice(0, 80);
  const bindingEntries = Object.entries(doc.bindings);
  const shownBindings = bindingEntries.slice(0, 40);

  return (
    <div>
      <VersionBar
        title="Библиотека ассетов"
        subtitle="C6 реестр + привязки. Upload PNG/WebP в media/ (бинарь = ART-05)."
      />
      {doc.summary ? (
        <div className="panel" style={{ marginBottom: 12 }}>
          <p className="muted" style={{ margin: 0 }}>
            items {doc.summary.items_total ?? doc.items.length} · bindings{" "}
            {doc.summary.bindings_total ?? bindingEntries.length} · heroes {doc.summary.heroes ?? "—"} ·
            rigs {doc.summary.rigs ?? "—"} · schema {doc.schema ?? 1}
          </p>
        </div>
      ) : null}
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
        <input
          placeholder="Фильтр id/role/status…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{ minWidth: 220 }}
        />
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
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>
            Элементы <span className="muted">· показано {shown.length}/{filtered.length}</span>
          </h3>
          <table className="table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Role</th>
                <th>Status</th>
                <th>Path</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((it) => (
                <tr key={it.id}>
                  <td>
                    <code>{it.id}</code>
                  </td>
                  <td>{it.role}</td>
                  <td>{it.status ?? "—"}</td>
                  <td className="muted" style={{ fontSize: 12 }}>
                    {it.path || "—"}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>
            Привязки <span className="muted">· {bindingEntries.length}</span>
          </h3>
          <ul className="list">
            {shownBindings.map(([k, v]) => (
              <li key={k}>
                <code>{k}</code> → {v}
              </li>
            ))}
            {bindingEntries.length > shownBindings.length ? (
              <li className="muted">… +{bindingEntries.length - shownBindings.length}</li>
            ) : null}
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
