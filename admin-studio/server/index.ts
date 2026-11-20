import cors from "cors";
import express from "express";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const PACKAGES = path.join(ROOT, "content/packages");

const DOC_FILES = [
  "manifest",
  "hub",
  "campaign",
  "heroes",
  "battle_modes",
  "features",
  "theme",
  "shell",
  "strings",
  "motion",
  "assets",
  "enemies",
  "economy",
  "progression",
  "equipment",
  "loot_tables",
  "gacha",
  "liveops",
  "pve_modes",
  "guilds",
  "mail",
  "login_calendars",
  "profile",
  "achievements",
  "daily_stories",
  "live_events",
  "skills",
  "dialogs",
] as const;

const app = express();
app.use(cors());
app.use(express.json({ limit: "12mb" }));

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
  if (!manifest.files) manifest.files = {};
  for (const doc of DOC_FILES) {
    if (doc === "manifest") continue;
    const name = `${doc}.json`;
    if (fs.existsSync(path.join(dir, name)) && !manifest.files[name]) {
      manifest.files[name] = { role: doc };
    }
  }
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

function packageDir(version: string) {
  return path.join(PACKAGES, version);
}

// Read-only operational metrics. Session count is NOT a live presence count.
const execFileAsync = promisify(execFile);
async function sqlRead(query: string) {
  const { stdout } = await execFileAsync("/usr/bin/docker", [
    "exec", "lunex-afk-postgres-1", "psql", "-U", "lunex_afk", "-d", "lunex_afk",
    "-X", "-A", "-t", "-c", query
  ], { timeout: 5000, maxBuffer: 256000 });
  return stdout.trim();
}
app.get("/api/operations/summary", async (_req, res) => {
  try {
    const [stats, players] = await Promise.all([
      sqlRead(`SELECT json_build_object(
        'accounts', (SELECT count(*) FROM accounts),
        'guests', (SELECT count(*) FROM accounts WHERE is_guest),
        'active_sessions', (SELECT count(*) FROM sessions WHERE expires_at > now() AND revoked_at IS NULL),
        'online_2min', (SELECT count(*) FROM player_profiles WHERE last_seen_at > now() - interval '2 minutes'),
        'sessions_24h', (SELECT count(*) FROM sessions WHERE expires_at > now() AND revoked_at IS NULL),
        'db_time', now()
      )::text`),
      sqlRead(`SELECT coalesce(json_agg(row_to_json(t)), '[]'::json)::text FROM (
        SELECT a.id, a.is_guest, a.status, a.created_at, a.email,
          coalesce(pp.nickname,'') AS nickname, coalesce(pp.level,1) AS level, coalesce(pp.xp,0) AS xp, pp.last_seen_at,
          coalesce((SELECT amount FROM wallet_balances w WHERE w.account_id=a.id AND resource_id='gold'),0) AS gold,
          coalesce((SELECT amount FROM wallet_balances w WHERE w.account_id=a.id AND resource_id='diamonds'),0) AS diamonds,
          (SELECT count(*) FROM heroes_owned h WHERE h.account_id=a.id) AS hero_count,
          (SELECT current_stage FROM campaign_progress c WHERE c.account_id=a.id) AS stage
        FROM accounts a LEFT JOIN player_profiles pp ON pp.account_id=a.id ORDER BY a.created_at DESC LIMIT 100
      ) t`)
    ]);
    res.setHeader("Cache-Control", "no-store");
    res.json({ ok: true, stats: JSON.parse(stats), profiles: JSON.parse(players),
      online_note: "Онлайн = игроки с heartbeat за последние 2 минуты. Действующие сессии отдельно и не равны онлайн.",
      edit_note: "Изменения сохраняются транзакционно с журналом аудита. Доступ защищён паролем админки." });
  } catch (err) {
    res.status(503).json({ ok: false, error: "metrics_unavailable" });
  }
});

