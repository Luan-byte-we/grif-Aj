--[[
    ╔══════════════════════════════════════════════╗
    ║        USER AUTO JOINER — Roblox Script       ║
    ║  Busca whitelist do site e aplica Highlight   ║
    ╚══════════════════════════════════════════════╝

    INSTRUÇÕES:
    1. Substitua API_URL pela URL real do seu site hospedado
       Exemplo: "https://seu-site.com/users"
    2. Cole no executor de sua preferência (ex: Synapse, KRNL, etc.)
    3. O script vai buscar a whitelist a cada REFRESH_INTERVAL segundos
--]]

-- ══════════════════════════════════════════════════
--  CONFIGURAÇÃO
-- ══════════════════════════════════════════════════

local API_URL          = "https://SEU-SITE.com/users"   -- << TROQUE AQUI
local REFRESH_INTERVAL = 30    -- segundos entre cada atualização da whitelist
local HIGHLIGHT_COLOR  = Color3.fromRGB(0, 195, 255)    -- azul estilo do painel
local HIGHLIGHT_FILL   = Color3.fromRGB(0, 120, 200)    -- fill interno
local FILL_TRANSPARENCY     = 0.65
local OUTLINE_TRANSPARENCY  = 0.25
local LABEL_FONT       = Enum.Font.GothamBold
local LABEL_SIZE       = 14    -- tamanho do texto flutuante
local LABEL_OFFSET     = Vector3.new(0, 3.2, 0)  -- altura do label sobre o personagem
local LABEL_BG_COLOR   = Color3.fromRGB(5, 15, 30)
local LABEL_TEXT_COLOR = Color3.fromRGB(0, 210, 255)
local TITLE_TEXT       = "✦ User AutoJoiner ✦"

-- ══════════════════════════════════════════════════
--  SERVIÇOS
-- ══════════════════════════════════════════════════

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local TweenService     = game:GetService("TweenService")

-- ══════════════════════════════════════════════════
--  ESTADO INTERNO
-- ══════════════════════════════════════════════════

local whitelistedUsers = {}   -- { ["username"] = true }
local activeHighlights = {}   -- { [player] = { highlight, billboard } }

-- ══════════════════════════════════════════════════
--  FUNÇÕES UTILITÁRIAS
-- ══════════════════════════════════════════════════

-- Busca a whitelist do site
local function fetchWhitelist()
    local ok, result = pcall(function()
        local response = game:HttpGet(API_URL, true)
        local data = HttpService:JSONDecode(response)
        return data
    end)

    if not ok then
        warn("[AutoJoiner] Falha ao buscar whitelist: " .. tostring(result))
        return nil
    end

    -- Suporta formato: { "users": [...] }  OU  lista direta [...]
    local list = result.users or result
    if type(list) ~= "table" then
        warn("[AutoJoiner] Formato de resposta inválido.")
        return nil
    end

    local newMap = {}
    for _, entry in ipairs(list) do
        local name = entry.username or entry.name
        if name and entry.whitelisted ~= false then
            newMap[name:lower()] = true
        end
    end
    return newMap
end

-- ══════════════════════════════════════════════════
--  HIGHLIGHT + BILLBOARD
-- ══════════════════════════════════════════════════

local function createBillboard(character, playerName)
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name          = "UAJ_Billboard"
    billboard.Adornee       = root
    billboard.Size          = UDim2.new(0, 180, 0, 50)
    billboard.StudsOffset   = LABEL_OFFSET
    billboard.AlwaysOnTop   = false
    billboard.MaxDistance    = 60
    billboard.ResetOnSpawn  = false

    -- Fundo semi-transparente
    local bg = Instance.new("Frame")
    bg.Name              = "BG"
    bg.Size              = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3  = LABEL_BG_COLOR
    bg.BackgroundTransparency = 0.35
    bg.BorderSizePixel   = 0
    bg.Parent            = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent       = bg

    -- Borda azul glowing
    local stroke = Instance.new("UIStroke")
    stroke.Color       = HIGHLIGHT_COLOR
    stroke.Thickness   = 1.5
    stroke.Transparency = 0.1
    stroke.Parent      = bg

    -- Título
    local title = Instance.new("TextLabel")
    title.Name               = "Title"
    title.Size               = UDim2.new(1, 0, 0.48, 0)
    title.Position           = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text               = TITLE_TEXT
    title.TextColor3         = HIGHLIGHT_COLOR
    title.Font               = LABEL_FONT
    title.TextSize           = LABEL_SIZE - 2
    title.TextXAlignment     = Enum.TextXAlignment.Center
    title.Parent             = bg

    -- Nome do jogador
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name               = "PlayerName"
    nameLabel.Size               = UDim2.new(1, 0, 0.52, 0)
    nameLabel.Position           = UDim2.new(0, 0, 0.48, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text               = "[ " .. playerName .. " ]"
    nameLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
    nameLabel.Font               = LABEL_FONT
    nameLabel.TextSize           = LABEL_SIZE
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Center
    nameLabel.Parent             = bg

    billboard.Parent = character

    -- Animação de fade-in suave no BG
    bg.BackgroundTransparency = 1
    TweenService:Create(bg, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        BackgroundTransparency = 0.35
    }):Play()

    return billboard
