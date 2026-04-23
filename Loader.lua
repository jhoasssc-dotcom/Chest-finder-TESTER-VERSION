--[[ Chest Finder v13.0 - Só pega baús com contorno (Highlight/SelectionBox) --]]

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

-- 🔍 Verifica se o objeto tem contorno (Highlight ou SelectionBox)
local function temContorno(obj)
    -- Verifica se o próprio objeto tem Highlight ou SelectionBox como filho
    if obj:FindFirstChildWhichIsA("Highlight") then
        return true
    end
    if obj:FindFirstChildWhichIsA("SelectionBox") then
        return true
    end
    -- Verifica se alguma parte do modelo tem contorno
    if obj:IsA("Model") then
        for _, part in ipairs(obj:GetDescendants()) do
            if part:IsA("BasePart") and (part:FindFirstChildWhichIsA("Highlight") or part:FindFirstChildWhichIsA("SelectionBox")) then
                return true
            end
        end
    end
    return false
end

-- 🚫 Lista de palavras proibidas (caso o contorno falhe)
local proibidas = {
    "presente", "gratuito", "free", "gift", "reward", "recompensa", "brinde",
    "shop", "loja", "store", "buy", "comprar", "roblox", "robux", "premium", "vip",
    "fuse", "set", "event", "starter", "iniciante", "pack", "pacote",
    "yellow", "amarelo", "gold", "dourado", "group", "grupo", "daily", "weekly", "bonus"
}

-- Verifica se é baú ruim (por nome ou preço)
local function isRuim(obj)
    local current = obj
    for i = 1, 5 do
        if not current then break end
        local nome = string.lower(current.Name or "")
        for _, p in ipairs(proibidas) do
            if string.find(nome, p) then
                return true
            end
        end
        if current:FindFirstChild("Price") or current:FindFirstChild("RobuxPrice") or current:FindFirstChild("Cost") then
            return true
        end
        current = current.Parent
    end
    return false
end

-- 🗑️ Deleta baús ruins (sem contorno e com palavras proibidas)
local function deletarRuins()
    local deletados = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        local nome = string.lower(obj.Name or "")
        if (string.find(nome, "chest") or string.find(nome, "bau") or obj:FindFirstChild("ClickDetector")) then
            -- Se não tem contorno E é ruim, deleta
            if not temContorno(obj) and isRuim(obj) then
                pcall(function() obj:Destroy() end)
                deletados = deletados + 1
            end
        end
    end
    if deletados > 0 then print("🗑️ Deletados", deletados, "baús sem contorno") end
end

-- ✅ Verifica se o baú é válido (tem contorno E não é ruim)
local function isPermitido(obj)
    local nome = string.lower(obj.Name or "")
    if not (string.find(nome, "chest") or string.find(nome, "bau")) then
        return false
    end
    -- Só permite se tiver contorno E não for ruim
    return temContorno(obj) and not isRuim(obj)
end

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

local function acharChests()
    local lista = {}
    local posChar = char:GetPivot().Position
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isPermitido(obj) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
            if pos then
                local tipo, prio, emoji = getTipo(obj.Name)
                local dist = (posChar - pos).Magnitude
                if dist < 500 then
                    table.insert(lista, {obj = obj, pos = pos, dist = dist, tipo = tipo, prio = prio, emoji = emoji})
                end
            end
        end
    end
    table.sort(lista, function(a, b)
        if a.prio ~= b.prio then return a.prio > b.prio end
        return a.dist < b.dist
    end)
    return lista
end

-- GUI (igual à versão anterior, mas vou resumir para não estender muito)
local gui = Instance.new("ScreenGui")
gui.Name = "ChestFinder"
gui.Parent = player:WaitForChild("PlayerGui")

-- Bolinha
local bola = Instance.new("ImageButton")
bola.Size = UDim2.new(0, 45, 0, 45)
bola.Position = UDim2.new(0, 10, 0, 100)
bola.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bola.Image = "rbxassetid://3926305904"
bola.ImageColor3 = Color3.fromRGB(0, 255, 255)
bola.Visible = false
bola.Parent = gui

