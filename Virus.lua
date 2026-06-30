local WindUI = nil
local success, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not success or not WindUI then
    warn("Falha ao carregar WindUI: " .. tostring(err))
    return 
end
WindUI:SetNotificationLower(true)
WindUI:SetTheme("Dark")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Window = WindUI:CreateWindow({
    Title = "Classic Hub - Skunk PVP",
    Icon = "rbxassetid://93450275909746",   
    Author = "Menordev & Nobary",
    Folder = "Classic Skunk", 
})
local CombatTab = Window:Tab({ Title = "Combat", Icon = "sword" })
local WeaponTab = Window:Tab({ Title = "Weapon", Icon = "gun" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "palette" })
local ESPTab = Window:Tab({ Title = "ESP", Icon = "scan" })
local MovementTab = Window:Tab({ Title = "Movement", Icon = "move" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "package" })
local ConfigTab = Window:Tab({ Title = "Config", Icon = "settings" })
local ESP_Config = {
    Enabled = false,        
    VisibilityCheck = false,
    Boxes = false,          
    Weapon = false,
    Tracers = false,
    Names = false,
    Skeletons = false,      
    Distance = false,
    Health = false,         
    MaxDistance = 300,
    ChamsColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,
    Streamproof = true
}
local _ESP_CACHE = {}
local _CONNECTIONS = {}
local SKELETON_BONES = {
    R15 = {
        {"UpperTorso", "LowerTorso"}, {"UpperTorso", "Head"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"} ,{"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    },
    R6 = {
        {"Torso", "Head"},
        {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
}
local GLOCK_OVERRIDE = {
    BaseDamage = 25,
    ClipSize = 15,
    ReloadTime = 1.2,
    Firerate = 4.5,
    MinSpread = 0,
    MaxSpread = 0,
    SpreadRate = 0,
    BulletSpeed = 1,
    HeadshotDamage = true,
    FireMode = "Auto",
    BulletTransparency = 0.1,
    MuzzleLightBrightness = 5,
    MuzzleLightRange = 20
}
local M4A1_OVERRIDE = {
    BaseDamage = 15,
    ClipSize = 30,
    ReloadTime = 0,
    Firerate = 1.2,
    MinSpread = 0,
    MaxSpread = 0,
    SpreadRate = 0,
    BulletSpeed = 1,
    HeadshotDamage = true,
    CanTeamkill = true,
    FireMode = "Auto",
    BulletTransparency = 0,
    MuzzleLightBrightness = 15,
    MuzzleLightRange = 60
}
local GLOBAL_DEFAULT_OVERRIDE = {
    BaseDamage = 100,
    ClipSize = 10000,
    ReloadTime = 0,
    Firerate = 50,
    MinSpread = 0,
    MaxSpread = 0,
    BulletSpeed = 5000,
    FireMode = "Auto"
}
local AdvancedWeaponManager = {}
AdvancedWeaponManager.__index = AdvancedWeaponManager
function AdvancedWeaponManager.Init()
    local self = setmetatable({}, AdvancedWeaponManager)
    self.ProcessedModules = {}
    self.ActiveConnections = {}
    return self
end
function AdvancedWeaponManager:GetMatrixForTool(toolName)
    local name = toolName:lower()
    if name:match("glock") or name:match("g17") then
        return GLOCK_OVERRIDE
    elseif name:match("m4a1") or name:match("fuzil") then
        return M4A1_OVERRIDE
    else
        return GLOBAL_DEFAULT_OVERRIDE
    end
end
function AdvancedWeaponManager:InjectMatrix(targetTable, matrix)
    for key, value in pairs(matrix) do
        rawset(targetTable, key, value)
    end
    local metatable = getmetatable(targetTable) or {}
    local originalNewIndex = metatable.__newindex
    metatable.__newindex = function(tbl, key, value)
        if matrix[key] ~= nil then
            rawset(tbl, key, matrix[key])
        else
            if type(originalNewIndex) == "function" then
                originalNewIndex(tbl, key, value)
            elseif type(originalNewIndex) == "table" then
                originalNewIndex[key] = value
            else
                rawset(tbl, key, value)
            end
        end
    end
    setmetatable(targetTable, metatable)
end
function AdvancedWeaponManager:ProcessWeapon(tool)
    if not tool:IsA("Tool") then return end
    local weaponMatrix = self:GetMatrixForTool(tool.Name)
    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("ModuleScript") then
            if descendant.Name:match("^Config") or descendant.Name:match("Configura") then
                if self.ProcessedModules[descendant] then continue end
                self.ProcessedModules[descendant] = true
                task.spawn(function()
                    local success, configTable = pcall(require, descendant)
                    if success and type(configTable) == "table" then
                        self:InjectMatrix(configTable, weaponMatrix)
                        print("[TUNE] Modificado: " .. tool.Name .. " -> " .. descendant.Name)
                    end
                end)
            end
        end
    end
end
function AdvancedWeaponManager:BindContainer(container)
    if not container then return end
    if self.ActiveConnections[container] then
        self.ActiveConnections[container]:Disconnect()
        self.ActiveConnections[container] = nil
    end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") then
            self:ProcessWeapon(item)
        end
    end
    self.ActiveConnections[container] = container.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.05)
            self:ProcessWeapon(child)
        end
    end)
end
local MainEngine = AdvancedWeaponManager.Init()
local function OnCharacterSpawn(character)
    if not character then return end
    print("[TUNE] Personagem spawnou, aplicando Tune...")
    MainEngine:BindContainer(character)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        print("[TUNE] Backpack encontrada, aplicando Tune...")
        MainEngine:BindContainer(backpack)
    end
    LocalPlayer.ChildAdded:Connect(function(child)
        if child.Name == "Backpack" then
            task.wait(0.1)
            print("[TUNE] Backpack criada, aplicando Tune...")
            MainEngine:BindContainer(child)
        end
    end)
end
if LocalPlayer.Character then
    task.spawn(OnCharacterSpawn, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(newChar)
    OnCharacterSpawn(newChar)
end)
local aimbotEnabled = false
local FOVRadius = 200
local lockedTarget = nil
local killCheckEnabled = false
local wallCheckEnabled = false
local HeadOffset = 1
local bodyShotModeEnabled = false
local bodyShotThreshold = 2
local shotCounts = {}
local prevHealth = {}
local rapidFireEnabled = false
local rapidFireDelay = 0.06
local actionDown = false
local rapidFireLoop = nil
local holdToAimEnabled = false
local aimKey = Enum.KeyCode.E
local mobileAimDown = false
local friendSet = {}
local aimbotFullCapa = false
local aimbotFullCapaHP = 40
local aimlockEnabled = false
local aimlockFOV = 200
local aimlockTarget = nil
local aimlockShowFOV = true
local aimlockWallCheck = false
local aimlockKillCheck = false
local aimlockBodyShotCount = 2  
local aimlockKey = Enum.KeyCode.Q  
local aimlockHoldEnabled = false  
local aimlockShotCounts = {}  
local aimlockFullCapa = false
local aimlockFullCapaHP = 40
local function findHeadPart(char)
    if not char then return nil end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local lname = part.Name:lower()
            if lname:find("head") or lname:find("cabeca") or lname:find("cabesa") then
                return part
            end
        end
    end
    local highest = nil
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            if not highest or part.Position.Y > highest.Position.Y then
                highest = part
            end
        end
    end
    return highest or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end
local function findChestPart(char)
    if not char then return nil end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local lname = part.Name:lower()
            if lname:find("torso") or lname:find("uppertorso") or lname:find("chest") or lname:find("peito") then
                return part
            end
        end
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end
local function resetShotDataForPlayer(plr)
    shotCounts[plr] = 0
    prevHealth[plr] = nil
end
local function isFriend(plr)
    return plr and friendSet[plr.UserId] == true
end
local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, closestDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isFriend(plr) then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if killCheckEnabled then if not hum or hum.Health <= 0 then continue end end
            local headPart = findHeadPart(plr.Character)
            local chestPart = findChestPart(plr.Character) or headPart
            local targetPart = headPart
            if bodyShotModeEnabled then
                local cnt = shotCounts[plr] or 0
                if cnt < bodyShotThreshold then targetPart = chestPart or headPart else targetPart = headPart end
            end
            if targetPart then
                local aimPosition = targetPart.Position
                if targetPart ~= headPart and HeadOffset ~= 0 then
                    aimPosition = aimPosition + Vector3.new(0, HeadOffset, 0)
                end
                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPosition)
                if onScreen then
                    if wallCheckEnabled then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local rayResult = Workspace:Raycast(Camera.CFrame.Position, (aimPosition - Camera.CFrame.Position).Unit * 1000, rayParams)
                        if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(plr.Character) then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < closestDist and dist <= FOVRadius then closest, closestDist = targetPart, dist end
                        end
                    else
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < closestDist and dist <= FOVRadius then closest, closestDist = targetPart, dist end
                    end
                end
            end
        end
    end
    return closest