end

local function createHighlight(character)
    -- Remove highlight antigo se existir
    local old = character:FindFirstChild("UAJ_Highlight")
    if old then old:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name                 = "UAJ_Highlight"
    hl.FillColor            = HIGHLIGHT_FILL
    hl.OutlineColor         = HIGHLIGHT_COLOR
    hl.FillTransparency     = FILL_TRANSPARENCY
    hl.OutlineTransparency  = OUTLINE_TRANSPARENCY
    hl.DepthMode            = Enum.HighlightDepthMode.Occluded
    hl.Adornee              = character
    hl.Parent               = character

    return hl
end

local function applyToPlayer(player)
    local char = player.Character
    if not char then return end

    -- Remove antigos
    local prev = activeHighlights[player]
    if prev then
        if prev.highlight and prev.highlight.Parent then prev.highlight:Destroy() end
        if prev.billboard and prev.billboard.Parent then prev.billboard:Destroy() end
    end

    local hl  = createHighlight(char)
    local bb  = createBillboard(char, player.Name)

    activeHighlights[player] = { highlight = hl, billboard = bb }
end

local function removeFromPlayer(player)
    local prev = activeHighlights[player]
    if prev then
        if prev.highlight and prev.highlight.Parent then prev.highlight:Destroy() end
        if prev.billboard and prev.billboard.Parent then prev.billboard:Destroy() end
        activeHighlights[player] = nil
    end
end

-- ══════════════════════════════════════════════════
--  CHECAR CADA JOGADOR ONLINE
-- ══════════════════════════════════════════════════

local function checkAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local isWhitelisted = whitelistedUsers[player.Name:lower()] == true

        if isWhitelisted then
            -- Aplica se personagem já existir
            if player.Character then
                applyToPlayer(player)
            end
            -- Garante reaplicar ao respawn
            if not player:GetAttribute("UAJ_Connected") then
                player:SetAttribute("UAJ_Connected", true)
                player.CharacterAdded:Connect(function()
                    task.wait(0.5) -- aguardar carregar
                    if whitelistedUsers[player.Name:lower()] then
                        applyToPlayer(player)
                    end
                end)
            end
        else
            removeFromPlayer(player)
        end
    end
end

-- ══════════════════════════════════════════════════
--  LOOP PRINCIPAL
-- ══════════════════════════════════════════════════

local function mainLoop()
    while true do
        print("[AutoJoiner] Buscando whitelist em: " .. API_URL)
        local newList = fetchWhitelist()

        if newList then
            whitelistedUsers = newList
            print("[AutoJoiner] Whitelist carregada. Usuários: " .. tostring(#(function()
                local c = 0
                for _ in pairs(whitelistedUsers) do c = c + 1 end
                return c
            end)()))
        end

        checkAllPlayers()
        task.wait(REFRESH_INTERVAL)
    end
end

-- Conectar novos jogadores que entram durante o jogo
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if whitelistedUsers[player.Name:lower()] then
            applyToPlayer(player)
        end
    end)
end)

-- Remover ao sair
Players.PlayerRemoving:Connect(function(player)
    removeFromPlayer(player)
    activeHighlights[player] = nil
end)

-- ══════════════════════════════════════════════════
--  INICIAR
-- ══════════════════════════════════════════════════

print("╔══════════════════════════════╗")
print("║   User AutoJoiner  LOADED    ║")
print("╚══════════════════════════════╝")

task.spawn(mainLoop)
