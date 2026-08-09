--[[
    Demonology Hub X Blix
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local States = {
    GhostESP = false,
    PlayerESP = false,
    GhostTracers = false,
    PlayerTracers = false,
    Fullbright = false,
    NoFog = false,
    Speed = false,
    Noclip = false,
    Fly = false,
    ThirdPerson = false,
    AntiAFK = false
}

local SpeedMultiplier = 2

local Colors = {
    GhostESP = Color3.fromRGB(180, 70, 255),
    PlayerESP = Color3.fromRGB(80, 180, 255),
    GhostTracer = Color3.fromRGB(200, 80, 255),
    PlayerTracer = Color3.fromRGB(80, 180, 255)
}

local MenuColors = {
    Background = Color3.fromRGB(0, 0, 0),
    Title = Color3.fromRGB(18, 12, 28),
    Accent = Color3.fromRGB(130, 70, 200)
}

local Keybinds = {
    ToggleGUI = Enum.KeyCode.RightControl,
    Fly = Enum.KeyCode.F,
    Speed = Enum.KeyCode.V,
    Noclip = Enum.KeyCode.N
}

local Connections = {}
local FlyBV, FlyBG = nil, nil
local Tracers = { Ghost = nil, Players = {} }
local GhostBox = nil
local PlayerBoxes = {}
local WaitingForKey = nil
local CurrentColorCallback = nil
local MenuOpen = true
local CachedGhost = nil
local LastGhostSearch = 0

local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local OriginalFOV = Camera.FieldOfView

local function ResetESP()
    if GhostBox then pcall(function() GhostBox:Remove() end) GhostBox = nil end
    if Tracers.Ghost then pcall(function() Tracers.Ghost:Remove() end) Tracers.Ghost = nil end
    for _, box in pairs(PlayerBoxes) do pcall(function() box:Remove() end) end
    PlayerBoxes = {}
    for _, line in pairs(Tracers.Players) do pcall(function() line:Remove() end) end
    Tracers.Players = {}
    CachedGhost = nil
    StarterGui:SetCore("SendNotification", {Title = "ESP Reset", Text = "All ESP has been reset", Duration = 2})
end

local function FindGhost()
    if CachedGhost and CachedGhost.Parent then return CachedGhost end
    local interval = (States.GhostESP or States.GhostTracers) and 0.066 or 1.5
    if tick() - LastGhostSearch < interval then return nil end
    LastGhostSearch = tick()

    local ghost = workspace:FindFirstChild("Ghost") 
        or workspace:FindFirstChild("ghost")
        or workspace:FindFirstChild("GhostModel")
        or workspace:FindFirstChild("Entity")

    if not ghost then
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") and (obj.Name:lower():find("ghost") or obj:GetAttribute("IsGhost")) then
                ghost = obj
                break
            end
        end
    end
    CachedGhost = ghost
    return ghost
end

-- corraded by blix

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DemonologyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 400, 0, 580)
Main.Position = UDim2.new(0.02, 0, 0.05, 0)
Main.BackgroundColor3 = MenuColors.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke")
Stroke.Color = MenuColors.Accent
Stroke.Thickness = 2.4
Stroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = MenuColors.Title
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 14)
TitleFix.Position = UDim2.new(0, 0, 1, -14)
TitleFix.BackgroundColor3 = MenuColors.Title
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "👻 Demonology Hub X Blix"
Title.TextColor3 = Color3.fromRGB(220, 185, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -36, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 60)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 110, 110)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -16, 0, 34)
TabBar.Position = UDim2.new(0, 8, 0, 48)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local TabNames = {"Info", "Player", "Visuals", "Settings"}
local TabButtons = {}
local Pages = {}

for i, name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, -4, 1, 0)
    btn.Position = UDim2.new((i-1)*0.25, 2, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 160, 180)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    TabButtons[name] = btn
end

local PagesFrame = Instance.new("Frame")
PagesFrame.Size = UDim2.new(1, -16, 1, -95)
PagesFrame.Position = UDim2.new(0, 8, 0, 90)
PagesFrame.BackgroundTransparency = 1
PagesFrame.Parent = Main

local function CreatePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(130, 80, 200)
    page.Visible = false
    page.CanvasSize = UDim2.new(0, 0, 0, 560)
    page.Parent = PagesFrame
    Pages[name] = page
    return page