local bolaC = Instance.new("UICorner")
bolaC.CornerRadius = UDim.new(1, 0)
bolaC.Parent = bola

-- Frame principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 450)
frame.Position = UDim2.new(0.5, -170, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = gui

local frameC = Instance.new("UICorner")
frameC.CornerRadius = UDim.new(0, 10)
frameC.Parent = frame

local borda = Instance.new("Frame")
borda.Size = UDim2.new(1, 0, 1, 0)
borda.BackgroundTransparency = 1
borda.BorderSizePixel = 2
borda.BorderColor3 = Color3.fromRGB(0, 255, 255)
borda.Parent = frame

-- Barra de título
local barra = Instance.new("Frame")
barra.Size = UDim2.new(1, 0, 0, 30)
barra.BackgroundTransparency = 1
barra.Parent = frame

local titulo = Instance.new("TextLabel")
titulo.Size = UDim2.new(1, -60, 0, 30)
titulo.Position = UDim2.new(0, 5, 0, 0)
titulo.BackgroundTransparency = 1
titulo.Text = "🎁 Chest Finder v13"
titulo.TextColor3 = Color3.fromRGB(0, 255, 255)
titulo.TextSize = 12
titulo.Font = Enum.Font.GothamBold
titulo.TextXAlignment = Enum.TextXAlignment.Left
titulo.Parent = barra

local mini = Instance.new("TextButton")
mini.Size = UDim2.new(0, 25, 0, 25)
mini.Position = UDim2.new(1, -30, 0, 3)
mini.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
mini.Text = "⬤"
mini.TextColor3 = Color3.fromRGB(0, 255, 255)
mini.TextSize = 14
mini.Font = Enum.Font.GothamBold
mini.Parent = barra

local miniC = Instance.new("UICorner")
miniC.CornerRadius = UDim.new(0, 5)
miniC.Parent = mini

local fechar = Instance.new("TextButton")
fechar.Size = UDim2.new(0, 25, 0, 25)
fechar.Position = UDim2.new(1, -58, 0, 3)
fechar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
fechar.Text = "✕"
fechar.TextColor3 = Color3.fromRGB(255, 100, 100)
fechar.TextSize = 14
fechar.Font = Enum.Font.GothamBold
fechar.Parent = barra

local fecharC = Instance.new("UICorner")
fecharC.CornerRadius = UDim.new(0, 5)
fecharC.Parent = fechar

-- Botão Auto Chest
local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0, 310, 0, 35)
autoBtn.Position = UDim2.new(0.5, -155, 0, 45)
autoBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
autoBtn.Text = "🔍 Auto Chest: ON"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.TextSize = 13
autoBtn.Font = Enum.Font.GothamSemibold
autoBtn.Parent = frame

local autoC = Instance.new("UICorner")
autoC.CornerRadius = UDim.new(0, 6)
autoC.Parent = autoBtn

-- Botão Anti-AFK
local afkBtn = Instance.new("TextButton")
afkBtn.Size = UDim2.new(0, 310, 0, 35)
afkBtn.Position = UDim2.new(0.5, -155, 0, 88)
afkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
afkBtn.Text = "💤 Anti-AFK: OFF"
afkBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
afkBtn.TextSize = 13
afkBtn.Font = Enum.Font.GothamSemibold
afkBtn.Parent = frame

local afkC = Instance.new("UICorner")
afkC.CornerRadius = UDim.new(0, 6)
afkC.Parent = afkBtn

-- Velocidade
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(0, 310, 0, 50)
speedFrame.Position = UDim2.new(0.5, -155, 0, 133)
speedFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
speedFrame.BackgroundTransparency = 0.3
speedFrame.Parent = frame