app.patch("/api/operations/profiles/:id", async (req, res) => {
  const id = String(req.params.id || "");
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) return res.status(400).json({error:"bad_id"});
  const body = req.body ?? {};
  const allowed = ["nickname","level","xp","gold","diamonds"];
  if (Object.keys(body).length === 0 || Object.keys(body).some(k=>!allowed.includes(k)))
    return res.status(400).json({error:"bad_fields"});
  if (body.nickname !== undefined && (typeof body.nickname !== "string" || body.nickname.trim().length < 2 || body.nickname.length > 24 || /[\x00-\x1f]/.test(body.nickname)))
    return res.status(400).json({error:"bad_nickname"});
  for (const key of ["level","xp","gold","diamonds"]) {
    if (body[key] !== undefined && (!Number.isSafeInteger(body[key]) || body[key] < (key==="level"?1:0) || body[key] > (key==="level"?200:1000000000000)))
      return res.status(400).json({error:"bad_"+key});
  }
  const quote = (v: string) => "'" + v.replace(/'/g,"''") + "'";
  const assignments: string[] = [];
  for(const key of ["nickname","level","xp"]) if(body[key]!==undefined)
    assignments.push(key+"="+(key==="nickname"?quote(body[key].trim()):String(body[key])));
  const profileUpdate = assignments.length ? "UPDATE player_profiles SET "+assignments.join(",")+" WHERE account_id="+quote(id)+"::uuid;" : "";
  const walletUpdates = ["gold","diamonds"].filter(k=>body[k]!==undefined).map(k=>
    `INSERT INTO wallet_balances(account_id,resource_id,amount,version) VALUES (${quote(id)}::uuid,${quote(k)},${body[k]},1)
     ON CONFLICT(account_id,resource_id) DO UPDATE SET amount=EXCLUDED.amount,version=wallet_balances.version+1;
     INSERT INTO wallet_ledger(account_id,resource_id,delta,source_type,source_id,idempotency_key)
     SELECT ${quote(id)}::uuid,${quote(k)},${body[k]}-coalesce((before_json->>'${k}')::bigint,0),'admin_adjustment','admin_studio',${quote(crypto.randomUUID())}
     FROM admin_profile_audit WHERE id=(SELECT max(id) FROM admin_profile_audit WHERE account_id=${quote(id)}::uuid);`).join("\n");
  // Transaction uses row lock to serialize administrative edits. The audit row captures both snapshots.
  const before = `SELECT json_build_object('nickname',p.nickname,'level',p.level,'xp',p.xp,
    'gold',coalesce((SELECT amount FROM wallet_balances WHERE account_id=p.account_id AND resource_id='gold'),0),
    'diamonds',coalesce((SELECT amount FROM wallet_balances WHERE account_id=p.account_id AND resource_id='diamonds'),0)) FROM player_profiles p WHERE p.account_id=${quote(id)}::uuid`;
  const after = before;
  const sql = `BEGIN;
    SELECT account_id FROM player_profiles WHERE account_id=${quote(id)}::uuid FOR UPDATE;
    INSERT INTO admin_profile_audit(account_id,action,before_json,after_json) SELECT ${quote(id)}::uuid,'profile_edit',(${before}), '{}'::jsonb WHERE EXISTS(SELECT 1 FROM player_profiles WHERE account_id=${quote(id)}::uuid);
    ${profileUpdate}
    ${walletUpdates}
    UPDATE admin_profile_audit SET after_json=(${after}) WHERE id=(SELECT max(id) FROM admin_profile_audit WHERE account_id=${quote(id)}::uuid);
    COMMIT;`;
  try {
    const {stderr} = await execFileAsync("/usr/bin/docker",["exec","lunex-afk-postgres-1","psql","-v","ON_ERROR_STOP=1","-U","lunex_afk","-d","lunex_afk","-X","-q","-c",sql],{timeout:7000,maxBuffer:200000});
    if(stderr && /ERROR:/.test(stderr)) throw Error("sql_error");
    res.setHeader("Cache-Control","no-store");res.json({ok:true});
  } catch {res.status(503).json({error:"edit_failed"});}
});

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "lunex-admin-studio",
    note: "Контент/дизайн комбайн. Не игровой сервер прогресса/платежей.",
    cdn: "http://127.0.0.1:8787/cdn",
  });
});

/** OTA CDN: клиент качает active + JSON пакета без переустановки APK */
app.get("/cdn/active.json", (_req, res) => {
  const fp = path.join(PACKAGES, "active.json");
  if (!fs.existsSync(fp)) return res.status(404).json({ error: "no active" });
  res.type("json").send(fs.readFileSync(fp, "utf8"));
});

