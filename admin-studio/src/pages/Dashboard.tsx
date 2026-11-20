import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import VersionBar from "../components/VersionBar";
import { usePackage } from "../state/PackageContext";

export default function Dashboard() {
  const { data, active } = usePackage();
  const [note, setNote] = useState("");
  useEffect(() => {
    api.health().then((h) => setNote(h.note)).catch(() => setNote("API недоступен — запустите npm run dev"));
  }, []);

  return (
    <div>
      <VersionBar
        title="Lunex Admin Studio · комбайн"
        subtitle="Дизайн, интерфейс, контент и версии пакетов. Клиент Godot только читает."
      />
      <div className="panel" style={{ marginBottom: 16 }}>
        <p className="warn" style={{ marginTop: 0 }}>
          {note || "…"}
        </p>
        <p className="muted">
          Активный пакет <strong>{active}</strong> · schema {String((data?.manifest as any)?.schema ?? "—")}
        </p>
      </div>
      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Дизайн</h3>
          <ul>
            <li>
              <Link to="/theme">Theme Studio</Link>
            </li>
            <li>
              <Link to="/shell">Shell / навигация</Link>
            </li>
            <li>
              <Link to="/strings">Строки UI</Link>
            </li>
            <li>
              <Link to="/motion">Motion / FX</Link>
            </li>
            <li>
              <Link to="/assets">Библиотека ассетов</Link>
            </li>
          </ul>
          <h3 style={{ color: "var(--gold)" }}>Экраны</h3>
          <ul>
            <li>
              <Link to="/hub">Хаб Visual Editor 2.0</Link>
            </li>
            <li>
              <Link to="/campaign">Кампания</Link>
            </li>
            <li>
              <Link to="/heroes">Герои</Link>
            </li>
            <li>
              <Link to="/battle">Режимы битвы</Link>
            </li>
            <li>
              <Link to="/features">Фичи</Link>
            </li>
            <li>
              <Link to="/packages">Пакеты · diff / publish / rollback</Link>
            </li>
          </ul>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Пакет сейчас</h3>
          {data ? (
            <ul className="muted">
              <li>Здания: {data.hub?.buildings?.length ?? 0}</li>
              <li>Этапы: {data.campaign?.stages?.length ?? 0}</li>
              <li>Герои: {data.heroes?.heroes?.length ?? 0}</li>
              <li>Тема: {data.theme?.title ?? "—"}</li>
              <li>Строк: {Object.keys(data.strings?.entries || {}).length}</li>
              <li>Ассетов: {data.assets?.items?.length ?? 0}</li>
            </ul>
          ) : (
            <p className="muted">Загрузка…</p>
          )}
        </div>
      </div>
    </div>
  );
}
