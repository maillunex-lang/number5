import cors from "cors";
import express from "express";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const PACKAGES = path.join(ROOT, "content/packages");
const CACHE = path.join(ROOT, ".godot-user-content-cache"); // optional mirror note

const app = express();
app.use(cors());
app.use(express.json({ limit: "4mb" }));

function listVersions(): string[] {
  return fs
    .readdirSync(PACKAGES, { withFileTypes: true })
    .filter((d) => d.isDirectory() && /^\d+\.\d+\.\d+$/.test(d.name))
    .map((d) => d.name)
    .sort();
}

function readJson(file: string): unknown {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function writeJson(file: string, data: unknown) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n", "utf8");
}

function hashFile(file: string): string {
  const buf = fs.readFileSync(file);
  return crypto.createHash("sha256").update(buf).digest("hex");
}

function updateManifestHashes(version: string) {
  const dir = path.join(PACKAGES, version);
  const manifestPath = path.join(dir, "manifest.json");
  const manifest = readJson(manifestPath) as Record<string, any>;
  const hashes: Record<string, string> = {};
  for (const name of Object.keys(manifest.files || {})) {
    const fp = path.join(dir, name);
    if (fs.existsSync(fp)) hashes[name] = hashFile(fp);
  }
  manifest.integrity = { algo: "sha256", hashes };
  manifest.updated_at = new Date().toISOString();
  writeJson(manifestPath, manifest);
  return manifest;
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "lunex-admin-studio",
    note: "Контент-API. Не игровой сервер прогресса/платежей.",
  });
});

app.get("/api/packages", (_req, res) => {
  const active = readJson(path.join(PACKAGES, "active.json")) as { version: string };
  res.json({ active: active.version, versions: listVersions() });
});

app.get("/api/packages/:version", (req, res) => {
  const dir = path.join(PACKAGES, req.params.version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "not found" });
  const files = ["manifest.json", "hub.json", "campaign.json", "heroes.json", "battle_modes.json", "features.json"];
  const data: Record<string, unknown> = {};
  for (const f of files) {
    const fp = path.join(dir, f);
    if (fs.existsSync(fp)) data[f.replace(".json", "")] = readJson(fp);
  }
  res.json(data);
});

app.put("/api/packages/:version/:doc", (req, res) => {
  const version = req.params.version;
  const doc = req.params.doc;
  const allowed = new Set(["hub", "campaign", "heroes", "battle_modes", "features", "manifest"]);
  if (!allowed.has(doc)) return res.status(400).json({ error: "invalid doc" });
  const dir = path.join(PACKAGES, version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "version not found" });
  const fp = path.join(dir, `${doc}.json`);
  writeJson(fp, req.body);
  const manifest = updateManifestHashes(version);
  res.json({ ok: true, version, doc, manifest });
});

app.post("/api/packages/:version/publish", (req, res) => {
  const version = req.params.version;
  const dir = path.join(PACKAGES, version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "version not found" });
  const manifest = updateManifestHashes(version);
  writeJson(path.join(PACKAGES, "active.json"), {
    version,
    source: "admin-studio",
    note: "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
    published_at: new Date().toISOString(),
  });
  // Mirror into a path Godot user cache can optionally pick up when synced manually
  const mirror = path.join(ROOT, "content/packages", version);
  res.json({
    ok: true,
    active: version,
    path: mirror,
    manifest,
    message: "Пакет опубликован локально. Godot читает res://content/packages.",
  });
});

app.post("/api/packages/create", (req, res) => {
  const from = String(req.body?.from || "0.1.0");
  const to = String(req.body?.to || "");
  if (!/^\d+\.\d+\.\d+$/.test(to)) return res.status(400).json({ error: "bad version" });
  const src = path.join(PACKAGES, from);
  const dst = path.join(PACKAGES, to);
  if (!fs.existsSync(src)) return res.status(404).json({ error: "source missing" });
  if (fs.existsSync(dst)) return res.status(409).json({ error: "already exists" });
  fs.mkdirSync(dst);
  for (const f of fs.readdirSync(src)) {
    fs.copyFileSync(path.join(src, f), path.join(dst, f));
  }
  const manifest = readJson(path.join(dst, "manifest.json")) as Record<string, any>;
  manifest.version = to;
  manifest.created_at = new Date().toISOString();
  writeJson(path.join(dst, "manifest.json"), manifest);
  updateManifestHashes(to);
  res.json({ ok: true, version: to });
});

const PORT = Number(process.env.PORT || 8787);
app.listen(PORT, "127.0.0.1", () => {
  console.log(`Lunex Admin Studio API on http://127.0.0.1:${PORT}`);
  console.log(`Packages root: ${PACKAGES}`);
});