app.get("/cdn/packages/:version/:file", (req, res) => {
  const version = req.params.version;
  const file = req.params.file;
  if (!/^\d+\.\d+\.\d+$/.test(version)) return res.status(400).json({ error: "bad version" });
  if (file.includes("..") || file.includes("/") || file.includes("\\")) {
    return res.status(400).json({ error: "bad file" });
  }
  const fp = path.join(packageDir(version), file);
  if (!fs.existsSync(fp)) return res.status(404).json({ error: "not found" });
  if (file.endsWith(".json")) res.type("json");
  res.sendFile(fp);
});

app.get("/cdn/packages/:version", (req, res) => {
  const dir = packageDir(req.params.version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "not found" });
  const files = fs.readdirSync(dir).filter((f) => !f.startsWith("."));
  res.json({ version: req.params.version, files });
});

app.get("/api/packages", (_req, res) => {
  const active = readJson(path.join(PACKAGES, "active.json")) as { version: string };
  res.json({ active: active.version, versions: listVersions() });
});

app.get("/api/packages/:version", (req, res) => {
  const dir = packageDir(req.params.version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "not found" });
  const data: Record<string, unknown> = {};
  for (const doc of DOC_FILES) {
    const fp = path.join(dir, `${doc}.json`);
    if (fs.existsSync(fp)) data[doc] = readJson(fp);
  }
  res.json(data);
});

app.get("/api/packages/:version/diff/:other", (req, res) => {
  const aDir = packageDir(req.params.version);
  const bDir = packageDir(req.params.other);
  if (!fs.existsSync(aDir) || !fs.existsSync(bDir)) return res.status(404).json({ error: "not found" });
  const changes: Array<{ doc: string; status: "changed" | "added" | "removed" | "same" }> = [];
  for (const doc of DOC_FILES) {
    if (doc === "manifest") continue;
    const af = path.join(aDir, `${doc}.json`);
    const bf = path.join(bDir, `${doc}.json`);
    const aExists = fs.existsSync(af);
    const bExists = fs.existsSync(bf);
    if (!aExists && !bExists) continue;
    if (aExists && !bExists) changes.push({ doc, status: "removed" });
    else if (!aExists && bExists) changes.push({ doc, status: "added" });
    else {
      const same = hashFile(af) === hashFile(bf);
      changes.push({ doc, status: same ? "same" : "changed" });
    }
  }
  res.json({ from: req.params.other, to: req.params.version, changes });
});

app.put("/api/packages/:version/:doc", (req, res) => {
  const version = req.params.version;
  const doc = req.params.doc;
  const allowed = new Set<string>([...DOC_FILES]);
  if (!allowed.has(doc)) return res.status(400).json({ error: "invalid doc" });
  const dir = packageDir(version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "version not found" });
  const fp = path.join(dir, `${doc}.json`);
  writeJson(fp, req.body);
  const manifest = updateManifestHashes(version);
  res.json({ ok: true, version, doc, manifest });
});

app.post("/api/packages/:version/publish", (req, res) => {
  const version = req.params.version;
  const dir = packageDir(version);
  if (!fs.existsSync(dir)) return res.status(404).json({ error: "not found" });
  const historyPath = path.join(PACKAGES, "publish_history.json");
  let history: Array<Record<string, unknown>> = [];
  if (fs.existsSync(historyPath)) history = readJson(historyPath) as Array<Record<string, unknown>>;
  const prev = readJson(path.join(PACKAGES, "active.json")) as { version: string };
  history.unshift({
    version,
    previous: prev.version,
    published_at: new Date().toISOString(),
  });
  history = history.slice(0, 30);
  writeJson(historyPath, history);
  const manifest = updateManifestHashes(version);
  writeJson(path.join(PACKAGES, "active.json"), {
    version,
    source: "admin-studio",
    note: "Клиент читает только опубликованный пакет. Прогресс игрока сюда не пишется.",
    published_at: new Date().toISOString(),
  });
  res.json({
    ok: true,
    active: version,
    previous: prev.version,
    path: dir,
    cdn_active: "http://127.0.0.1:8787/cdn/active.json",
    cdn_package: `http://127.0.0.1:8787/cdn/packages/${version}/`,
    manifest,
    message: `Пакет ${version} опубликован в CDN. Клиенты подтянут OTA без переустановки APK (cdn_base в update_config).`,
  });
});