end
local function getBestAimlockTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest, closestDist = nil, math.huge
    if aimlockTarget then
        local plr = aimlockTarget.Parent and Players:FindFirstChild(aimlockTarget.Parent.Name)
        if plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local headPart = findHeadPart(plr.Character)
            if headPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= aimlockFOV then
                        return headPart, dist
                    end
                end
            end
        end
        aimlockTarget = nil
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not isFriend(plr) then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if aimlockKillCheck and (not hum or hum.Health <= 0) then continue end
            local headPart = findHeadPart(plr.Character)
            local chestPart = findChestPart(plr.Character) or headPart
            local targetPart = headPart
            local shotCount = aimlockShotCounts[plr] or 0
            if shotCount < aimlockBodyShotCount then
                targetPart = chestPart
            else
                targetPart = headPart
            end
if aimlockFullCapa and hum and hum.Health > aimlockFullCapaHP then
    targetPart = headPart
end
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    if aimlockWallCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        local rayResult = Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000, rayParams)
                        if rayResult and rayResult.Instance and rayResult.Instance:IsDescendantOf(plr.Character) then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < closestDist and dist <= aimlockFOV then
                                closest, closestDist = targetPart, dist
                            end
                        end
                    else
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist < closestDist and dist <= aimlockFOV then
                            closest, closestDist = targetPart, dist
                        end
                    end
                end
            end
        end
    end
    aimlockTarget = closest
    return closest, closestDist
end
local drawingSupported, _ = pcall(function() return Drawing end)
local drawingFOV = nil
local fovVisible = false
if drawingSupported then
     local ok, fovObj = pcall(function() return Drawing.new("Circle") end)
drawingFOV = ok and fovObj or nil
        if drawingFOV then
        drawingFOV.Radius = FOVRadius
        drawingFOV.Color = Color3.fromRGB(255, 0, 0)
        drawingFOV.Thickness = 2
        drawingFOV.Filled = false
        drawingFOV.Visible = false
    end
end

local function updateFOVVisual()
    if drawingSupported and drawingFOV then
        pcall(function()
            if aimlockEnabled and aimlockShowFOV then
                drawingFOV.Radius = aimlockFOV
                drawingFOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                drawingFOV.Color = Color3.fromRGB(0, 200, 255)  
                drawingFOV.Visible = true
            elseif aimbotEnabled and fovVisible then
                drawingFOV.Radius = FOVRadius
                drawingFOV.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                drawingFOV.Color = Color3.fromRGB(255, 0, 0)    
                drawingFOV.Visible = true
            else
                drawingFOV.Visible = false
            end
        end)
    end
end
local function startRapidFire()
    if rapidFireLoop then return end
    rapidFireLoop = task.spawn(function()
        while actionDown and rapidFireEnabled do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local tool = nil
                    for _, c in ipairs(char:GetChildren()) do
                        if c:IsA("Tool") then tool = c; break end
                    end
                    if tool and tool.Parent == char then
                        pcall(function() tool:Activate() end)
                    end
                end
            end)
            task.wait(rapidFireDelay)
        end
        rapidFireLoop = nil
    end)
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        actionDown = true
        if rapidFireEnabled then startRapidFire() end
    end
end)
UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        actionDown = false
        mobileAimDown = false
    end
end)
RunService.RenderStepped:Connect(function()
    updateFOVVisual()
    if aimlockEnabled then
        local target = getBestAimlockTarget()
        if target then
            pcall(function()
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            end)
        end
        return 
    end
    if not aimbotEnabled then return end
    if holdToAimEnabled then
        local active = UserInputService:IsKeyDown(aimKey)
        if not active then lockedTarget = nil; return end
    end
    local target = getBestTarget()
    if target then
        pcall(function()
            local aimPos = target.Position
            local headPart = findHeadPart(target.Parent)
            if headPart and target ~= headPart and HeadOffset ~= 0 then
                aimPos = aimPos + Vector3.new(0, HeadOffset, 0)
            end
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
            lockedTarget = target
        end)
    else lockedTarget = nil end
end)
local function ClearAllVisibility(objects)
    if not objects then return end
    if objects.Box then objects.Box.Visible = false end
    if objects.BoxOutline then objects.BoxOutline.Visible = false end
    if objects.Name then objects.Name.Visible = false end
    if objects.Dist then objects.Dist.Visible = false end
    if objects.HealthBar then objects.HealthBar.Visible = false end
    if objects.HealthBack then objects.HealthBack.Visible = false end
    if objects.Tracer then objects.Tracer.Visible = false end

    for _, line in ipairs(objects.SkeletonLines or {}) do if line then line.Visible = false end end
