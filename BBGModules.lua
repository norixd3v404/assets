-- ============================================================
--  BBGModules.lua
--  GitHub pe upload karo — BBGMain.lua ise automatically load karega
--  Ye file apna koi UI nahi banati — sirf BBG Panel mein tabs inject karti hai
-- ============================================================

-- BBGMain se shared vars lo
local BBG                 = _G.BBG
local Players             = BBG.Players
local RunService          = BBG.RunService
local VirtualInputManager = BBG.VirtualInputManager
local player              = BBG.player
local LP                  = BBG.LP
local mouse               = BBG.mouse
local mainFrame           = BBG.mainFrame
local screenGui           = BBG.screenGui
local createSidebarTab    = BBG.createSidebarTab
local createPageScroll    = BBG.createPageScroll
local createSwitch        = BBG.createSwitch
local createInputBox      = BBG.createInputBox
local switchPage          = BBG.switchPage
local allPages            = BBG.allPages
local allTabButtons       = BBG.allTabButtons

-- ============================================================
--  BACKEND: SORU SILENT
-- ============================================================
local soruSilentEnabled  = false
local cachedTarget       = nil
local infiniteSoruEnabled = false

pcall(function()
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if self == mouse and (key == "Hit" or key == "Target") then
            if soruSilentEnabled and cachedTarget then
                local target = Players:FindFirstChild(cachedTarget)
                local eHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if eHRP then
                    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if myHRP then
                        local dist = (eHRP.Position - myHRP.Position).Magnitude
                        if dist <= 2000 then
                            if key == "Hit" then return CFrame.new(eHRP.Position) end
                            if key == "Target" then return eHRP end
                        end
                    end
                end
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end)

RunService.Heartbeat:Connect(function()
    if infiniteSoruEnabled and LP.Character then
        pcall(function() LP.Character:SetAttribute("FlashstepCooldown", 1) end)
    end
end)

-- ============================================================
--  BACKEND: RAJAWARE LAG
-- ============================================================
local RajawareLagEnabled = false
local _RajawareLagLoop   = nil

local function stopRajawareLag()
    if _RajawareLagLoop then
        pcall(function() _RajawareLagLoop:Disconnect() end)
        _RajawareLagLoop = nil
    end
end

local function startRajawareLag()
    stopRajawareLag()
    local INTERVAL = 1 / 20
    _RajawareLagLoop = RunService.RenderStepped:Connect(function()
        if not RajawareLagEnabled then stopRajawareLag(); return end
        local start = tick()
        while tick() - start < INTERVAL do end
    end)
end

-- ============================================================
--  BACKEND: SORU DETECTOR SLOT VARS
-- ============================================================
local slot1 = { type = "None", move = "None", active = false }
local slot2 = { type = "None", move = "None", active = false }

-- ============================================================
--  MINI WINDOW: SORU SILENT
-- ============================================================
local _SoruMiniGui = Instance.new("ScreenGui")
_SoruMiniGui.Name = "SoruDetectorMiniGui"
_SoruMiniGui.ResetOnSpawn = false
_SoruMiniGui.DisplayOrder = 1002
_SoruMiniGui.Parent = game:GetService("CoreGui")
_SoruMiniGui.Enabled = false

local _SoruMiniMain = Instance.new("Frame", _SoruMiniGui)
_SoruMiniMain.Size = UDim2.new(0, 190, 0, 129)
_SoruMiniMain.Position = UDim2.new(0.1, 0, 0.45, 0)
_SoruMiniMain.Active = true; _SoruMiniMain.Draggable = true
_SoruMiniMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
_SoruMiniMain.BackgroundTransparency = 0.1
Instance.new("UICorner", _SoruMiniMain).CornerRadius = UDim.new(0, 10)

local _sMinBtn = Instance.new("TextButton", _SoruMiniMain)
_sMinBtn.Size = UDim2.new(0, 35, 0, 25); _sMinBtn.Position = UDim2.new(0, 5, 0, -28)
_sMinBtn.Text = "-"; _sMinBtn.Font = Enum.Font.RobotoMono
_sMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255); _sMinBtn.TextSize = 25
_sMinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); _sMinBtn.BackgroundTransparency = 0.1
Instance.new("UICorner", _sMinBtn).CornerRadius = UDim.new(0, 6)

