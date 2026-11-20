import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import DocJsonPanel from "../components/DocJsonPanel";
import { usePackage } from "../state/PackageContext";

const CATALOG = [
  { id: "gacha", label: "Гача", hint: "4 баннера" },
  { id: "liveops", label: "AFK / квесты", hint: "liveops.json" },
  { id: "pve_modes", label: "PvE", hint: "башня / охота / врата" },
  { id: "guilds", label: "Гильдии", hint: "рейды / магазин" },
  { id: "progression", label: "Прогрессия", hint: "уровни / звёзды" },
  { id: "equipment", label: "Экипировка", hint: "12 сетов" },
  { id: "loot_tables", label: "Лут", hint: "stage bindings" },
  { id: "enemies", label: "Бестиарий", hint: "риги / E* / B*" },
  { id: "skills", label: "Навыки", hint: "45×5" },
  { id: "dialogs", label: "Диалоги", hint: "сюжетные сцены" },
] as const;

type CatId = (typeof CATALOG)[number]["id"];

export default function CatalogEditor() {
  const { data, saveDoc } = usePackage();
  const bundle = data as Record<string, unknown> | null;
  const [tab, setTab] = useState<CatId>("gacha");
  const [doc, setDoc] = useState<Record<string, unknown> | null>(null);
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (!bundle) return;
    const v = bundle[tab];
    if (v && typeof v === "object") {
      setDoc(structuredClone(v as Record<string, unknown>));
      setDirty(false);
    } else {
      setDoc(null);
      setDirty(false);
    }
  }, [bundle, tab]);

  if (!bundle) return <p className="muted">Загрузка каталога…</p>;
  const meta = CATALOG.find((c) => c.id === tab)!;

  return (
    <div>
      <VersionBar
        title="Каталог контента"
        subtitle="Гача, PvE, гильдии, прогрессия, бестиарий, навыки, диалоги — редактирование JSON пакета."
      />
      <div className="toolbar" style={{ flexWrap: "wrap", gap: 8 }}>
        {CATALOG.map((c) => (
          <button
            key={c.id}
            type="button"
            className={`btn secondary${tab === c.id ? " active" : ""}`}
            onClick={() => setTab(c.id)}
          >
            {c.label}
          </button>
        ))}
        <button
          className="btn"
          type="button"
          disabled={!dirty || !doc}
          onClick={async () => {
            if (!doc) return;
            await saveDoc(tab, doc);
            setDirty(false);
            alert(`${tab}.json сохранён`);
          }}
        >
          Сохранить {tab}.json
        </button>
      </div>
      <div className="panel">
        <h3 style={{ marginTop: 0, color: "var(--gold)" }}>
          {meta.label} <span className="muted">· {meta.hint} · {tab}.json</span>
        </h3>
        {!doc ? (
          <p className="warn">Документ отсутствует в пакете {String((bundle.manifest as { version?: string })?.version ?? "")}</p>
        ) : (
          <DocJsonPanel
            value={doc}
            onChange={(next) => {
              setDoc(next as Record<string, unknown>);
              setDirty(true);
            }}
            height={560}
          />
        )}
      </div>
    </div>
  );
}