end

local InfoPage = CreatePage("Info")
local PlayerPage = CreatePage("Player")
local VisualsPage = CreatePage("Visuals")
local SettingsPage = CreatePage("Settings")

local function CreateInfoCard(parent, title, y)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 58)
    card.Position = UDim2.new(0, 0, 0, y)
    card.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -16, 0, 18)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(140, 130, 170)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 11
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -16, 0, 24)
    valueLabel.Position = UDim2.new(0, 12, 0, 26)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "—"
    valueLabel.TextColor3 = Color3.fromRGB(240, 235, 255)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 15
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.Parent = card
    return valueLabel
end

local function CreateToggle(parent, name, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 1, 0)
    nameLabel.Position = UDim2.new(0, 14, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(225, 225, 235)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 18, 0, 18)
    indicator.Position = UDim2.new(1, -32, 0.5, -9)
    indicator.BackgroundColor3 = Color3.fromRGB(50, 48, 60)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        indicator.BackgroundColor3 = enabled and Color3.fromRGB(150, 90, 240) or Color3.fromRGB(50, 48, 60)
        callback(enabled)
    end)
    return btn
end

local function CreateButton(parent, name, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(70, 45, 110)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(235, 220, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateSectionLabel(parent, text, y)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 22)
    label.Position = UDim2.new(0, 0, 0, y)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(160, 120, 220)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
end

local function CreateKeybindButton(parent, name, y, currentKey, keyName)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 14, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = btn

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.38, -8, 0, 24)
    keyLabel.Position = UDim2.new(0.58, 0, 0.5, -12)
    keyLabel.BackgroundColor3 = Color3.fromRGB(45, 35, 65)
    keyLabel.Text = currentKey.Name
    keyLabel.TextColor3 = Color3.fromRGB(210, 180, 255)
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextSize = 12
    keyLabel.Parent = btn
    Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        if WaitingForKey then return end
        WaitingForKey = keyName
        keyLabel.Text = "..."
        keyLabel.BackgroundColor3 = Color3.fromRGB(140, 50, 50)
    end)
    return keyLabel
end

local ColorPicker = Instance.new("Frame")
ColorPicker.Size = UDim2.new(0, 340, 0, 160)
ColorPicker.Position = UDim2.new(0.5, -170, 0.5, -80)
ColorPicker.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
ColorPicker.BorderSizePixel = 0
ColorPicker.Visible = false
ColorPicker.ZIndex = 20
ColorPicker.Parent = ScreenGui
Instance.new("UICorner", ColorPicker).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ColorPicker).Color = Color3.fromRGB(130, 70, 200)

local CPTitle = Instance.new("TextLabel")
CPTitle.Size = UDim2.new(1, 0, 0, 26)
CPTitle.BackgroundTransparency = 1
CPTitle.Text = "Select Color"
CPTitle.TextColor3 = Color3.fromRGB(220, 200, 255)
CPTitle.Font = Enum.Font.GothamBold
CPTitle.TextSize = 13
CPTitle.Parent = ColorPicker

local function OpenColorPicker(callback)
    CurrentColorCallback = callback
    ColorPicker.Visible = true
end

local function CreatePalette()
    local hues = {0, 20, 40, 60, 90, 120, 150, 180, 200, 220, 240, 260, 280, 300, 320, 0}
    for row = 0, 4 do
        for col = 0, 15 do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 18, 0, 18)
            btn.Position = UDim2.new(0, 12 + col * 20, 0, 32 + row * 22)
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 21
            btn.Parent = ColorPicker
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local color = col == 15 and Color3.fromRGB((1-row/4)*255, (1-row/4)*255, (1-row/4)*255)
                or Color3.fromHSV(hues[col+1]/360, 1, 1 - (row/4)*0.85)
            btn.BackgroundColor3 = color
            btn.MouseButton1Click:Connect(function()
                if CurrentColorCallback then CurrentColorCallback(color) end
                ColorPicker.Visible = false
                CurrentColorCallback = nil
            end)
        end
    end
end
CreatePalette()

