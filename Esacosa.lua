--[[
═══════════════════════════════════════════════════════════════════════════
   VENICE.JS  •  Jujutsu Shenanigans Automation Suite   (v3.0 — FINAL)
   Auto-Tech | Lock-On (cámara + cuerpo) | Dash Assist | Combos | Anti | HUD
   ─────────────────────────────────────────────────────────────────────────
   Autónomo: sin dependencias externas ni links.
   ─────────────────────────────────────────────────────────────────────────
   v3.0:
     [NEW] Lock-On Cuerpo real (AutoRotate off, ataques apuntados al rival)
     [NEW] Fly con MoveDirection (compatible joystick móvil)
     [NEW] Combos de wiki por personaje + Auto-Combo
     [NEW] Configurador de keybinds en UI
     [NEW] Silent Animations
     [FIX] HUD FLY ahora crea/destruye el vuelo correctamente (watcher)
     [FIX] watchers de estado, sin flags muertos
     [FIX] drag/sliders touch+mouse, UI escalada en móvil
═══════════════════════════════════════════════════════════════════════════
]]

------------------------------------------------------------------
-- 0. PROTECCIONES
------------------------------------------------------------------
if getgenv().VeniceJJS and getgenv().VeniceJJS.Unload then
    pcall(getgenv().VeniceJJS.Unload)
end

local VJS = {}
getgenv().VeniceJJS = VJS
VJS.Version = "3.0.0"
VJS.Flags   = {}
VJS.Conns   = {}
VJS.Alive   = true
VJS.Target  = nil

------------------------------------------------------------------
-- 1. SERVICIOS
------------------------------------------------------------------
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera       = workspace.CurrentCamera

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")
local Char, Hum, Root

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

------------------------------------------------------------------
-- 2. CONFIG
------------------------------------------------------------------
VJS.Config = {
    Block="F", Special="R", Awakening="G", Dash="Q", Domain="Four",
    Skills={"One","Two","Three","Four"},
    BlockRange=14, BlockReconnect=0.045,
    BFMove="Three", BFRange=13, BFBaseDelay=0.10, BFMaxChain=4, BFAutoChain=true,
    CounterRange=11, AutoDomainRange=40, AimRange=300,
    WalkSpeed=22, JumpPower=55, FlySpeed=60, HitboxRange=14, DashAssistRange=16,
}
local function cfg(k) return VJS.Config[k] end
local function setCfg(k,v) VJS.Config[k]=v end

------------------------------------------------------------------
-- 3. KEYS
------------------------------------------------------------------
local execKey = {F="F",R="R",G="G",Q="Q",E="E",Space="Space",LeftShift="LeftShift",
    One="1",Two="2",Three="3",Four="4",Five="5"}
local enumKey = {F=Enum.KeyCode.F,R=Enum.KeyCode.R,G=Enum.KeyCode.G,Q=Enum.KeyCode.Q,E=Enum.KeyCode.E,
    Space=Enum.KeyCode.Space,LeftShift=Enum.KeyCode.LeftShift,
    One=Enum.KeyCode.One,Two=Enum.KeyCode.Two,Three=Enum.KeyCode.Three,Four=Enum.KeyCode.Four,Five=Enum.KeyCode.Five}
local function K(n) return execKey[n] or n end

local function keyDown(n)
    local ek, vk = K(n), enumKey[n]
    if keypress and ek then pcall(keypress, ek)
    elseif vk then VIM:SendKeyEvent(true, vk, false, game) end
end
local function keyUp(n)
    local ek, vk = K(n), enumKey[n]
    if keyrelease and ek then pcall(keyrelease, ek)
    elseif vk then VIM:SendKeyEvent(false, vk, false, game) end
end
local function tap(n, hold)
    hold = hold or 0.03
    keyDown(n); task.wait(hold); keyUp(n)
