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
};

export type HubDoc = {
  world: { width: number; height: number };
  parallax?: Record<string, number>;
  buildings: Building[];
  side_rail: SideRailItem[];
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
};