local ClosePickerBtn = Instance.new("TextButton")
ClosePickerBtn.Size = UDim2.new(0, 60, 0, 22)
ClosePickerBtn.Position = UDim2.new(1, -70, 0, 4)
ClosePickerBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
ClosePickerBtn.Text = "Close"
ClosePickerBtn.TextColor3 = Color3.fromRGB(220, 200, 255)
ClosePickerBtn.Font = Enum.Font.Gotham
ClosePickerBtn.TextSize = 11
ClosePickerBtn.ZIndex = 21
ClosePickerBtn.Parent = ColorPicker
Instance.new("UICorner", ClosePickerBtn).CornerRadius = UDim.new(0, 5)
ClosePickerBtn.MouseButton1Click:Connect(function()
    ColorPicker.Visible = false
    CurrentColorCallback = nil
end)

local function CreateColorPair(parent, name1, name2, y, color1, color2, callback1, callback2)
    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(0.48, 0, 0, 36)
    btn1.Position = UDim2.new(0, 0, 0, y)
    btn1.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    btn1.Text = ""
    btn1.AutoButtonColor = false
    btn1.Parent = parent
    Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 9)

    local label1 = Instance.new("TextLabel")
    label1.Size = UDim2.new(1, -40, 1, 0)
    label1.Position = UDim2.new(0, 10, 0, 0)
    label1.BackgroundTransparency = 1
    label1.Text = name1
    label1.TextColor3 = Color3.fromRGB(220, 220, 230)
    label1.Font = Enum.Font.GothamMedium
    label1.TextSize = 12
    label1.TextXAlignment = Enum.TextXAlignment.Left
    label1.Parent = btn1

    local box1 = Instance.new("Frame")
    box1.Size = UDim2.new(0, 18, 0, 18)
    box1.Position = UDim2.new(1, -28, 0.5, -9)
    box1.BackgroundColor3 = color1
    box1.Parent = btn1
    Instance.new("UICorner", box1).CornerRadius = UDim.new(0, 5)

    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0.48, 0, 0, 36)
    btn2.Position = UDim2.new(0.52, 0, 0, y)
    btn2.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    btn2.Text = ""
    btn2.AutoButtonColor = false
    btn2.Parent = parent
    Instance.new("UICorner", btn2).CornerRadius = UDim.new(0, 9)

    local label2 = Instance.new("TextLabel")
    label2.Size = UDim2.new(1, -40, 1, 0)
    label2.Position = UDim2.new(0, 10, 0, 0)
    label2.BackgroundTransparency = 1
    label2.Text = name2
    label2.TextColor3 = Color3.fromRGB(220, 220, 230)
    label2.Font = Enum.Font.GothamMedium
    label2.TextSize = 12
    label2.TextXAlignment = Enum.TextXAlignment.Left
    label2.Parent = btn2

    local box2 = Instance.new("Frame")
    box2.Size = UDim2.new(0, 18, 0, 18)
    box2.Position = UDim2.new(1, -28, 0.5, -9)
    box2.BackgroundColor3 = color2
    box2.Parent = btn2
    Instance.new("UICorner", box2).CornerRadius = UDim.new(0, 5)

    btn1.MouseButton1Click:Connect(function()
        OpenColorPicker(function(c) box1.BackgroundColor3 = c callback1(c) end)
    end)
    btn2.MouseButton1Click:Connect(function()
        OpenColorPicker(function(c) box2.BackgroundColor3 = c callback2(c) end)
    end)
end

local function CreateColorButton(parent, name, y, currentColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 9)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -50, 1, 0)
    nameLabel.Position = UDim2.new(0, 14, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = btn

    local colorBox = Instance.new("Frame")
    colorBox.Size = UDim2.new(0, 20, 0, 20)
    colorBox.Position = UDim2.new(1, -34, 0.5, -10)
    colorBox.BackgroundColor3 = currentColor
    colorBox.Parent = btn
    Instance.new("UICorner", colorBox).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        OpenColorPicker(function(c) colorBox.BackgroundColor3 = c callback(c) end)
    end)
end

local GhostTypeLabel   = CreateInfoCard(InfoPage, "GHOST TYPE", 8)
local GhostRoomLabel   = CreateInfoCard(InfoPage, "GHOST ROOM (Favorite)", 74)
local CurrentRoomLabel = CreateInfoCard(InfoPage, "CURRENT ROOM", 140)
local EnergyLabel      = CreateInfoCard(InfoPage, "YOUR ENERGY", 206)

