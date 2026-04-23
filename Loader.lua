--[[ Chest Finder v1.0 (corrigido) – Coleta contínua ]]--

local Players = game:GetService("Players")
local Pathfinding = game:GetService("PathfindingService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

local auto = true
local coletados = 0

-- Função para verificar se o baú tem contorno (Highlight ou SelectionBox)
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
local proibidas = {"presente","gratuito","free","gift","reward","shop","loja","store","buy","roblox","robux","fuse","group","daily","weekly","yellow","gold"}

-- Verifica se é um baú ruim (loja/recompensa)
local function isRuim(obj)
    local current = obj
    for i = 1, 5 do
        if not current then break end
        local nome = string.lower(current.Name or "")
        for _, p in ipairs(proibidas) do
            if string.find(nome, p) then return true end
        end
        if current:FindFirstChild("Price") or current:FindFirstChild("RobuxPrice") then return true end
        current = current.Parent
    end
    return false
end

-- Verifica se o baú é permitido (tem contorno e não é ruim)
local function isPermitido(obj)
    local nome = string.lower(obj.Name or "")
    if not (string.find(nome, "chest") or string.find(nome, "bau")) then return false end
    return temContorno(obj) and not isRuim(obj)
end

-- Encontra o baú mais próximo permitido
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
                    melhor = {obj = obj, pos = pos, dist = dist}
                end
            end
        end
    end
    return melhor
end

-- Função para mover e coletar o baú
local function moverEColetar(baú)
    if not baú or not hum then return end
    -- Cria caminho
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
        -- Pulo ao chegar
        hum.Jump = true
        task.wait(0.3)
        -- Verifica se o baú ainda existe
        if baú.obj and baú.obj.Parent and isPermitido(baú.obj) then
            coletados = coletados + 1
            print("✅ Baú coletado! Total:", coletados)
            -- Tenta clicar
            local click = baú.obj:FindFirstChild("ClickDetector")
            if click then
                click:Click()
            else
                local parte = baú.obj:IsA("BasePart") and baú.obj or baú.obj:FindFirstChildWhichIsA("BasePart")
                if parte then fireclickdetector(parte) end
            end
            task.wait(0.5) -- aguarda o baú sumir
        end
    else
        print("❌ Caminho bloqueado para o baú")
    end
end

-- 🔁 LOOP PRINCIPAL (infinito)
local loopTask
local function iniciarLoop()
    if loopTask then task.cancel(loopTask) end
    loopTask = task.spawn(function()
        while auto do
            if hum and hum.Health > 0 then
                local baú = acharMelhorBaú()
                if baú then
                    moverEColetar(baú)
                else
                    print("🔍 Nenhum baú permitido encontrado. Aguardando...")
                end
            end
            task.wait(1) -- espera 1 segundo antes de procurar novamente
        end
    end)
end

-- GUI mínima (apenas uma bolinha para ativar/desativar)
local gui = Instance.new("ScreenGui")
gui.Name = "ChestFinder"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = player:WaitForChild("PlayerGui")

local bola = Instance.new("ImageButton")
bola.Size = UDim2.new(0, 50, 0, 50)
bola.Position = UDim2.new(0, 10, 0, 100)
bola.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
bola.Image = "rbxassetid://3926305904"
bola.Parent = gui
local bolaC = Instance.new("UICorner")
bolaC.CornerRadius = UDim.new(1, 0)
bolaC.Parent = bola

-- Frame de status simples
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.5, -100, 0.5, -50)
frame.BackgroundColor3 = Color3.fromRGB(20,20,30)
frame.Visible = false
frame.Parent = gui
local frameC = Instance.new("UICorner")
frameC.CornerRadius = UDim.new(0, 8)
frameC.Parent = frame

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 0, 30)
statusText.Position = UDim2.new(0, 0, 0, 10)
statusText.BackgroundTransparency = 1
statusText.Text = "Auto Chest: ON"
statusText.TextColor3 = Color3.fromRGB(0,255,0)
statusText.TextSize = 14
statusText.Font = Enum.Font.GothamBold
statusText.Parent = frame

local countText = Instance.new("TextLabel")
countText.Size = UDim2.new(1, 0, 0, 30)
countText.Position = UDim2.new(0, 0, 0, 45)
countText.BackgroundTransparency = 1
countText.Text = "Coletados: 0"
countText.TextColor3 = Color3.fromRGB(0,255,255)
countText.TextSize = 12
countText.Font = Enum.Font.Gotham
countText.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 80, 0, 30)
toggleBtn.Position = UDim2.new(0.5, -40, 0, 80)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0,100,0)
toggleBtn.Text = "Desativar"
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.Parent = frame
local toggleC = Instance.new("UICorner")
toggleC.CornerRadius = UDim.new(0, 5)
toggleC.Parent = toggleBtn

-- Atualizar contador na UI
local function atualizarUI()
    countText.Text = "Coletados: " .. coletados
end
-- Sobrescreve a função de coletar para atualizar UI
local oldMover = moverEColetar
moverEColetar = function(baú)
    oldMover(baú)
    atualizarUI()
end

-- Eventos da UI
toggleBtn.MouseButton1Click:Connect(function()
    auto = not auto
    if auto then
        toggleBtn.Text = "Desativar"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0,100,0)
        statusText.Text = "Auto Chest: ON"
        statusText.TextColor3 = Color3.fromRGB(0,255,0)
        iniciarLoop()
    else
        toggleBtn.Text = "Ativar"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
        statusText.Text = "Auto Chest: OFF"
        statusText.TextColor3 = Color3.fromRGB(255,100,100)
        if loopTask then task.cancel(loopTask) end
    end
end)

bola.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Inicia o loop
iniciarLoop()
print("✅ Script corrigido – Coleta vários baús (não para). Clique na bolinha azul para ver o menu.")