local speedC = Instance.new("UICorner")
speedC.CornerRadius = UDim.new(0, 6)
speedC.Parent = speedFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 60, 1, 0)
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "⚡ Velocidade:"
speedLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
speedLabel.TextSize = 11
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0, 170, 0, 5)
sliderBg.Position = UDim2.new(0, 75, 0.5, -2.5)
sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = speedFrame

local sliderBgC = Instance.new("UICorner")
sliderBgC.CornerRadius = UDim.new(1, 0)
sliderBgC.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((velocidade - 10) / 90, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(0, 12, 0, 12)
sliderBtn.Position = UDim2.new((velocidade - 10) / 90, -6, 0.5, -6)
sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
sliderBtn.Text = ""
sliderBtn.BorderSizePixel = 0
sliderBtn.Parent = sliderBg

local speedValueBtn = Instance.new("TextButton")
speedValueBtn.Size = UDim2.new(0, 45, 0, 28)
speedValueBtn.Position = UDim2.new(1, -50, 0.5, -14)
speedValueBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
speedValueBtn.Text = tostring(velocidade)
speedValueBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
speedValueBtn.TextSize = 12
speedValueBtn.Font = Enum.Font.GothamBold
speedValueBtn.Parent = speedFrame

-- Slider
local sliderDrag = false
sliderBtn.MouseButton1Down:Connect(function() sliderDrag = true end)
UserInput.InputChanged:Connect(function(input)
    if sliderDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position.X - sliderBg.AbsolutePosition.X
        local p = math.clamp(pos / sliderBg.AbsoluteSize.X, 0, 1)
        setSpeed(10 + (p * 90))
    end
end)
UserInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = false end
end)

-- Editar velocidade
speedValueBtn.MouseButton1Click:Connect(function()
    local edit = Instance.new("TextBox")
    edit.Size = UDim2.new(1, 0, 1, 0)
    edit.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    edit.Text = tostring(velocidade)
    edit.TextColor3 = Color3.fromRGB(0, 255, 255)
    edit.TextSize = 12
    edit.Font = Enum.Font.GothamBold
    edit.TextXAlignment = Enum.TextXAlignment.Center
    edit.Parent = speedValueBtn
    edit.FocusLost:Connect(function()
        local n = tonumber(edit.Text)
        if n then setSpeed(n) end
        edit:Destroy()
    end)
end)

-- Informações
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(0, 310, 0, 50)
infoFrame.Position = UDim2.new(0.5, -155, 0, 193)
infoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
infoFrame.BackgroundTransparency = 0.3
infoFrame.Parent = frame

local infoC = Instance.new("UICorner")
infoC.CornerRadius = UDim.new(0, 6)
infoC.Parent = infoFrame

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -10, 1, -10)
infoText.Position = UDim2.new(0, 5, 0, 5)
infoText.BackgroundTransparency = 1
infoText.Text = "🔍 Só pega baús com CONTORNO BRANCO (Highlight)\n🗑️ Deleta baús da loja e recompensas"
infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
infoText.TextSize = 9
infoText.TextWrapped = true
infoText.Font = Enum.Font.Gotham
infoText.Parent = infoFrame

-- Status
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(0, 310, 0, 50)
statusFrame.Position = UDim2.new(0.5, -155, 0, 253)
statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statusFrame.BackgroundTransparency = 0.3
statusFrame.Parent = frame

local statusC = Instance.new("UICorner")
statusC.CornerRadius = UDim.new(0, 6)
statusC.Parent = statusFrame

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -10, 1, -10)
statusText.Position = UDim2.new(0, 5, 0, 5)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ Auto Chest ATIVADO!"
statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
statusText.TextSize = 10
statusText.TextWrapped = true
statusText.Font = Enum.Font.Gotham
statusText.Parent = statusFrame

-- Contador
local contFrame = Instance.new("Frame")
contFrame.Size = UDim2.new(0, 310, 0, 30)
contFrame.Position = UDim2.new(0.5, -155, 0, 313)
contFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contFrame.BackgroundTransparency = 0.3
contFrame.Parent = frame

local contC = Instance.new("UICorner")
contC.CornerRadius = UDim.new(0, 6)
contC.Parent = contFrame