end
local function CreateDrawInstance(type, properties)
    local obj = Drawing.new(type)
    if ESP_Config.Streamproof then
        pcall(function() obj.VisibleInCapture = false end)
    end
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    return obj
end
local function RegisterPlayerVisuals(player)
    if player == LocalPlayer or _ESP_CACHE[player] then return end
    local objects = {
        BoxOutline = CreateDrawInstance("Square", {Thickness = 3, Color = Color3.fromRGB(0,0,0), Filled = false, Visible = false, ZIndex = 1}),
        Box = CreateDrawInstance("Square", {Thickness = 1, Color = ESP_Config.ChamsColor, Filled = false, Visible = false, ZIndex = 2}),
        Name = CreateDrawInstance("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255,255,255), Font = 3, Visible = false}),
        Dist = CreateDrawInstance("Text", {Size = 10, Center = true, Outline = true, Color = Color3.fromRGB(200,200,200), Font = 3, Visible = false}),
        HealthBack = CreateDrawInstance("Square", {Thickness = 1, Color = Color3.fromRGB(0,0,0), Filled = true, Visible = false, ZIndex = 1}),
        HealthBar = CreateDrawInstance("Square", {Thickness = 1, Color = Color3.fromRGB(0,255,0), Filled = true, Visible = false, ZIndex = 2}),
        Tracer = CreateDrawInstance("Line", {Thickness = 1, Color = ESP_Config.ChamsColor, Visible = false}),
        SkeletonLines = {}
    }
    for i = 1, 15 do
        objects.SkeletonLines[i] = CreateDrawInstance("Line", {Thickness = 1, Color = Color3.fromRGB(255,255,255), Visible = false})
    end
 
    _CONNECTIONS[player.Name .. "_CharAdded"] = player.CharacterAdded:Connect(function(char)
        if _ESP_CACHE[player] then
            ClearAllVisibility(_ESP_CACHE[player])
        end
        task.wait(0.1)
    end)
    _ESP_CACHE[player] = objects
end
local function UnregisterPlayerVisuals(player)
    local connKey = player.Name .. "_CharAdded"
    if _CONNECTIONS[connKey] then
        _CONNECTIONS[connKey]:Disconnect()
        _CONNECTIONS[connKey] = nil
    end
    local objects = _ESP_CACHE[player]
    if objects then
        for key, value in pairs(objects) do
            if key == "SkeletonLines" then
                for _, line in ipairs(value) do pcall(function() line:Remove() end) end
            else
                pcall(function() value:Remove() end)
            end
        end
        _ESP_CACHE[player] = nil
    end
end
for _, p in ipairs(Players:GetPlayers()) do RegisterPlayerVisuals(p) end
_CONNECTIONS.PlayerAdded = Players.PlayerAdded:Connect(RegisterPlayerVisuals)
_CONNECTIONS.PlayerRemoving = Players.PlayerRemoving:Connect(UnregisterPlayerVisuals)
local function AtualizarESP(Player, Objects, RootPos, FrameData)
    local Char = Player.Character
    local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
    if not Char or not Hum then return end
    local DynamicColor = ESP_Config.ChamsColor
    local X, Y, W, H = FrameData.X, FrameData.Y, FrameData.W, FrameData.H
    local FeetS = FrameData.FeetS
    local Distance = FrameData.Distance
    local boxVisible = ESP_Config.Boxes
    Objects.Box.Visible = boxVisible
    Objects.BoxOutline.Visible = boxVisible
    if boxVisible then
        local boxSize = Vector2.new(W, H)
        local boxPos = Vector2.new(X, Y)
        Objects.Box.Size = boxSize
        Objects.Box.Position = boxPos
        Objects.Box.Color = DynamicColor
        Objects.BoxOutline.Size = boxSize
        Objects.BoxOutline.Position = boxPos
    end
local nameVisible = ESP_Config.Names
if Objects.Name then
    Objects.Name.Visible = nameVisible
    if nameVisible and Player and Player.Name then
        Objects.Name.Text = Player.Name:lower()
        Objects.Name.Position = Vector2.new(RootPos.X, math.max(Y - 14, 0)) 
    end
end
local distVisible = ESP_Config.Distance
if Objects.Dist then
    Objects.Dist.Visible = distVisible
    if distVisible and Distance then
        Objects.Dist.Text = "[" .. math.floor(Distance) .. "m]"
        Objects.Dist.Position = Vector2.new(RootPos.X, FeetS.Y + 2)
    end
end
    local healthVisible = ESP_Config.Health
    Objects.HealthBar.Visible = healthVisible
    Objects.HealthBack.Visible = healthVisible
    if healthVisible then
        local HP = math.clamp(Hum.Health / Hum.MaxHealth, 0, 1)
        Objects.HealthBack.Size = Vector2.new(2, H)
        Objects.HealthBack.Position = Vector2.new(X - 5, Y)
        Objects.HealthBar.Size = Vector2.new(2, H * HP)
        Objects.HealthBar.Position = Vector2.new(X - 5, FeetS.Y - (H * HP))
        Objects.HealthBar.Color = Color3.fromHSV(HP * 0.3, 1, 1)
    end
    local tracerVisible = ESP_Config.Tracers
    Objects.Tracer.Visible = tracerVisible
    if tracerVisible then
        Objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        Objects.Tracer.To = Vector2.new(RootPos.X, FeetS.Y)
        Objects.Tracer.Color = DynamicColor
    end
    if ESP_Config.Skeletons then
        local Rig = (Hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
        local ConnectionList = SKELETON_BONES[Rig]
        for i, Bone in ipairs(ConnectionList) do
            local p1, p2 = Char:FindFirstChild(Bone[1]), Char:FindFirstChild(Bone[2])
            local targetLine = Objects.SkeletonLines[i]
            if p1 and p2 and targetLine then
                local a, aOn = Camera:WorldToViewportPoint(p1.Position)
                local b, bOn = Camera:WorldToViewportPoint(p2.Position)
                if aOn and bOn then
                    targetLine.Visible = true
                    targetLine.From = Vector2.new(a.X, a.Y)
                    targetLine.To = Vector2.new(b.X, b.Y)
                    targetLine.Color = DynamicColor
                else
                    targetLine.Visible = false
                end
            elseif targetLine then
                targetLine.Visible = false
            end
        end
    else
        for _, line in ipairs(Objects.SkeletonLines) do line.Visible = false end
    end
end
local FrameDataTemplate = {}
_CONNECTIONS.MasterRenderLoop = RunService.RenderStepped:Connect(function()
    if not ESP_Config.Enabled then
for _, objects in pairs(_ESP_CACHE) do ClearAllVisibility(objects) end
        return
    end
    Camera = Workspace.CurrentCamera
    local localChar = LocalPlayer.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localChar or not localHRP then return end
    local camCFrame = Camera.CFrame
    for player, objects in pairs(_ESP_CACHE) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if char and hrp and hum and hum.Health > 0 then
            if ESP_Config.TeamCheck and player.Team == LocalPlayer.Team then
                ClearAllVisibility(objects)
                continue
            end
            local distance = (camCFrame.Position - hrp.Position).Magnitude
            if distance <= ESP_Config.MaxDistance then
                local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local isVisible = true
                    if ESP_Config.VisibilityCheck and localHRP then
                        local raycastParams = RaycastParams.new()
                        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                        raycastParams.FilterDescendantsInstances = {localChar, char}
                        local ray = Workspace:Raycast(camCFrame.Position, hrp.Position - camCFrame.Position, raycastParams)
                        if ray then
                            isVisible = false
                        end
                    end
                    local originalColor = ESP_Config.ChamsColor
                    if ESP_Config.VisibilityCheck then
                        if isVisible then
                            ESP_Config.ChamsColor = Color3.fromRGB(0, 255, 0)
                        else
                            ESP_Config.ChamsColor = Color3.fromRGB(255, 0, 0)
                        end
                    end
                    local head = char:FindFirstChild("Head")
                    local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0)) or Vector3.new(rootPos.X, rootPos.Y - 2, 0)
                    local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 4, 0))
                    local height = math.abs(headPos.Y - feetPos.Y)
                    local width = height / 2
                    FrameDataTemplate.X = rootPos.X - (width / 2)
                    FrameDataTemplate.Y = headPos.Y
                    FrameDataTemplate.W = width
                    FrameDataTemplate.H = height
                    FrameDataTemplate.FeetS = feetPos
                    FrameDataTemplate.Distance = distance
                    AtualizarESP(player, objects, rootPos, FrameDataTemplate)
                    ESP_Config.ChamsColor = originalColor
                else
                    ClearAllVisibility(objects)
                end
            else
                ClearAllVisibility(objects)
            end
        else
            ClearAllVisibility(objects)
        end
    end
end)
local spinbotEnabled = false
local spinSpeed = 50
local spinbotConnection = nil
local function ToggleSpinbot(state)
    spinbotEnabled = state
    if state then
        if spinbotConnection then return end
        spinbotConnection = RunService.Heartbeat:Connect(function()
            if not spinbotEnabled then return end
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                pcall(function() hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0) end)
            end
        end)
    else
        if spinbotConnection then spinbotConnection:Disconnect(); spinbotConnection = nil end
    end
end
local fakeDashEnabled = false
local DashDistance = 8
local DashCooldown = 0.25
local LastDashTime = 0
local dashLoop = nil
local fakeLagEnabled = false
local LagDistance = 15
local LagCooldown = 1.0
local LagDistanceVariacoes = {12, 15, 18}
local forceIndex = 1
local LastLagTime = 0
local lagLoop = nil
local function startDashLoop()
    if dashLoop then return end
    dashLoop = RunService.Heartbeat:Connect(function()
        if fakeDashEnabled and tick() - LastDashTime > DashCooldown then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                if hum.MoveDirection.Magnitude > 0 then
                    local dir = hrp.CFrame.LookVector
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {char}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local rayResult = Workspace:Raycast(hrp.Position, dir * DashDistance, rayParams)
                    if not rayResult then
                        hrp.CFrame = hrp.CFrame + dir * DashDistance
                    end
                    LastDashTime = tick()
                end
            end
        end
    end)
end
local function startLagLoop()
    if lagLoop then return end
    lagLoop = RunService.Heartbeat:Connect(function()
        if fakeLagEnabled and tick() - LastLagTime > LagCooldown then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local hrp = char.HumanoidRootPart
                local hum = char.Humanoid
                if hum.MoveDirection.Magnitude > 0 then
                    forceIndex = (forceIndex % #LagDistanceVariacoes) + 1
                    local dist = LagDistanceVariacoes[forceIndex]
                    local direction = hrp.CFrame.LookVector
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {char}
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local rayResult = Workspace:Raycast(hrp.Position, direction * dist, rayParams)
                    if not rayResult or (rayResult and not rayResult.Instance.CanCollide) then
                        hrp.CFrame = hrp.CFrame + direction * dist
                    end
                    LastLagTime = tick()
                end
            end
        end
    end)
end
local freezePlayer = false
local hitboxExpanded = false
local hitboxSize = 15
local hitboxTransparency = 0.7
local hitboxOriginais = {}
local legitAtivo = false
local legitTam = 6
local originaisLegit = {}
local visualPartsLegit = {}
local function expandirUpperTorso(char)
    local part = char:FindFirstChild("UpperTorso")
    if part and part:IsA("BasePart") then
        if not hitboxOriginais[part] then
            hitboxOriginais[part] = {
                Size = part.Size,
                Transparency = part.Transparency,
                Material = part.Material,
                Color = part.Color,
                CanCollide = part.CanCollide,
                Massless = part.Massless,
            }
        end
        part.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        part.Transparency = hitboxTransparency
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 0, 0)
        part.CanCollide = false
        part.Massless = true
    end
end
local function criarVisualPart(torso)
    if visualPartsLegit[torso] then return end
    local ok, visual = pcall(function() return torso:Clone() end)
    if not ok or not visual then return end
    visual.Size = torso.Size
    visual.CFrame = torso.CFrame
    visual.Anchored = false
    visual.CanCollide = false
    visual.Transparency = 0
    visual.Parent = torso.Parent
    local weld = Instance.new("Weld")
    weld.Part0 = torso
    weld.Part1 = visual
    weld.Parent = visual
    visualPartsLegit[torso] = visual
end
local function expandirTronco(char)
    local torso = char:FindFirstChild("UpperTorso")
    if torso and torso:IsA("BasePart") then
        if not originaisLegit[torso] then
            originaisLegit[torso] = {
                Size = torso.Size,
                Transparency = torso.Transparency
            }
            criarVisualPart(torso)
        end
        torso.Size = Vector3.new(legitTam, legitTam, legitTam)
        torso.Transparency = 1
    end