end
local function m1()
    if mouse1click then pcall(mouse1click)
    else
        VIM:SendMouseButtonEvent(0,0,0,true,game,0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(0,0,0,false,game,0)
    end
end

------------------------------------------------------------------
-- 4. HELPERS
------------------------------------------------------------------
local function Notify(title, text, dur)
    dur = dur or 3
    local sg = PG:FindFirstChild("VJS_Notify")
    if not sg then
        sg = Instance.new("ScreenGui"); sg.Name="VJS_Notify"; sg.ResetOnSpawn=false; sg.Parent=PG
    end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,260,0,54)
    frame.Position = UDim2.new(1,-280,0,16 + #sg:GetChildren()*60)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,24)
    frame.BackgroundTransparency = 1; frame.BorderSizePixel = 0; frame.Parent = sg
    local c = Instance.new("UICorner",frame); c.CornerRadius = UDim.new(0,10)
    local s = Instance.new("UIStroke",frame); s.Color = Color3.fromRGB(120,90,255)
    local acc = Instance.new("Frame",frame); acc.Size=UDim2.new(0,4,1,0)
    acc.BackgroundColor3=Color3.fromRGB(150,120,255); acc.BorderSizePixel=0; acc.Parent=frame
    local c2 = Instance.new("UICorner",acc); c2.CornerRadius=UDim.new(0,10)
    local t = Instance.new("TextLabel",frame); t.BackgroundTransparency=1
    t.Position=UDim2.new(0,14,0,6); t.Size=UDim2.new(1,-20,0,20)
    t.Font=Enum.Font.GothamBold; t.TextSize=13; t.TextColor3=Color3.fromRGB(235,235,255)
    t.TextXAlignment=Enum.TextXAlignment.Left; t.Text=title
    local d = Instance.new("TextLabel",frame); d.BackgroundTransparency=1
    d.Position=UDim2.new(0,14,0,26); d.Size=UDim2.new(1,-20,0,22)
    d.Font=Enum.Font.Gotham; d.TextSize=11; d.TextColor3=Color3.fromRGB(170,170,190)
    d.TextXAlignment=Enum.TextXAlignment.Left; d.Text=text; d.TextWrapped=true
    TweenService:Create(frame,TweenInfo.new(0.25),{BackgroundTransparency=0.05}):Play()
    task.delay(dur,function()
        local tw=TweenService:Create(frame,TweenInfo.new(0.3),{BackgroundTransparency=1,Position=frame.Position+UDim2.new(0,40,0,0)})
        tw:Play(); tw.Completed:Wait(); frame:Destroy()
    end)
end

local function getPing()
    local ok,p = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
    return ok and p or 80
end

local function refreshChar()
    Char = LP.Character
    if Char then
        Hum = Char:FindFirstChildOfClass("Humanoid")
        Root = Char:FindFirstChild("HumanoidRootPart")
    end
end
local function isAlive() return Char and Hum and Hum.Health > 0 and Root end

local function getEnemies(maxRange)
    if not isAlive() then return {} end
    local list = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then
                local d = (r.Position - Root.Position).Magnitude
                if not maxRange or d <= maxRange then
                    table.insert(list,{player=p,hum=h,root=r,dist=d})
                end
            end
        end
    end
    table.sort(list,function(a,b) return a.dist < b.dist end)
    return list
end
VJS.getEnemies = getEnemies

local function getTarget(range)
    if VJS.Target and VJS.Target.Parent and VJS.Target.Character then
        local h = VJS.Target.Character:FindFirstChildOfClass("Humanoid")
        local r = VJS.Target.Character:FindFirstChild("HumanoidRootPart")
        if h and r and h.Health > 0 then
            local d = (r.Position - Root.Position).Magnitude
            if not range or d <= range then return {player=VJS.Target,hum=h,root=r,dist=d} end
        end
    end
    return getEnemies(range)[1]
end
VJS.getTarget = getTarget

VJS.runSequence = function(seq)
    task.spawn(function()
        for _, step in ipairs(seq) do
            if step.m1 then m1() else tap(step.key, step.hold or 0.03) end
            task.wait(step.wait or 0.1)
        end
    end)
end

------------------------------------------------------------------
-- 5. ESTADO
------------------------------------------------------------------
LP.CharacterAdded:Connect(function()
    task.wait(0.4); refreshChar()
    if VJS.Flags.Speed and Hum then Hum.WalkSpeed = cfg("WalkSpeed") end
end)
refreshChar()

------------------------------------------------------------------
-- 6. COMBATE
------------------------------------------------------------------
task.spawn(function()
    local blocked=false
    while VJS.Alive do
        task.wait(cfg("BlockReconnect"))
        if VJS.Flags.AutoBlock and isAlive() then
            local threat = #getEnemies(cfg("BlockRange"))>0
            if threat and not blocked then keyDown(cfg("Block")); blocked=true
            elseif not threat and blocked then keyUp(cfg("Block")); blocked=false end
        elseif blocked then keyUp(cfg("Block")); blocked=false end
    end
end)

task.spawn(function()
    local chain=0
    while VJS.Alive do
        task.wait(0.05)
        if VJS.Flags.AutoBF and isAlive() then
            if #getEnemies(cfg("BFRange"))>0 then
                local delay = cfg("BFBaseDelay") + math.clamp(getPing()/1000,0.03,0.09)
                tap(cfg("BFMove"),0.02); task.wait(delay); tap(cfg("BFMove"),0.02)
                if cfg("BFAutoChain") then
                    chain=chain+1
                    if chain>=cfg("BFMaxChain") then chain=0; task.wait(0.08) end
                end
                task.wait(0.09)
            else chain=0 end
        end
    end
end)

task.spawn(function()
    while VJS.Alive do
        task.wait(0.06)
        if VJS.Flags.AutoCounter and isAlive() then
            for _,e in ipairs(getEnemies(cfg("CounterRange"))) do
                local dir=(Root.Position-e.root.Position).Unit
                if e.root.CFrame.LookVector:Dot(dir)>0.3 then
                    keyDown(cfg("Block")); task.wait(0.03); m1(); keyUp(cfg("Block")); break
                end
            end
        end
    end
end)

task.spawn(function()
    while VJS.Alive do
        task.wait(0.16)
        if VJS.Flags.AutoM1 and isAlive() and #getEnemies(cfg("BlockRange")+2)>0 then m1() end
    end
end)

task.spawn(function()
    local i=1
    while VJS.Alive do
        task.wait(0.35)
        if VJS.Flags.AutoSkills and isAlive() and #getEnemies(cfg("BlockRange")+4)>0 then
            tap(cfg("Skills")[i],0.03); i=i%4+1
        end
    end
end)

-- Skill spam (lo que TBO llama "no-cd"; el cooldown real lo pone el server)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.08)
        if VJS.Flags.NoCD and isAlive() and #getEnemies(cfg("BlockRange")+3)>0 then
            for _,k in ipairs(cfg("Skills")) do tap(k,0.02) end
        end
    end
end)

task.spawn(function()
    while VJS.Alive do
        task.wait(0.5)
        if isAlive() then
            local n=#getEnemies(cfg("AutoDomainRange"))
            if VJS.Flags.AutoAwaken and n>0 then tap(cfg("Awakening"),0.03) end
            if VJS.Flags.AutoDomain and n>1 then tap(cfg("Domain"),0.03) end
        end
    end
end)

