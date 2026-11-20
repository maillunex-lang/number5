import type { PackageBundle } from "../types/content";

async function req<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    headers: { "Content-Type": "application/json", ...(init?.headers || {}) },
    ...init,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || res.statusText);
  }
  return res.json() as Promise<T>;
}

export const api = {
  health: () => req<{ ok: boolean; note: string }>("/api/health"),
  listPackages: () => req<{ active: string; versions: string[] }>("/api/packages"),
  getPackage: (version: string) => req<PackageBundle>(`/api/packages/${version}`),
  saveDoc: (version: string, doc: string, body: unknown) =>
    req(`/api/packages/${version}/${doc}`, { method: "PUT", body: JSON.stringify(body) }),
  publish: (version: string) =>
    req<{ ok: boolean; message: string }>(`/api/packages/${version}/publish`, { method: "POST", body: "{}" }),
  createVersion: (from: string, to: string) =>
    req(`/api/packages/create`, { method: "POST", body: JSON.stringify({ from, to }) }),
};