CreateButton(InfoPage, "📋 Copy Ghost Info", 285, function()
    local text = string.format("Ghost Type: %s\nGhost Room: %s\nCurrent Room: %s",
        GhostTypeLabel.Text, GhostRoomLabel.Text, CurrentRoomLabel.Text)
    setclipboard(text)
    StarterGui:SetCore("SendNotification", {Title = "Demonology Hub X Blix", Text = "Ghost info copied!", Duration = 2})
end)

-- corraded by blix

CreateSectionLabel(PlayerPage, "MOVEMENT", 5)
CreateToggle(PlayerPage, "Speed Boost", 30, function(state)
    States.Speed = state
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.WalkSpeed = state and (16 * SpeedMultiplier) or 16
    end
end)
CreateToggle(PlayerPage, "Noclip", 74, function(state) States.Noclip = state end)
CreateToggle(PlayerPage, "Fly", 118, function(state)
    States.Fly = state
    if state then
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            FlyBV.Parent = RootPart
            FlyBG = Instance.new("BodyGyro")
            FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            FlyBG.P = 9e4
            FlyBG.Parent = RootPart
        end
    else
        if FlyBV then FlyBV:Destroy() FlyBV = nil end
        if FlyBG then FlyBG:Destroy() FlyBG = nil end
    end
end)

CreateSectionLabel(PlayerPage, "CAMERA & UTILITY", 170)
CreateToggle(PlayerPage, "Third Person", 195, function(state)
    States.ThirdPerson = state
    if state then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = 20
        LocalPlayer.CameraMinZoomDistance = 5
    else
        LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end)
CreateToggle(PlayerPage, "Anti AFK", 239, function(state) States.AntiAFK = state end)
CreateButton(PlayerPage, "Sit / Stand", 283, function()
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.Sit = not Character.Humanoid.Sit
    end
end)
CreateButton(PlayerPage, "Reset", 327, function()
    if Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.Health = 0
    end
end)

CreateSectionLabel(VisualsPage, "ESP & TRACERS", 5)
CreateToggle(VisualsPage, "Ghost ESP", 30, function(state)
    States.GhostESP = state
    if not state and GhostBox then pcall(function() GhostBox:Remove() end) GhostBox = nil end
end)
CreateToggle(VisualsPage, "Ghost Tracers", 74, function(state)
    States.GhostTracers = state
    if not state and Tracers.Ghost then pcall(function() Tracers.Ghost:Remove() end) Tracers.Ghost = nil end
end)
CreateToggle(VisualsPage, "Player ESP", 118, function(state)
    States.PlayerESP = state
    if not state then
        for _, box in pairs(PlayerBoxes) do pcall(function() box:Remove() end) end
        PlayerBoxes = {}
    end
end)
CreateToggle(VisualsPage, "Player Tracers", 162, function(state)
    States.PlayerTracers = state
    if not state then
        for _, line in pairs(Tracers.Players) do pcall(function() line:Remove() end) end
        Tracers.Players = {}
    end
end)
CreateButton(VisualsPage, "🔄 Reset ESP", 216, ResetESP)

CreateSectionLabel(VisualsPage, "WORLD", 270)
CreateToggle(VisualsPage, "Fullbright", 295, function(state)
    States.Fullbright = state
    if state then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
    else
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.ClockTime = OriginalLighting.ClockTime
        Lighting.GlobalShadows = OriginalLighting.GlobalShadows
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    end
end)
CreateToggle(VisualsPage, "No Fog", 339, function(state)
    States.NoFog = state
    Lighting.FogEnd = state and 100000 or OriginalLighting.FogEnd
end)

CreateSectionLabel(SettingsPage, "ESP / TRACER COLORS", 5)
CreateColorPair(SettingsPage, "Ghost ESP", "Ghost Tracer", 30, Colors.GhostESP, Colors.GhostTracer,
    function(c) Colors.GhostESP = c end,
    function(c) Colors.GhostTracer = c if Tracers.Ghost then Tracers.Ghost.Color = c end end)
CreateColorPair(SettingsPage, "Player ESP", "Player Tracer", 74, Colors.PlayerESP, Colors.PlayerTracer,
    function(c) Colors.PlayerESP = c end,
    function(c) Colors.PlayerTracer = c for _,l in pairs(Tracers.Players) do if l then l.Color = c end end end)