task.spawn(function()
    while VJS.Alive do
        task.wait(0.1)
        if VJS.Flags.KillAura and isAlive() and getEnemies(cfg("HitboxRange")+3)[1] then m1() end
    end
end)

-- Side Dash Assist
task.spawn(function()
    while VJS.Alive do
        task.wait(0.14)
        if VJS.Flags.DashAssist and isAlive() then
            local t = getTarget(cfg("DashAssistRange"))
            if t then
                local side=(t.root.Position-Root.Position).Unit
                local useRight = side:Dot(Root.CFrame.RightVector) > 0
                local key = useRight and "D" or "A"
                keyDown(key); task.wait(0.02); tap(cfg("Dash"),0.03); task.wait(0.02); keyUp(key)
            end
        end
    end
end)

-- Forward Dash Assist
task.spawn(function()
    while VJS.Alive do
        task.wait(0.2)
        if VJS.Flags.ForwardDash and isAlive() then
            local t = getTarget(cfg("DashAssistRange")+6)
            if t and t.dist > cfg("BlockRange") then
                keyDown("W"); task.wait(0.02); tap(cfg("Dash"),0.03); task.wait(0.02); keyUp("W")
            end
        end
    end
end)

------------------------------------------------------------------
-- 7. TECHS POR PERSONAJE
------------------------------------------------------------------
VJS.Presets = {
    Yuki   = {{key="R",wait=0.35},{key="Three",wait=0.12},{key="R",wait=0.12},{key="Two",wait=0.15},{m1=true,wait=0.16},{m1=true,wait=0.16}},
    Todo   = {{key="R",wait=0.2},{m1=true,wait=0.16},{key="Three",wait=0.15},{key="Two",wait=0.15}},
    Sukuna = {{key="Three",wait=0.15},{key="R",wait=0.12},{key="R",wait=0.4}},
    Hakari = {{key="One",wait=0.2},{key="Two",wait=0.2},{key="Three",wait=0.25},{key="One",wait=0.2}},
    Locust = {{m1=true,wait=0.16},{key="Space",wait=0.05},{m1=true,wait=0.16},{key="R",wait=0.15}},
    Gojo   = {{key="Two",wait=0.2},{key="Three",wait=0.15},{key="R",wait=0.12},{key="Four",wait=0.2}},
    Megumi = {{key="One",wait=0.2},{key="Two",wait=0.2},{key="Four",wait=0.25},{key="Three",wait=0.2}},
    Mahito = {{key="Three",wait=0.12},{key="Three",wait=0.1},{key="One",wait=0.15},{key="Two",wait=0.15}},
    Yuta   = {{key="One",wait=0.2},{key="Two",wait=0.2},{key="Three",wait=0.2},{key="Four",wait=0.25}},
}
task.spawn(function()
    local map = {AutoYuki="Yuki",AutoTodo="Todo",AutoWCS="Sukuna",AutoHakari="Hakari",
        AutoLocust="Locust",AutoGojo="Gojo",AutoMegumi="Megumi",AutoMahito="Mahito",AutoYuta="Yuta"}
    while VJS.Alive do
        task.wait(0.9)
        if isAlive() and not VJS._comboBusy then
            for flag,preset in pairs(map) do
                if VJS.Flags[flag] and #getEnemies(cfg("BFRange")+2)>0 then
                    VJS.runSequence(VJS.Presets[preset]); break
                end
            end
        end
    end
end)

------------------------------------------------------------------
-- 8. COMBOS (de la wiki)
------------------------------------------------------------------
VJS.Combos = {
    ["Vessel · Base"]      = {{m1=true,wait=0.16},{key="One",wait=0.15},{m1=true,wait=0.16},{m1=true,wait=0.16},{m1=true,wait=0.16},{key="Two",wait=0.15}},
    ["Vessel · BF Chain"]  = {{key="Three",wait=0.12},{key="Three",wait=0.1},{key="Three",wait=0.12},{key="Three",wait=0.1},{key="Three",wait=0.12},{key="Three",wait=0.1}},
    ["Gojo · Base"]        = {{m1=true,wait=0.16},{m1=true,wait=0.16},{key="One",wait=0.15},{key="Two",wait=0.15},{key="Three",wait=0.15}},
    ["Hakari · Combo"]     = {{m1=true,wait=0.16},{m1=true,wait=0.16},{m1=true,wait=0.16},{key="Two",wait=0.2},{key="Four",wait=0.2},{key="Three",wait=0.2}},
    ["Locust · Combo"]     = {{m1=true,wait=0.16},{key="One",wait=0.15},{m1=true,wait=0.16},{m1=true,wait=0.16},{key="Three",wait=0.2},{key="R",wait=0.15}},
    ["Yuki · Garuda"]      = {{key="One",wait=0.15},{key="R",wait=0.2},{key="Two",wait=0.15},{key="Four",wait=0.2}},
    ["Todo · Boogie"]      = {{key="Two",wait=0.15},{key="Three",wait=0.15},{key="R",wait=0.15},{m1=true,wait=0.16}},
    ["Megumi · Summons"]   = {{key="One",wait=0.2},{key="Two",wait=0.2},{key="Three",wait=0.2},{key="Four",wait=0.25}},
    ["Mahito · BF"]        = {{key="Three",wait=0.12},{key="Three",wait=0.1},{key="One",wait=0.15},{key="Two",wait=0.15}},
    ["Yuta · Kit"]         = {{key="One",wait=0.2},{key="Two",wait=0.2},{key="Three",wait=0.2},{key="Four",wait=0.25}},
}
VJS.SelectedCombo = "Vessel · Base"

