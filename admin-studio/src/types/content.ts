export type Building = {
  id: string;
  name: string;
  x: number;
  y: number;
  route: string;
  locked: boolean;
  req: string;
  color: string;
  payload?: Record<string, unknown>;
  size?: { w: number; h: number };
};

export type SideRailItem = {
  id: string;
  icon: string;
  tip: string;
  route: string;
  color: string;
  size?: number;
};

export type HubLook = {
  sky_top: string;
  sky_mid: string;
  sky_bottom: string;
  mid_color: string;
  path_color: string;
  ambient: number;
  glow: number;
  vignette: number;
  show_shell: boolean;
};

export type SideRailLayout = {
  offset_right: number;
  offset_top: number;
  button_size: number;
  gap: number;
};

export type HubDoc = {
  world: { width: number; height: number };
  parallax?: Record<string, number>;
  look?: HubLook;
  side_rail_layout?: SideRailLayout;
  buildings: Building[];
  side_rail: SideRailItem[];
};

export type ThemeDoc = {
  id: string;
  title: string;
  radius: Record<string, number>;
  spacing: Record<string, number>;
  fonts: Record<string, string>;
  palette: Record<string, string>;
  components: Record<string, number>;
};

export type ShellDoc = {
  top_bar: Record<string, unknown>;
  bottom_nav: {
    height: number;
    bg: string;
    border: string;
    tabs: Array<{ id: string; label: string; icon: string; enabled: boolean }>;
  };
  safe_area: Record<string, number>;
  welcome_toast: string;
};

export type StringsDoc = {
  locale: string;
  entries: Record<string, string>;
};

export type MotionDoc = {
  transition_ms: number;
  parallax_enabled: boolean;
  hub_pulse: boolean;
  hub_pulse_sec: number;
  particle_scale: number;
  max_active_fx: number;
  hub_decor_layers: number;
  building_float: boolean;
  toast_ms: number;
};

export type AssetsDoc = {
  items: Array<{
    id: string;
    path: string;
    role: string;
    tags?: string[];
    note?: string;
    mime?: string;
    bytes?: number;
  }>;
  bindings: Record<string, string>;
};

export type Stage = {
  id: string;
  name: string;
  power: number;
  type: "main" | "side" | "secret" | string;
  state: string;
  rewards: string[];
  x?: number;
  y?: number;
  reveal_hint?: string;
};

export type CampaignDoc = {
  chapter_id: string;
  chapter_name: string;
  current_stage: string;
  regions: Array<Record<string, unknown>>;
  stages: Stage[];
  edges: string[][];
};

export type Hero = {
  id: string;
  name: string;
  class: string;
  faction: string;
  rarity: string;
  tint: string;
  level: number;
  stars: number;
  power: number;
  skills: string[];
  favorite?: boolean;
};

export type HeroesDoc = {
  heroes: Hero[];
  equipment: Array<Record<string, unknown>>;
  squad_presets: Array<{ id: string; name: string; slots: string[] }>;
  default_squad: string[];
};

export type BattlePortal = {
  id: string;
  name: string;
  route: string;
  payload?: Record<string, unknown>;
  x: number;
  y: number;
  color: string;
  size?: { w: number; h: number };
};

export type BattleModesDoc = {
  portals: BattlePortal[];
  world: { width: number; height: number };
};

export type PackageBundle = {
  manifest: Record<string, unknown>;
  hub: HubDoc;
  campaign: CampaignDoc;
  heroes: HeroesDoc;
  battle_modes: BattleModesDoc;
  features: Record<string, unknown>;
  theme?: ThemeDoc;
  shell?: ShellDoc;
  strings?: StringsDoc;
  motion?: MotionDoc;
  assets?: AssetsDoc;
};

export const DEFAULT_HUB_LOOK: HubLook = {
  sky_top: "#101a2c",
  sky_mid: "#132038",
  sky_bottom: "#0b1220",
  mid_color: "#1f332e",
  path_color: "#382e1f8c",
  ambient: 0.92,
  glow: 0.45,
  vignette: 0.28,
  show_shell: true,
};

export const DEFAULT_SIDE_RAIL_LAYOUT: SideRailLayout = {
  offset_right: 12,
  offset_top: 12,
  button_size: 64,
  gap: 10,
};

export const DOC_LABELS: Record<string, string> = {
  theme: "Тема UI",
  shell: "Shell / навигация",
  strings: "Строки",
  motion: "Motion / FX",
  assets: "Ассеты",
  hub: "Хаб",
  campaign: "Кампания",
  heroes: "Герои",
  battle_modes: "Режимы битвы",
  features: "Фичи",
};
