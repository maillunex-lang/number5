import { useEffect, useState } from "react";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";
import type { Hero, HeroesDoc } from "../types/content";

export default function HeroesEditor() {
  const { data, saveDoc } = usePackage();
  const [doc, setDoc] = useState<HeroesDoc | null>(null);
  const [selected, setSelected] = useState("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (data?.heroes) {
      setDoc(structuredClone(data.heroes));
      setDirty(false);
      if (!selected && data.heroes.heroes[0]) setSelected(data.heroes.heroes[0].id);
    }
  }, [data]);

  if (!doc) return <p className="muted">Загрузка героев…</p>;
  const hero = doc.heroes.find((h) => h.id === selected) || null;

  return (
    <div>
      <VersionBar title="Герои" subtitle="Коллекция, сила, фракции, пресеты отрядов." />
      <div className="toolbar">
        <button
          className="btn"
          type="button"
          disabled={!dirty}
          onClick={async () => {
            await saveDoc("heroes", doc);
            setDirty(false);
            alert("heroes.json сохранён");
          }}
        >
          Сохранить heroes.json
        </button>
      </div>
      <div className="grid-2">
        <div className="panel">
          <table className="table">
            <thead>
              <tr>
                <th>Имя</th>
                <th>Класс</th>
                <th>Редкость</th>
                <th>Сила</th>
              </tr>
            </thead>
            <tbody>
              {doc.heroes.map((h) => (
                <tr
                  key={h.id}
                  onClick={() => setSelected(h.id)}
                  style={{ cursor: "pointer", background: selected === h.id ? "rgba(232,197,106,0.08)" : undefined }}
                >
                  <td>
                    <span style={{ color: h.tint }}>●</span> {h.name}
                  </td>
                  <td>{h.class}</td>
                  <td>{h.rarity}</td>
                  <td>{h.power}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="panel">
          {hero ? (
            <HeroForm
              hero={hero}
              onChange={(next) => {
                setDoc({
                  ...doc,
                  heroes: doc.heroes.map((h) => (h.id === next.id ? next : h)),
                });
                setDirty(true);
              }}
            />
          ) : null}
          <h4 style={{ color: "var(--cyan)" }}>Пресеты отрядов</h4>
          <ul className="muted">
            {doc.squad_presets.map((p) => (
              <li key={p.id}>
                {p.name}: {p.slots.join(", ")}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

function HeroForm({ hero, onChange }: { hero: Hero; onChange: (h: Hero) => void }) {
  return (
    <div>
      <h3 style={{ marginTop: 0, color: "var(--gold)" }}>{hero.name}</h3>
      <div className="field">
        <label>Имя</label>
        <input value={hero.name} onChange={(e) => onChange({ ...hero, name: e.target.value })} />
      </div>
      <div className="field">
        <label>Класс / Фракция</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input value={hero.class} onChange={(e) => onChange({ ...hero, class: e.target.value })} />
          <input value={hero.faction} onChange={(e) => onChange({ ...hero, faction: e.target.value })} />
        </div>
      </div>
      <div className="field">
        <label>Редкость / Tint</label>
        <div style={{ display: "flex", gap: 8 }}>
          <select value={hero.rarity} onChange={(e) => onChange({ ...hero, rarity: e.target.value })}>
            <option value="common">common</option>
            <option value="rare">rare</option>
            <option value="epic">epic</option>
            <option value="legendary">legendary</option>
          </select>
          <input value={hero.tint} onChange={(e) => onChange({ ...hero, tint: e.target.value })} />
        </div>
      </div>
      <div className="field">
        <label>Уровень / Звёзды / Сила</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input type="number" value={hero.level} onChange={(e) => onChange({ ...hero, level: Number(e.target.value) })} />
          <input type="number" value={hero.stars} onChange={(e) => onChange({ ...hero, stars: Number(e.target.value) })} />
          <input type="number" value={hero.power} onChange={(e) => onChange({ ...hero, power: Number(e.target.value) })} />
        </div>
      </div>
    </div>
  );
}