VJS.runCombo = function(name)
    local seq = VJS.Combos[name]
    if not seq then return end
    VJS._comboBusy = true
    task.spawn(function()
        for _, step in ipairs(seq) do
            if step.m1 then m1() else tap(step.key, step.hold or 0.03) end
            task.wait(step.wait or 0.1)
        end
        VJS._comboBusy = false
    end)
end

-- Auto-combo: ejecuta el combo seleccionado cuando hay enemigo en rango
task.spawn(function()
    while VJS.Alive do
        task.wait(0.4)
        if VJS.Flags.AutoCombo and isAlive() and not VJS._comboBusy and #getEnemies(cfg("BlockRange")+1)>0 then
            VJS.runCombo(VJS.SelectedCombo)
        end
    end
end)

------------------------------------------------------------------
-- 9. MOVIMIENTO
------------------------------------------------------------------
VJS.StartFly = function()
    if VJS._flyBV or not isAlive() then return end
    local bg=Instance.new("BodyGyro"); bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.CFrame=Root.CFrame; bg.Parent=Root
    local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=Root
    VJS._flyBG, VJS._flyBV = bg, bv
    VJS._flyConn = RunService.RenderStepped:Connect(function()
        if not isAlive() then return end
        local dir = Hum.MoveDirection          -- funciona en móvil (joystick) y PC
        if dir.Magnitude > 0 then bv.Velocity = dir * cfg("FlySpeed") else bv.Velocity = Vector3.zero end
        if UIS:IsKeyDown(Enum.KeyCode.Space) or Hum:GetState()==Enum.HumanoidStateType.Jumping then
            bv.Velocity = bv.Velocity + Vector3.new(0,cfg("FlySpeed")*0.6,0)
        end
        bg.CFrame = Camera.CFrame
    end)
end
VJS.StopFly = function()
    if VJS._flyConn then VJS._flyConn:Disconnect(); VJS._flyConn=nil end
    if VJS._flyBG then VJS._flyBG:Destroy(); VJS._flyBG=nil end
    if VJS._flyBV then VJS._flyBV:Destroy(); VJS._flyBV=nil end
end
-- watcher: el flag es la fuente de verdad
task.spawn(function()
    while VJS.Alive do
        task.wait(0.1)
        if VJS.Flags.Fly and isAlive() and not VJS._flyBV then VJS.StartFly()
        elseif not VJS.Flags.Fly and VJS._flyBV then VJS.StopFly() end
    end
end)

VJS.Conns.hb = RunService.Heartbeat:Connect(function()
    if not isAlive() then return end
    if VJS.Flags.Speed then Hum.WalkSpeed=cfg("WalkSpeed") end
    if VJS.Flags.Jump then Hum.UseJumpPower=true; Hum.JumpPower=cfg("JumpPower") end
end)
VJS.Conns.jump = UIS.JumpRequest:Connect(function()
    if VJS.Flags.InfJump and isAlive() then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
VJS.Conns.noclip = RunService.Stepped:Connect(function()
    if VJS.Flags.NoClip and Char then
        for _,p in ipairs(Char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
        end
    end
end)
VJS.Conns.parkour = RunService.Heartbeat:Connect(function()
    if not (VJS.Flags.Parkour and isAlive()) then return end
    if Hum.FloorMaterial ~= Enum.Material.Air then
        local params=RaycastParams.new(); params.FilterDescendantsInstances={Char}
        params.FilterType=Enum.RaycastFilterType.Exclude
        if workspace:Raycast(Root.Position, Root.CFrame.LookVector*3, params) then
            Hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

------------------------------------------------------------------
-- 10. ANTI / DEFENSIVO
------------------------------------------------------------------
task.spawn(function()
    while VJS.Alive do
        task.wait(0.1)
        if VJS.Flags.AntiRagdoll and isAlive() then
            local st=Hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown then
                Hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.08)
        if VJS.Flags.AntiStun and isAlive() and Hum.WalkSpeed<8 then Hum.WalkSpeed=cfg("WalkSpeed") end
    end
end)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.12)
        if VJS.Flags.AntiKill and isAlive() and Hum.Health<=25 then
            local st=Hum:GetState()
            if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.FallingDown then
                keyDown(cfg("Dash")); task.wait(0.05); keyUp(cfg("Dash"))
            end
        end
    end
end)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.15)
        if VJS.Flags.AntiBlackhole and isAlive() then
            for _,v in ipairs(workspace:GetChildren()) do
                if v:IsA("BasePart") and (v.Name:lower():find("hole") or v.Name:lower():find("black")) then
                    if (v.Position-Root.Position).Magnitude<40 then
                        keyDown(cfg("Dash")); task.wait(0.05); keyUp(cfg("Dash"))
                    end
                end
            end
        end
    end
end)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.2)
        if isAlive() and (VJS.Flags.AntiDomain or VJS.Flags.WalkDomain) then
            for _,v in ipairs(workspace:GetChildren()) do
                if v:IsA("Model") and v.Name:lower():find("domain") then
                    local c=v:GetPivot().Position
                    if (c-Root.Position).Magnitude<70 then
                        if VJS.Flags.WalkDomain and not VJS.Flags.AntiDomain then
                            Root.CFrame = Root.CFrame + (c-Root.Position).Unit*0.4
                        else
                            Root.CFrame = Root.CFrame + Root.CFrame.LookVector*0.5
                        end
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------------
-- 11. LOCK-ON (cámara libre + cuerpo fijo, ataques apuntados)
------------------------------------------------------------------
VJS.Conns.lock = RunService.RenderStepped:Connect(function()
    if not isAlive() then return end
    -- cuerpo: desactiva AutoRotate y orienta al objetivo (estilo TBO)
    Hum.AutoRotate = not VJS.Flags.LockBody
    if VJS.Flags.LockBody or VJS.Flags.LockCamera then
        local t = getTarget(cfg("AimRange"))
        if t then
            local pos = t.root.Position
            if VJS.Flags.LockCamera then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Vector3.new(pos.X,pos.Y+2,pos.Z))
            end
            if VJS.Flags.LockBody then
                Root.CFrame = CFrame.lookAt(Root.Position, Vector3.new(pos.X, Root.Position.Y, pos.Z))
            end
        end
    end