local _sMaxBtn = Instance.new("TextButton", _SoruMiniMain)
_sMaxBtn.Size = UDim2.new(0, 35, 0, 25); _sMaxBtn.Position = UDim2.new(0, 5, 0, -28)
_sMaxBtn.Text = "+"; _sMaxBtn.Font = Enum.Font.RobotoMono
_sMaxBtn.TextColor3 = Color3.fromRGB(255, 255, 255); _sMaxBtn.TextSize = 20
_sMaxBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); _sMaxBtn.BackgroundTransparency = 0.1
_sMaxBtn.Visible = false
Instance.new("UICorner", _sMaxBtn).CornerRadius = UDim.new(0, 6)

local _sTitle = Instance.new("TextLabel", _SoruMiniMain)
_sTitle.Size = UDim2.new(0, 178, 0, 24); _sTitle.Position = UDim2.new(0, 6, 0, 6)
_sTitle.Text = "Soru Silent"; _sTitle.Font = Enum.Font.RobotoMono
_sTitle.TextColor3 = Color3.fromRGB(255, 255, 255); _sTitle.TextSize = 12
_sTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20); _sTitle.BackgroundTransparency = 0.2
Instance.new("UICorner", _sTitle).CornerRadius = UDim.new(0, 8)

local _SoruMiniTargetDropdown = Instance.new("TextButton", _SoruMiniMain)
_SoruMiniTargetDropdown.Size = UDim2.new(0, 178, 0, 24); _SoruMiniTargetDropdown.Position = UDim2.new(0, 6, 0, 37)
_SoruMiniTargetDropdown.Text = "Select Player"; _SoruMiniTargetDropdown.Font = Enum.Font.RobotoMono
_SoruMiniTargetDropdown.TextSize = 11; _SoruMiniTargetDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
_SoruMiniTargetDropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45); _SoruMiniTargetDropdown.BackgroundTransparency = 0.3
Instance.new("UICorner", _SoruMiniTargetDropdown).CornerRadius = UDim.new(0, 8)

local _sDropdownFrame = Instance.new("ScrollingFrame", _SoruMiniGui)
_sDropdownFrame.Size = UDim2.new(0, 178, 0, 120)
_sDropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); _sDropdownFrame.Visible = false
_sDropdownFrame.ClipsDescendants = true; _sDropdownFrame.BorderSizePixel = 0; _sDropdownFrame.ScrollBarThickness = 6
Instance.new("UICorner", _sDropdownFrame).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", _sDropdownFrame).Padding = UDim.new(0, 4)

local _sRefreshBtn = Instance.new("TextButton", _SoruMiniMain)
_sRefreshBtn.Size = UDim2.new(0, 178, 0, 24); _sRefreshBtn.Position = UDim2.new(0, 6, 0, 68)
_sRefreshBtn.Text = "Refresh"; _sRefreshBtn.Font = Enum.Font.RobotoMono
_sRefreshBtn.TextSize = 11; _sRefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
_sRefreshBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); _sRefreshBtn.BackgroundTransparency = 0.3
Instance.new("UICorner", _sRefreshBtn).CornerRadius = UDim.new(0, 8)

local _SoruMiniToggleBtn = Instance.new("TextButton", _SoruMiniMain)
_SoruMiniToggleBtn.Size = UDim2.new(0, 178, 0, 24); _SoruMiniToggleBtn.Position = UDim2.new(0, 6, 0, 99)
_SoruMiniToggleBtn.Text = "STATUS: OFF"; _SoruMiniToggleBtn.Font = Enum.Font.RobotoMono
_SoruMiniToggleBtn.TextSize = 12; _SoruMiniToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
_SoruMiniToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50); _SoruMiniToggleBtn.BackgroundTransparency = 0.2
Instance.new("UICorner", _SoruMiniToggleBtn).CornerRadius = UDim.new(0, 8)

local soruDropdownBtn -- forward declaration (used in updateMiniSoruList)

local function updateMiniSoruList()
    for _, child in ipairs(_sDropdownFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30); btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1, 1, 1); btn.Text = plr.Name
            btn.Font = Enum.Font.RobotoMono; btn.TextSize = 11; btn.AutoButtonColor = true
            btn.Parent = _sDropdownFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            btn.MouseButton1Click:Connect(function()
                cachedTarget = plr.Name
                _SoruMiniTargetDropdown.Text = "Target: " .. plr.Name
                if soruDropdownBtn then soruDropdownBtn.Text = "Target: " .. plr.Name end
                _sDropdownFrame.Visible = false
            end)
        end
    end
    task.defer(function()
        _sDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, _sDropdownFrame:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
    end)
    _sDropdownFrame.Visible = false