end
local audioEnhancerEnabled = false
local hitSound = Instance.new("Sound", Workspace)
hitSound.SoundId = "rbxassetid://9120386403"
hitSound.Volume = 1
hitSound.Name = "FluxoHitSound"
local lastHitHealths = {}
task.spawn(function()
    while task.wait(0.5) do
        if audioEnhancerEnabled then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Sound") then
                    local soundId = tostring(obj.SoundId or ""):lower()
                    if soundId:find("gun") or soundId:find("shoot") or soundId:find("fire")
                       or soundId:find("weapon") or soundId:find("rifle") or soundId:find("pistol") then
                        obj.Volume = math.clamp((obj.Volume or 1) * 0.3, 0, 0.3)
                    end
                end
            end
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        for _, sound in pairs(humanoid:GetChildren()) do
                            if sound:IsA("Sound") and string.lower(sound.Name):find("running") then
                                sound.Volume = math.min((sound.Volume or 1) * 1.8, 1.5)
                            end
                        end
                    end
                end
            end
            SoundService.AmbientReverb = Enum.ReverbType.NoReverb
        end
    end
end)
task.spawn(function()
    while task.wait(0.1) do
        if audioEnhancerEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        if not lastHitHealths[player] then
                            lastHitHealths[player] = humanoid.Health
                        end
                        if humanoid.Health < lastHitHealths[player] then
                            hitSound:Stop()
                            hitSound:Play()
                        end
                        lastHitHealths[player] = humanoid.Health
                    end
                end
            end
        end
    end
end)
RunService.RenderStepped:Connect(function()
    if freezePlayer then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.Anchored = true end) end
            end
        end
    end
    if hitboxExpanded then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then pcall(expandirUpperTorso, plr.Character) end
        end
    end
    if legitAtivo then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then pcall(expandirTronco, plr.Character) end
        end
    end
end)
local AimbotSection = CombatTab:Section({ Title = "Aimbot", Icon = "crosshair", Opened = true })
local ToggleAimbot = AimbotSection:Toggle({
    Title = "Enable",
    Flag = "AimbotToggle",
    Value = false,
    Callback = function(Value)
        aimbotEnabled = Value
        updateFOVVisual()
    end
})
local SliderFOV = AimbotSection:Slider({
    Title = "FOV Radius",
    Flag = "FOVSlider",
    Step = 1,
    Value = { Min = 50, Max = 400, Default = 200 },
    Callback = function(Value)
        FOVRadius = Value
        updateFOVVisual()
    end
})
local ToggleShowFOV = AimbotSection:Toggle({
    Title = "Show FOV",
    Flag = "ShowFOV",
    Value = false,
    Callback = function(Value)
        fovVisible = Value
        updateFOVVisual()
    end
})
local ToggleKillCheck = AimbotSection:Toggle({
    Title = "Kill Check",
    Flag = "KillCheck",
    Value = false,
    Callback = function(Value)
        killCheckEnabled = Value
    end
})
local ToggleWallCheck = AimbotSection:Toggle({
    Title = "Wall Check",
    Flag = "WallCheck",
    Value = false,
    Callback = function(Value)
        wallCheckEnabled = Value
    end
})
local SliderAimbotFullCapaHP = AimbotSection:Slider({
    Title = "Se Estiver com mais de, headshot",
    Flag = "AimbotFullCapaHP",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 40 },
    Callback = function(v)
        aimbotFullCapaHP = v
    end
})
local SliderHeadOffset = AimbotSection:Slider({
    Title = "Head Offset",
    Flag = "HeadOffset",
    Step = 1,
    Value = { Min = 0, Max = 10, Default = 1 },
    Callback = function(Value)
        HeadOffset = Value
    end
})
local BodyShotSection = CombatTab:Section({ Title = "Body Shot", Icon = "target", Opened = true })
local ToggleBodyShot = BodyShotSection:Toggle({
    Title = "enable.",
    Flag = "BodyShotToggle",
    Value = false,
    Callback = function(Value)
        bodyShotModeEnabled = Value
        if not Value then for _, p in ipairs(Players:GetPlayers()) do shotCounts[p] = 0 end end
    end
})
local ToggleAimbotFullCapa = AimbotSection:Toggle({
    Title = "Full Capa (Headshot > 40 HP)",
    Flag = "AimbotFullCapa",
    Value = false,
    Callback = function(v)
        aimbotFullCapa = v
    end
})
local SliderShotThreshold = BodyShotSection:Slider({
    Title = "Quantos tiros para subir na cabeça.",
    Flag = "ShotThreshold",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = 2 },
    Callback = function(Value)
        bodyShotThreshold = Value
    end
})
local RapidFireSection = CombatTab:Section({ Title = "Auto fire", Icon = "zap", Opened = true })
local ToggleRapidFire = RapidFireSection:Toggle({
    Title = "Ligar auto fire.",
    Flag = "RapidFireToggle",
    Value = false,
    Callback = function(Value)
        rapidFireEnabled = Value
    end
})
local SliderRapidDelay = RapidFireSection:Slider({
    Title = "Delay (ms)",
    Flag = "RapidDelay",
    Step = 1,
    Value = { Min = 10, Max = 200, Default = 60 },
    Callback = function(Value)
        rapidFireDelay = Value / 1000
    end
})
local HoldToAimSection = CombatTab:Section({ Title = "Segure para ativar.", Icon = "hand", Opened = true })
local ToggleHoldToAim = HoldToAimSection:Toggle({
    Title = "Enable",
    Flag = "HoldToAimToggle",
    Value = false,
    Callback = function(Value)
        holdToAimEnabled = Value
    end
})
local KeybindAim = HoldToAimSection:Keybind({
    Title = "Aim Key",
    Flag = "AimKeybind",
    Value = "E",
    Callback = function(key)
        aimKey = Enum.KeyCode[key]
    end
})
local AimlockTab = Window:Tab({ Title = "Aimlock", Icon = "target" })
local GeneralSection = AimlockTab:Section({ Title = "General", Icon = "settings", Opened = true })
local ToggleAimlock = GeneralSection:Toggle({
    Title = "Enable Aimlock",
    Flag = "AimlockEnable",
    Value = false,
    Callback = function(v)
        aimlockEnabled = v
        if not v then aimlockTarget = nil end
        updateFOVVisual()
    end
})
local ToggleAimlockShowFOV = GeneralSection:Toggle({
    Title = "Show FOV",
    Flag = "AimlockShowFOV",
    Value = true,
    Callback = function(v)
        aimlockShowFOV = v
        updateFOVVisual()
    end
})
local SliderAimlockFOV = GeneralSection:Slider({
    Title = "FOV Radius",
    Flag = "AimlockFOV",
    Step = 1,
    Value = { Min = 50, Max = 400, Default = 200 },
    Callback = function(v)
        aimlockFOV = v
        updateFOVVisual()
    end
})
local CheckSection = AimlockTab:Section({ Title = "Checks", Icon = "check", Opened = true })
local ToggleAimlockKillCheck = CheckSection:Toggle({
    Title = "Kill Check",
    Flag = "AimlockKillCheck",
    Value = false,
    Callback = function(v) aimlockKillCheck = v end
})
local ToggleAimlockWallCheck = CheckSection:Toggle({
    Title = "Wall Check",
    Flag = "AimlockWallCheck",
    Value = false,
    Callback = function(v) aimlockWallCheck = v end
})
local BodySection = AimlockTab:Section({ Title = "Legit", Icon = "target", Opened = true })
local SliderBodyShotCount = BodySection:Slider({
    Title = "Shots on Chest before Head",
    Flag = "AimlockBodyShotCount",
    Step = 1,
    Value = { Min = 0, Max = 10, Default = 2 },
    Callback = function(v)
        aimlockBodyShotCount = v
        aimlockShotCounts = {}
    end
})
local ButtonResetCounts = BodySection:Button({
    Title = "Reset Body Shot Counts",
    Callback = function()
        aimlockShotCounts = {}
        WindUI:Notify({ Title = "Reset", Content = "Body shot counts resetados", Duration = 2 })
    end
})
local ToggleAimlockFullCapa = BodySection:Toggle({
    Title = "Full Capa (Headshot > 40 HP)",
    Flag = "AimlockFullCapa",
    Value = false,
    Callback = function(v)
        aimlockFullCapa = v
    end
})
local SliderAimlockFullCapaHP = BodySection:Slider({
    Title = "Se Estiver com mais de, headshot",
    Flag = "AimlockFullCapaHP",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 40 },
    Callback = function(v)
        aimlockFullCapaHP = v
    end
})
local KeybindSection = AimlockTab:Section({ Title = "Keybind", Icon = "key", Opened = true })
local ToggleHoldMode = KeybindSection:Toggle({
    Title = "Hold Mode (toggle off = press to toggle)",
    Flag = "AimlockHoldMode",
    Value = false,
    Callback = function(v)
        aimlockHoldEnabled = v
    end
})
local KeybindAimlock = KeybindSection:Keybind({
    Title = "Activation Key",
    Flag = "AimlockKey",
    Value = "Q",
    Callback = function(key)
        aimlockKey = Enum.KeyCode[key]
    end
})
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == aimlockKey then
        if aimlockHoldEnabled then
            aimlockEnabled = true
            ToggleAimlock:Set(true)
        else
            aimlockEnabled = not aimlockEnabled
            ToggleAimlock:Set(aimlockEnabled)
            if not aimlockEnabled then aimlockTarget = nil end
        end
        updateFOVVisual()
    end