end)

------------------------------------------------------------------
-- 12. VISUAL
------------------------------------------------------------------
local espFolder = Instance.new("Folder",workspace); espFolder.Name="VJS_ESP"
task.spawn(function()
    while VJS.Alive do
        task.wait(0.5)
        if VJS.Flags.ESP then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LP and p.Character and not espFolder:FindFirstChild(p.Name) then
                    local hl=Instance.new("Highlight",espFolder); hl.Name=p.Name; hl.Adornee=p.Character
                    hl.FillColor=Color3.fromRGB(150,90,255); hl.OutlineColor=Color3.fromRGB(255,255,255)
                    hl.FillTransparency=0.6
                end
            end
            for _,c in ipairs(espFolder:GetChildren()) do
                if not Players:FindFirstChild(c.Name) then c:Destroy() end
            end
        else
            for _,c in ipairs(espFolder:GetChildren()) do c:Destroy() end
        end
    end
end)
task.spawn(function()
    local box
    while VJS.Alive do
        task.wait(0.05)
        if VJS.Flags.ShowHitbox and isAlive() then
            if not box or not box.Parent then
                box=Instance.new("Part"); box.Name="VJS_Hitbox"; box.Anchored=true
                box.CanCollide=false; box.CanQuery=false; box.CanTouch=false
                box.Material=Enum.Material.ForceField; box.Color=Color3.fromRGB(255,80,80)
                box.Transparency=0.7; box.Size=Vector3.new(6,6,6); box.Parent=workspace
            end
            box.CFrame=Root.CFrame
        elseif box then box:Destroy(); box=nil end
    end
end)

-- Silent Animations (best-effort: detiene tus tracks)
task.spawn(function()
    while VJS.Alive do
        task.wait(0.1)
        if VJS.Flags.SilentAnim and isAlive() then
            local anim = Hum:FindFirstChildOfClass("Animator")
            if anim then
                for _,tr in ipairs(anim:GetPlayingAnimationTracks()) do
                    if tr.Animation and not tr.Animation.Name:lower():find("idle") then
                        tr:Stop()
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------------
-- 13. UI LIB
------------------------------------------------------------------
local function New(class, props)
    local i = Instance.new(class)
    local parent
    for k,v in pairs(props) do
        if k=="Parent" then parent=v else i[k]=v end
    end
    if parent then i.Parent = parent end
    return i
end
local function corner(o,r) New("UICorner",{CornerRadius=UDim.new(0,r or 8),Parent=o}) end
local function stroke(o,c) New("UIStroke",{Color=c or Color3.fromRGB(70,70,90),Thickness=1,Parent=o}) end
local function pad(o,n) New("UIPadding",{PaddingTop=UDim.new(0,n),PaddingBottom=UDim.new(0,n),PaddingLeft=UDim.new(0,n),PaddingRight=UDim.new(0,n),Parent=o}) end

local Screen = New("ScreenGui",{Name="VeniceJJS",ResetOnSpawn=false,IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999,Parent=PG})

local Main = New("Frame",{Name="Main",Size=UDim2.new(0,620,0,440),Position=UDim2.new(0.5,-310,0.5,-220),
    BackgroundColor3=Color3.fromRGB(15,15,22),BorderSizePixel=0,Parent=Screen})
corner(Main,14); stroke(Main,Color3.fromRGB(90,70,200)); Main.ClipsDescendants=true
if isMobile then New("UIScale",{Scale=0.62,Parent=Main}) end

local Top = New("Frame",{Name="Top",Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(20,20,30),BorderSizePixel=0,Parent=Main})
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,16,0,0),Size=UDim2.new(1,-80,1,0),
    Font=Enum.Font.GothamBlack,TextSize=17,Text="VENICE.JS  •  Jujutsu Shenanigans",
    TextColor3=Color3.fromRGB(200,180,255),TextXAlignment=Enum.TextXAlignment.Left,Parent=Top})
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(1,-90,0,0),Size=UDim2.new(0,80,1,0),
    Font=Enum.Font.Gotham,TextSize=12,Text="v"..VJS.Version,TextColor3=Color3.fromRGB(140,140,170),
    TextXAlignment=Enum.TextXAlignment.Right,Parent=Top})

do
    local dragging,dragStart,startPos
    Top.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=i.Position; startPos=Main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dragStart
            Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

local Side = New("Frame",{Name="Side",Position=UDim2.new(0,0,0,40),Size=UDim2.new(0,150,1,-40),
    BackgroundColor3=Color3.fromRGB(18,18,26),BorderSizePixel=0,Parent=Main})
