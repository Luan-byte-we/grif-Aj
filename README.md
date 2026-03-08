# 🎮 User Auto Joiner — Site + API

Painel web para gerenciar a whitelist do script Roblox **User Auto Joiner**.

---

## 📁 Estrutura de Arquivos

```
autojoiner-site/
├── index.html       ← Painel admin (front-end)
├── server.js        ← Servidor Node.js com a API
├── users.json       ← Banco de dados dos usuários (gerado automaticamente)
├── AutoJoiner.lua   ← Script para colar no executor do Roblox
├── package.json     ← Dependências Node.js
└── README.md        ← Este arquivo
```

---

## 🚀 Como Rodar

### 1. Instalar dependências
```bash
npm install
```

### 2. Iniciar o servidor
```bash
npm start
```

O servidor sobe em: **http://localhost:3000**

### 3. Acessar o painel
Abra o navegador em: **http://localhost:3000**

---

## 🌐 Rotas da API

| Método   | Rota              | Descrição                              |
|----------|-------------------|----------------------------------------|
| GET      | `/users`          | Lista todos os usuários                |
| GET      | `/users/whitelist`| Lista apenas os usuários na whitelist  |
| POST     | `/users`          | Adiciona um usuário `{ "username": "Nome" }` |
| PATCH    | `/users/:id`      | Alterna whitelist (true ↔ false)       |
| DELETE   | `/users/:id`      | Remove um usuário                      |

### Formato do `/users` (o que o Lua consome):
```json
{
  "users": [
    { "id": 1700000000000, "username": "PlayerName", "whitelisted": true, "addedAt": "2024-01-01T00:00:00.000Z" }
  ]
}
```

---

## 🔧 Configurar o Script Lua

Abra `AutoJoiner.lua` e troque a linha:
```lua
local API_URL = "https://SEU-SITE.com/users"
```
pela URL real onde você hospedou o site, por exemplo:
```lua
local API_URL = "https://meu-autojoiner.vercel.app/users"
```

---

## ☁️ Hospedar Online (gratuito)

### Opção 1 — Railway (recomendado)
1. Crie conta em https://railway.app
2. New Project → Deploy from GitHub (suba o código)
3. Vai gerar uma URL pública automaticamente

### Opção 2 — Render
1. Crie conta em https://render.com
2. New → Web Service → conecte o repositório
3. Build Command: `npm install`  
   Start Command: `npm start`

### Opção 3 — Rodar local com ngrok (para testes)
```bash
npm start
# em outro terminal:
ngrok http 3000
# use a URL gerada no AutoJoiner.lua
```

---

## 📜 Configurações do Script Lua

| Variável           | Padrão   | Descrição                            |
|--------------------|----------|--------------------------------------|
| `API_URL`          | —        | URL do seu site + `/users` ← **OBRIGATÓRIO** |
| `REFRESH_INTERVAL` | 30s      | Intervalo de atualização da whitelist|
| `HIGHLIGHT_COLOR`  | Azul     | Cor do outline do Highlight          |
| `LABEL_SIZE`       | 14       | Tamanho da fonte do nome flutuante   |
| `LABEL_OFFSET`     | Y=3.2    | Altura do label acima do personagem  |