end

local function syncMiniDropdownPos()
    _sDropdownFrame.Position = UDim2.new(0, _SoruMiniTargetDropdown.AbsolutePosition.X, 0, _SoruMiniTargetDropdown.AbsolutePosition.Y + 28)
end
_SoruMiniTargetDropdown.MouseButton1Click:Connect(function() syncMiniDropdownPos(); _sDropdownFrame.Visible = not _sDropdownFrame.Visible end)
_sRefreshBtn.MouseButton1Click:Connect(function() updateMiniSoruList() end)
_SoruMiniMain:GetPropertyChangedSignal("Position"):Connect(syncMiniDropdownPos)
updateMiniSoruList()

_SoruMiniToggleBtn.MouseButton1Click:Connect(function()
    soruSilentEnabled = not soruSilentEnabled
    _SoruMiniToggleBtn.Text = soruSilentEnabled and "STATUS: ON" or "STATUS: OFF"
    _SoruMiniToggleBtn.BackgroundColor3 = soruSilentEnabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
end)

_sMinBtn.MouseButton1Click:Connect(function()
    _sTitle.Visible = false; _SoruMiniTargetDropdown.Visible = false
    _sRefreshBtn.Visible = false; _SoruMiniToggleBtn.Visible = false; _sDropdownFrame.Visible = false
    _SoruMiniMain.Size = UDim2.new(0, 45, 0, 30); _SoruMiniMain.BackgroundTransparency = 1
    _sMinBtn.Position = UDim2.new(0, 5, 0, 2); _sMinBtn.Visible = false; _sMaxBtn.Visible = true
end)
_sMaxBtn.MouseButton1Click:Connect(function()
    _SoruMiniMain.Size = UDim2.new(0, 190, 0, 129); _SoruMiniMain.BackgroundTransparency = 0.1
    _sMinBtn.Position = UDim2.new(0, 5, 0, -28)
    _sTitle.Visible = true; _SoruMiniTargetDropdown.Visible = true
    _sRefreshBtn.Visible = true; _SoruMiniToggleBtn.Visible = true
    _sMinBtn.Visible = true; _sMaxBtn.Visible = false
end)

-- ============================================================
--  MINI WINDOW: SORU DETECTOR V11
-- ============================================================
local _SoruDetGui = Instance.new("ScreenGui")
_SoruDetGui.Name = "SoruDetectorDualSlotGui"; _SoruDetGui.ResetOnSpawn = false
_SoruDetGui.DisplayOrder = 1005; _SoruDetGui.Parent = game:GetService("CoreGui"); _SoruDetGui.Enabled = false

local SDMainFrame = Instance.new("Frame", _SoruDetGui)
SDMainFrame.Size = UDim2.new(0, 190, 0, 310); SDMainFrame.Position = UDim2.new(0.12, 0, 0.45, 0)
SDMainFrame.Active = true; SDMainFrame.Draggable = true
SDMainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); SDMainFrame.BackgroundTransparency = 0.1
Instance.new("UICorner", SDMainFrame).CornerRadius = UDim.new(0, 10)

local SDminBtn = Instance.new("TextButton", SDMainFrame)
SDminBtn.Size = UDim2.new(0, 35, 0, 25); SDminBtn.Position = UDim2.new(0, 5, 0, -28)
SDminBtn.Text = "-"; SDminBtn.Font = Enum.Font.RobotoMono; SDminBtn.TextColor3 = Color3.fromRGB(255, 255, 255); SDminBtn.TextSize = 25
SDminBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20); SDminBtn.BackgroundTransparency = 0.1
Instance.new("UICorner", SDminBtn).CornerRadius = UDim.new(0, 6)

local SDmaxBtn = Instance.new("TextButton", SDMainFrame)
SDmaxBtn.Size = UDim2.new(0, 35, 0, 25); SDmaxBtn.Position = UDim2.new(0, 5, 0, -28)
SDmaxBtn.Text = "+"; SDmaxBtn.Font = Enum.Font.RobotoMono; SDmaxBtn.TextColor3 = Color3.fromRGB(255, 255, 255); SDmaxBtn.TextSize = 20
SDmaxBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); SDmaxBtn.BackgroundTransparency = 0.1; SDmaxBtn.Visible = false
Instance.new("UICorner", SDmaxBtn).CornerRadius = UDim.new(0, 6)

