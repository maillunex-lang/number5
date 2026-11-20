import { useEffect, useMemo, useState } from "react";
import VersionBar from "../components/VersionBar";
import DocJsonPanel from "../components/DocJsonPanel";
import { usePackage } from "../state/PackageContext";

const META_DOCS = [
  { id: "mail", label: "Почта", hint: "шаблоны + DEMO inbox" },
  { id: "login_calendars", label: "Календари", hint: "LOGIN_7 / 30 / NEWCOMER_14" },
  { id: "profile", label: "Профиль", hint: "косметика / приватность" },
  { id: "achievements", label: "Достижения", hint: "48 + 6 секретов" },
  { id: "daily_stories", label: "Сюжеты дня", hint: "30 карточек" },
  { id: "live_events", label: "Live-ивенты", hint: "6 форматов" },
] as const;

type MetaId = (typeof META_DOCS)[number]["id"];

function countHint(id: MetaId, doc: Record<string, unknown> | null): string {
  if (!doc) return "—";
  switch (id) {
    case "mail":
      return `templates ${(doc.templates as unknown[] | undefined)?.length ?? 0} · inbox ${(doc.demo_inbox as unknown[] | undefined)?.length ?? 0}`;
    case "login_calendars":
      return `calendars ${(doc.calendars as unknown[] | undefined)?.length ?? 0}`;
    case "profile": {
      const cos = doc.cosmetics as Record<string, unknown[]> | undefined;
      return `avatars ${cos?.avatars?.length ?? 0} · frames ${cos?.frames?.length ?? 0}`;
    }
    case "achievements":
      return `ach ${(doc.achievements as unknown[] | undefined)?.length ?? 0} · secrets ${(doc.secrets as unknown[] | undefined)?.length ?? 0}`;
    case "daily_stories":
      return `stories ${(doc.stories as unknown[] | undefined)?.length ?? 0}`;
    case "live_events":
      return `events ${(doc.events as unknown[] | undefined)?.length ?? 0}`;
    default:
      return "";
  }
}

export default function MetaEditor() {
  const { data, saveDoc } = usePackage();
  const bundle = data as Record<string, unknown> | null;
  const [tab, setTab] = useState<MetaId>("mail");
  const [docs, setDocs] = useState<Partial<Record<MetaId, Record<string, unknown>>>>({});
  const [dirty, setDirty] = useState<Partial<Record<MetaId, boolean>>>({});

  useEffect(() => {
    if (!bundle) return;
    const next: Partial<Record<MetaId, Record<string, unknown>>> = {};
    for (const m of META_DOCS) {
      const v = bundle[m.id];
      if (v && typeof v === "object") next[m.id] = structuredClone(v as Record<string, unknown>);
    }
    setDocs(next);
    setDirty({});
  }, [bundle]);

  const current = docs[tab] ?? null;
  const meta = useMemo(() => META_DOCS.find((m) => m.id === tab)!, [tab]);

  if (!bundle) return <p className="muted">Загрузка meta-документов…</p>;

  return (
    <div>
      <VersionBar
        title="Meta-слой"
        subtitle="Почта → календари → профиль → достижения → сюжеты → live-ивенты (M→V)."
      />
      <div className="toolbar" style={{ flexWrap: "wrap", gap: 8 }}>
        {META_DOCS.map((m) => (
          <button
            key={m.id}
            type="button"
            className={`btn secondary${tab === m.id ? " active" : ""}`}
            onClick={() => setTab(m.id)}
          >
            {m.label}
            {dirty[m.id] ? " ·*" : ""}
          </button>
        ))}
        <button
          className="btn"
          type="button"
          disabled={!dirty[tab] || !current}
          onClick={async () => {
            if (!current) return;
            await saveDoc(tab, current);
            setDirty((d) => ({ ...d, [tab]: false }));
            alert(`${tab}.json сохранён`);
          }}
        >
          Сохранить {tab}.json
        </button>
      </div>

      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>
            {meta.label} <span className="muted">· {meta.hint}</span>
          </h3>
          {!current ? (
            <p className="warn">Документ отсутствует в этом пакете</p>
          ) : (
            <>
              <p className="muted">{countHint(tab, current)}</p>
              <MetaOverview id={tab} doc={current} />
            </>
          )}
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>JSON · {tab}.json</h3>
          {current ? (
            <DocJsonPanel
              value={current}
              onChange={(next) => {
                setDocs((d) => ({ ...d, [tab]: next as Record<string, unknown> }));
                setDirty((d) => ({ ...d, [tab]: true }));
              }}
              height={480}
            />
          ) : (
            <p className="muted">Нечего редактировать</p>
          )}
        </div>
      </div>
    </div>
  );
}

function MetaOverview({ id, doc }: { id: MetaId; doc: Record<string, unknown> }) {
  if (id === "mail") {
    const templates = (doc.templates as Array<{ id: string; title?: string; category?: string }>) || [];
    return (
      <ul className="list">
        {templates.slice(0, 12).map((t) => (
          <li key={t.id}>
            <code>{t.id}</code> · {t.title ?? "—"} · {t.category ?? ""}
          </li>
        ))}
        {templates.length > 12 ? <li className="muted">… +{templates.length - 12}</li> : null}
      </ul>
    );
  }
  if (id === "login_calendars") {
    const cals = (doc.calendars as Array<{ id: string; days?: unknown[] }>) || [];
    return (
      <ul className="list">
        {cals.map((c) => (
          <li key={c.id}>
            <strong>{c.id}</strong> · дней {c.days?.length ?? "?"}
          </li>
        ))}
      </ul>
    );
  }
  if (id === "achievements") {
    const ach = (doc.achievements as Array<{ id: string; title?: string; category?: string }>) || [];
    return (
      <ul className="list">
        {ach.slice(0, 16).map((a) => (
          <li key={a.id}>
            <code>{a.id}</code> · {a.title ?? "—"}
          </li>
        ))}
        {ach.length > 16 ? <li className="muted">… +{ach.length - 16}</li> : null}
      </ul>
    );
  }
  if (id === "daily_stories") {
    const stories = (doc.stories as Array<{ id: string; title?: string }>) || [];
    return (
      <ul className="list">
        {stories.slice(0, 12).map((s) => (
          <li key={s.id}>
            <code>{s.id}</code> · {s.title ?? "—"}
          </li>
        ))}
      </ul>
    );
  }
  if (id === "live_events") {
    const events = (doc.events as Array<{ id: string; format?: string; name?: string }>) || [];
    return (
      <ul className="list">
        {events.map((e) => (
          <li key={e.id}>
            <strong>{e.format ?? e.id}</strong> · {e.name ?? e.id}
          </li>
        ))}
      </ul>
    );
  }
  if (id === "profile") {
    const cos = (doc.cosmetics as Record<string, unknown[]>) || {};
    return (
      <ul className="muted">
        <li>avatars: {cos.avatars?.length ?? 0}</li>
        <li>frames: {cos.frames?.length ?? 0}</li>
        <li>titles: {cos.titles?.length ?? 0}</li>
      </ul>
    );
  }
  return null;
}
