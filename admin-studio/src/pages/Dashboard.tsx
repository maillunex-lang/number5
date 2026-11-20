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
        title="Lunex Admin Studio"
        subtitle="Визуальное редактирование контента и версионные пакеты ассетов/данных."
      />
      <div className="panel" style={{ marginBottom: 16 }}>
        <p className="warn" style={{ marginTop: 0 }}>
          {note || "…"}
        </p>
        <p className="muted">
          Активный пакет <strong>{active}</strong> читает Godot из <code>res://content/packages</code>. Клиент не пишет
          сюда прогресс игрока.
        </p>
      </div>
      <div className="grid-2">
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Быстрый вход</h3>
          <ul>
            <li>
              <Link to="/hub">Расстановка зданий хаба</Link>
            </li>
            <li>
              <Link to="/campaign">Этапы кампании</Link>
            </li>
            <li>
              <Link to="/heroes">Герои и пресеты</Link>
            </li>
            <li>
              <Link to="/battle">Порталы режимов битвы</Link>
            </li>
            <li>
              <Link to="/features">Фичи / офферы / квесты</Link>
            </li>
            <li>
              <Link to="/packages">Версии и публикация</Link>
            </li>
          </ul>
        </div>
        <div className="panel">
          <h3 style={{ marginTop: 0, color: "var(--gold)" }}>Содержимое пакета</h3>
          {data ? (
            <ul className="muted">
              <li>Здания хаба: {data.hub.buildings.length}</li>
              <li>Этапы: {data.campaign.stages.length}</li>
              <li>Герои: {data.heroes.heroes.length}</li>
              <li>Порталы битвы: {data.battle_modes.portals.length}</li>
              <li>
                Офферы магазина:{" "}
                {Array.isArray((data.features as { shop_offers?: unknown[] }).shop_offers)
                  ? (data.features as { shop_offers: unknown[] }).shop_offers.length
                  : 0}
              </li>
            </ul>
          ) : (
            <p className="muted">Загрузка…</p>
          )}
        </div>
      </div>
    </div>
  );
}
