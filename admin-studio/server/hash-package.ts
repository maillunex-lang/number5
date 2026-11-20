import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "../..");
const PACKAGES = path.join(ROOT, "content/packages");

const version = process.argv[2] || "0.1.0";
const dir = path.join(PACKAGES, version);
const manifestPath = path.join(dir, "manifest.json");

if (!fs.existsSync(manifestPath)) {
  console.error(`manifest missing: ${manifestPath}`);
  process.exit(1);
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8")) as {
  files?: Record<string, unknown>;
  integrity?: { algo: string; hashes: Record<string, string> };
  updated_at?: string;
};

const hashes: Record<string, string> = {};
for (const name of Object.keys(manifest.files || {})) {
  const fp = path.join(dir, name);
  if (!fs.existsSync(fp)) continue;
  const buf = fs.readFileSync(fp);
  hashes[name] = crypto.createHash("sha256").update(buf).digest("hex");
}

manifest.integrity = { algo: "sha256", hashes };
manifest.updated_at = new Date().toISOString();
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n", "utf8");
console.log(`Updated hashes for ${version}:`, hashes);