local contText = Instance.new("TextLabel")
contText.Size = UDim2.new(1, -10, 1, -10)
contText.Position = UDim2.new(0, 5, 0, 5)
contText.BackgroundTransparency = 1
contText.Text = "📊 Coletados: 0"
contText.TextColor3 = Color3.fromRGB(0, 255, 255)
contText.TextSize = 11
contText.Font = Enum.Font.Gotham
contText.Parent = contFrame

-- Reset
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 90, 0, 28)
resetBtn.Position = UDim2.new(0.5, -45, 0, 355)
resetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
resetBtn.Text = "↺ Resetar (16)"
resetBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
resetBtn.TextSize = 10
resetBtn.Font = Enum.Font.Gotham
resetBtn.Parent = frame

local resetC = Instance.new("UICorner")
resetC.CornerRadius = UDim.new(0, 5)
resetC.Parent = resetBtn

resetBtn.MouseButton1Click:Connect(function() setSpeed(16) end)

-- Notificação
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.new(0, 250, 0, 45)
notifFrame.Position = UDim2.new(1, -270, 0, 50)
notifFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
notifFrame.BackgroundTransparency = 0.1
notifFrame.Visible = false
notifFrame.Parent = gui

local notifC = Instance.new("UICorner")
notifC.CornerRadius = UDim.new(0, 6)
notifC.Parent = notifFrame

local notifText = Instance.new("TextLabel")
notifText.Size = UDim2.new(1, -10, 1, -10)
notifText.Position = UDim2.new(0, 5, 0, 5)
notifText.BackgroundTransparency = 1
notifText.Text = ""
notifText.TextColor3 = Color3.fromRGB(0, 255, 255)
notifText.TextSize = 11
notifText.Font = Enum.Font.Gotham
notifText.Parent = notifFrame

local function avisar(msg)
    notifText.Text = msg
    notifFrame.Visible = true
    task.wait(2)
    notifFrame.Visible = false
end

-- Movimento
local function mover(chest)
    if not chest or not hum then return end
    statusText.Text = chest.emoji .. " " .. chest.tipo .. " (" .. math.floor(chest.dist) .. "m)"
    local path = Pathfinding:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    local ok = pcall(function() path:ComputeAsync(char:GetPivot().Position, chest.pos) end)
    if ok and path.Status == Enum.PathStatus.Success then
        for _, wp in ipairs(path:GetWaypoints()) do
            if not auto then break end
            hum:MoveTo(wp.Position)
            hum.MoveToFinished:Wait(1)
        end
        if chest.obj and chest.obj.Parent and isPermitido(chest.obj) then
            coletados = coletados + 1
            contText.Text = "📊 Coletados: " .. coletados
            avisar(chest.emoji .. " " .. chest.tipo .. " #" .. coletados)
            statusText.Text = "✅ " .. chest.tipo .. "!"
            local click = chest.obj:FindFirstChild("ClickDetector")
            if click then
                click:Click()
            else
                local parte = chest.obj:IsA("BasePart") and chest.obj or chest.obj:FindFirstChildWhichIsA("BasePart")
                if parte then fireclickdetector(parte) end
            end
        end
    else
        statusText.Text = "⚠️ Caminho bloqueado!"
    end
end

-- Loop
local loop
local function iniciarLoop()
    if loop then task.cancel(loop) end
    loop = task.spawn(function()
        while auto do
            if hum and hum.Health > 0 then
                deletarRuins()
                local chests = acharChests()
                if #chests > 0 then
                    mover(chests[1])
                else
                    statusText.Text = "🔍 Nenhum baú com contorno..."
                end
            end
            task.wait(1)
        end
    end)
end

-- Arrastar UI
local arrastando = false
local arrastarInicio, frameInicio
barra.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        arrastando = true
        arrastarInicio = i.Position
        frameInicio = frame.Position
    end