local SDTitle = Instance.new("TextLabel", SDMainFrame)
SDTitle.Size = UDim2.new(0, 178, 0, 24); SDTitle.Position = UDim2.new(0, 6, 0, 6)
SDTitle.Text = "BBG Soru Detector"; SDTitle.Font = Enum.Font.RobotoMono
SDTitle.TextColor3 = Color3.fromRGB(255, 255, 255); SDTitle.TextSize = 12
SDTitle.BackgroundColor3 = Color3.fromRGB(20, 20, 20); SDTitle.BackgroundTransparency = 0.2
Instance.new("UICorner", SDTitle).CornerRadius = UDim.new(0, 8)

local function makeSDInput(parent, yPos, labelText)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0, 178, 0, 24); f.Position = UDim2.new(0, 6, 0, yPos)
    f.BackgroundTransparency = 0.5; f.BackgroundColor3 = Color3.new(0, 0, 0)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.6, 0, 1, 0); lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelText; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.RobotoMono; lbl.TextSize = 11; lbl.TextColor3 = Color3.new(1, 1, 1)
    local box = Instance.new("TextBox", f)
    box.Size = UDim2.new(0, 55, 0, 18); box.Position = UDim2.new(1, -63, 0.5, -9)
    box.BackgroundColor3 = Color3.fromRGB(176, 176, 176); box.BackgroundTransparency = 0.3; box.Text = "0.05"
    box.Font = Enum.Font.RobotoMono; box.TextSize = 12; box.TextColor3 = Color3.new(1, 1, 1); box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    return f, box
end

local function makeSDDrop(parent, yPos, labelText)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 178, 0, 24); btn.Position = UDim2.new(0, 6, 0, yPos)
    btn.Text = labelText; btn.Font = Enum.Font.RobotoMono; btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); btn.BackgroundTransparency = 0.3
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local function makeSDToggle(parent, yPos, labelText)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 178, 0, 24); btn.Position = UDim2.new(0, 6, 0, yPos)
    btn.Text = labelText; btn.Font = Enum.Font.RobotoMono; btn.TextSize = 11
    btn.TextColor3 = Color3.fromRGB(255, 255, 255); btn.BackgroundColor3 = Color3.fromRGB(150, 50, 50); btn.BackgroundTransparency = 0.2
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

local SDinputFrame1, SDinputBox1 = makeSDInput(SDMainFrame, 37, "Slot 1 Delay")
local SDtargetDrop1              = makeSDDrop(SDMainFrame, 68, "S1 Type: None")
local SDmovesDrop1               = makeSDDrop(SDMainFrame, 99, "S1 Move: None")
local SDtoggleBtn1               = makeSDToggle(SDMainFrame, 130, "S1 STATUS: OFF")
local SDinputFrame2, SDinputBox2 = makeSDInput(SDMainFrame, 168, "Slot 2 Delay")
local SDtargetDrop2              = makeSDDrop(SDMainFrame, 199, "S2 Type: None")
local SDmovesDrop2               = makeSDDrop(SDMainFrame, 230, "S2 Move: None")
local SDtoggleBtn2               = makeSDToggle(SDMainFrame, 261, "S2 STATUS: OFF")

local SDsharedMenu = Instance.new("Frame", _SoruDetGui)
SDsharedMenu.Size = UDim2.new(0, 178, 0, 125); SDsharedMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25); SDsharedMenu.Visible = false
Instance.new("UICorner", SDsharedMenu).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", SDsharedMenu).SortOrder = Enum.SortOrder.LayoutOrder
local SDactiveDropdown = nil

