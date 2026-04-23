--[[ Chest Finder v13.0 - Coleta contínua + pulo automático (CORRIGIDO) --]]

local Players = game:GetService("Players")
local Pathfinding = game:GetService("PathfindingService")
local UserInput = game:GetService("UserInputService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

local auto = true
local coletados = 0
local velocidade = 16

local function setSpeed(s)
    velocidade = math.clamp(s, 10, 100)
    hum.WalkSpeed = velocidade
    if speedValueBtn then speedValueBtn.Text = tostring(math.floor(velocidade)) end
    if sliderFill then
        local p = (velocidade - 10) / 90
        sliderFill.Size = UDim2.new(p, 0, 1, 0)
        sliderBtn.Position = UDim2.new(p, -6, 0.5, -6)
    end
end

-- 🔍 Verifica contorno (Highlight ou SelectionBox)
local function temContorno(obj)
    if obj:FindFirstChildWhichIsA("Highlight") then return true end
    if obj:FindFirstChildWhichIsA("SelectionBox") then return true end
    if obj:IsA("Model") then
        for _, part in ipairs(obj:GetDescendants()) do
            if part:IsA("BasePart") and (part:FindFirstChildWhichIsA("Highlight") or part:FindFirstChildWhichIsA("SelectionBox")) then
                return true
            end
        end
    end
    return false
end

-- Palavras proibidas (loja, recompensa, etc.)
local proibidas = {
    "presente", "gratuito", "free", "gift", "reward", "recompensa", "brinde",
    "shop", "loja", "store", "buy", "comprar", "roblox", "robux", "premium", "vip",
    "fuse", "set", "event", "starter", "iniciante", "pack", "pacote",
    "yellow", "amarelo", "gold", "dourado", "group", "grupo", "daily", "weekly", "bonus"
}

-- Verifica se é um baú ruim (loja/recompensa)
local function isRuim(obj)
    local current = obj
    for i = 1, 5 do
        if not current then break end
        local nome = string.lower(current.Name or "")
        for _, p in ipairs(proibidas) do
            if string.find(nome, p) then return true end
        end
        if current:FindFirstChild("Price") or current:FindFirstChild("RobuxPrice") or current:FindFirstChild("Cost") then
            return true
        end
        current = current.Parent
    end
    return false
end

-- Deleta baús ruins do mapa
local function deletarRuins()
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nome = string.lower(obj.Name or "")
        if (string.find(nome, "chest") or string.find(nome, "bau") or obj:FindFirstChild("ClickDetector")) then
            if not temContorno(obj) and isRuim(obj) then
                pcall(function() obj:Destroy() end)
            end
        end
    end
end

-- Verifica se o baú é permitido (tem contorno e não é ruim)
local function isPermitido(obj)
    local nome = string.lower(obj.Name or "")
    if not (string.find(nome, "chest") or string.find(nome, "bau")) then return false end
    return temContorno(obj) and not isRuim(obj)
end

-- Detecta o tipo do baú pelo nome
local function getTipo(nome)
    local n = string.lower(nome)
    if string.find(n, "rainbow") or string.find(n, "arco") then
        return "🌈 Arco-Íris", 5, "🌈"
    elseif string.find(n, "legendary") or string.find(n, "lendario") then
        return "🏆 Lendário", 4, "🏆"
    elseif string.find(n, "rare") or string.find(n, "raro") then
        return "💎 Raro", 3, "💎"
    else
        return "📦 Comum", 1, "📦"
    end
end

-- Encontra o baú mais próximo e permitido
local function acharMelhorBaú()
    local melhor = nil
    local menorDist = math.huge
    local posChar = char:GetPivot().Position
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPermitido(obj) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
            if pos then
                local dist = (posChar - pos).Magnitude
                if dist < menorDist and dist < 500 then
                    menorDist = dist
                    local tipo, prio, emoji = getTipo(obj.Name)
                    melhor = {obj = obj, pos = pos, dist = dist, tipo = tipo, prio = prio, emoji = emoji}
                end
            end
        end
    end
    return melhor
end

-- Função para mover, pular e coletar o baú
local function moverEColetar(baú)
    if not baú or not hum then return end
    -- Atualiza status na UI
    if statusText then statusText.Text = baú.emoji .. " " .. baú.tipo .. " (" .. math.floor(baú.dist) .. "m)" end
    
    local path = Pathfinding:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local sucesso = pcall(function()
        path:ComputeAsync(char:GetPivot().Position, baú.pos)
    end)
    
    if sucesso and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, wp in ipairs(waypoints) do
            if not auto then break end
            hum:MoveTo(wp.Position)
            hum.MoveToFinished:Wait(1)
        end
        -- Pulo ao chegar perto do baú
        hum.Jump = true
        task.wait(0.3)
        
        if baú.obj and baú.obj.Parent and isPermitido(baú.obj) then
            coletados = coletados + 1
            if countText then countText.Text = "📊 Coletados: " .. coletados end
            if statusText then statusText.Text = "✅ " .. baú.tipo .. " coletado!" end
            -- Tenta clicar no baú
            local click = baú.obj:FindFirstChild("ClickDetector")
            if click then
                click:Click()
            else
                local parte = baú.obj:IsA("BasePart") and baú.obj or baú.obj:FindFirstChildWhichIsA("BasePart")
                if parte then fireclickdetector(parte) end
            end
            task.wait(0.5) -- Aguarda o baú ser removido
        end
    else
        if statusText then statusText.Text = "⚠️ Caminho bloqueado!" end
    end
end

-- 🔁 LOOP PRINCIPAL (CORRIGIDO - não para mais)
local loopTask
local function iniciarLoop()
    if loopTask then task.cancel(loopTask) end
    loopTask = task.spawn(function()
        while auto do
            if hum and hum.Health > 0 then
                deletarRuins() -- Limpa baús ruins
                local baú = acharMelhorBaú()
                if baú then
                    moverEColetar(baú)
                else
                    if statusText then statusText.Text = "🔍 Nenhum baú com contorno..." end
                    task.wait(1) -- Pequena pausa para não sobrecarregar
                end
            else
                if statusText then statusText.Text = "⚠️ Personagem morto ou sem humanoid" end
                task.wait(2)
            end
            task.wait(0.5) -- Aguarda um pouco antes de procurar o próximo
        end
    end)
end

-- GUI (mantida como no seu script original, sem alterações)
local gui = Instance.new("ScreenGui")
gui.Name = "ChestFinder"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 999
gui.Parent = player:WaitForChild("PlayerGui")

-- ... (aqui entra todo o código da sua GUI, da bolinha até os botões. Não vou repetir para não ficar enorme, mas mantenha exatamente como está no seu arquivo original) ...

-- Inicialização
task.spawn(function()
    wait(2)
    setSpeed(16)
    deletarRuins()
    iniciarLoop()
    print("✅ Chest Finder v13.0 - Coleta contínua corrigida!")
    if avisar then avisar("🚀 Auto Chest ON | Coletando baús com contorno") end
end)

-- Animação da borda (se existir)
-- task.spawn(function() ... end) -- Mantenha a animação do seu script original