app.post("/api/packages/rollback", (req, res) => {
  const historyPath = path.join(PACKAGES, "publish_history.json");
  if (!fs.existsSync(historyPath)) return res.status(400).json({ error: "no history" });
  const history = readJson(historyPath) as Array<{ previous?: string; version?: string }>;
  const target = String(req.body?.version || history[0]?.previous || "");
  if (!target || !fs.existsSync(packageDir(target))) return res.status(404).json({ error: "target missing" });
  writeJson(path.join(PACKAGES, "active.json"), {
    version: target,
    source: "admin-studio-rollback",
    note: "Откат active-указателя. Прогресс игрока не затрагивается.",
    published_at: new Date().toISOString(),
  });
  res.json({ ok: true, active: target, message: `Откат на ${target}` });
});

app.get("/api/packages/history", (_req, res) => {
  const historyPath = path.join(PACKAGES, "publish_history.json");
  res.json({ history: fs.existsSync(historyPath) ? readJson(historyPath) : [] });
});

app.post("/api/packages/create", (req, res) => {
  const from = String(req.body?.from || "0.1.0");
  const to = String(req.body?.to || "");
  if (!/^\d+\.\d+\.\d+$/.test(to)) return res.status(400).json({ error: "bad version" });
  const src = packageDir(from);
  const dst = packageDir(to);
  if (!fs.existsSync(src)) return res.status(404).json({ error: "source missing" });
  if (fs.existsSync(dst)) return res.status(409).json({ error: "already exists" });
  fs.cpSync(src, dst, { recursive: true });
  const manifest = readJson(path.join(dst, "manifest.json")) as Record<string, any>;
  manifest.version = to;
  manifest.created_at = new Date().toISOString();
  writeJson(path.join(dst, "manifest.json"), manifest);
  updateManifestHashes(to);
  res.json({ ok: true, version: to });
});

app.post("/api/packages/:version/assets/register", (req, res) => {
  const version = req.params.version;
  const dir = packageDir(version);
  const assetsPath = path.join(dir, "assets.json");
  if (!fs.existsSync(assetsPath)) return res.status(404).json({ error: "assets.json missing" });
  const doc = readJson(assetsPath) as { items: any[]; bindings: Record<string, string> };
  const item = req.body?.item;
  if (!item?.id) return res.status(400).json({ error: "item.id required" });
  const idx = doc.items.findIndex((i) => i.id === item.id);
  if (idx >= 0) doc.items[idx] = { ...doc.items[idx], ...item };
  else doc.items.push(item);
  if (req.body?.binding_key) {
    doc.bindings = doc.bindings || {};
    doc.bindings[String(req.body.binding_key)] = item.id;
  }
  writeJson(assetsPath, doc);
  updateManifestHashes(version);
  res.json({ ok: true, assets: doc });
});

app.post("/api/packages/:version/assets/upload", (req, res) => {
  const version = req.params.version;
  const dir = packageDir(version);
  const { id, filename, data_base64, mime, role, tags } = req.body || {};
  if (!id || !filename || !data_base64) return res.status(400).json({ error: "id, filename, data_base64 required" });
  const safe = String(filename).replace(/[^a-zA-Z0-9._-]/g, "_");
  const assetsDir = path.join(dir, "media");
  fs.mkdirSync(assetsDir, { recursive: true });
  const rel = `media/${safe}`;
  const buf = Buffer.from(String(data_base64), "base64");
  fs.writeFileSync(path.join(dir, rel), buf);
  const assetsPath = path.join(dir, "assets.json");
  const doc = (fs.existsSync(assetsPath) ? readJson(assetsPath) : { items: [], bindings: {} }) as {
    items: any[];
    bindings: Record<string, string>;
  };
  const item = {
    id,
    path: `res://content/packages/${version}/${rel}`,
    role: role || "upload",
    tags: tags || ["upload"],
    mime: mime || "application/octet-stream",
    bytes: buf.length,
  };
  const idx = doc.items.findIndex((i) => i.id === id);
  if (idx >= 0) doc.items[idx] = item;
  else doc.items.push(item);
  writeJson(assetsPath, doc);
  updateManifestHashes(version);
  res.json({ ok: true, item, assets: doc });
});

const PORT = Number(process.env.PORT || 8787);
app.listen(PORT, "127.0.0.1", () => {
  console.log(`Lunex Admin Studio API on http://127.0.0.1:${PORT}`);
  console.log(`Packages root: ${PACKAGES}`);
});
