import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { StringsDoc } from "../types/content";

export default function StringsEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<StringsDoc | null>(null);
  const [dirty, setDirty] = useState(false);
  const [filter, setFilter] = useState("");
  const [newKey, setNewKey] = useState("");
  const [newVal, setNewVal] = useState("");

  useEffect(() => {
    if (data?.strings) {
      setDoc(structuredClone(data.strings));
      setDirty(false);
    }
  }, [data]);

  const keys = useMemo(() => {
    if (!doc) return [];
    return Object.keys(doc.entries)
      .filter((k) => !filter || k.includes(filter) || doc.entries[k].includes(filter))
      .sort();
  }, [doc, filter]);

  if (!doc) return <p className="muted">Загрузка strings.json…</p>;

  return (
    <div>
      <VersionBar title="Строки UI" subtitle="Ключи локализации. Клиент: ContentPackageLoader.tr_key()." />
      <div className="toolbar">
        <input placeholder="фильтр" value={filter} onChange={(e) => setFilter(e.target.value)} />
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("strings", doc);
            setDirty(false);
            alert("strings.json сохранён");
          }}
        >
          Сохранить
        </button>
      </div>
      <div className="panel" style={{ marginBottom: 12 }}>
        <div className="field-row">
          <input placeholder="новый ключ" value={newKey} onChange={(e) => setNewKey(e.target.value)} />
          <input placeholder="значение" value={newVal} onChange={(e) => setNewVal(e.target.value)} />
          <button
            className="btn secondary"
            type="button"
            onClick={() => {
              if (!newKey) return;
              setDoc({ ...doc, entries: { ...doc.entries, [newKey]: newVal } });
              setNewKey("");
              setNewVal("");
              setDirty(true);
            }}
          >
            Добавить
          </button>
        </div>
      </div>
      <div className="panel">
        <table className="table">
          <thead>
            <tr>
              <th>Ключ</th>
              <th>Текст</th>
            </tr>
          </thead>
          <tbody>
            {keys.map((k) => (
              <tr key={k}>
                <td>
                  <code>{k}</code>
                </td>
                <td>
                  <input
                    value={doc.entries[k]}
                    onChange={(e) => {
                      setDoc({ ...doc, entries: { ...doc.entries, [k]: e.target.value } });
                      setDirty(true);
                    }}
                    style={{ width: "100%" }}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