CreateSectionLabel(SettingsPage, "MENU COLORS", 128)
CreateColorPair(SettingsPage, "Background", "Title Bar", 153, MenuColors.Background, MenuColors.Title,
    function(c) MenuColors.Background = c Main.BackgroundColor3 = c end,
    function(c) MenuColors.Title = c TitleBar.BackgroundColor3 = c TitleFix.BackgroundColor3 = c end)
CreateColorButton(SettingsPage, "Accent Color", 197, MenuColors.Accent, function(c)
    MenuColors.Accent = c
    Stroke.Color = c
end)

CreateSectionLabel(SettingsPage, "SPEED MULTIPLIER", 250)
local SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Size = UDim2.new(1, 0, 0, 18)
SpeedValueLabel.Position = UDim2.new(0, 0, 0, 276)
SpeedValueLabel.BackgroundTransparency = 1
SpeedValueLabel.Text = "2.0x"
SpeedValueLabel.TextColor3 = Color3.fromRGB(210, 180, 255)
SpeedValueLabel.Font = Enum.Font.GothamBold
SpeedValueLabel.TextSize = 14
SpeedValueLabel.Parent = SettingsPage

local SliderBg = Instance.new("Frame")
SliderBg.Size = UDim2.new(1, 0, 0, 10)
SliderBg.Position = UDim2.new(0, 0, 0, 302)
SliderBg.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
SliderBg.Parent = SettingsPage
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.25, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(150, 90, 240)
SliderFill.Parent = SliderBg
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderBtn = Instance.new("TextButton")
SliderBtn.Size = UDim2.new(0, 18, 0, 18)
SliderBtn.Position = UDim2.new(0.25, -9, 0.5, -9)
SliderBtn.BackgroundColor3 = Color3.fromRGB(230, 210, 255)
SliderBtn.Text = ""
SliderBtn.Parent = SliderBg
Instance.new("UICorner", SliderBtn).CornerRadius = UDim.new(1, 0)

local sliding = false
local function UpdateSpeedFromSlider(x)
    local relative = math.clamp(x / SliderBg.AbsoluteSize.X, 0, 1)
    SpeedMultiplier = math.floor((1 + relative * 4) * 10 + 0.5) / 10
    SliderFill.Size = UDim2.new(relative, 0, 1, 0)
    SliderBtn.Position = UDim2.new(relative, -9, 0.5, -9)
    SpeedValueLabel.Text = string.format("%.1fx", SpeedMultiplier)
    if States.Speed and Character and Character:FindFirstChild("Humanoid") then
        Character.Humanoid.WalkSpeed = 16 * SpeedMultiplier
    end
end

SliderBtn.MouseButton1Down:Connect(function() sliding = true end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
UserInputService.InputChanged:Connect(function(i)
    if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
        UpdateSpeedFromSlider(UserInputService:GetMouseLocation().X - SliderBg.AbsolutePosition.X)
    end
end)
SliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        sliding = true
        UpdateSpeedFromSlider(UserInputService:GetMouseLocation().X - SliderBg.AbsolutePosition.X)
    end
end)

CreateSectionLabel(SettingsPage, "KEYBINDS", 345)
local KeyLabels = {}
KeyLabels.ToggleGUI = CreateKeybindButton(SettingsPage, "Toggle GUI", 370, Keybinds.ToggleGUI, "ToggleGUI")
KeyLabels.Fly       = CreateKeybindButton(SettingsPage, "Fly", 414, Keybinds.Fly, "Fly")
KeyLabels.Speed     = CreateKeybindButton(SettingsPage, "Speed Boost", 458, Keybinds.Speed, "Speed")
KeyLabels.Noclip    = CreateKeybindButton(SettingsPage, "Noclip", 502, Keybinds.Noclip, "Noclip")

local function SwitchTab(name)
    for n, p in pairs(Pages) do p.Visible = (n == name) end
    for n, b in pairs(TabButtons) do
        if n == name then
            b.BackgroundColor3 = Color3.fromRGB(100, 60, 170)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
            b.TextColor3 = Color3.fromRGB(160, 160, 180)
        end
    end
end
for n, b in pairs(TabButtons) do b.MouseButton1Click:Connect(function() SwitchTab(n) end) end
SwitchTab("Info")

