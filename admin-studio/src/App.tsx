import { NavLink, Route, Routes } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import HubEditor from "./pages/HubEditor";
import CampaignEditor from "./pages/CampaignEditor";
import HeroesEditor from "./pages/HeroesEditor";
import BattleModesEditor from "./pages/BattleModesEditor";
import PackagesPage from "./pages/PackagesPage";
import FeaturesEditor from "./pages/FeaturesEditor";
import { PackageProvider } from "./state/PackageContext";

export default function App() {
  return (
    <PackageProvider>
      <div className="app-shell">
        <aside className="sidebar">
          <div className="brand">
            LUNEX Admin Studio
            <small>Контент · не игровой сервер</small>
          </div>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/" end>
            Обзор
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/hub">
            Хаб 2.5D
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/campaign">
            Кампания
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/heroes">
            Герои
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/battle">
            Режимы битвы
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/features">
            Фичи
          </NavLink>
          <NavLink className={({ isActive }) => `nav-link${isActive ? " active" : ""}`} to="/packages">
            Пакеты
          </NavLink>
          <p className="muted" style={{ marginTop: "auto", fontSize: 12, lineHeight: 1.4 }}>
            Клиент Godot только читает опубликованный пакет и рисует. Прогресс/валюты/бой — не здесь.
          </p>
        </aside>
        <main className="main">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/hub" element={<HubEditor />} />
            <Route path="/campaign" element={<CampaignEditor />} />
            <Route path="/heroes" element={<HeroesEditor />} />
            <Route path="/battle" element={<BattleModesEditor />} />
            <Route path="/features" element={<FeaturesEditor />} />
            <Route path="/packages" element={<PackagesPage />} />
          </Routes>
        </main>
      </div>
    </PackageProvider>
  );
}
