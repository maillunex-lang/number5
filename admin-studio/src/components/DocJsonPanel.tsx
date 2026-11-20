import { useEffect, useState } from "react";

type Props = {
  value: unknown;
  onChange: (next: unknown) => void;
  height?: number;
};

/** Shared raw JSON editor for package docs. */
export default function DocJsonPanel({ value, onChange, height = 420 }: Props) {
  const [raw, setRaw] = useState(() => JSON.stringify(value ?? {}, null, 2));
  const [err, setErr] = useState("");

  useEffect(() => {
    setRaw(JSON.stringify(value ?? {}, null, 2));
    setErr("");
  }, [value]);

  return (
    <div>
      <textarea
        className="code-area"
        style={{ minHeight: height }}
        value={raw}
        spellCheck={false}
        onChange={(e) => {
          const text = e.target.value;
          setRaw(text);
          try {
            const parsed = JSON.parse(text);
            setErr("");
            onChange(parsed);
          } catch (ex) {
            setErr(ex instanceof Error ? ex.message : "JSON error");
          }
        }}
      />
      {err ? <p className="warn">JSON: {err}</p> : <p className="muted">JSON валиден</p>}
    </div>
  );
}
