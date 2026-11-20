import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { api } from "../api/client";
import type { PackageBundle } from "../types/content";

type Ctx = {
  version: string;
  versions: string[];
  active: string;
  data: PackageBundle | null;
  loading: boolean;
  error: string;
  setVersion: (v: string) => void;
  reload: () => Promise<void>;
  saveDoc: (doc: keyof PackageBundle, body: unknown) => Promise<void>;
  publish: () => Promise<string>;
};

const PackageContext = createContext<Ctx | null>(null);

export function PackageProvider({ children }: { children: React.ReactNode }) {
  const [version, setVersion] = useState("0.1.0");
  const [versions, setVersions] = useState<string[]>([]);
  const [active, setActive] = useState("0.1.0");
  const [data, setData] = useState<PackageBundle | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const reload = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const list = await api.listPackages();
      setVersions(list.versions);
      setActive(list.active);
      const ver = list.versions.includes(version) ? version : list.active;
      if (ver !== version) setVersion(ver);
      const pack = await api.getPackage(ver);
      setData(pack);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }, [version]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const saveDoc = useCallback(
    async (doc: keyof PackageBundle, body: unknown) => {
      await api.saveDoc(version, String(doc), body);
      await reload();
    },
    [version, reload]
  );

  const publish = useCallback(async () => {
    const r = await api.publish(version);
    await reload();
    return r.message;
  }, [version, reload]);

  const value = useMemo(
    () => ({ version, versions, active, data, loading, error, setVersion, reload, saveDoc, publish }),
    [version, versions, active, data, loading, error, reload, saveDoc, publish]
  );

  return <PackageContext.Provider value={value}>{children}</PackageContext.Provider>;
}

export function usePackage() {
  const ctx = useContext(PackageContext);
  if (!ctx) throw new Error("usePackage outside provider");
  return ctx;
}