end)
UserInputService.InputEnded:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == aimlockKey and aimlockHoldEnabled then
        aimlockEnabled = false
        ToggleAimlock:Set(false)
        aimlockTarget = nil
        updateFOVVisual()
    end
end)
local GlockSection = WeaponTab:Section({ Title = "Tunar Glock", Icon = "pistol", Opened = true })
local SliderGlockDamage = GlockSection:Slider({
    Title = "Dano da pistola.",
    Flag = "GlockDamage",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 25 },
    Callback = function(Value)
        GLOCK_OVERRIDE.BaseDamage = Value
    end
})
local SliderGlockFirerate = GlockSection:Slider({
    Title = "Tiros por segundo",
    Flag = "GlockFirerate",
    Step = 0.1,
    Value = { Min = 4.5, Max = 150, Default = 4.5 },
    Callback = function(Value)
        GLOCK_OVERRIDE.Firerate = Value
    end
})
local SliderGlockClip = GlockSection:Slider({
    Title = "Tamanho do pente",
    Flag = "GlockClip",
    Step = 1,
    Value = { Min = 15, Max = 999, Default = 15 },
    Callback = function(Value)
        GLOCK_OVERRIDE.ClipSize = Value
    end
})
local SliderGlockBullet = GlockSection:Slider({
    Title = "Velocidade da Bala",
    Flag = "GlockBullet",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 1 },
    Callback = function(Value)
        GLOCK_OVERRIDE.BulletSpeed = Value
    end
})
local SliderGlockReload = GlockSection:Slider({
    Title = "Tempo de recarregar.",
    Flag = "GlockReload",
    Step = 0.1,
    Value = { Min = 0, Max = 5, Default = 1.2 },
    Callback = function(Value)
        GLOCK_OVERRIDE.ReloadTime = Value
    end
})
local SliderGlockMinSpread = GlockSection:Slider({
    Title = "Minimo de espalhar.",
    Flag = "GlockMinSpread",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 0 },
    Callback = function(Value)
        GLOCK_OVERRIDE.MinSpread = Value
    end
})
local SliderGlockMaxSpread = GlockSection:Slider({
    Title = "Maximo de espalhar.",
    Flag = "GlockMaxSpread",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 0 },
    Callback = function(Value)
        GLOCK_OVERRIDE.MaxSpread = Value
    end
})
local ToggleGlockHeadshot = GlockSection:Toggle({
    Title = "Mata na cara.",
    Flag = "GlockHeadshot",
    Value = false,
    Callback = function(Value)
        GLOCK_OVERRIDE.HeadshotDamage = Value
    end
})
local M4Section = WeaponTab:Section({ Title = "Tunar fuzil", Icon = "rifle", Opened = true })
local SliderM4Damage = M4Section:Slider({
    Title = "Dano do fuzil.",
    Flag = "M4Damage",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 15 },
    Callback = function(Value)
        M4A1_OVERRIDE.BaseDamage = Value
    end
})
local SliderM4Firerate = M4Section:Slider({
    Title = "Tiros por segundo.",
    Flag = "M4Firerate",
    Step = 0.1,
    Value = { Min = 8, Max = 75, Default = 8 },
    Callback = function(Value)
        M4A1_OVERRIDE.Firerate = Value
    end
})
local SliderM4Clip = M4Section:Slider({
    Title = "Tamanho do pente.",
    Flag = "M4Clip",
    Step = 1,
    Value = { Min = 30, Max = 9999, Default = 30 },
    Callback = function(Value)
        M4A1_OVERRIDE.ClipSize = Value
    end
})
local SliderM4Bullet = M4Section:Slider({
    Title = "Velocidade do tiro.",
    Flag = "M4Bullet",
    Step = 1,
    Value = { Min = 1, Max = 999, Default = 1 },
    Callback = function(Value)
        M4A1_OVERRIDE.BulletSpeed = Value
    end
})
local SliderM4Reload = M4Section:Slider({
    Title = "Tempo de recarregar",
    Flag = "M4Reload",
    Step = 0.1,
    Value = { Min = 0, Max = 5, Default = 1.2 },
    Callback = function(Value)
        M4A1_OVERRIDE.ReloadTime = Value
    end
})
local SliderM4MinSpread = M4Section:Slider({
    Title = "Minimo de espalhar.",
    Flag = "M4MinSpread",
    Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    Callback = function(Value)
        M4A1_OVERRIDE.MinSpread = Value
    end
})
local SliderM4MaxSpread = M4Section:Slider({
    Title = "Maximo de espalhar.",
    Flag = "M4MaxSpread",
    Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    Callback = function(Value)
        M4A1_OVERRIDE.MaxSpread = Value
    end
})
local ToggleM4Headshot = M4Section:Toggle({
    Title = "dano na cara.",
    Flag = "M4Headshot",
    Value = false,
    Callback = function(Value)
        M4A1_OVERRIDE.HeadshotDamage = Value
    end
})
local ToggleM4Teamkill = M4Section:Toggle({
    Title = "DEIXE ATIVO.",
    Flag = "M4Teamkill",
    Value = false,
    Callback = function(Value)
        M4A1_OVERRIDE.CanTeamkill = Value
    end
})
local GlobalSection = WeaponTab:Section({ Title = "Tunar personalizada", Icon = "globe", Opened = true })
local SliderGlobalDamage = GlobalSection:Slider({
    Title = "Dano da arma.",
    Flag = "GlobalDamage",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 100 },
    Callback = function(Value)
        GLOBAL_DEFAULT_OVERRIDE.BaseDamage = Value
    end
})
local SliderGlobalFirerate = GlobalSection:Slider({
    Title = "Tiros por segundo",
    Flag = "GlobalFirerate",
    Step = 1,
    Value = { Min = 10, Max = 150, Default = 50 },
    Callback = function(Value)
        GLOBAL_DEFAULT_OVERRIDE.Firerate = Value
    end
})
local SliderGlobalClip = GlobalSection:Slider({
    Title = "Tamanho do pente.",
    Flag = "GlobalClip",
    Step = 1,
    Value = { Min = 100, Max = 99999, Default = 10000 },
    Callback = function(Value)
        GLOBAL_DEFAULT_OVERRIDE.ClipSize = Value
    end
})
local SliderGlobalBullet = GlobalSection:Slider({
    Title = "Velocidade do tiro.",
    Flag = "GlobalBullet",
    Step = 1,
    Value = { Min = 1000, Max = 20000, Default = 5000 },
    Callback = function(Value)
        GLOBAL_DEFAULT_OVERRIDE.BulletSpeed = Value
    end
})
local ButtonApply = GlobalSection:Button({
    Title = "Aplicar p armas personalizadas.",
    Callback = function()
        if LocalPlayer.Character then MainEngine:BindContainer(LocalPlayer.Character) end
        local backpack = LocalPlayer:WaitForChild("Backpack", 5)
        if backpack then MainEngine:BindContainer(backpack) end
    end
})
local VisualSection = VisualTab:Section({ Title = "Visual", Icon = "brush", Opened = true })
local ButtonRefreshVisuals = VisualSection:Button({
    Title = "atualizar Visuals ( Caso bugar ).",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if _ESP_CACHE[p] then UnregisterPlayerVisuals(p) end
            RegisterPlayerVisuals(p)
        end
    end
})
local ESPGeneralSection = ESPTab:Section({ Title = "General", Icon = "settings", Opened = true })
local ToggleESPEnabled = ESPGeneralSection:Toggle({
    Title = "ligar esp.",
    Flag = "ESPEnabled",
    Value = false,
    Callback = function(Value)
        ESP_Config.Enabled = Value
    end
})
local SliderESPMaxDistance = ESPGeneralSection:Slider({
    Title = "Maxima Distancia.",
    Flag = "ESPMaxDistance",
    Step = 1,
    Value = { Min = 50, Max = 1000, Default = 300 },
    Callback = function(Value)
        ESP_Config.MaxDistance = Value
    end
})
local ToggleESPTeamCheck = ESPGeneralSection:Toggle({
    Title = "NAO ATIVE.",
    Flag = "ESPTeamCheck",
    Value = false,
    Callback = function(Value)
        ESP_Config.TeamCheck = Value
    end
})
local ESPVisualsSection = ESPTab:Section({ Title = "Visuals", Icon = "eye", Opened = true })
local ToggleESPBoxes = ESPVisualsSection:Toggle({
    Title = "Boxes",
    Flag = "ESPBoxes",
    Value = false,
    Callback = function(Value)
        ESP_Config.Boxes = Value
    end
})
local ToggleESPNames = ESPVisualsSection:Toggle({
    Title = "Names",
    Flag = "ESPNames",
    Value = false,
    Callback = function(Value)
        ESP_Config.Names = Value
    end
})
local ToggleESPDistance = ESPVisualsSection:Toggle({
    Title = "Distance",
    Flag = "ESPDistance",
    Value = false,
    Callback = function(Value)
        ESP_Config.Distance = Value
    end
})
local ToggleESPHealth = ESPVisualsSection:Toggle({
    Title = "Health",
    Flag = "ESPHealth",
    Value = false,
    Callback = function(Value)
        ESP_Config.Health = Value
    end
})
local ToggleESPSkeletons = ESPVisualsSection:Toggle({
    Title = "Skeletons",
    Flag = "ESPSkeletons",
    Value = false,
    Callback = function(Value)
        ESP_Config.Skeletons = Value
    end
})
local ToggleESPTracers = ESPVisualsSection:Toggle({
    Title = "Tracers",
    Flag = "ESPTracers",
    Value = false,
    Callback = function(Value)
        ESP_Config.Tracers = Value
    end
})
local ColorpickerESPColor = ESPVisualsSection:Colorpicker({
    Title = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Callback = function(Color)
        ESP_Config.ChamsColor = Color
    end
})
local ESPAdvancedSection = ESPTab:Section({ Title = "Advanced", Icon = "cpu", Opened = true })
local ToggleESPVisibility = ESPAdvancedSection:Toggle({
    Title = "Visibility Check",
    Flag = "ESPVisibilityCheck",
    Value = false,
    Callback = function(Value)
        ESP_Config.VisibilityCheck = Value
    end
})
local ToggleESPStreamproof = ESPAdvancedSection:Toggle({
    Title = "Streamproof",
    Flag = "ESPStreamproof",
    Value = false,
    Callback = function(Value)
        ESP_Config.Streamproof = Value
    end
})
local MovementSpinbotSection = MovementTab:Section({ Title = "Spinbot", Icon = "rotate-cw", Opened = true })
local SpinbotToggleElement = MovementSpinbotSection:Toggle({
    Title = "Ligar blaybade ( spinbot ).",
    Flag = "SpinbotToggle",
    Value = false,
    Callback = function(Value)
        ToggleSpinbot(Value)   
    end
})
local SliderSpinSpeed = MovementSpinbotSection:Slider({
    Title = "Velocidade do giro.",
    Flag = "SpinSpeed",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = 50 },
    Callback = function(Value)
        spinSpeed = Value
    end
})