New("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=Side}); pad(Side,8)
local Content = New("Frame",{Name="Content",Position=UDim2.new(0,150,0,40),Size=UDim2.new(1,-150,1,-40),
    BackgroundColor3=Color3.fromRGB(15,15,22),BorderSizePixel=0,Parent=Main})

local tabs={}
local function selectTab(name)
    for n,t in pairs(tabs) do t.Page.Visible=(n==name) end
    for n,b in pairs(tabs) do b.Button.BackgroundColor3=(n==name) and Color3.fromRGB(45,35,85) or Color3.fromRGB(24,24,34) end
end
local function createTab(name)
    local btn=New("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=Color3.fromRGB(24,24,34),BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=12,Text="  "..name,TextColor3=Color3.fromRGB(200,200,220),
        TextXAlignment=Enum.TextXAlignment.Left,Parent=Side})
    corner(btn,8)
    local page=New("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=4,ScrollBarImageColor3=Color3.fromRGB(120,90,255),CanvasSize=UDim2.new(0,0,0,0),
        Visible=false,Parent=Content})
    pad(page,12)
    local lay=New("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=page})
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+20) end)
    tabs[name]={Button=btn,Page=page}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

local function section(p,t)
    New("TextLabel",{Size=UDim2.new(1,-10,0,26),BackgroundTransparency=1,Font=Enum.Font.GothamBlack,
        TextSize=12,Text=t,TextColor3=Color3.fromRGB(150,120,255),TextXAlignment=Enum.TextXAlignment.Left,Parent=p})
end
local function toggle(p,t,d,cb)
    local f=New("TextButton",{Size=UDim2.new(1,-10,0,30),BackgroundColor3=Color3.fromRGB(24,24,34),BorderSizePixel=0,
        Text="",AutoButtonColor=false,Parent=p})
    corner(f,8)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-60,1,0),
        Font=Enum.Font.Gotham,TextSize=12,Text=t,TextColor3=Color3.fromRGB(210,210,230),
        TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local track=New("Frame",{Position=UDim2.new(1,-46,0.5,-9),Size=UDim2.new(0,34,0,18),
        BackgroundColor3=Color3.fromRGB(50,50,70),BorderSizePixel=0,Parent=f}); corner(track,9)
    local knob=New("Frame",{Position=UDim2.new(0,2,0,2),Size=UDim2.new(0,14,0,14),
        BackgroundColor3=Color3.fromRGB(230,230,240),BorderSizePixel=0,Parent=track}); corner(knob,7)
    local st=d or false
    local function render()
        TweenService:Create(knob,TweenInfo.new(0.15),{Position=st and UDim2.new(1,-16,0,2) or UDim2.new(0,2,0,2)}):Play()
        TweenService:Create(track,TweenInfo.new(0.15),{BackgroundColor3=st and Color3.fromRGB(120,90,255) or Color3.fromRGB(50,50,70)}):Play()
    end
    render()
    f.MouseButton1Click:Connect(function() st=not st; render(); if cb then cb(st) end end)
end
local function slider(p,t,mn,mx,d,cb)
    local f=New("Frame",{Size=UDim2.new(1,-10,0,44),BackgroundColor3=Color3.fromRGB(24,24,34),BorderSizePixel=0,Parent=p}); corner(f,8)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,4),Size=UDim2.new(1,-60,0,16),
        Font=Enum.Font.Gotham,TextSize=12,Text=t,TextColor3=Color3.fromRGB(210,210,230),TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local val=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(1,-70,0,4),Size=UDim2.new(0,58,0,16),
        Font=Enum.Font.GothamBold,TextSize=12,Text=tostring(d),TextColor3=Color3.fromRGB(150,120,255),TextXAlignment=Enum.TextXAlignment.Right,Parent=f})
    local bar=New("Frame",{Position=UDim2.new(0,12,0,26),Size=UDim2.new(1,-24,0,10),BackgroundColor3=Color3.fromRGB(45,45,60),BorderSizePixel=0,Parent=f}); corner(bar,5)
    local fill=New("Frame",{Size=UDim2.new((d-mn)/(mx-mn),0,1,0),BackgroundColor3=Color3.fromRGB(120,90,255),BorderSizePixel=0,Parent=bar}); corner(fill,5)
    local dr=false
    local function set(i)
        local rel=math.clamp((i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
        local v=math.floor(mn+(mx-mn)*rel+0.5)
        val.Text=tostring(v); fill.Size=UDim2.new(rel,0,1,0); if cb then cb(v) end
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=true; set(i) end end)
    UIS.InputChanged:Connect(function(i)
        if dr and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i) end end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=false end end)
end
local function button(p,t,cb)
    local b=New("TextButton",{Size=UDim2.new(1,-10,0,30),BackgroundColor3=Color3.fromRGB(35,30,60),BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=12,Text=t,TextColor3=Color3.fromRGB(210,200,255),AutoButtonColor=true,Parent=p})
    corner(b,8); b.MouseButton1Click:Connect(function() if cb then cb() end end)
    return b
end
local function label(p,t)
    New("TextLabel",{Size=UDim2.new(1,-10,0,18),BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=11,
        Text=t,TextColor3=Color3.fromRGB(160,160,185),TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=p})