local ConfirmFrame = Instance.new("Frame")
ConfirmFrame.Size = UDim2.new(0, 280, 0, 140)
ConfirmFrame.Position = UDim2.new(0.5, -140, 0.5, -70)
ConfirmFrame.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
ConfirmFrame.Visible = false
ConfirmFrame.ZIndex = 10
ConfirmFrame.Parent = ScreenGui
Instance.new("UICorner", ConfirmFrame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", ConfirmFrame).Color = Color3.fromRGB(140, 70, 200)

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -20, 0, 30)
ConfirmTitle.Position = UDim2.new(0, 10, 0, 12)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "Unload Script?"
ConfirmTitle.TextColor3 = Color3.fromRGB(230, 200, 255)
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextSize = 16
ConfirmTitle.Parent = ConfirmFrame

local ConfirmText = Instance.new("TextLabel")
ConfirmText.Size = UDim2.new(1, -20, 0, 30)
ConfirmText.Position = UDim2.new(0, 10, 0, 42)
ConfirmText.BackgroundTransparency = 1
ConfirmText.Text = "This will fully remove the script."
ConfirmText.TextColor3 = Color3.fromRGB(180, 180, 200)
ConfirmText.Font = Enum.Font.Gotham
ConfirmText.TextSize = 13
ConfirmText.Parent = ConfirmFrame

local YesBtn = Instance.new("TextButton")
YesBtn.Size = UDim2.new(0, 110, 0, 34)
YesBtn.Position = UDim2.new(0, 20, 1, -50)
YesBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 70)
YesBtn.Text = "Yes, Unload"
YesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
YesBtn.Font = Enum.Font.GothamBold
YesBtn.TextSize = 13
YesBtn.Parent = ConfirmFrame
Instance.new("UICorner", YesBtn).CornerRadius = UDim.new(0, 8)

local NoBtn = Instance.new("TextButton")
NoBtn.Size = UDim2.new(0, 110, 0, 34)
NoBtn.Position = UDim2.new(1, -130, 1, -50)
NoBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
NoBtn.Text = "Cancel"
NoBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
NoBtn.Font = Enum.Font.GothamBold
NoBtn.TextSize = 13
NoBtn.Parent = ConfirmFrame
Instance.new("UICorner", NoBtn).CornerRadius = UDim.new(0, 8)

local function UnloadScript()
    if Character and Character:FindFirstChild("Humanoid") then Character.Humanoid.WalkSpeed = 16 end
    if Character then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
    ResetESP()
    if FlyBV then FlyBV:Destroy() end
    if FlyBG then FlyBG:Destroy() end
    Camera.FieldOfView = OriginalFOV
    LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
    Lighting.Brightness = OriginalLighting.Brightness
    Lighting.ClockTime = OriginalLighting.ClockTime
    Lighting.FogEnd = OriginalLighting.FogEnd
    Lighting.GlobalShadows = OriginalLighting.GlobalShadows
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    for _, c in pairs(Connections) do if typeof(c) == "RBXScriptConnection" then c:Disconnect() end end
    ScreenGui:Destroy()
    print("[Demonology Hub X Blix] Unloaded")
end

CloseBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = true end)
YesBtn.MouseButton1Click:Connect(UnloadScript)
NoBtn.MouseButton1Click:Connect(function() ConfirmFrame.Visible = false end)

local function SetMenuOpen(open)
    MenuOpen = open
    Main.Visible = open
end

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if WaitingForKey then
        Keybinds[WaitingForKey] = input.KeyCode
        if KeyLabels[WaitingForKey] then
            KeyLabels[WaitingForKey].Text = input.KeyCode.Name
            KeyLabels[WaitingForKey].BackgroundColor3 = Color3.fromRGB(45, 35, 65)
        end
        WaitingForKey = nil
        return
    end

    if input.KeyCode == Keybinds.ToggleGUI then
        SetMenuOpen(not MenuOpen)
        if not MenuOpen then ConfirmFrame.Visible = false end
    elseif input.KeyCode == Keybinds.Fly then
        States.Fly = not States.Fly
        if States.Fly then
            if not FlyBV then
                FlyBV = Instance.new("BodyVelocity")
                FlyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                FlyBV.Parent = RootPart
                FlyBG = Instance.new("BodyGyro")
                FlyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                FlyBG.P = 9e4
                FlyBG.Parent = RootPart
            end
        else
            if FlyBV then FlyBV:Destroy() FlyBV = nil end
            if FlyBG then FlyBG:Destroy() FlyBG = nil end
        end
    elseif input.KeyCode == Keybinds.Speed then
        States.Speed = not States.Speed
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = States.Speed and (16 * SpeedMultiplier) or 16
        end
    elseif input.KeyCode == Keybinds.Noclip then
        States.Noclip = not States.Noclip
    end