local MovementDashSection = MovementTab:Section({ Title = "Dash", Icon = "move", Opened = true })
local ToggleFakeDash = MovementDashSection:Toggle({
    Title = "Ligar tp curto p frente.",
    Flag = "FakeDash",
    Value = false,
    Callback = function(Value)
        fakeDashEnabled = Value
        if Value then startDashLoop() elseif dashLoop then dashLoop:Disconnect(); dashLoop = nil end
    end
})
local SliderDashDistance = MovementDashSection:Slider({
    Title = "Distance que vai ser o tp",
    Flag = "DashDistance",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = 8 },
    Callback = function(Value)
        DashDistance = Value
    end
})
local SliderDashCooldown = MovementDashSection:Slider({
    Title = "A cada quantos(ms) Vai dar",
    Flag = "DashCooldown",
    Step = 1,
    Value = { Min = 50, Max = 2000, Default = 250 },
    Callback = function(Value)
        DashCooldown = Value / 1000
    end
})

local MovementLagSection = MovementTab:Section({ Title = "Lag", Icon = "clock", Opened = true })
local ToggleFakeLag = MovementLagSection:Toggle({
    Title = "Enable",
    Flag = "FakeLag",
    Value = false,
    Callback = function(Value)
        fakeLagEnabled = Value
        if Value then startLagLoop() elseif lagLoop then lagLoop:Disconnect(); lagLoop = nil end
    end
})
local SliderLagDistance = MovementLagSection:Slider({
    Title = "Distance",
    Flag = "LagDistance",
    Step = 1,
    Value = { Min = 5, Max = 100, Default = 15 },
    Callback = function(Value)
        LagDistance = Value
    end
})
local SliderLagCooldown = MovementLagSection:Slider({
    Title = "Cooldown (ms)",
    Flag = "LagCooldown",
    Step = 1,
    Value = { Min = 100, Max = 5000, Default = 1000 },
    Callback = function(Value)
        LagCooldown = Value / 1000
    end
})
local MiscGeneralSection = MiscTab:Section({ Title = "General", Icon = "home", Opened = true })
local ToggleFreeze = MiscGeneralSection:Toggle({
    Title = "Congelar as pessoas.",
    Flag = "FreezeToggle",
    Value = false,
    Callback = function(Value)
        freezePlayer = Value
    end
})
local MiscHitboxSection = MiscTab:Section({ Title = "Hitbox 100hs", Icon = "box", Opened = true })
local ToggleHitbox = MiscHitboxSection:Toggle({
    Title = "Enable",
    Flag = "HitboxToggle",
    Value = false,
    Callback = function(Value)
        hitboxExpanded = Value
        if not Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local part = player.Character:FindFirstChild("UpperTorso")
                    if part and hitboxOriginais[part] then
                        local o = hitboxOriginais[part]
                        pcall(function()
                            part.Size = o.Size; part.Transparency = o.Transparency; part.Material = o.Material
                            part.Color = o.Color; part.CanCollide = o.CanCollide; part.Massless = o.Massless
                        end)
                        hitboxOriginais[part] = nil
                    end
                end
            end
        end
    end
})
local SliderHitboxSize = MiscHitboxSection:Slider({
    Title = "Size",
    Flag = "HitboxSize",
    Step = 1,
    Value = { Min = 5, Max = 100, Default = 15 },
    Callback = function(Value)
        hitboxSize = Value
    end
})
local SliderHitboxTransparency = MiscHitboxSection:Slider({
    Title = "Transparency",
    Flag = "HitboxTransparency",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 70 },
    Callback = function(Value)
        hitboxTransparency = Value / 100
    end
})
local MiscLegitHitboxSection = MiscTab:Section({ Title = "Hitbox Legit", Icon = "crosshair", Opened = true })
local ToggleLegitHitbox = MiscLegitHitboxSection:Toggle({
    Title = "Enable",
    Flag = "LegitHitboxToggle",
    Value = false,
    Callback = function(Value)
        legitAtivo = Value
        if not Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local torso = plr.Character:FindFirstChild("UpperTorso")
                    if torso and originaisLegit[torso] then
                        pcall(function()
                            torso.Size = originaisLegit[torso].Size
                            torso.Transparency = originaisLegit[torso].Transparency
                        end)
                        if visualPartsLegit[torso] then pcall(function() visualPartsLegit[torso]:Destroy() end) end
                        originaisLegit[torso] = nil
                    end
                end
            end
        end
    end
})
local SliderLegitHitboxSize = MiscLegitHitboxSection:Slider({
    Title = "Size",
    Flag = "LegitHitboxSize",
    Step = 1,
    Value = { Min = 4, Max = 10, Default = 1 },
    Callback = function(Value)
        legitTam = Value
    end
})
local MiscAudioSection = MiscTab:Section({ Title = "Audio", Icon = "speaker", Opened = true })
local ToggleAudioEnhancer = MiscAudioSection:Toggle({
    Title = "Audio Enhancer",
    Flag = "AudioEnhancer",
    Value = false,
    Callback = function(Value)
        audioEnhancerEnabled = Value
    end
})
local ToggleHitSound = MiscAudioSection:Toggle({
    Title = "Hit Sound",
    Flag = "HitSound",
    Value = false,
    Callback = function(Value)
        audioEnhancerEnabled = Value
    end
})
local ConfigFriendsSection = ConfigTab:Section({ Title = "Whitelist", Icon = "users", Opened = true })
local ButtonAddAll = ConfigFriendsSection:Button({
    Title = "Adicionar todos Players",
    Callback = function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                friendSet[plr.UserId] = true
            end
        end
    end
})
local ButtonClearFriends = ConfigFriendsSection:Button({
    Title = "Limpar todos Friends",
    Callback = function()
        friendSet = {}
    end
})