local function SDopenMenu(targetButton, options, callback)
    if SDactiveDropdown == targetButton and SDsharedMenu.Visible then SDsharedMenu.Visible = false; return end
    SDactiveDropdown = targetButton
    for _, child in ipairs(SDsharedMenu:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    SDsharedMenu.Size = UDim2.new(0, 178, 0, #options * 25)
    SDsharedMenu.Position = UDim2.new(0, targetButton.AbsolutePosition.X, 0, targetButton.AbsolutePosition.Y + 28)
    for _, opt in ipairs(options) do
        local btn = Instance.new("TextButton", SDsharedMenu); btn.Size = UDim2.new(1, 0, 0, 25); btn.BackgroundTransparency = 1
        btn.Text = opt; btn.Font = Enum.Font.RobotoMono; btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.TextSize = 11
        btn.MouseButton1Click:Connect(function() callback(opt); SDsharedMenu.Visible = false end)
    end
    SDsharedMenu.Visible = true
end
SDMainFrame:GetPropertyChangedSignal("Position"):Connect(function() SDsharedMenu.Visible = false end)

local SDtargets = {"None","Melee","Sword","Fruit","Gun"}
local SDmovesByType = { None={"None"}, Melee={"None","Z","X","C"}, Sword={"None","Z","X"}, Fruit={"None","Z","X","C","V","F"}, Gun={"None","Z","X"} }
local function SDgetMovesFor(t) return SDmovesByType[t] or {"None"} end

SDtargetDrop1.MouseButton1Click:Connect(function() SDopenMenu(SDtargetDrop1, SDtargets, function(val) slot1.type=val; slot1.move="None"; SDtargetDrop1.Text="S1 Type: "..val; SDmovesDrop1.Text="S1 Move: None" end) end)
SDmovesDrop1.MouseButton1Click:Connect(function() SDopenMenu(SDmovesDrop1, SDgetMovesFor(slot1.type), function(val) slot1.move=val; SDmovesDrop1.Text="S1 Move: "..val end) end)
SDtargetDrop2.MouseButton1Click:Connect(function() SDopenMenu(SDtargetDrop2, SDtargets, function(val) slot2.type=val; slot2.move="None"; SDtargetDrop2.Text="S2 Type: "..val; SDmovesDrop2.Text="S2 Move: None" end) end)
SDmovesDrop2.MouseButton1Click:Connect(function() SDopenMenu(SDmovesDrop2, SDgetMovesFor(slot2.type), function(val) slot2.move=val; SDmovesDrop2.Text="S2 Move: "..val end) end)

SDtoggleBtn1.MouseButton1Click:Connect(function() slot1.active=not slot1.active; SDtoggleBtn1.Text=slot1.active and "S1 STATUS: ON" or "S1 STATUS: OFF"; SDtoggleBtn1.BackgroundColor3=slot1.active and Color3.fromRGB(50,150,50) or Color3.fromRGB(150,50,50) end)
SDtoggleBtn2.MouseButton1Click:Connect(function() slot2.active=not slot2.active; SDtoggleBtn2.Text=slot2.active and "S2 STATUS: ON" or "S2 STATUS: OFF"; SDtoggleBtn2.BackgroundColor3=slot2.active and Color3.fromRGB(50,150,50) or Color3.fromRGB(150,50,50) end)

SDminBtn.MouseButton1Click:Connect(function()
    SDTitle.Visible=false; SDinputFrame1.Visible=false; SDtargetDrop1.Visible=false; SDmovesDrop1.Visible=false; SDtoggleBtn1.Visible=false
    SDinputFrame2.Visible=false; SDtargetDrop2.Visible=false; SDmovesDrop2.Visible=false; SDtoggleBtn2.Visible=false; SDsharedMenu.Visible=false
    SDMainFrame.Size=UDim2.new(0,45,0,30); SDMainFrame.BackgroundTransparency=1
    SDminBtn.Position=UDim2.new(0,5,0,2); SDminBtn.Visible=false; SDmaxBtn.Visible=true
end)
SDmaxBtn.MouseButton1Click:Connect(function()
    SDMainFrame.Size=UDim2.new(0,190,0,310); SDMainFrame.BackgroundTransparency=0.1
    SDminBtn.Position=UDim2.new(0,5,0,-28); SDTitle.Visible=true
    SDinputFrame1.Visible=true; SDtargetDrop1.Visible=true; SDmovesDrop1.Visible=true; SDtoggleBtn1.Visible=true
    SDinputFrame2.Visible=true; SDtargetDrop2.Visible=true; SDmovesDrop2.Visible=true; SDtoggleBtn2.Visible=true
    SDminBtn.Visible=true; SDmaxBtn.Visible=false
end)

-- Soru Detector logic
local MELEE_KW={"combat","step","electro","fishman","dragon","human","karate","claw","superhuman","death","sharkman"}
local GUN_KW={"gun","rifle","musket","cannon","kabucha","flintlock","revolver","sniper","shotgun"}
local SWORD_KW={"sword","blade","katana","saber","sabre","cutlass","rapier","scythe","dark","light","pole","trident","koko","canvander","wando","gravity","saddi","shisui","cursed","soul","yama","tushita","enma","buddy","rengoku","admin","godhuman","dragon","dough","quake","buddha","string","paw","bomb","barrier","ice","sand","smoke","magma","flame","rubber","love","spider","phoenix","leopard","mammoth","shadow"}

local function SDdetectType(tool)
    if not tool or not tool:IsA("Tool") then return "None" end
    local attr; pcall(function() attr = tool:GetAttribute("WeaponType") end)
    if attr and type(attr)=="string" then
        if attr=="Demon Fruit" or attr=="Fruit" then return "Fruit" end
        if attr=="Melee" then return "Melee" end
        if attr=="Sword" then return "Sword" end
        if attr=="Gun" then return "Gun" end
    end
    local n = string.lower(tool.Name)
    if string.find(n,"fruit") then return "Fruit" end
    for _,kw in ipairs(GUN_KW) do if string.find(n,kw) then return "Gun" end end
    for _,kw in ipairs(MELEE_KW) do if string.find(n,kw) then return "Melee" end end
    for _,kw in ipairs(SWORD_KW) do if string.find(n,kw) then return "Sword" end end
    return "None"
end

local function SDcurrentType() local c=player.Character; if not c then return "None" end; local t=c:FindFirstChildOfClass("Tool"); return t and SDdetectType(t) or "None" end
local function SDautoEquip(cat)
    if SDcurrentType()==cat then return true end
    local bp,c=player.Backpack,player.Character; if not bp or not c then return false end
    local h=c:FindFirstChildOfClass("Humanoid"); if not h then return false end
    local target; for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and SDdetectType(t)==cat then target=t; break end end
    if not target then return false end
    h:EquipTool(target); for i=1,30 do task.wait(); if SDcurrentType()==cat then return true end end; return false
end
local function SDfireKey(key) local k=Enum.KeyCode[key]; if not k then return end; VirtualInputManager:SendKeyEvent(true,k,false,game); task.wait(0.04); VirtualInputManager:SendKeyEvent(false,k,false,game) end
local _running=false; local slot2MoveDetected=false
local function SDwaitForSlot2Move(char,moveKey,callback) local h=char:FindFirstChildOfClass("Humanoid"); if not h then callback(); return end; local conn; conn=h.AnimationPlayed:Connect(function(track) local name=string.lower(track.Name); if string.find(name,"idle") or string.find(name,"walk") or string.find(name,"run") or string.find(name,"jump") or string.find(name,"fall") or string.find(name,"climb") then return end; slot2MoveDetected=true; if conn then conn:Disconnect() end; callback() end) end
local function SDfireDualMove()
    if _running then return end; _running=true; local slot1Done=false
    if slot1.active and slot1.type~="None" and slot1.move~="None" then
        if SDautoEquip(slot1.type) then local d1=math.max(0,tonumber(SDinputBox1.Text) or 0.05); if d1>0 then task.wait(d1) end; SDfireKey(slot1.move); slot1Done=true end
    end
    if slot1Done and slot2.active and slot2.type~="None" and slot2.move~="None" then
        local char=player.Character
        if char and SDautoEquip(slot2.type) then local d2=math.max(0.03,tonumber(SDinputBox2.Text) or 0.05); slot2MoveDetected=false; SDwaitForSlot2Move(char,slot2.move,function() slot2MoveDetected=true end); local timeout=tick()+5; while not slot2MoveDetected and tick()<timeout and _running do SDfireKey(slot2.move); task.wait(d2) end end
    end
    task.wait(0.05); _running=false
end
local FLASH_NAMES={"FlashStepRegular","FlashStepDraco","FlashStep","Flashstep","Soru"}
local FLASH_IDS={"17555632156","18461649274","616006778","616010882","5403485593","5403491911"}
local function SDisFlashstep(track) for _,n in ipairs(FLASH_NAMES) do if string.find(string.lower(track.Name),string.lower(n)) then return true end end; local id=track.Animation.AnimationId:match("%d+") or ""; for _,fid in ipairs(FLASH_IDS) do if id==fid then return true end end; return false end
local function SDmonitorChar(char) local h=char:WaitForChild("Humanoid",5); if not h then return end; h.AnimationPlayed:Connect(function(track) if SDisFlashstep(track) then SDfireDualMove() end end) end
if player.Character then SDmonitorChar(player.Character) end
player.CharacterAdded:Connect(SDmonitorChar)

-- ============================================================
--  MINI WINDOW: RAJAWARE LAG
-- ============================================================
local _RajawareLagGui = Instance.new("ScreenGui")
_RajawareLagGui.Name="RajawareLagGui"; _RajawareLagGui.ResetOnSpawn=false; _RajawareLagGui.DisplayOrder=1006; _RajawareLagGui.Parent=game:GetService("CoreGui"); _RajawareLagGui.Enabled=false
local RLMainFrame=Instance.new("Frame",_RajawareLagGui); RLMainFrame.Size=UDim2.new(0,190,0,74); RLMainFrame.Position=UDim2.new(0.2,0,0.45,0); RLMainFrame.Active=true; RLMainFrame.Draggable=true; RLMainFrame.BackgroundColor3=Color3.fromRGB(30,30,30); RLMainFrame.BackgroundTransparency=0.1; Instance.new("UICorner",RLMainFrame).CornerRadius=UDim.new(0,10)
local RLminBtn=Instance.new("TextButton",RLMainFrame); RLminBtn.Size=UDim2.new(0,35,0,25); RLminBtn.Position=UDim2.new(0,5,0,-28); RLminBtn.Text="-"; RLminBtn.Font=Enum.Font.RobotoMono; RLminBtn.TextColor3=Color3.fromRGB(255,255,255); RLminBtn.TextSize=25; RLminBtn.BackgroundColor3=Color3.fromRGB(20,20,20); RLminBtn.BackgroundTransparency=0.1; Instance.new("UICorner",RLminBtn).CornerRadius=UDim.new(0,6)
local RLmaxBtn=Instance.new("TextButton",RLMainFrame); RLmaxBtn.Size=UDim2.new(0,35,0,25); RLmaxBtn.Position=UDim2.new(0,5,0,-28); RLmaxBtn.Text="+"; RLmaxBtn.Font=Enum.Font.RobotoMono; RLmaxBtn.TextColor3=Color3.fromRGB(255,255,255); RLmaxBtn.TextSize=20; RLmaxBtn.BackgroundColor3=Color3.fromRGB(50,50,50); RLmaxBtn.BackgroundTransparency=0.1; RLmaxBtn.Visible=false; Instance.new("UICorner",RLmaxBtn).CornerRadius=UDim.new(0,6)
local RLTitleLabel=Instance.new("TextLabel",RLMainFrame); RLTitleLabel.Size=UDim2.new(0,178,0,24); RLTitleLabel.Position=UDim2.new(0,6,0,6); RLTitleLabel.Text="Rajaware Elite"; RLTitleLabel.Font=Enum.Font.RobotoMono; RLTitleLabel.TextColor3=Color3.fromRGB(255,255,255); RLTitleLabel.TextSize=12; RLTitleLabel.BackgroundColor3=Color3.fromRGB(20,20,20); RLTitleLabel.BackgroundTransparency=0.2; Instance.new("UICorner",RLTitleLabel).CornerRadius=UDim.new(0,8)
local RLtoggleBtn=Instance.new("TextButton",RLMainFrame); RLtoggleBtn.Size=UDim2.new(0,178,0,24); RLtoggleBtn.Position=UDim2.new(0,6,0,37); RLtoggleBtn.Text="STATUS: OFF"; RLtoggleBtn.Font=Enum.Font.RobotoMono; RLtoggleBtn.TextSize=12; RLtoggleBtn.TextColor3=Color3.fromRGB(255,255,255); RLtoggleBtn.BackgroundColor3=Color3.fromRGB(150,50,50); RLtoggleBtn.BackgroundTransparency=0.2; Instance.new("UICorner",RLtoggleBtn).CornerRadius=UDim.new(0,8)
RLtoggleBtn.MouseButton1Click:Connect(function() RajawareLagEnabled=not RajawareLagEnabled; if RajawareLagEnabled then RLtoggleBtn.Text="STATUS: ON"; RLtoggleBtn.BackgroundColor3=Color3.fromRGB(50,150,50); startRajawareLag() else RLtoggleBtn.Text="STATUS: OFF"; RLtoggleBtn.BackgroundColor3=Color3.fromRGB(150,50,50); stopRajawareLag() end end)
RLminBtn.MouseButton1Click:Connect(function() RLTitleLabel.Visible=false; RLtoggleBtn.Visible=false; RLMainFrame.Size=UDim2.new(0,45,0,30); RLMainFrame.BackgroundTransparency=1; RLminBtn.Position=UDim2.new(0,5,0,2); RLminBtn.Visible=false; RLmaxBtn.Visible=true end)
RLmaxBtn.MouseButton1Click:Connect(function() RLMainFrame.Size=UDim2.new(0,190,0,74); RLMainFrame.BackgroundTransparency=0.1; RLminBtn.Position=UDim2.new(0,5,0,-28); RLTitleLabel.Visible=true; RLtoggleBtn.Visible=true; RLminBtn.Visible=true; RLmaxBtn.Visible=false end)

-- ============================================================
--  INJECT NEW TABS INTO BBG PANEL
-- ============================================================
local soruButton     = createSidebarTab("Soru",     6)
local rajawareButton = createSidebarTab("Rajaware", 7)

local soruScroll     = createPageScroll()
local rajawareScroll = createPageScroll()

-- Register in allPages and allTabButtons so switchPage works
allPages["Soru"]          = soruScroll
allPages["Rajaware"]      = rajawareScroll
allTabButtons["Soru"]     = soruButton
allTabButtons["Rajaware"] = rajawareButton

soruButton.MouseButton1Click:Connect(function()     switchPage("Soru")     end)
rajawareButton.MouseButton1Click:Connect(function() switchPage("Rajaware") end)

-- ============================================================
--  SORU TAB CONTENT
-- ============================================================
soruDropdownBtn = Instance.new("TextButton", soruScroll)
soruDropdownBtn.Size = UDim2.new(1, -10, 0, 30)
soruDropdownBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); soruDropdownBtn.BackgroundTransparency = 0.3
soruDropdownBtn.TextColor3 = Color3.new(1, 1, 1); soruDropdownBtn.Text = "Select Player"
soruDropdownBtn.Font = Enum.Font.GothamBold; soruDropdownBtn.TextSize = 14
Instance.new("UICorner", soruDropdownBtn).CornerRadius = UDim.new(0, 13)

local soruDropdownFrame = Instance.new("ScrollingFrame", mainFrame)
soruDropdownFrame.Size = UDim2.new(0, 240, 0, 120); soruDropdownFrame.Position = UDim2.new(0, 96, 0, 75)
soruDropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); soruDropdownFrame.Visible = false
soruDropdownFrame.ClipsDescendants = true; soruDropdownFrame.BorderSizePixel = 0; soruDropdownFrame.ScrollBarThickness = 6
Instance.new("UIListLayout", soruDropdownFrame).Padding = UDim.new(0, 4)

