import { useEffect, useState } from "react";

export default function App() {
  const [items, setItems] = useState([]);
  const [id, setId] = useState("");
  const [name, setName] = useState("");
  const [error, setError] = useState("");

  async function load() {
    try {
      const r = await fetch("/api/items");
      if (!r.ok) throw new Error(r.statusText);
      setItems(await r.json());
    } catch (e) {
      setError(e.message);
    }
  }

  async function add(e) {
    e.preventDefault();
    setError("");
    try {
      const r = await fetch("/api/items", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ id, name }),
      });
      if (!r.ok) throw new Error((await r.json()).error || r.statusText);
      setId("");
      setName("");
      load();
    } catch (e) {
      setError(e.message);
    }
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <div style={{ maxWidth: 480, margin: "40px auto", fontFamily: "system-ui" }}>
      <h1>bhvr items</h1>
      <form onSubmit={add} style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        <input placeholder="id" value={id} onChange={(e) => setId(e.target.value)} />
        <input placeholder="name" value={name} onChange={(e) => setName(e.target.value)} />
        <button type="submit">Add</button>
      </form>
      {error && <p style={{ color: "crimson" }}>{error}</p>}
      <ul>
        {items.map((it) => (
          <li key={it.pk}>
            {it.pk} — {it.name}
          </li>
        ))}
      </ul>
    </div>
  );
}