local ConfigSettingsSection = ConfigTab:Section({ Title = "Settings", Icon = "wrench", Opened = true })
ConfigManager = Window.ConfigManager
myConfig = ConfigManager:CreateConfig("BalrightConfig")
pcall(function() myConfig:Delete() end)  
myConfig = ConfigManager:CreateConfig("BalrightConfig")
myConfig:Register("AimbotToggle", ToggleAimbot)
myConfig:Register("FOVSlider", SliderFOV)
myConfig:Register("ShowFOV", ToggleShowFOV)
myConfig:Register("KillCheck", ToggleKillCheck)
myConfig:Register("WallCheck", ToggleWallCheck)
myConfig:Register("HeadOffset", SliderHeadOffset)
myConfig:Register("BodyShotToggle", ToggleBodyShot)
myConfig:Register("ShotThreshold", SliderShotThreshold)
myConfig:Register("AimbotFullCapa", ToggleAimbotFullCapa)
myConfig:Register("AimbotFullCapaHP", SliderAimbotFullCapaHP)
myConfig:Register("RapidFireToggle", ToggleRapidFire)
myConfig:Register("RapidDelay", SliderRapidDelay)
myConfig:Register("HoldToAimToggle", ToggleHoldToAim)
myConfig:Register("AimKeybind", KeybindAim)
myConfig:Register("AimlockEnable", ToggleAimlock)
myConfig:Register("AimlockShowFOV", ToggleAimlockShowFOV)
myConfig:Register("AimlockFOV", SliderAimlockFOV)
myConfig:Register("AimlockKillCheck", ToggleAimlockKillCheck)
myConfig:Register("AimlockWallCheck", ToggleAimlockWallCheck)
myConfig:Register("AimlockBodyShotCount", SliderBodyShotCount)
myConfig:Register("AimlockHoldMode", ToggleHoldMode)
myConfig:Register("AimlockKey", KeybindAimlock)
myConfig:Register("AimlockFullCapa", ToggleAimlockFullCapa)
myConfig:Register("AimlockFullCapaHP", SliderAimlockFullCapaHP)
myConfig:Register("GlockDamage", SliderGlockDamage)
myConfig:Register("GlockFirerate", SliderGlockFirerate)
myConfig:Register("GlockClip", SliderGlockClip)
myConfig:Register("GlockBullet", SliderGlockBullet)
myConfig:Register("GlockReload", SliderGlockReload)
myConfig:Register("GlockMinSpread", SliderGlockMinSpread)
myConfig:Register("GlockMaxSpread", SliderGlockMaxSpread)
myConfig:Register("GlockHeadshot", ToggleGlockHeadshot)
myConfig:Register("M4Damage", SliderM4Damage)
myConfig:Register("M4Firerate", SliderM4Firerate)
myConfig:Register("M4Clip", SliderM4Clip)
myConfig:Register("M4Bullet", SliderM4Bullet)
myConfig:Register("M4Reload", SliderM4Reload)
myConfig:Register("M4MinSpread", SliderM4MinSpread)
myConfig:Register("M4MaxSpread", SliderM4MaxSpread)
myConfig:Register("M4Headshot", ToggleM4Headshot)
myConfig:Register("M4Teamkill", ToggleM4Teamkill)
myConfig:Register("GlobalDamage", SliderGlobalDamage)
myConfig:Register("GlobalFirerate", SliderGlobalFirerate)
myConfig:Register("GlobalClip", SliderGlobalClip)
myConfig:Register("GlobalBullet", SliderGlobalBullet)
myConfig:Register("ESPEnabled", ToggleESPEnabled)
myConfig:Register("ESPMaxDistance", SliderESPMaxDistance)
myConfig:Register("ESPTeamCheck", ToggleESPTeamCheck)
myConfig:Register("ESPBoxes", ToggleESPBoxes)
myConfig:Register("ESPNames", ToggleESPNames)
myConfig:Register("ESPDistance", ToggleESPDistance)
myConfig:Register("ESPHealth", ToggleESPHealth)
myConfig:Register("ESPSkeletons", ToggleESPSkeletons)
myConfig:Register("ESPTracers", ToggleESPTracers)
myConfig:Register("ESPColor", ColorpickerESPColor)
myConfig:Register("ESPVisibilityCheck", ToggleESPVisibility)
myConfig:Register("ESPStreamproof", ToggleESPStreamproof)
myConfig:Register("SpinbotToggle", SpinbotToggleElement)
myConfig:Register("SpinSpeed", SliderSpinSpeed)
myConfig:Register("FakeDash", ToggleFakeDash)
myConfig:Register("DashDistance", SliderDashDistance)
myConfig:Register("DashCooldown", SliderDashCooldown)
myConfig:Register("FakeLag", ToggleFakeLag)
myConfig:Register("LagDistance", SliderLagDistance)
myConfig:Register("LagCooldown", SliderLagCooldown)
myConfig:Register("FreezeToggle", ToggleFreeze)
myConfig:Register("HitboxToggle", ToggleHitbox)
myConfig:Register("HitboxSize", SliderHitboxSize)
myConfig:Register("HitboxTransparency", SliderHitboxTransparency)
myConfig:Register("LegitHitboxToggle", ToggleLegitHitbox)
myConfig:Register("LegitHitboxSize", SliderLegitHitboxSize)
myConfig:Register("AudioEnhancer", ToggleAudioEnhancer)
myConfig:Register("HitSound", ToggleHitSound)
ConfigSettingsSection:Button({
    Title = "Save Config",
    Callback = function()
        myConfig:Save()
        WindUI:Notify({
            Title = "Config",
            Content = "Configuração salva com sucesso!",
            Duration = 2,
            Icon = "check"
        })
    end
})
ConfigSettingsSection:Button({
    Title = "Load Config",
    Callback = function()
        myConfig:Load()
        WindUI:Notify({
            Title = "Config",
            Content = "Configuração carregada!",
            Duration = 2,
            Icon = "check"
        })
    end
})
ConfigSettingsSection:Button({
    Title = "Delete Config",
    Callback = function()
        myConfig:Delete()
        WindUI:Notify({
            Title = "Config",
            Content = "Configuração deletada!",
            Duration = 2,
            Icon = "trash-2"
        })
    end
})
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "sliders" })
local AppearanceSection = SettingsTab:Section({
    Title = "Appearance",
    Icon = "palette",
    Opened = true
})
local ToggleDarkTheme = AppearanceSection:Toggle({
    Title = "Dark Theme",
    Desc = "Alterna entre tema escuro e claro",
    Icon = "moon",
    Value = true, 
    Callback = function(state)
        WindUI:SetTheme(state and "Dark" or "Light")
    end
})
local ToggleTransparency = AppearanceSection:Toggle({
    Title = "Transparent Window",
    Desc = "Deixa a janela do menu transparente",
    Icon = "eye",
    Value = false,
    Callback = function(state)
        Window:ToggleTransparency(state)
    end
})
local ColorpickerAccent = AppearanceSection:Colorpicker({
    Title = "Accent Color",
    Desc = "Cor principal dos botões e elementos",
    Default = Color3.fromRGB(255, 15, 123),
    Transparency = 0,
    Callback = function(color)
        Window:EditOpenButton({
            Title = "Open Classic Hub",
            Icon = "sword",
            CornerRadius = UDim.new(0, 16),
            StrokeThickness = 2,
            Color = ColorSequence.new(color, color),
            OnlyMobile = false,
            Enabled = true,
            Draggable = true,
        })
    end
})
local ButtonEditOpen = AppearanceSection:Button({
    Title = "Customize Open Button",
    Desc = "Edite o título, ícone e cores do botão flutuante",
    Icon = "edit",
    Callback = function()
        local Dialog = Window:Dialog({
            Icon = "pencil",
            Title = "Edit Open Button",
            Content = "Digite o novo título e escolha a cor:",
            Buttons = {
                {
                    Title = "Apply",
                    Callback = function()
                        Window:EditOpenButton({
                            Title = "My Hub",
                            Icon = "rocket",
                            CornerRadius = UDim.new(0, 20),
                            StrokeThickness = 3,
                            Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 0, 200)),
                            OnlyMobile = false,
                            Enabled = true,
                            Draggable = true,
                        })
                        WindUI:Notify({ Title = "Open Button", Content = "Atualizado!", Duration = 2 })
                    end
                },
                { Title = "Cancel", Callback = function() end }
            }
        })
        Dialog:Show()
    end
})
local BehaviorSection = SettingsTab:Section({
    Title = "Behavior",
    Icon = "settings",
    Opened = true
})
local KeybindToggle = BehaviorSection:Keybind({
    Title = "Toggle Menu Key",
    Desc = "Tecla de atalho para abrir/fechar o menu",
    Value = "H",
    Callback = function(key)
        Window:SetToggleKey(Enum.KeyCode[key])
    end
})
local ToggleNotifications = BehaviorSection:Toggle({
    Title = "Enable Notifications",
    Desc = "Mostra notificações ao salvar, carregar, etc.",
    Icon = "bell",
    Value = true,
    Callback = function(state)
        WindUI:SetNotificationLower(state) 
        _G.EnableNotifications = state
    end
})
local SliderNotifDuration = BehaviorSection:Slider({
    Title = "Notification Duration",
    Desc = "Tempo que as notificações ficam visíveis",
    Step = 0.5,
    Value = { Min = 1, Max = 10, Default = 3 },
    Callback = function(value)
        _G.NotifDuration = value
    end
})
local ConfigSection = SettingsTab:Section({
    Title = "Config Management",
    Icon = "save",
    Opened = true
})
local ButtonSave = ConfigSection:Button({
    Title = "Save Current Config",
    Icon = "check-circle",
    Callback = function()
        myConfig:Save()
        if _G.EnableNotifications ~= false then
            WindUI:Notify({
                Title = "Config",
                Content = "Configuração salva com sucesso!",
                Duration = _G.NotifDuration or 3,
                Icon = "check"
            })
        end
    end
})
local ButtonLoad = ConfigSection:Button({
    Title = "Load Last Config",
    Icon = "upload",
    Callback = function()
        myConfig:Load()
        if _G.EnableNotifications ~= false then
            WindUI:Notify({
                Title = "Config",
                Content = "Configuração carregada!",
                Duration = _G.NotifDuration or 3,
                Icon = "check"
            })
        end
    end
})
local ButtonDelete = ConfigSection:Button({
    Title = "Delete Current Config",
    Icon = "trash-2",
    Callback = function()
        myConfig:Delete()
        if _G.EnableNotifications ~= false then
            WindUI:Notify({
                Title = "Config",
                Content = "Configuração deletada!",
                Duration = _G.NotifDuration or 3,
                Icon = "trash-2"
            })
        end
    end
})
local ConfigListSection = nil
local function UpdateConfigList()
    if ConfigListSection then
        ConfigListSection:Destroy()
    end
    ConfigListSection = SettingsTab:Section({
        Title = "Saved Configs",
        Icon = "folder",
        Opened = true
    })
    local folder = "WindUI/" .. (Window.Folder or "ClassicHub") .. "/config/"
    local files = {}
    if listfiles then
        for _, file in ipairs(listfiles(folder)) do
            if file:match("%.json$") then
                table.insert(files, file:match("([^/]+)%.json$"))
            end
        end
    end
    if #files == 0 then
        ConfigListSection:Paragraph({
            Title = "No configs found",
            Desc = "Salve uma configuração para vê-la aqui."
        })
    else
        for _, name in ipairs(files) do
            local btn = ConfigListSection:Button({
                Title = name,
                Icon = "file-text",
                Callback = function()
                    local tempConfig = ConfigManager:CreateConfig(name)
                    tempConfig:Load()
                    if _G.EnableNotifications ~= false then
                        WindUI:Notify({
                            Title = "Config",
                            Content = "Config '" .. name .. "' carregada!",
                            Duration = _G.NotifDuration or 3,
                            Icon = "check"
                        })
                    end
                end
            })
        end
    end