end)
UserInput.InputChanged:Connect(function(i)
    if arrastando and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - arrastarInicio
        frame.Position = UDim2.new(frameInicio.X.Scale, frameInicio.X.Offset + delta.X, frameInicio.Y.Scale, frameInicio.Y.Offset + delta.Y)
    end
end)
UserInput.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then arrastando = false end
end)

-- Arrastar bolinha
local bolaArrastando = false
local bolaInicio, bolaPosInicio
bola.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        bolaArrastando = true
        bolaInicio = i.Position
        bolaPosInicio = bola.Position
    end
end)
UserInput.InputChanged:Connect(function(i)
    if bolaArrastando and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - bolaInicio
        bola.Position = UDim2.new(bolaPosInicio.X.Scale, bolaPosInicio.X.Offset + delta.X, bolaPosInicio.Y.Scale, bolaPosInicio.Y.Offset + delta.Y)
    end
end)
UserInput.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then bolaArrastando = false end
end)

-- Minimizar
mini.MouseButton1Click:Connect(function()
    if frame.Visible then
        frame.Visible = false
        bola.Visible = true
        avisar("📌 Minimizado")
    else
        frame.Visible = true
        bola.Visible = false
        avisar("📂 Restaurado")
    end
end)
fechar.MouseButton1Click:Connect(function()
    frame.Visible = false
    bola.Visible = true
    avisar("📁 Minimizado")
end)
bola.MouseButton1Click:Connect(function()
    frame.Visible = true
    bola.Visible = false
    avisar("📂 Restaurado")
end)

-- Toggle Auto Chest
autoBtn.MouseButton1Click:Connect(function()
    auto = not auto
    if auto then
        autoBtn.Text = "🔍 Auto Chest: ON"
        autoBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        iniciarLoop()
        statusText.Text = "✅ ATIVADO!"
        avisar("✅ Auto Chest ON - Só pega baús com contorno")
    else
        autoBtn.Text = "🔍 Auto Chest: OFF"
        autoBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        if loop then task.cancel(loop) end
        statusText.Text = "⏸️ DESATIVADO"
        avisar("❌ Auto Chest OFF")
    end
end)

-- Anti AFK
local afkAtivo = false
local afkLoop
local function iniciarAFK()
    afkLoop = task.spawn(function()
        while afkAtivo do
            task.wait(240)
            if afkAtivo then
                local mouse = player:GetMouse()
                if mouse then
                    local x = mouse.X
                    mouse.Move(x + 1, mouse.Y)
                    task.wait(0.1)
                    mouse.Move(x, mouse.Y)
                end
                if hum then
                    hum:MoveTo(char:GetPivot().Position + Vector3.new(1, 0, 0))
                    task.wait(0.2)
                    hum:MoveTo(char:GetPivot().Position)
                end
            end
        end
    end)
end
afkBtn.MouseButton1Click:Connect(function()
    afkAtivo = not afkAtivo
    if afkAtivo then
        afkBtn.Text = "💤 Anti-AFK: ON"
        afkBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
        iniciarAFK()
        avisar("💤 Anti-AFK ON")
    else
        afkBtn.Text = "💤 Anti-AFK: OFF"
        afkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        if afkLoop then task.cancel(afkLoop) end
        avisar("💪 Anti-AFK OFF")
    end
end)

-- Iniciar
task.spawn(function()
    wait(2)
    setSpeed(16)
    deletarRuins()
    iniciarLoop()
    print("✅ Chest Finder v13 - Só pega baús com CONTORNO BRANCO")
    avisar("🚀 Só pega baús com contorno | Deletando os outros")
end)

-- Animação
task.spawn(function()
    while true do
        for i = 0, 1, 0.05 do
            local t = 0.5 + math.sin(i * math.pi) * 0.5
            borda.BorderColor3 = Color3.fromRGB(0, 255 * (1 - t), 255)
            if bola.Visible then
                bola.ImageColor3 = Color3.fromRGB(0, 255 * (1 - t), 255)
            end
            task.wait(0.05)
        end
    end
end)