local function updateMainSoruList()
    for _, child in ipairs(soruDropdownFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            local btn = Instance.new("TextButton"); btn.Size = UDim2.new(1, -10, 0, 30)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50); btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Text = plr.Name; btn.Font = Enum.Font.GothamBold; btn.TextSize = 14
            btn.AutoButtonColor = true; btn.Parent = soruDropdownFrame
            btn.MouseButton1Click:Connect(function()
                cachedTarget = plr.Name
                soruDropdownBtn.Text = "Target: " .. plr.Name
                soruDropdownFrame.Visible = false
                if _SoruMiniTargetDropdown then _SoruMiniTargetDropdown.Text = "Target: " .. plr.Name end
            end)
        end
    end
    task.defer(function() soruDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, soruDropdownFrame:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y) end)
    soruDropdownFrame.Visible = false
end
soruDropdownBtn.MouseButton1Click:Connect(function() soruDropdownFrame.Visible = not soruDropdownFrame.Visible end)
updateMainSoruList()

createSwitch(soruScroll, "Soru Silent", false, function(state)
    soruSilentEnabled = state
    if _SoruMiniToggleBtn then
        _SoruMiniToggleBtn.Text = state and "STATUS: ON" or "STATUS: OFF"
        _SoruMiniToggleBtn.BackgroundColor3 = state and Color3.fromRGB(50,150,50) or Color3.fromRGB(150,50,50)
    end
end)
createSwitch(soruScroll, "Mini Window Soru Silent",   false, function(state) _SoruMiniGui.Enabled = state end)
createSwitch(soruScroll, "Inf Soru",                  false, function(state) infiniteSoruEnabled = state end)
createSwitch(soruScroll, "Mini Window Soru Detector", false, function(state) _SoruDetGui.Enabled = state end)

-- ============================================================
--  RAJAWARE TAB CONTENT
-- ============================================================
createSwitch(rajawareScroll, "Mini Window Rajaware Elite", false, function(state) _RajawareLagGui.Enabled = state end)

print("[BBGModules] Loaded — Soru & Rajaware tabs injected into BBG Panel")