end
UpdateConfigList()
ConfigSection:Button({
    Title = "Refresh Config List",
    Icon = "refresh-cw",
    Callback = function()
        UpdateConfigList()
    end
})
local AboutSection = SettingsTab:Section({
    Title = "About",
    Icon = "info",
    Opened = true
})
AboutSection:Paragraph({
    Title = "Classic Hub - Skunk PVP",
    Desc = "Versão: 2.0\nAutor: Skunk\nBaseado em WindUI\n\n© 2026 Todos os direitos reservados.",
    Image = "rbxassetid://93450275909746", 
    ImageSize = 60,
    Thumbnail = "rbxassetid://93450275909746",
    ThumbnailSize = 80,
    Buttons = {
        {
            Icon = "discord",
            Title = "Discord",
            Callback = function()
                setclipboard("https://discord.gg/uXtz4Am6Jx")
                WindUI:Notify({ Title = "Link Copiado", Content = "Convite do Discord copiado!", Duration = 2 })
            end
        }
    }
})
_G.EnableNotifications = true
_G.NotifDuration = 3
ToggleAimbot:Set(aimbotEnabled)
SliderFOV:Set(FOVRadius)
ToggleShowFOV:Set(fovVisible)
ToggleKillCheck:Set(killCheckEnabled)
ToggleWallCheck:Set(wallCheckEnabled)
SliderHeadOffset:Set(HeadOffset)
ToggleBodyShot:Set(bodyShotModeEnabled)
SliderShotThreshold:Set(bodyShotThreshold)
ToggleRapidFire:Set(rapidFireEnabled)
SliderRapidDelay:Set(rapidFireDelay * 1000)
ToggleHoldToAim:Set(holdToAimEnabled)
KeybindAim:Set(aimKey.Name)
ToggleAimbotFullCapa:Set(aimbotFullCapa)
SliderAimbotFullCapaHP:Set(aimbotFullCapaHP)
ToggleAimlock:Set(aimlockEnabled)
ToggleAimlockShowFOV:Set(aimlockShowFOV)
SliderAimlockFOV:Set(aimlockFOV)
ToggleAimlockKillCheck:Set(aimlockKillCheck)
ToggleAimlockWallCheck:Set(aimlockWallCheck)
SliderBodyShotCount:Set(aimlockBodyShotCount)
ToggleHoldMode:Set(aimlockHoldEnabled)
KeybindAimlock:Set(aimlockKey.Name)
ToggleAimlockFullCapa:Set(aimlockFullCapa)
SliderAimlockFullCapaHP:Set(aimlockFullCapaHP)
SliderGlockDamage:Set(GLOCK_OVERRIDE.BaseDamage)
SliderGlockFirerate:Set(GLOCK_OVERRIDE.Firerate)
SliderGlockClip:Set(GLOCK_OVERRIDE.ClipSize)
SliderGlockBullet:Set(GLOCK_OVERRIDE.BulletSpeed)
SliderGlockReload:Set(GLOCK_OVERRIDE.ReloadTime)
SliderGlockMinSpread:Set(GLOCK_OVERRIDE.MinSpread)
SliderGlockMaxSpread:Set(GLOCK_OVERRIDE.MaxSpread)
ToggleGlockHeadshot:Set(GLOCK_OVERRIDE.HeadshotDamage)
SliderM4Damage:Set(M4A1_OVERRIDE.BaseDamage)
SliderM4Firerate:Set(M4A1_OVERRIDE.Firerate)
SliderM4Clip:Set(M4A1_OVERRIDE.ClipSize)
SliderM4Bullet:Set(M4A1_OVERRIDE.BulletSpeed)
SliderM4Reload:Set(M4A1_OVERRIDE.ReloadTime)
SliderM4MinSpread:Set(M4A1_OVERRIDE.MinSpread)
SliderM4MaxSpread:Set(M4A1_OVERRIDE.MaxSpread)
ToggleM4Headshot:Set(M4A1_OVERRIDE.HeadshotDamage)
ToggleM4Teamkill:Set(M4A1_OVERRIDE.CanTeamkill)
SliderGlobalDamage:Set(GLOBAL_DEFAULT_OVERRIDE.BaseDamage)
SliderGlobalFirerate:Set(GLOBAL_DEFAULT_OVERRIDE.Firerate)
SliderGlobalClip:Set(GLOBAL_DEFAULT_OVERRIDE.ClipSize)
SliderGlobalBullet:Set(GLOBAL_DEFAULT_OVERRIDE.BulletSpeed)
ToggleESPEnabled:Set(ESP_Config.Enabled)
SliderESPMaxDistance:Set(ESP_Config.MaxDistance)
ToggleESPTeamCheck:Set(ESP_Config.TeamCheck)
ToggleESPBoxes:Set(ESP_Config.Boxes)
ToggleESPNames:Set(ESP_Config.Names)
ToggleESPDistance:Set(ESP_Config.Distance)
ToggleESPHealth:Set(ESP_Config.Health)
ToggleESPSkeletons:Set(ESP_Config.Skeletons)
ToggleESPTracers:Set(ESP_Config.Tracers)
ColorpickerESPColor:Set(ESP_Config.ChamsColor)
ToggleESPVisibility:Set(ESP_Config.VisibilityCheck)
ToggleESPStreamproof:Set(ESP_Config.Streamproof)
SpinbotToggleElement:Set(spinbotEnabled)
SliderSpinSpeed:Set(spinSpeed)
ToggleFakeDash:Set(fakeDashEnabled)
SliderDashDistance:Set(DashDistance)
SliderDashCooldown:Set(DashCooldown * 1000)
ToggleFakeLag:Set(fakeLagEnabled)
SliderLagDistance:Set(LagDistance)
SliderLagCooldown:Set(LagCooldown * 1000)
ToggleFreeze:Set(freezePlayer)
ToggleHitbox:Set(hitboxExpanded)
SliderHitboxSize:Set(hitboxSize)
SliderHitboxTransparency:Set(hitboxTransparency * 100)
ToggleLegitHitbox:Set(legitAtivo)
SliderLegitHitboxSize:Set(legitTam)
ToggleAudioEnhancer:Set(audioEnhancerEnabled)
ToggleHitSound:Set(audioEnhancerEnabled)
ToggleDarkTheme:Set(true)
ToggleTransparency:Set(false)
ColorpickerAccent:Set(Color3.fromRGB(255, 15, 123))
KeybindToggle:Set("H")
ToggleNotifications:Set(true)
SliderNotifDuration:Set(3)
WindUI:Notify({
    Title = "Classic Hub vip.",
    Content = "Menu carregado.",
    Duration = 5,
    Icon = "check"
})