end))

local function CreateTracer(color)
    local ok, line = pcall(function() return Drawing.new("Line") end)
    if ok and line then
        line.Visible = false
        line.Color = color
        line.Thickness = 1.5
        line.Transparency = 1
        return line
    end
end

local function CreateBox(color)
    local ok, box = pcall(function() return Drawing.new("Square") end)
    if ok and box then
        box.Visible = false
        box.Color = color
        box.Thickness = 2
        box.Filled = false
        box.Transparency = 1
        return box
    end
end

local function GetBoxData(part, height)
    height = height or 5
    local top = part.Position + Vector3.new(0, height/2, 0)
    local bottom = part.Position - Vector3.new(0, height/2, 0)
    local topPos, topVis = Camera:WorldToViewportPoint(top)
    local bottomPos, bottomVis = Camera:WorldToViewportPoint(bottom)
    if not topVis and not bottomVis then return nil end
    local h = math.clamp(math.abs(topPos.Y - bottomPos.Y), 25, 300)
    local w = math.clamp(h * 0.6, 15, 180)
    local cx = (topPos.X + bottomPos.X) / 2
    local cy = (topPos.Y + bottomPos.Y) / 2
    return { Position = Vector2.new(cx - w/2, cy - h/2), Size = Vector2.new(w, h) }
end

local function GetGhostData()
    local data = { Type = "Unknown", Room = "Unknown", CurrentRoom = "Unknown", Energy = "—" }
    local ghost = FindGhost()
    local rs = game:GetService("ReplicatedStorage")

    for _, src in pairs({rs:FindFirstChild("GhostData"), rs:FindFirstChild("GameData"), rs:FindFirstChild("RoundData")}) do
        if src then
            for _, n in pairs({"GhostType", "Type", "Ghost", "CurrentGhost"}) do
                local v = src:FindFirstChild(n)
                if v and v:IsA("StringValue") and v.Value ~= "" and v.Value:lower() ~= "ghost" then
                    data.Type = v.Value
                    break
                end
            end
        end
    end

    if ghost then
        for _, a in pairs({"GhostType", "Type", "Name"}) do
            local v = ghost:GetAttribute(a)
            if v and tostring(v) ~= "" and tostring(v):lower() ~= "ghost" then
                data.Type = tostring(v)
                break
            end
        end
        for _, n in pairs({"FavoriteRoom", "GhostRoom", "Room"}) do
            local v = ghost:GetAttribute(n) or (ghost:FindFirstChild(n) and ghost[n].Value)
            if v and tostring(v) ~= "" then data.Room = tostring(v) break end
        end
        local part = ghost.PrimaryPart or ghost:FindFirstChildWhichIsA("BasePart")
        if part then
            local curr = ghost:GetAttribute("CurrentRoom")
            if curr then data.CurrentRoom = tostring(curr)
            else
                local p = part.Parent
                while p and p ~= workspace do
                    if not p.Name:lower():find("ghost") then data.CurrentRoom = p.Name break end
                    p = p.Parent
                end
            end
        end
    end

    local function findEnergy(obj)
        if not obj then return end
        for _, n in pairs({"Energy", "energy"}) do
            local v = obj:FindFirstChild(n)
            if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then return v.Value end
        end
    end
    local e = findEnergy(LocalPlayer) or findEnergy(Character)
    if e then data.Energy = math.floor(e) .. "%" end
    return data
end