end
-- botón que cicla un keybind y actualiza su propio texto
local function cycleKey(p, labelText, key, list)
    local b = button(p, labelText..": "..cfg(key), function()
        local i = table.find(list, cfg(key)) or 0
        setCfg(key, list[i % #list + 1])
        b.Text = labelText..": "..cfg(key)
    end)
    return b
end

------------------------------------------------------------------
-- 14. PESTAÑAS
------------------------------------------------------------------
local combat=createTab("Combate")
section(combat,"AUTOMATIZACIÓN")
toggle(combat,"Auto Block (anti-desync)",false,function(v) VJS.Flags.AutoBlock=v end)
toggle(combat,"Auto Black Flash (chain x4)",false,function(v) VJS.Flags.AutoBF=v end)
toggle(combat,"Auto Counter / Parry",false,function(v) VJS.Flags.AutoCounter=v end)
toggle(combat,"Auto M1",false,function(v) VJS.Flags.AutoM1=v end)
toggle(combat,"Auto Skills (1-4)",false,function(v) VJS.Flags.AutoSkills=v end)
toggle(combat,"No-CD (skill spam)",false,function(v) VJS.Flags.NoCD=v end)
toggle(combat,"Auto Awakening",false,function(v) VJS.Flags.AutoAwaken=v end)
toggle(combat,"Auto Domain",false,function(v) VJS.Flags.AutoDomain=v end)
toggle(combat,"Kill Aura",false,function(v) VJS.Flags.KillAura=v end)
section(combat,"LOCK-ON / MOVILIDAD")
toggle(combat,"Lock-On Cámara (cámara fija)",false,function(v) VJS.Flags.LockCamera=v end)
toggle(combat,"Lock-On Cuerpo (personaje fijo, cámara libre)",false,function(v) VJS.Flags.LockBody=v end)
toggle(combat,"Side Dash Assist",false,function(v) VJS.Flags.DashAssist=v end)
toggle(combat,"Forward Dash Assist",false,function(v) VJS.Flags.ForwardDash=v end)
section(combat,"AJUSTES")
slider(combat,"Rango de bloqueo",6,30,cfg("BlockRange"),function(v) setCfg("BlockRange",v) end)
slider(combat,"Rango Black Flash",6,25,cfg("BFRange"),function(v) setCfg("BFRange",v) end)
slider(combat,"Delay BF (s)",0.05,0.25,cfg("BFBaseDelay"),function(v) setCfg("BFBaseDelay",v) end)
slider(combat,"Rango hitbox",6,30,cfg("HitboxRange"),function(v) setCfg("HitboxRange",v) end)

local ch=createTab("Personaje")
section(ch,"TECHS AUTOMATIZADAS")
toggle(ch,"Auto Yuki (Garuda)",false,function(v) VJS.Flags.AutoYuki=v end)
toggle(ch,"Auto Todo (Boogie Woogie)",false,function(v) VJS.Flags.AutoTodo=v end)
toggle(ch,"Auto Sukuna (WCS)",false,function(v) VJS.Flags.AutoWCS=v end)
toggle(ch,"Auto Hakari (Domain rush)",false,function(v) VJS.Flags.AutoHakari=v end)
toggle(ch,"Auto Locust (air combo)",false,function(v) VJS.Flags.AutoLocust=v end)
toggle(ch,"Auto Gojo (Red MAX)",false,function(v) VJS.Flags.AutoGojo=v end)
toggle(ch,"Auto Megumi (summons)",false,function(v) VJS.Flags.AutoMegumi=v end)
toggle(ch,"Auto Mahito (BF)",false,function(v) VJS.Flags.AutoMahito=v end)
toggle(ch,"Auto Yuta (kit)",false,function(v) VJS.Flags.AutoYuta=v end)
section(ch,"OBJETIVO")
button(ch,"Fijar objetivo más cercano",function()
    local e=getEnemies(); if e[1] then VJS.Target=e[1].player; Notify("Objetivo",e[1].player.Name,2) end
end)
button(ch,"Limpiar objetivo",function() VJS.Target=nil; Notify("Objetivo","libre",1.5) end)

local cbTab=createTab("Combos")
section(cbTab,"COMBO SELECCIONADO")
local selLabel = New("TextLabel",{Size=UDim2.new(1,-10,0,20),BackgroundTransparency=1,Font=Enum.Font.GothamBold,
    TextSize=12,Text="Activo: "..VJS.SelectedCombo,TextColor3=Color3.fromRGB(150,120,255),
    TextXAlignment=Enum.TextXAlignment.Left,Parent=cbTab})
toggle(cbTab,"Auto-Combo",false,function(v) VJS.Flags.AutoCombo=v end)
section(cbTab,"EJECUTAR / SELECCIONAR")
for name,_ in pairs(VJS.Combos) do
    local b = button(cbTab, name.."  ▶", function()
        VJS.SelectedCombo = name; selLabel.Text = "Activo: "..name
        if not VJS.Flags.AutoCombo then VJS.runCombo(name) end
    end)
end

local mv=createTab("Movimiento")
toggle(mv,"Speed",false,function(v) VJS.Flags.Speed=v end)
toggle(mv,"Jump Boost",false,function(v) VJS.Flags.Jump=v end)
toggle(mv,"Infinite Jump",false,function(v) VJS.Flags.InfJump=v end)
toggle(mv,"Parkour (auto-climb)",false,function(v) VJS.Flags.Parkour=v end)
toggle(mv,"Fly",false,function(v) VJS.Flags.Fly=v end)
toggle(mv,"NoClip",false,function(v) VJS.Flags.NoClip=v end)
slider(mv,"WalkSpeed",16,120,cfg("WalkSpeed"),function(v) setCfg("WalkSpeed",v) end)
slider(mv,"JumpPower",50,200,cfg("JumpPower"),function(v) setCfg("JumpPower",v) end)
slider(mv,"FlySpeed",20,250,cfg("FlySpeed"),function(v) setCfg("FlySpeed",v) end)

local vis=createTab("Visual")
toggle(vis,"Player ESP",false,function(v) VJS.Flags.ESP=v end)
toggle(vis,"Mostrar Hitbox",false,function(v) VJS.Flags.ShowHitbox=v end)
toggle(vis,"Silent Animations",false,function(v) VJS.Flags.SilentAnim=v end)
section(vis,"DEFENSA / ANTI")
toggle(vis,"Anti Ragdoll",false,function(v) VJS.Flags.AntiRagdoll=v end)
toggle(vis,"Anti Stun",false,function(v) VJS.Flags.AntiStun=v end)
toggle(vis,"Anti Domain",false,function(v) VJS.Flags.AntiDomain=v end)
toggle(vis,"Walk Into Domain",false,function(v) VJS.Flags.WalkDomain=v end)
toggle(vis,"Anti Kill",false,function(v) VJS.Flags.AntiKill=v end)
toggle(vis,"Anti Blackhole",false,function(v) VJS.Flags.AntiBlackhole=v end)

local srv=createTab("Servidor")
button(srv,"Rejoin",function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
button(srv,"Server Hop",function()
    local d=game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100")).data
    for _,s in ipairs(d) do if s.playing<s.maxPlayers and s.id~=game.JobId then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,s.id); break end end
end)
button(srv,"Mostrar/Ocultar HUD",function() VJS.ToggleHUD() end)

local st=createTab("Ajustes")
section(st,"KEYBINDS (cicla para cambiar)")
cycleKey(st,"Block","Block",{"F","G","H","J","K"})
cycleKey(st,"Special","Special",{"R","T","Y","U","E"})
cycleKey(st,"Dash","Dash",{"Q","LeftShift","E","Z","C"})
cycleKey(st,"Awakening","Awakening",{"G","H","Y","U"})
cycleKey(st,"Domain","Domain",{"Four","Five","Three"})
section(st,"INFO")
label(st,"VENICE.JS v"..VJS.Version.." — Jujutsu Shenanigans")
button(st,"Unload script",function() VJS.Unload() end)

selectTab("Combate")

------------------------------------------------------------------
-- 15. HUD MÓVIL
------------------------------------------------------------------
local HUD = New("ScreenGui",{Name="VeniceJJS_HUD",ResetOnSpawn=false,IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1000,Parent=PG})

local hudFrame = New("Frame",{Name="HUD",Size=UDim2.new(0,58,0,360),Position=UDim2.new(1,-76,0.5,-180),
    BackgroundTransparency=1,Parent=HUD})
New("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
    HorizontalAlignment=Enum.HorizontalAlignment.Center,Parent=hudFrame})

local hudButtons = {}
local function hudButton(text, flag, colOn, onClick)
    local b=New("TextButton",{Size=UDim2.new(0,52,0,52),BackgroundColor3=Color3.fromRGB(28,28,40),
        BorderSizePixel=0,Text=text,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(210,210,230),
        AutoButtonColor=false,Parent=hudFrame})
    corner(b,26); stroke(b,Color3.fromRGB(90,70,200))
    local function render()
        if flag then
            local on = VJS.Flags[flag]
            local col = on and colOn or Color3.fromRGB(28,28,40)
            if b.BackgroundColor3 ~= col then
                TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=col}):Play()
            end
        end
    end
    b.MouseButton1Click:Connect(function()
        if onClick then onClick() else VJS.Flags[flag] = not VJS.Flags[flag] end
        render()
    end)
    table.insert(hudButtons, render)
    render()
    return b
