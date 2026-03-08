const express = require("express");
const fs      = require("fs");
const path    = require("path");
const cors    = require("cors");

const app      = express();
const PORT     = process.env.PORT || 80;
const DB_PATH  = path.join(__dirname, "users.json");

// ── MIDDLEWARES ──────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.static(__dirname)); // serve index.html

// ── HELPERS ──────────────────────────────────────────────────
function readDB() {
  try {
    const raw = fs.readFileSync(DB_PATH, "utf-8");
    return JSON.parse(raw);
  } catch {
    return { users: [] };
  }
}

function writeDB(data) {
  fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2), "utf-8");
}

// ── ROTAS ────────────────────────────────────────────────────

// GET /users  → retorna todos os usuários (Lua script consome isso)
app.get("/users", (req, res) => {
  const db = readDB();
  res.json(db);
});

// GET /users/whitelist → apenas whitelisted (atalho útil)
app.get("/users/whitelist", (req, res) => {
  const db = readDB();
  const wl = db.users.filter(u => u.whitelisted === true);
  res.json({ users: wl });
});

// POST /users → adiciona usuário
// body: { "username": "NomeRoblox" }
app.post("/users", (req, res) => {
  const { username } = req.body;
  if (!username || typeof username !== "string") {
    return res.status(400).json({ error: "username é obrigatório." });
  }

  const db = readDB();
  const exists = db.users.find(
    u => u.username.toLowerCase() === username.toLowerCase()
  );

  if (exists) {
    return res.status(409).json({ error: "Usuário já cadastrado." });
  }

  const newUser = {
    id:          Date.now(),
    username:    username.trim(),
    whitelisted: true,
    addedAt:     new Date().toISOString()
  };

  db.users.push(newUser);
  writeDB(db);
  res.status(201).json({ message: "Usuário adicionado.", user: newUser });
});

// PATCH /users/:id → alterna whitelist (true ↔ false)
app.patch("/users/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const db = readDB();
  const user = db.users.find(u => u.id === id);

  if (!user) {
    return res.status(404).json({ error: "Usuário não encontrado." });
  }

  // Se body tiver whitelisted explícito, usa; senão faz toggle
  if (typeof req.body.whitelisted === "boolean") {
    user.whitelisted = req.body.whitelisted;
  } else {
    user.whitelisted = !user.whitelisted;
  }

  writeDB(db);
  res.json({ message: "Status atualizado.", user });
});

// DELETE /users/:id → remove usuário
app.delete("/users/:id", (req, res) => {
  const id = parseInt(req.params.id);
  const db = readDB();
  const idx = db.users.findIndex(u => u.id === id);

  if (idx === -1) {
    return res.status(404).json({ error: "Usuário não encontrado." });
  }

  const [removed] = db.users.splice(idx, 1);
  writeDB(db);
  res.json({ message: "Usuário removido.", user: removed });
});

// ── START ─────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`╔══════════════════════════════════════╗`);
  console.log(`║   User AutoJoiner  SERVER ONLINE     ║`);
  console.log(`║   http://localhost:${PORT}               ║`);
  console.log(`║   API: GET http://localhost:${PORT}/users ║`);
  console.log(`╚══════════════════════════════════════╝`);
});