local lastUpdate = 0
local lastAFK = 0

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if MenuOpen then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    if States.GhostESP or States.GhostTracers then
        local ghost = FindGhost()
        if ghost and ghost:IsA("Model") then
            local part = ghost.PrimaryPart or ghost:FindFirstChildWhichIsA("BasePart")
            if part then
                if States.GhostTracers then
                    if not Tracers.Ghost then Tracers.Ghost = CreateTracer(Colors.GhostTracer) end
                    if Tracers.Ghost then
                        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen and pos.Z > 0 then
                            Tracers.Ghost.From = screenCenter
                            Tracers.Ghost.To = Vector2.new(pos.X, pos.Y)
                            Tracers.Ghost.Color = Colors.GhostTracer
                            Tracers.Ghost.Visible = true
                        else Tracers.Ghost.Visible = false end
                    end
                elseif Tracers.Ghost then Tracers.Ghost.Visible = false end

                if States.GhostESP then
                    if not GhostBox then GhostBox = CreateBox(Colors.GhostESP) end
                    if GhostBox then
                        local boxData = GetBoxData(part, 6)
                        if boxData then
                            GhostBox.Size = boxData.Size
                            GhostBox.Position = boxData.Position
                            GhostBox.Color = Colors.GhostESP
                            GhostBox.Visible = true
                        else GhostBox.Visible = false end
                    end
                elseif GhostBox then GhostBox.Visible = false end
            end
        else
            if Tracers.Ghost then Tracers.Ghost.Visible = false end
            if GhostBox then GhostBox.Visible = false end
        end
    else
        if Tracers.Ghost then Tracers.Ghost.Visible = false end
        if GhostBox then GhostBox.Visible = false end
    end

    if States.PlayerESP or States.PlayerTracers then
        local active = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                local name = plr.Name
                active[name] = true
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                if States.PlayerTracers then
                    if not Tracers.Players[name] then Tracers.Players[name] = CreateTracer(Colors.PlayerTracer) end
                    local line = Tracers.Players[name]
                    if line then
                        if onScreen and pos.Z > 0 then
                            line.From = screenCenter
                            line.To = Vector2.new(pos.X, pos.Y)
                            line.Color = Colors.PlayerTracer
                            line.Visible = true
                        else line.Visible = false end
                    end
                end

                if States.PlayerESP then
                    if not PlayerBoxes[name] then PlayerBoxes[name] = CreateBox(Colors.PlayerESP) end
                    local box = PlayerBoxes[name]
                    if box then
                        local boxData = GetBoxData(hrp, 5)
                        if boxData then
                            box.Size = boxData.Size
                            box.Position = boxData.Position
                            box.Color = Colors.PlayerESP
                            box.Visible = true
                        else box.Visible = false end
                    end
                end
            end
        end
        for name, box in pairs(PlayerBoxes) do
            if not active[name] then pcall(function() box:Remove() end) PlayerBoxes[name] = nil end
        end
        for name, line in pairs(Tracers.Players) do
            if not active[name] then pcall(function() line:Remove() end) Tracers.Players[name] = nil end
        end
    end
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if States.Noclip and Character then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    if States.Fly and FlyBV and RootPart then
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0,1,0) end
        FlyBV.Velocity = move.Magnitude > 0 and move.Unit * 60 or Vector3.zero
        FlyBG.CFrame = cam.CFrame
    end

    if States.AntiAFK and tick() - lastAFK > 30 then
        lastAFK = tick()
        pcall(function()
            local vim = game:GetService("VirtualUser")
            vim:CaptureController()
            vim:ClickButton2(Vector2.new())
        end)
    end

    if not MenuOpen then return end
    if tick() - lastUpdate < 0.8 then return end
    lastUpdate = tick()

    local info = GetGhostData()
    GhostTypeLabel.Text = info.Type
    GhostRoomLabel.Text = info.Room
    CurrentRoomLabel.Text = info.CurrentRoom
    EnergyLabel.Text = info.Energy
end))

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    if States.Speed then Humanoid.WalkSpeed = 16 * SpeedMultiplier end
    if States.Fly then
        if FlyBV then FlyBV:Destroy() end
        if FlyBG then FlyBG:Destroy() end
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.MaxForce = Vector3.new(9e9,9e9,9e9)
        FlyBV.Parent = RootPart
        FlyBG = Instance.new("BodyGyro")
        FlyBG.MaxTorque = Vector3.new(9e9,9e9,9e9)
        FlyBG.P = 9e4
        FlyBG.Parent = RootPart
    end
end))

table.insert(Connections, Players.PlayerRemoving:Connect(function(plr)
    local name = plr.Name
    if PlayerBoxes[name] then pcall(function() PlayerBoxes[name]:Remove() end) PlayerBoxes[name] = nil end
    if Tracers.Players[name] then pcall(function() Tracers.Players[name]:Remove() end) Tracers.Players[name] = nil end
end))

-- corraded by blix

SetMenuOpen(true)
print("[Demonology Hub X Blix] Loaded")