end

hudButton("BLOCK","AutoBlock",Color3.fromRGB(120,90,255))
hudButton("BF","AutoBF",Color3.fromRGB(120,90,255))
hudButton("LOCK","LockBody",Color3.fromRGB(90,200,140))
hudButton("DASH","DashAssist",Color3.fromRGB(90,200,140))
hudButton("FLY","Fly",Color3.fromRGB(90,160,255))
hudButton("UI",nil,Color3.fromRGB(200,120,90),function() VJS.ToggleHUD() end)

VJS.ToggleHUD = function() hudFrame.Visible = not hudFrame.Visible end

task.spawn(function()
    while VJS.Alive do task.wait(0.25); for _,f in ipairs(hudButtons) do f() end end
end)

do
    local dragging,dragStart,startPos
    hudFrame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=i.Position; startPos=hudFrame.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=i.Position-dragStart
            hudFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

------------------------------------------------------------------
-- 16. WATERMARK + FPS
------------------------------------------------------------------
local fps = 60
VJS.Conns.fps = RunService.RenderStepped:Connect(function(dt)
    if dt > 0 then fps = math.floor(1/dt + 0.5) end
end)
local wm = New("TextLabel",{Name="VJS_WM",Size=UDim2.new(0,260,0,18),Position=UDim2.new(0,10,1,-24),
    BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.fromRGB(200,180,255),
    TextXAlignment=Enum.TextXAlignment.Left,Parent=Screen,Text="VENICE.JS v"..VJS.Version})
task.spawn(function()
    while VJS.Alive do
        task.wait(0.5)
        wm.Text = string.format("VENICE.JS v%s | %d FPS | %d ms", VJS.Version, fps, math.floor(getPing()))
    end
end)

------------------------------------------------------------------
-- 17. UNLOAD
------------------------------------------------------------------
function VJS.Unload()
    VJS.Alive=false
    for _,c in pairs(VJS.Conns) do pcall(function() c:Disconnect() end) end
    pcall(VJS.StopFly)
    if Hum then pcall(function() Hum.AutoRotate = true end) end
    if Screen then Screen:Destroy() end
    if HUD then HUD:Destroy() end
    local n=PG:FindFirstChild("VJS_Notify"); if n then n:Destroy() end
    if espFolder then espFolder:Destroy() end
    getgenv().VeniceJJS=nil
    print("[VENICE.JS] Descargado.")
end

Notify("VENICE.JS v"..VJS.Version,"Cargado. HUD a la derecha, menú draggable.")
print("[VENICE.JS] cargado correctamente.")
