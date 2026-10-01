--[[
    NovaUI  |  A clean, themeable Luau UI library inspired by WindUI
    ---------------------------------------------------------------
    Elements (each one is its own independent function):
        Tab:Section / Label / Paragraph / Divider
        Tab:Button / Toggle / Slider / Input / Dropdown / Keybind / ColorPicker
        Tab:FeatureCard   (toggle presented as an icon feature card, e.g. ESP)
        Tab:FastKeys      (grid of rebindable quick-action keys)
        Tab:SupportedGames(list of supported games with status + "current" marker)
    Window:
        Window:Tab{ Title, Icon, Badge, Group }
        Window:MiscTab, Window:SupportedGamesTab
        Window:Notify, Window:SetTheme, Window:Toggle, Window:Destroy
        Window:SetSnow, Window:SetScriptStatus, Window:SetPlayerPlan
    Themes:
        Dark, Light, Ocean, Rose, Emerald, Amethyst  (or pass your own table)

    Suggested tab organisation (use the Group option to get sidebar headers):
        Group "Main"     -> Home
        Group "Features" -> Player, Combat, Visuals, Movement
        Group "Hub"      -> Misc, Supported Games, Settings
]]

local TweenService       = game:GetService("TweenService")
local UIS                = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local TextService        = game:GetService("TextService")
local MarketplaceService = game:GetService("MarketplaceService")

local Library = { Version = "1.20", Windows = {} }

local TOP_H = 58 -- larger Nova Hub header

--------------------------------------------------------------------------
-- THEMES
--------------------------------------------------------------------------
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

Library.Themes = {
    Dark = {
        Background = rgb(17, 17, 22),  Surface = rgb(24, 24, 31),
        Element = rgb(33, 33, 42),     ElementHover = rgb(44, 44, 56),
        Stroke = rgb(58, 58, 72),      Accent = rgb(108, 117, 255),
        AccentText = rgb(255, 255, 255),
        Text = rgb(242, 242, 247),     SubText = rgb(152, 152, 172),
        Success = rgb(74, 222, 128),   Warning = rgb(250, 204, 21),
        Danger = rgb(248, 113, 113),
    },
    Light = {
        Background = rgb(244, 245, 250), Surface = rgb(255, 255, 255),
        Element = rgb(236, 238, 246),    ElementHover = rgb(224, 227, 240),
        Stroke = rgb(205, 209, 226),     Accent = rgb(79, 70, 229),
        AccentText = rgb(255, 255, 255),
        Text = rgb(24, 24, 36),          SubText = rgb(98, 102, 124),
        Success = rgb(22, 163, 74),      Warning = rgb(202, 138, 4),
        Danger = rgb(220, 38, 38),
    },
    Ocean = {
        Background = rgb(10, 18, 30),  Surface = rgb(15, 26, 42),
        Element = rgb(22, 37, 58),     ElementHover = rgb(31, 50, 76),
        Stroke = rgb(44, 66, 96),      Accent = rgb(34, 211, 238),
        AccentText = rgb(6, 22, 34),
        Text = rgb(232, 244, 252),     SubText = rgb(136, 164, 190),
        Success = rgb(52, 211, 153),   Warning = rgb(251, 191, 36),
        Danger = rgb(251, 113, 133),
    },
    Rose = {
        Background = rgb(22, 14, 18),  Surface = rgb(30, 19, 25),
        Element = rgb(42, 27, 35),     ElementHover = rgb(56, 36, 46),
        Stroke = rgb(76, 50, 62),      Accent = rgb(244, 114, 182),
        AccentText = rgb(40, 8, 24),
        Text = rgb(252, 238, 244),     SubText = rgb(176, 146, 160),
        Success = rgb(74, 222, 128),   Warning = rgb(250, 204, 21),
        Danger = rgb(248, 113, 113),
    },
    Emerald = {
        Background = rgb(12, 20, 17),  Surface = rgb(17, 28, 24),
        Element = rgb(24, 40, 34),     ElementHover = rgb(33, 54, 46),
        Stroke = rgb(48, 74, 64),      Accent = rgb(52, 211, 153),
        AccentText = rgb(4, 30, 20),
        Text = rgb(236, 252, 245),     SubText = rgb(140, 176, 162),
        Success = rgb(74, 222, 128),   Warning = rgb(250, 204, 21),
        Danger = rgb(248, 113, 113),
    },
    Amethyst = {
        Background = rgb(16, 12, 26),  Surface = rgb(23, 17, 38),
        Element = rgb(33, 25, 54),     ElementHover = rgb(45, 35, 72),
        Stroke = rgb(66, 52, 102),     Accent = rgb(167, 139, 250),
        AccentText = rgb(20, 10, 44),
        Text = rgb(244, 240, 255),     SubText = rgb(160, 148, 190),
        Success = rgb(74, 222, 128),   Warning = rgb(250, 204, 21),
        Danger = rgb(248, 113, 113),
    },
}

function Library:AddTheme(name, theme)
    self.Themes[name] = theme
end

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local FONT      = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local function New(class, props, children)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        o.Font = FONT; o.TextSize = 14; o.BackgroundTransparency = 1
    end
    if o:IsA("ScrollingFrame") then o.BorderSizePixel = 0 end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else o[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = o end
    o.Parent = parent
    return o
end

local function tw(inst, props, t, style, dir)
    local tween = TweenService:Create(inst,
        TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end

local function corner(p, r) return New("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function pad(p, l, t, r, b)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
        PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or 0), Parent = p })
end

local function clamp(n, a, b) return math.max(a, math.min(b, n)) end

local function round(n, inc)
    inc = inc or 1
    return math.floor(n / inc + 0.5) * inc
end

local function decimals(inc)
    local d = tostring(inc):match("%.(%d+)")
    return d and #d or 0
end

local function mountGui(gui)
    local ok, ui = pcall(function() return gethui() end)
    if ok and ui then
        local ok2 = pcall(function() gui.Parent = ui end)
        if ok2 and gui.Parent then return end
    end
    local ok3 = pcall(function() gui.Parent = CoreGui end)
    if ok3 and gui.Parent then return end
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function isImage(s)
    return type(s) == "string" and (s:find("rbxasset") ~= nil or s:match("^%d+$") ~= nil)
end
local function toImage(s)
    if s:match("^%d+$") then return "rbxassetid://" .. s end
    return s
end

-- theme binding ----------------------------------------------------------
local function bind(win, inst, prop, key)
    inst[prop] = win.Theme[key]
    table.insert(win._bound, { inst, prop, key })
end

local function glow(win, parent, thickness, transparency)
    local g = New("UIStroke", {
        Thickness = thickness or 3,
        Transparency = transparency or 0.88,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
    bind(win, g, "Color", "Accent")
    return g
end

local function onTheme(win, fn)
    local token = {}
    win._themeCbs[token] = fn
    return token
end

local function stroke(win, parent, key, thickness)
    local s = New("UIStroke", {
        Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
    bind(win, s, "Color", key or "Stroke")
    return s
end

local function label(win, parent, text, size, key, font)
    local l = New("TextLabel", {
        Text = text, TextSize = size or 14, Font = font or FONT,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
    bind(win, l, "TextColor3", key or "Text")
    return l
end

local function iconKindFor(title)
    local s = string.lower(tostring(title or ""))
    if s == "main" then return "dashboard" end
    if s == "home" or s:find("home", 1, true) then return "home" end
    if s:find("dashboard", 1, true) then return "dashboard" end
    if s:find("player", 1, true) then return "player" end
    if s:find("aim", 1, true) or s:find("combat", 1, true) or s:find("target", 1, true) then return "combat" end
    if s:find("visual", 1, true) or s:find("esp", 1, true) or s:find("render", 1, true) then return "visual" end
    if s:find("movement", 1, true) or s:find("speed", 1, true) or s:find("fly", 1, true) then return "movement" end
    if s:find("setting", 1, true) or s:find("config", 1, true) then return "settings" end
    if s:find("info", 1, true) or s:find("about", 1, true) then return "info" end
    if s:find("key", 1, true) then return "keys" end
    if s:find("game", 1, true) then return "games" end
    if s:find("script", 1, true) or s:find("misc", 1, true) then return "misc" end
    return "misc"
end

local function newIconPart(parent, size, position, color, radius, rotation)
    local f = New("Frame", {
        Size = size, Position = position, BackgroundColor3 = color, BackgroundTransparency = 0, Parent = parent
    })
    if radius then corner(f, radius) end
    if rotation then f.Rotation = rotation end
    return f
end

local function createNativeIcon(win, parent, kind)
    -- Clean, consistent 18x18 vector-style icons. Every icon uses the same
    -- visual weight, view-box, padding and alignment so tabs never jump around.
    local holder = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        BackgroundTransparency = 1,
        Parent = parent,
    })
    holder:SetAttribute("NovaIconKind", kind)

    local parts = {}
    local STROKE = 1.65

    local function bindPart(f)
        table.insert(parts, f)
        bind(win, f, "BackgroundColor3", "SubText")
        return f
    end

    local function box(x, y, w, h, r)
        local f = New("Frame", {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h),
            BackgroundTransparency = 0,
            Parent = holder,
        })
        if r then corner(f, r) end
        return bindPart(f)
    end

    local function line(x, y, w, h, rotation)
        -- Rounded micro-strokes for Lucide-like line art.
        return box(x, y, w, h, math.max(1, math.min(w, h) / 2))
            and (function(f)
                f.Rotation = rotation or 0
                f.BackgroundTransparency = 0
                return f
            end)(holder:GetChildren()[#holder:GetChildren()])
    end

    local function strokeRect(x, y, w, h, radius)
        local f = New("Frame", {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h),
            BackgroundTransparency = 1,
            Parent = holder,
        })
        corner(f, radius or 4)
        local st = New("UIStroke", {
            Thickness = STROKE,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = f,
        })
        bind(win, st, "Color", "SubText")
        table.insert(parts, st)
        return f
    end

    local function line2(x, y, w, h, rotation)
        local f = New("Frame", {
            Position = UDim2.fromOffset(x, y),
            Size = UDim2.fromOffset(w, h),
            BackgroundTransparency = 0,
            Parent = holder,
        })
        corner(f, math.max(1, math.floor(math.min(w, h) / 2)))
        f.Rotation = rotation or 0
        return bindPart(f)
    end

    kind = tostring(kind or "misc")

    if kind == "home" then
        -- polished dashboard/home icon: rounded house with clean proportions
        local roof = strokeRect(3, 7, 12, 8, 2.5)
        local roofLine = line2(3.5, 5.8, 11, 1.8, 0)
        local left = line2(4, 4.2, 2, 5, -42)
        left.Position = UDim2.fromOffset(3.3, 4.2)
        local right = line2(12, 4.2, 2, 5, 42)
        right.Position = UDim2.fromOffset(12.7, 4.2)
        box(8, 10, 3, 5, 1.2)
        box(5.2, 9.5, 1.5, 1.5, 0.7)
    elseif kind == "dashboard" then
        -- four balanced dashboard cards
        for _, pos in ipairs({{2,2},{10,2},{2,10},{10,10}}) do
            strokeRect(pos[1], pos[2], 6, 6, 1.8)
        end
    elseif kind == "player" then
        -- user silhouette
        local head = New("Frame", {
            Position = UDim2.fromOffset(6, 1.5), Size = UDim2.fromOffset(6, 6),
            BackgroundTransparency = 1, Parent = holder,
        })
        corner(head, 3)
        local hs = New("UIStroke", { Thickness = STROKE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = head })
        bind(win, hs, "Color", "SubText"); table.insert(parts, hs)
        local body = New("Frame", {
            Position = UDim2.fromOffset(3.5, 9), Size = UDim2.fromOffset(11, 7),
            BackgroundTransparency = 1, Parent = holder,
        })
        corner(body, 4)
        local bs = New("UIStroke", { Thickness = STROKE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = body })
        bind(win, bs, "Color", "SubText"); table.insert(parts, bs)
    elseif kind == "combat" then
        -- crosshair / target
        local ring = strokeRect(2.5, 2.5, 13, 13, 6.5)
        line2(8, 1, 2, 4, 0)
        line2(8, 13, 2, 4, 0)
        line2(1, 8, 4, 2, 0)
        line2(13, 8, 4, 2, 0)
        box(7, 7, 4, 4, 2)
    elseif kind == "visual" then
        -- eye
        local eye = New("Frame", {
            Position = UDim2.fromOffset(2, 5), Size = UDim2.fromOffset(14, 8),
            BackgroundTransparency = 1, Parent = holder,
        })
        local es = New("UIStroke", { Thickness = STROKE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = eye })
        bind(win, es, "Color", "SubText"); table.insert(parts, es)
        corner(eye, 5)
        local pupil = box(7, 7, 4, 4, 2)
        local shine = box(9, 8, 1.2, 1.2, 1)
    elseif kind == "movement" then
        -- speed arrow
        line2(3, 8, 9, 2, 0)
        line2(10, 5, 6, 2, 45)
        line2(10, 11, 6, 2, -45)
        line2(2, 4, 6, 1.6, 0)
        line2(2, 13, 6, 1.6, 0)
    elseif kind == "settings" then
        -- simple balanced gear
        strokeRect(5, 5, 8, 8, 4)
        box(8, 8, 2, 2, 1)
        box(8, 0.7, 2, 4, 1)
        box(8, 13.3, 2, 4, 1)
        box(0.7, 8, 4, 2, 1)
        box(13.3, 8, 4, 2, 1)
    elseif kind == "info" then
        strokeRect(2.5, 2.5, 13, 13, 6.5)
        box(8.1, 6, 1.8, 2, 0.9)
        box(8.1, 9, 1.8, 5, 0.9)
    elseif kind == "keys" then
        -- compact keyboard
        strokeRect(1.5, 4, 15, 10, 2.8)
        for _, x in ipairs({4, 7, 10}) do box(x, 7, 1.7, 1.7, 0.7) end
        box(5, 10.5, 8, 1.7, 0.8)
    elseif kind == "games" then
        -- game controller
        local padBody = New("Frame", {
            Position = UDim2.fromOffset(1.5, 5), Size = UDim2.fromOffset(15, 9),
            BackgroundTransparency = 1, Parent = holder,
        })
        corner(padBody, 4.5)
        local ps = New("UIStroke", { Thickness = STROKE, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = padBody })
        bind(win, ps, "Color", "SubText"); table.insert(parts, ps)
        box(4, 8, 4.5, 1.7, 0.8)
        box(5.4, 6.6, 1.7, 4.5, 0.8)
        box(11.3, 7, 2.2, 2.2, 1.1)
        box(12.2, 6.1, 0.6, 0.6, 0.3)
        box(10.9, 7.4, 0.6, 0.6, 0.3)
    else
        -- misc / fallback: clean sparkle
        line2(8, 1, 2, 7, 0)
        line2(5.5, 3.5, 7, 2, 0)
        line2(8, 10, 2, 7, 0)
        line2(5.5, 12.5, 7, 2, 0)
    end

    local function setOn(on)
        for _, item in ipairs(parts) do
            if item:IsA("UIStroke") then
                item.Color = on and win.Theme.Accent or win.Theme.SubText
            elseif item:IsA("Frame") then
                item.BackgroundColor3 = on and win.Theme.Accent or win.Theme.SubText
            end
        end
    end

    setOn(false)
    return holder, setOn
end

-- icon chip used on feature cards (native shape icon or asset id) ---------
local function makeIconChip(win, parent, icon, cleanup)
    local chip = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 0.86, Parent = parent })
    bind(win, chip, "BackgroundColor3", "Accent")
    corner(chip, 9)
    local chipStroke = stroke(win, chip, "Accent", 1)
    chipStroke.Transparency = 0.72
    if isImage(icon) then
        local img = New("ImageLabel", {
            Image = toImage(icon), BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(16, 16), Parent = chip })
        bind(win, img, "ImageColor3", "Accent")
    else
        local _, setOn = createNativeIcon(win, chip, tostring(icon))
        setOn(true)
        table.insert(cleanup, onTheme(win, function() setOn(true) end))
    end
    return chip
end

-- drag helper (mouse + touch) -------------------------------------------
local function isPress(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function dragger(win, area, fn)
    local dragging = false
    table.insert(win._conns, area.InputBegan:Connect(function(i)
        if isPress(i) then dragging = true; fn(i.Position.X, i.Position.Y) end
    end))
    table.insert(win._conns, UIS.InputChanged:Connect(function(i)
        if dragging and isMove(i) then fn(i.Position.X, i.Position.Y) end
    end))
    table.insert(win._conns, UIS.InputEnded:Connect(function(i)
        if isPress(i) then dragging = false end
    end))
end

--------------------------------------------------------------------------
-- ELEMENT BASE
--------------------------------------------------------------------------
-- Builds the standard card: [ (icon) title / description ............ right-control ]
-- iconKind is optional; when given, a feature-card icon chip is drawn on the left.
local function makeRow(tab, title, desc, rightWidth, iconKind)
    local win = tab.Window
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.04, Parent = tab.Page })
    bind(win, row, "BackgroundColor3", "Element")
    corner(row, 12)
    local rowStroke = stroke(win, row, "Stroke")
    local rowGlow = glow(win, row, 3, 0.96)
    row.MouseEnter:Connect(function()
        tw(rowGlow, { Transparency = 0.78 }, 0.18, Enum.EasingStyle.Quint)
        tw(rowStroke, { Thickness = 1.35 }, 0.16, Enum.EasingStyle.Quint)
    end)
    row.MouseLeave:Connect(function()
        tw(rowGlow, { Transparency = 0.96 }, 0.22, Enum.EasingStyle.Quint)
        tw(rowStroke, { Thickness = 1 }, 0.16, Enum.EasingStyle.Quint)
    end)
    New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

    local header = New("Frame", {
        BackgroundTransparency = 1, LayoutOrder = 0,
        Size = UDim2.new(1, 0, 0, desc and desc ~= "" and 56 or 44), Parent = row })
    pad(header, 14, 0, 14, 0)

    local hasDesc = desc and desc ~= ""
    local rw = rightWidth or 0
    local ix = iconKind and 38 or 0
    local titleLbl = label(win, header, title or "", 14, "Text", FONT_BOLD)
    titleLbl.AnchorPoint = Vector2.new(0, 0.5)
    titleLbl.Position = UDim2.new(0, ix, 0.5, hasDesc and -9 or 0)
    titleLbl.Size = UDim2.new(1, -(rw + 8 + ix), 0, 18)

    local descLbl
    if hasDesc then
        descLbl = label(win, header, desc, 12, "SubText")
        descLbl.AnchorPoint = Vector2.new(0, 0.5)
        descLbl.Position = UDim2.new(0, ix, 0.5, 10)
        descLbl.Size = UDim2.new(1, -(rw + 8 + ix), 0, 14)
    end

    local obj = { Instance = row, Title = title }
    local cleanup = {}

    if iconKind then
        makeIconChip(win, header, iconKind, cleanup)
    end

    function obj:SetTitle(t) titleLbl.Text = t end
    function obj:SetDescription(t)
        if descLbl then descLbl.Text = t end
    end
    function obj:SetVisible(v) row.Visible = v end
    function obj:Destroy()
        for _, tok in ipairs(cleanup) do win._themeCbs[tok] = nil end
        row:Destroy()
    end

    return row, header, obj, cleanup
end

local function hoverable(win, btn, target)
    btn.MouseEnter:Connect(function() tw(target, { BackgroundColor3 = win.Theme.ElementHover }, 0.12) end)
    btn.MouseLeave:Connect(function() tw(target, { BackgroundColor3 = win.Theme.Element }, 0.12) end)
end

local function setFlag(win, opts, value)
    if opts.Flag then win.Flags[opts.Flag] = value end
end

--------------------------------------------------------------------------
-- BUTTON
--  opts: Title, Description, Icon, Style ("Default" | "Accent"), Callback
--------------------------------------------------------------------------
local function CreateButton(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj, cleanup = makeRow(tab, opts.Title or "Button", opts.Description, 30, opts.Icon)

    local accent = opts.Style == "Accent"
    local hit = New("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = header })

    local arrow = New("TextLabel", {
        Text = "›", TextSize = 24, Font = FONT_BOLD, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, -2), Size = UDim2.fromOffset(24, 24), Parent = header })
    local function paint()
        if accent then
            tw(row, { BackgroundColor3 = win.Theme.Accent }, 0.2)
            arrow.TextColor3 = win.Theme.AccentText
        else
            arrow.TextColor3 = win.Theme.SubText
        end
    end
    if accent then
        for _, v in ipairs(header:GetChildren()) do
            if v:IsA("TextLabel") and v ~= arrow then
                bind(win, v, "TextColor3", "AccentText")
            end
        end
        for i = #win._bound, 1, -1 do
            if win._bound[i][1] == row and win._bound[i][2] == "BackgroundColor3" then
                win._bound[i][3] = "Accent"
            end
        end
    end
    table.insert(cleanup, onTheme(win, paint))
    paint()

    hit.MouseEnter:Connect(function()
        tw(row, { BackgroundColor3 = accent and win.Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.12) or win.Theme.ElementHover }, 0.12)
        tw(arrow, { Position = UDim2.new(1, 3, 0.5, -2) }, 0.12)
    end)
    hit.MouseLeave:Connect(function()
        tw(row, { BackgroundColor3 = accent and win.Theme.Accent or win.Theme.Element }, 0.12)
        tw(arrow, { Position = UDim2.new(1, 0, 0.5, -2) }, 0.12)
    end)
    hit.MouseButton1Down:Connect(function()
        tw(row, { BackgroundColor3 = accent and win.Theme.Accent:Lerp(Color3.new(0, 0, 0), 0.15) or win.Theme.Stroke }, 0.08)
    end)
    hit.MouseButton1Click:Connect(function()
        if opts.Callback then task.spawn(opts.Callback) end
    end)

    function obj:Fire() if opts.Callback then task.spawn(opts.Callback) end end
    return obj
end

--------------------------------------------------------------------------
-- TOGGLE
--  opts: Title, Description, Icon, Tag, Default, Flag, Callback(value)
--------------------------------------------------------------------------
local function CreateToggle(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local tagW = opts.Tag and 64 or 0
    local row, header, obj, cleanup = makeRow(tab, opts.Title or "Toggle", opts.Description, 50 + tagW, opts.Icon)
    local value = opts.Default == true

    local hit = New("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = header })
    local track = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(42, 22), Parent = header })
    corner(track, 11)
    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Color3.new(1, 1, 1), Parent = track })
    corner(knob, 8)

    if opts.Tag then
        local tag = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -54, 0.5, 0),
            Size = UDim2.fromOffset(56, 18), BackgroundTransparency = 0.84, Parent = header })
        bind(win, tag, "BackgroundColor3", "Accent")
        corner(tag, 9)
        local tagLbl = label(win, tag, string.upper(tostring(opts.Tag)), 9, "Accent", FONT_BOLD)
        tagLbl.Size = UDim2.fromScale(1, 1)
        tagLbl.TextXAlignment = Enum.TextXAlignment.Center
        tagLbl.TextYAlignment = Enum.TextYAlignment.Center
    end

    local function paint(instant)
        local t = instant and 0 or 0.18
        tw(track, { BackgroundColor3 = value and win.Theme.Accent or win.Theme.Stroke }, t)
        tw(knob, { Position = value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, t)
    end
    paint(true)
    table.insert(cleanup, onTheme(win, paint))

    local function set(v, silent)
        local changed = value ~= (v and true or false)
        value = v and true or false
        paint()
        setFlag(win, opts, value)
        if changed and not silent and opts.Notify ~= false then
            win:Notify({
                Title = value and "Feature Activated" or "Feature Deactivated",
                Content = (opts.Title or "Feature") .. (value and " is now enabled." or " is now disabled."),
                Type = value and "Success" or "Info",
                Duration = opts.NotifyDuration or 2.4,
            })
        end
        if not silent and opts.Callback then task.spawn(opts.Callback, value) end
    end
    hit.MouseButton1Click:Connect(function() set(not value) end)
    hoverable(win, hit, row)

    setFlag(win, opts, value)
    if value and opts.Callback then task.spawn(opts.Callback, value) end

    function obj:Set(v) set(v) end
    function obj:Get() return value end
    return obj
end

--------------------------------------------------------------------------
-- FEATURE CARD  (a Toggle presented as a proper icon card, e.g. ESP)
--  opts: same as Toggle. Icon defaults to "visual"; Tag shows a small pill.
--------------------------------------------------------------------------
local function CreateFeatureCard(tab, opts)
    local o = {}
    for k, v in pairs(opts or {}) do o[k] = v end
    o.Icon = o.Icon or "visual"
    return CreateToggle(tab, o)
end

--------------------------------------------------------------------------
-- SLIDER
--  opts: Title, Description, Icon, Min, Max, Default, Increment, Suffix, Flag, Callback(value)
--------------------------------------------------------------------------
local function CreateSlider(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local min, max = opts.Min or 0, opts.Max or 100
    local inc = opts.Increment or 1
    local dec = decimals(inc)
    local suffix = opts.Suffix or ""
    local value = clamp(opts.Default or min, min, max)

    local row, header, obj = makeRow(tab, opts.Title or "Slider", opts.Description, 70, opts.Icon)
    local valueLbl = label(win, header, "", 13, "Accent", FONT_BOLD)
    valueLbl.AnchorPoint = Vector2.new(1, 0.5)
    valueLbl.Position = UDim2.new(1, 0, 0.5, 0)
    valueLbl.Size = UDim2.fromOffset(64, 18)
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right

    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = row })
    pad(holder, 14, 0, 14, 4)
    local track = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, -2),
        Size = UDim2.new(1, 0, 0, 6), Parent = holder })
    bind(win, track, "BackgroundColor3", "Stroke")
    corner(track, 3)
    local fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = track })
    bind(win, fill, "BackgroundColor3", "Accent")
    corner(fill, 3)
    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), Parent = fill })
    corner(knob, 7)
    stroke(win, knob, "Accent", 2)

    local function render(animate)
        local pct = (value - min) / math.max(max - min, 1e-9)
        valueLbl.Text = string.format("%." .. dec .. "f", value) .. suffix
        if animate then tw(fill, { Size = UDim2.fromScale(pct, 1) }, 0.08)
        else fill.Size = UDim2.fromScale(pct, 1) end
    end

    local function set(v, silent)
        v = clamp(round(v - min, inc) + min, min, max)
        v = tonumber(string.format("%." .. dec .. "f", v))
        local changed = v ~= value
        value = v
        render(true)
        setFlag(win, opts, value)
        if changed and not silent and opts.Callback then task.spawn(opts.Callback, value) end
    end

    dragger(win, holder, function(x)
        local pct = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        set(min + (max - min) * pct)
    end)

    render(false)
    setFlag(win, opts, value)
    if opts.Callback then task.spawn(opts.Callback, value) end

    function obj:Set(v) set(v) end
    function obj:Get() return value end
    return obj
end

--------------------------------------------------------------------------
-- INPUT
--  opts: Title, Description, Default, Placeholder, Numeric, ClearOnFocus, Flag, Callback(text, enter)
--------------------------------------------------------------------------
local function CreateInput(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj = makeRow(tab, opts.Title or "Input", opts.Description, 160)

    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(150, 28), BackgroundTransparency = 0,
        Text = opts.Default or "", PlaceholderText = opts.Placeholder or "Type here...",
        ClearTextOnFocus = opts.ClearOnFocus == true, TextSize = 13,
        ClipsDescendants = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
    bind(win, box, "BackgroundColor3", "Surface")
    bind(win, box, "TextColor3", "Text")
    bind(win, box, "PlaceholderColor3", "SubText")
    corner(box, 6); pad(box, 8, 0, 8, 0)
    local st = stroke(win, box, "Stroke")

    box.Focused:Connect(function() tw(st, { Color = win.Theme.Accent }, 0.15) end)
    box.FocusLost:Connect(function(enter)
        tw(st, { Color = win.Theme.Stroke }, 0.15)
        if opts.Numeric then
            local n = tonumber(box.Text)
            box.Text = n and tostring(n) or ""
        end
        setFlag(win, opts, box.Text)
        if opts.Callback then task.spawn(opts.Callback, box.Text, enter) end
    end)
    setFlag(win, opts, box.Text)

    function obj:Set(t) box.Text = tostring(t); setFlag(win, opts, box.Text) end
    function obj:Get() return box.Text end
    return obj
end

--------------------------------------------------------------------------
-- DROPDOWN
--  opts: Title, Description, Values{}, Default, Multi, Flag, Callback(value | table)
--------------------------------------------------------------------------
local function CreateDropdown(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local multi = opts.Multi == true
    local values = opts.Values or {}
    local selected = {}
    local open = false

    local row, header, obj, cleanup = makeRow(tab, opts.Title or "Dropdown", opts.Description, 170)

    if multi and type(opts.Default) == "table" then
        for _, v in ipairs(opts.Default) do selected[v] = true end
    elseif not multi and opts.Default ~= nil then
        selected[opts.Default] = true
    end

    local hit = New("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = header })
    local arrow = New("TextLabel", {
        Text = "▼", TextSize = 13, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), Parent = header })
    bind(win, arrow, "TextColor3", "SubText")
    local valueLbl = label(win, header, "", 13, "Accent", FONT_BOLD)
    valueLbl.AnchorPoint = Vector2.new(1, 0.5)
    valueLbl.Position = UDim2.new(1, -20, 0.5, 0)
    valueLbl.Size = UDim2.fromOffset(140, 18)
    valueLbl.TextXAlignment = Enum.TextXAlignment.Right

    local container = New("Frame", {
        BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0), Parent = row })
    local list = New("ScrollingFrame", {
        Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, -12),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, Parent = container })
    bind(win, list, "BackgroundColor3", "Surface")
    list.ScrollBarImageColor3 = win.Theme.Accent
    corner(list, 6); pad(list, 4, 4, 4, 4)
    New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

    local items = {}

    local function display()
        local names = {}
        for _, v in ipairs(values) do if selected[v] then table.insert(names, tostring(v)) end end
        if #names == 0 then valueLbl.Text = multi and "None" or "Select..."
        else valueLbl.Text = table.concat(names, ", ") end
    end

    local function result()
        if multi then
            local out = {}
            for _, v in ipairs(values) do if selected[v] then table.insert(out, v) end end
            return out
        end
        for _, v in ipairs(values) do if selected[v] then return v end end
        return nil
    end

    local function paint()
        list.ScrollBarImageColor3 = win.Theme.Accent
        for v, it in pairs(items) do
            local on = selected[v]
            tw(it.btn, { BackgroundTransparency = on and 0.82 or 1, BackgroundColor3 = win.Theme.Accent }, 0.12)
            it.txt.TextColor3 = on and win.Theme.Accent or win.Theme.Text
            it.check.TextColor3 = win.Theme.Accent
            it.check.Visible = on and true or false
        end
        display()
    end
    table.insert(cleanup, onTheme(win, paint))

    local function commit()
        paint()
        local r = result()
        setFlag(win, opts, r)
        if opts.Callback then task.spawn(opts.Callback, r) end
    end

    local function resize()
        local h = math.min(#values, 5) * 30 + 8
        if open then tw(container, { Size = UDim2.new(1, 0, 0, h + 12) }, 0.2) end
    end

    local function build()
        for _, it in pairs(items) do it.btn:Destroy() end
        items = {}
        for i, v in ipairs(values) do
            local btn = New("TextButton", {
                Text = "", Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i,
                BackgroundTransparency = 1, AutoButtonColor = false, Parent = list })
            corner(btn, 5)
            local txt = New("TextLabel", {
                Text = tostring(v), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -30, 1, 0), Parent = btn })
            local check = New("TextLabel", {
                Text = "✓", TextSize = 14, Font = FONT_BOLD, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(16, 16), Parent = btn })
            items[v] = { btn = btn, txt = txt, check = check }
            btn.MouseEnter:Connect(function()
                if not selected[v] then tw(btn, { BackgroundTransparency = 0.6, BackgroundColor3 = win.Theme.ElementHover }, 0.1) end
            end)
            btn.MouseLeave:Connect(function()
                if not selected[v] then tw(btn, { BackgroundTransparency = 1 }, 0.1) end
            end)
            btn.MouseButton1Click:Connect(function()
                if multi then
                    selected[v] = not selected[v] or nil
                else
                    selected = { [v] = true }
                    open = false
                    tw(container, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                    tw(arrow, { Rotation = 0 }, 0.2)
                end
                commit()
            end)
        end
        paint()
        resize()
    end

    hit.MouseButton1Click:Connect(function()
        open = not open
        local h = math.min(#values, 5) * 30 + 8
        tw(container, { Size = UDim2.new(1, 0, 0, open and (h + 12) or 0) }, 0.2)
        tw(arrow, { Rotation = open and 180 or 0 }, 0.2)
    end)
    hoverable(win, hit, row)

    build()
    setFlag(win, opts, result())
    if result() ~= nil and opts.Callback then task.spawn(opts.Callback, result()) end

    function obj:Set(v)
        selected = {}
        if multi and type(v) == "table" then for _, x in ipairs(v) do selected[x] = true end
        elseif v ~= nil then selected[v] = true end
        commit()
    end
    function obj:Get() return result() end
    function obj:Refresh(newValues)
        values = newValues
        for k in pairs(selected) do
            if not table.find(values, k) then selected[k] = nil end
        end
        build()
    end
    return obj
end

--------------------------------------------------------------------------
-- KEYBIND
--  opts: Title, Description, Default (Enum.KeyCode), Flag, Callback(), Changed(key)
--------------------------------------------------------------------------
local function CreateKeybind(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj = makeRow(tab, opts.Title or "Keybind", opts.Description, 100)
    local key = opts.Default
    local listening = false

    local btn = New("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(86, 26), BackgroundTransparency = 0,
        AutoButtonColor = false, TextSize = 12, Font = FONT_BOLD, Parent = header })
    bind(win, btn, "BackgroundColor3", "Surface")
    bind(win, btn, "TextColor3", "Accent")
    corner(btn, 6)
    local st = stroke(win, btn, "Stroke")

    local function render()
        btn.Text = listening and "..." or (key and key.Name or "None")
    end
    render()

    btn.MouseButton1Click:Connect(function()
        listening = true; render()
        tw(st, { Color = win.Theme.Accent }, 0.12)
    end)

    table.insert(win._conns, UIS.InputBegan:Connect(function(i, gp)
        if listening then
            if i.UserInputType == Enum.UserInputType.Keyboard then
                listening = false
                if i.KeyCode == Enum.KeyCode.Escape then
                    -- cancel
                elseif i.KeyCode == Enum.KeyCode.Backspace then
                    key = nil
                    if opts.Changed then task.spawn(opts.Changed, nil) end
                else
                    key = i.KeyCode
                    if opts.Changed then task.spawn(opts.Changed, key) end
                end
                setFlag(win, opts, key)
                render()
                tw(st, { Color = win.Theme.Stroke }, 0.12)
            end
        elseif not gp and key and i.KeyCode == key then
            if opts.Callback then task.spawn(opts.Callback) end
        end
    end))
    setFlag(win, opts, key)

    function obj:Set(k) key = k; setFlag(win, opts, key); render() end
    function obj:Get() return key end
    return obj
end

--------------------------------------------------------------------------
-- COLOR PICKER
--  opts: Title, Description, Default (Color3), Flag, Callback(Color3)
--------------------------------------------------------------------------
local function CreateColorPicker(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj = makeRow(tab, opts.Title or "Color", opts.Description, 60)
    local h, s, v = (opts.Default or Color3.fromRGB(255, 255, 255)):ToHSV()
    local open = false

    local swatch = New("TextButton", {
        Text = "", AutoButtonColor = false, BackgroundTransparency = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 22),
        Parent = header })
    corner(swatch, 7); stroke(win, swatch, "Stroke")
    glow(win, swatch, 2.5, 0.90)

    local panel = New("Frame", {
        BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0), Parent = row })

    local sv = New("Frame", {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -60, 0, 110), Parent = panel })
    corner(sv, 6)
    local white = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv })
    corner(white, 6)
    New("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
    local black = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv })
    corner(black, 6)
    New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
    local svCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1, ZIndex = 3, Parent = sv })
    corner(svCursor, 6)
    New("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = svCursor })

    local hue = New("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.fromOffset(26, 110), BackgroundColor3 = Color3.new(1, 1, 1), Parent = panel })
    corner(hue, 6)
    local seq = {}
    for i = 0, 6 do table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))) end
    New("UIGradient", { Rotation = 90, Color = ColorSequence.new(seq), Parent = hue })
    local hueCursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 6, 0, 5),
        BackgroundColor3 = Color3.new(1, 1, 1), Parent = hue })
    corner(hueCursor, 3)
    New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.5, Parent = hueCursor })

    local function current() return Color3.fromHSV(h, s, v) end
    local function update(silent)
        local c = current()
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        swatch.BackgroundColor3 = c
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.new(0.5, 0, h, 0)
        setFlag(win, opts, c)
        if not silent and opts.Callback then task.spawn(opts.Callback, c) end
    end

    dragger(win, sv, function(x, y)
        s = clamp((x - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
        v = 1 - clamp((y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        update()
    end)
    dragger(win, hue, function(_, y)
        h = clamp((y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 0.999)
        update()
    end)

    swatch.MouseButton1Click:Connect(function()
        open = not open
        tw(panel, { Size = UDim2.new(1, 0, 0, open and 124 or 0) }, 0.22)
    end)

    update(true)
    if opts.Callback then task.spawn(opts.Callback, current()) end

    function obj:Set(c) h, s, v = c:ToHSV(); update() end
    function obj:Get() return current() end
    return obj
end

--------------------------------------------------------------------------
-- STATIC ELEMENTS: Section / Label / Paragraph / Divider
--------------------------------------------------------------------------
local function CreateSection(tab, title, icon)
    local win = tab.Window
    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = tab.Page })

    local line = New("Frame", {
        BackgroundColor3 = win.Theme.Border, BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 1), Position = UDim2.fromOffset(4, 30),
        Parent = holder })

    local prefix = icon and (tostring(icon) .. "  ") or "✦  "
    local l = label(win, holder, prefix .. string.upper(title or "Section"), 13, "Accent", FONT_BOLD)
    l.Size = UDim2.new(1, -8, 0, 28)
    l.Position = UDim2.fromOffset(4, 0)

    local obj = { Instance = holder }
    function obj:SetTitle(t) l.Text = prefix .. string.upper(t) end
    function obj:Destroy() holder:Destroy() end
    function obj:SetVisible(v) holder.Visible = v end
    return obj
end

local function CreateLabel(tab, text)
    local win = tab.Window
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = tab.Page })
    local l = label(win, row, text or "Label", 13, "SubText")
    l.Size = UDim2.new(1, 0, 1, 0); l.Position = UDim2.fromOffset(4, 0)
    local obj = { Instance = row }
    function obj:Set(t) l.Text = t end
    function obj:Destroy() row:Destroy() end
    function obj:SetVisible(v) row.Visible = v end
    return obj
end

local function CreateParagraph(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = tab.Page })
    bind(win, row, "BackgroundColor3", "Element")
    corner(row, 8); stroke(win, row, "Stroke"); pad(row, 14, 12, 14, 12)
    New("UIListLayout", { Padding = UDim.new(0, 4), Parent = row })
    local t = label(win, row, opts.Title or "Paragraph", 14, "Text", FONT_BOLD)
    t.Size = UDim2.new(1, 0, 0, 18)
    local c = label(win, row, opts.Content or "", 13, "SubText")
    c.Size = UDim2.new(1, 0, 0, 0); c.AutomaticSize = Enum.AutomaticSize.Y
    c.TextWrapped = true; c.TextTruncate = Enum.TextTruncate.None; c.TextYAlignment = Enum.TextYAlignment.Top
    local obj = { Instance = row }
    function obj:Set(title, content)
        if title then t.Text = title end
        if content then c.Text = content end
    end
    function obj:Destroy() row:Destroy() end
    function obj:SetVisible(v) row.Visible = v end
    return obj
end

local function CreateDivider(tab)
    local win = tab.Window
    local holder = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), Parent = tab.Page })
    local line = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.new(1, 0, 0, 1), Parent = holder })
    bind(win, line, "BackgroundColor3", "Stroke")
    return { Instance = holder, Destroy = function() holder:Destroy() end }
end

--------------------------------------------------------------------------
-- FAST KEYS  (grid of rebindable quick-action keys)
--  opts: Title, Description, Keys = { { Title, Default (Enum.KeyCode), Flag, Callback(), Changed(key) }, ... }
--  Returns obj with obj.Keys[title] = { Set(key), Get() }
--------------------------------------------------------------------------
local function CreateFastKeys(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local keys = opts.Keys or {}

    local card = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 0.04, Parent = tab.Page })
    bind(win, card, "BackgroundColor3", "Element")
    corner(card, 12); stroke(win, card, "Stroke"); glow(win, card, 3, 0.96)
    pad(card, 14, 12, 14, 14)
    New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

    local hasDesc = opts.Description and opts.Description ~= ""
    local head = New("Frame", {
        BackgroundTransparency = 1, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, hasDesc and 34 or 18), Parent = card })
    local t = label(win, head, opts.Title or "Fast Keys", 14, "Text", FONT_BOLD)
    t.Size = UDim2.new(1, 0, 0, 18)
    if hasDesc then
        local d = label(win, head, opts.Description, 12, "SubText")
        d.Position = UDim2.fromOffset(0, 19); d.Size = UDim2.new(1, 0, 0, 14)
    end

    local grid = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = card })
    New("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 42), CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })

    local obj = { Instance = card, Keys = {} }

    for i, k in ipairs(keys) do
        local key = k.Default
        local listening = false

        local tile = New("Frame", { LayoutOrder = i, Parent = grid })
        bind(win, tile, "BackgroundColor3", "Surface")
        corner(tile, 9)
        local tileStroke = stroke(win, tile, "Stroke")

        local name = label(win, tile, k.Title or ("Key " .. i), 13, "Text", FONT_BOLD)
        name.Position = UDim2.fromOffset(10, 0); name.Size = UDim2.new(1, -86, 1, 0)

        local btn = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(66, 26), BackgroundTransparency = 0,
            AutoButtonColor = false, TextSize = 12, Font = FONT_BOLD, Parent = tile })
        bind(win, btn, "BackgroundColor3", "Element")
        bind(win, btn, "TextColor3", "Accent")
        corner(btn, 6)
        local btnStroke = stroke(win, btn, "Stroke")

        local function render()
            btn.Text = listening and "..." or (key and key.Name or "None")
        end
        render()

        tile.MouseEnter:Connect(function() tw(tileStroke, { Color = win.Theme.Accent }, 0.14) end)
        tile.MouseLeave:Connect(function() tw(tileStroke, { Color = win.Theme.Stroke }, 0.14) end)

        btn.MouseButton1Click:Connect(function()
            listening = true; render()
            tw(btnStroke, { Color = win.Theme.Accent }, 0.12)
        end)

        table.insert(win._conns, UIS.InputBegan:Connect(function(inp, gp)
            if listening then
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    if inp.KeyCode == Enum.KeyCode.Escape then
                        -- cancel
                    elseif inp.KeyCode == Enum.KeyCode.Backspace then
                        key = nil
                        if k.Changed then task.spawn(k.Changed, nil) end
                    else
                        key = inp.KeyCode
                        if k.Changed then task.spawn(k.Changed, key) end
                    end
                    setFlag(win, k, key)
                    render()
                    tw(btnStroke, { Color = win.Theme.Stroke }, 0.12)
                end
            elseif not gp and key and inp.KeyCode == key then
                if k.Callback then task.spawn(k.Callback) end
            end
        end))
        setFlag(win, k, key)

        obj.Keys[k.Title or tostring(i)] = {
            Set = function(nk) key = nk; setFlag(win, k, key); render() end,
            Get = function() return key end,
        }
    end

    function obj:SetVisible(v) card.Visible = v end
    function obj:Destroy() card:Destroy() end
    return obj
end

--------------------------------------------------------------------------
-- SUPPORTED GAMES
--  opts: Games = { { Name, PlaceId, UniverseId, Status ("Working"|"Updating"|"Beta"|"Patched"|"Down"), Note }, ... }
--------------------------------------------------------------------------
local function CreateSupportedGames(tab, opts)
    opts = opts or {}

    local win = tab.Window
    local games = opts.Games or {}

    local statusKey = {
        Working = "Success",
        Updating = "Warning",
        Beta = "Accent",
        Patched = "Danger",
        Down = "Danger",
    }

    local cards = {}

    for i, g in ipairs(games) do
        local isCurrent =
            (g.PlaceId ~= nil and g.PlaceId == game.PlaceId)
            or (g.UniverseId ~= nil and g.UniverseId == game.GameId)

        local status = g.Status or "Working"
        local colorKey = statusKey[status] or "Accent"

        ------------------------------------------------------------------
        -- ROW
        ------------------------------------------------------------------
        local row = New("Frame", {
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundTransparency = 0.04,
            LayoutOrder = i,
            Parent = tab.Page,
        })

        bind(win, row, "BackgroundColor3", "Element")
        corner(row, 12)
        stroke(win, row, isCurrent and "Success" or "Stroke")
        glow(win, row, 3, 0.96)

        ------------------------------------------------------------------
        -- GAME ICON
        -- Small + LEFT side
        ------------------------------------------------------------------
        local chip = New("ImageLabel", {
            Name = "GameIcon",

            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),

            Size = UDim2.fromOffset(36, 36),

            BackgroundTransparency = 1,
            Image = g.Icon or "",
            Parent = row,

            ScaleType = Enum.ScaleType.Crop,
        })

        corner(chip, 9)

        ------------------------------------------------------------------
        -- TEXT
        --
        -- Leave enough room on the RIGHT for:
        --   CURRENT 66px  + spacing
        --   STATUS  92px
        ------------------------------------------------------------------
        local name = label(
            win,
            row,
            tostring(g.Name or "Unknown"),
            14,
            "Text",
            FONT_BOLD
        )

        name.Position = UDim2.fromOffset(60, 10)

        -- Right-side space consumed by status/current badges.
        local rightReserve = isCurrent and 188 or 114

        name.Size = UDim2.new(
            1,
            -(60 + rightReserve),
            0,
            18
        )

        ------------------------------------------------------------------
        -- OPTIONAL NOTE
        ------------------------------------------------------------------
        local note = label(win, row, "", 12, "SubText")
        note.Visible = false

        ------------------------------------------------------------------
        -- STATUS PILL
        ------------------------------------------------------------------
        local pill = New("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),

            Size = UDim2.fromOffset(92, 24),

            BackgroundTransparency = 0.82,
            Parent = row,
        })

        bind(win, pill, "BackgroundColor3", colorKey)
        corner(pill, 12)

        local pdot = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 10, 0.5, 0),

            Size = UDim2.fromOffset(6, 6),

            Parent = pill,
        })

        bind(win, pdot, "BackgroundColor3", colorKey)
        corner(pdot, 3)

        local ptxt = label(
            win,
            pill,
            string.upper(status),
            9,
            colorKey,
            FONT_BOLD
        )

        ptxt.Position = UDim2.fromOffset(22, 0)
        ptxt.Size = UDim2.new(1, -26, 1, 0)
        ptxt.TextYAlignment = Enum.TextYAlignment.Center

        ------------------------------------------------------------------
        -- CURRENT BADGE
        ------------------------------------------------------------------
        if isCurrent then
            local cur = New("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -114, 0.5, 0),

                Size = UDim2.fromOffset(66, 20),

                BackgroundTransparency = 0.82,
                Parent = row,
            })

            bind(win, cur, "BackgroundColor3", "Success")
            corner(cur, 10)

            local ctxt = label(
                win,
                cur,
                "CURRENT",
                9,
                "Success",
                FONT_BOLD
            )

            ctxt.Size = UDim2.fromScale(1, 1)
            ctxt.TextXAlignment = Enum.TextXAlignment.Center
            ctxt.TextYAlignment = Enum.TextYAlignment.Center
        end

        table.insert(cards, row)
    end

    return {
        Instance = cards,

        Destroy = function()
            for _, c in ipairs(cards) do
                c:Destroy()
            end
        end,
    }
end

--------------------------------------------------------------------------
-- SNOW GFX LAYER (small drifting flakes over the whole window; no glyphs)
--------------------------------------------------------------------------
local function createSnow(win, main, count)
    local layer = New("Frame", {
        Name = "SnowLayer", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        ClipsDescendants = true, Active = false, ZIndex = 40, Parent = main })
    win._snow = layer
    local rng = Random.new()
    for _ = 1, count do
        local size = rng:NextInteger(2, 4)
        local flake = New("Frame", {
            Size = UDim2.fromOffset(size, size), BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = rng:NextNumber(0.55, 0.85), ZIndex = 40, Parent = layer })
        corner(flake, size)
        task.spawn(function()
            task.wait(rng:NextNumber(0, 8))
            while flake.Parent do
                local x = rng:NextNumber(0, 1)
                local drift = rng:NextNumber(-0.06, 0.06)
                local dur = rng:NextNumber(7, 13)
                flake.Position = UDim2.new(x, 0, 0, -8)
                tw(flake, { Position = UDim2.new(x + drift, 0, 1, 8) }, dur, Enum.EasingStyle.Linear)
                task.wait(dur)
            end
        end)
    end
end

--------------------------------------------------------------------------
-- HOME DASHBOARD
--------------------------------------------------------------------------
local function createHomeDashboard(win, tab)
    local page = tab.Page
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 196), BackgroundTransparency = 1, LayoutOrder = -1000, Parent = page
    })

    -- One floating glass surface.
    local hero = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 0.10, Parent = holder
    })
    bind(win, hero, "BackgroundColor3", "Surface")
    corner(hero, 18)
    local heroStroke = stroke(win, hero, "Stroke", 1)
    local heroGlow = glow(win, hero, 4, 0.94)

    local accentRail = New("Frame", {
        Position = UDim2.fromOffset(0, 16), Size = UDim2.fromOffset(3, 164), Parent = hero
    })
    bind(win, accentRail, "BackgroundColor3", "Accent")
    corner(accentRail, 2)

    local kicker = label(win, hero, "NOVA / HOME", 9, "Accent", FONT_BOLD)
    kicker.Position = UDim2.fromOffset(18, 14)
    kicker.Size = UDim2.fromOffset(120, 14)

    local welcome = label(win, hero, "Control Center", 24, "Text", FONT_BOLD)
    welcome.Position = UDim2.fromOffset(18, 31)
    welcome.Size = UDim2.new(0.46, 0, 0, 28)

    local player = Players.LocalPlayer
    local display = player and player.DisplayName or "Player"
    local hint = label(win, hero, "Welcome back, " .. display, 11, "SubText")
    hint.Position = UDim2.fromOffset(18, 61)
    hint.Size = UDim2.new(0.46, 0, 0, 16)
    hint.TextTruncate = Enum.TextTruncate.AtEnd

    -- Live script state: animated green signal.
    local statusDock = New("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 14),
        Size = UDim2.fromOffset(142, 30), BackgroundTransparency = 0.80, Parent = hero
    })
    bind(win, statusDock, "BackgroundColor3", "Success")
    corner(statusDock, 15)
    local statusDockGlow = glow(win, statusDock, 3, 0.84)

    local statusDot = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(7, 7), Parent = statusDock
    })
    bind(win, statusDot, "BackgroundColor3", "Success")
    corner(statusDot, 4)
    local statusDotGlow = New("UIStroke", {
        Thickness = 4, Transparency = 0.20, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = statusDot
    })
    bind(win, statusDotGlow, "Color", "Success")

    onTheme(win, function()
        if statusDotGlow.Parent then
            statusDotGlow.Color = win.Theme.Success
        end
    end)

    local statusValue = label(win, statusDock, win._scriptStatus, 10, "Text", FONT_BOLD)
    statusValue.AnchorPoint = Vector2.new(0, 0.5)
    statusValue.Position = UDim2.new(0, 25, 0.5, 0)
    statusValue.Size = UDim2.new(1, -32, 0, 18)
    statusValue.TextXAlignment = Enum.TextXAlignment.Left

    -- Expanded stats row: current game, server population, session timer.
    local stats = New("Frame", {
        Position = UDim2.fromOffset(18, 88), Size = UDim2.new(1, -36, 0, 36),
        BackgroundTransparency = 1, Parent = hero
    })
    New("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -6, 1, 0), CellPadding = UDim2.fromOffset(9, 0),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = stats
    })
    local function statChip(order, caption, value)
        local chip = New("Frame", { LayoutOrder = order, BackgroundTransparency = 0.35, Parent = stats })
        bind(win, chip, "BackgroundColor3", "Element")
        corner(chip, 10)
        stroke(win, chip, "Stroke")
        local cap = label(win, chip, caption, 8, "SubText", FONT_BOLD)
        cap.Position = UDim2.fromOffset(10, 4); cap.Size = UDim2.new(1, -20, 0, 10)
        local val = label(win, chip, value, 12, "Text", FONT_BOLD)
        val.Position = UDim2.fromOffset(10, 16); val.Size = UDim2.new(1, -20, 0, 16)
        return val
    end
    local gameVal = statChip(1, "GAME", win._gameName or "Loading...")
    local playersVal = statChip(2, "SERVER", "-")
    local sessionVal = statChip(3, "SESSION", "00:00")
    win._homeGameLbl = gameVal

    local startedAt = os.clock()
    task.spawn(function()
        while hero.Parent do
            local t = math.floor(os.clock() - startedAt)
            sessionVal.Text = string.format("%02d:%02d", math.floor(t / 60), t % 60)
            playersVal.Text = tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            task.wait(1)
        end
    end)

    -- Player profile dock. The image is the actual Roblox HeadShot thumbnail.
    local playerDock = New("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -13),
        Size = UDim2.new(1, -36, 0, 48), BackgroundTransparency = 1, Parent = hero
    })

    local avatar = New("ImageLabel", {
        Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = win.Theme.Element, BackgroundTransparency = 0.05,
        Image = "", ScaleType = Enum.ScaleType.Crop, Parent = playerDock
    })
    corner(avatar, 24)
    stroke(win, avatar, "Accent", 1)

    local playerName = label(win, playerDock, display, 14, "Text", FONT_BOLD)
    playerName.Position = UDim2.fromOffset(61, 5)
    playerName.Size = UDim2.new(1, -190, 0, 19)
    playerName.TextTruncate = Enum.TextTruncate.AtEnd

    local username = player and player.Name or "Unknown"
    local playerUser = label(win, playerDock, "@" .. username, 10, "SubText")
    playerUser.Position = UDim2.fromOffset(61, 25)
    playerUser.Size = UDim2.new(1, -190, 0, 15)
    playerUser.TextTruncate = Enum.TextTruncate.AtEnd

    -- Premium / Freemium placeholder pill.
    local planPill = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(112, 28), BackgroundTransparency = 0.78, Parent = playerDock
    })
    bind(win, planPill, "BackgroundColor3", "Accent")
    corner(planPill, 14)
    local planDot = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(6, 6), Parent = planPill
    })
    bind(win, planDot, "BackgroundColor3", "Accent")
    corner(planDot, 3)
    local planValue = label(win, planPill, string.upper(win._playerPlan), 9, "Text", FONT_BOLD)
    planValue.Position = UDim2.fromOffset(23, 0)
    planValue.Size = UDim2.new(1, -30, 1, 0)
    planValue.TextXAlignment = Enum.TextXAlignment.Left
    planValue.TextYAlignment = Enum.TextYAlignment.Center

    local trace = New("Frame", {
        Position = UDim2.new(0, 18, 1, -4), Size = UDim2.fromOffset(52, 2), Parent = hero
    })
    bind(win, trace, "BackgroundColor3", "Accent")
    corner(trace, 2)

    task.spawn(function()
        while hero.Parent do
            tw(trace, { Size = UDim2.fromOffset(145, 2), BackgroundTransparency = 0.08 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(heroGlow, { Transparency = 0.84 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(statusDotGlow, { Transparency = 0.03 }, 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(statusDot, { Size = UDim2.fromOffset(9, 9) }, 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.55)
            if not hero.Parent then break end
            tw(trace, { Size = UDim2.fromOffset(52, 2), BackgroundTransparency = 0.32 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(heroGlow, { Transparency = 0.94 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(statusDotGlow, { Transparency = 0.56 }, 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            tw(statusDot, { Size = UDim2.fromOffset(7, 7) }, 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.55)
        end
    end)

    task.spawn(function()
        if not player then return end
        local ok, image = pcall(function()
            local content = Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
            return content
        end)
        if ok and image and avatar.Parent then
            avatar.Image = image
        end
    end)

    win._homeStatus = statusValue
    win._homeStatusDot = statusDot
    win._homeStatusDotGlow = statusDotGlow
    win._homePlan = planValue
    -- Backward-compatible aliases for existing setters.
    win._mainStatus = statusValue
    win._mainStatusDot = statusDot
    win._mainStatusDotGlow = statusDotGlow
    win._mainPlan = planValue
end

--------------------------------------------------------------------------
-- WINDOW
--------------------------------------------------------------------------
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- Independent element functions exposed on the library too:
--   Library.Elements.Button(tab, opts) etc.
Library.Elements = {
    Button = CreateButton, Toggle = CreateToggle, Slider = CreateSlider, Input = CreateInput,
    Dropdown = CreateDropdown, Keybind = CreateKeybind, ColorPicker = CreateColorPicker,
    Section = CreateSection, Label = CreateLabel, Paragraph = CreateParagraph, Divider = CreateDivider,
    FeatureCard = CreateFeatureCard, FastKeys = CreateFastKeys, SupportedGames = CreateSupportedGames,
}



-- v9 layout extensions: screenshot-style cards and collapsible groups
local function CreateCard(tab, opts)
    opts = opts or {}
    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, opts.Height or 120),
        BackgroundColor3 = tab.Window.Theme.Surface,
        BorderSizePixel = 0,
        Parent = tab.Content or tab._content or tab.Window.Content
    })
    corner(frame, 14)
    local title = label(tab.Window, frame, string.upper(opts.Title or "SECTION"), 11, "Text", FONT_BOLD)
    title.Position = UDim2.fromOffset(16, 10)
    title.Size = UDim2.new(1,-32,0,22)
    local line = New("Frame", {Size=UDim2.new(1,-32,0,1), Position=UDim2.fromOffset(16,36), BackgroundColor3=tab.Window.Theme.Border, BorderSizePixel=0, Parent=frame})
    local card = {Frame=frame, Tab=tab}
    function card:Label(text, desc)
        local y = #frame:GetChildren()*22 + 35
        local l = label(tab.Window, frame, text, 14, "Text", FONT_REG)
        l.Position=UDim2.fromOffset(16,y)
        if desc then
            local d=label(tab.Window, frame, desc, 12, "SubText", FONT_REG)
            d.Position=UDim2.fromOffset(16,y+18)
        end
    end
    return card
end

Tab.Card = CreateCard

function Tab:Button(o)         return CreateButton(self, o) end
function Tab:Toggle(o)         return CreateToggle(self, o) end
function Tab:Slider(o)         return CreateSlider(self, o) end
function Tab:Input(o)          return CreateInput(self, o) end
function Tab:Dropdown(o)       return CreateDropdown(self, o) end
function Tab:Keybind(o)        return CreateKeybind(self, o) end
function Tab:ColorPicker(o)    return CreateColorPicker(self, o) end
function Tab:Section(t, icon)    return CreateSection(self, t, icon) end
function Tab:Label(t)          return CreateLabel(self, t) end
function Tab:Paragraph(o)      return CreateParagraph(self, o) end
function Tab:Divider()         return CreateDivider(self) end
function Tab:FeatureCard(o)    return CreateFeatureCard(self, o) end
function Tab:FastKeys(o)       return CreateFastKeys(self, o) end
function Tab:SupportedGames(o) return CreateSupportedGames(self, o) end
function Tab:Select()          self.Window:_select(self) end

local function mergeTheme(t)
    local out = {}
    for k, val in pairs(Library.Themes.Dark) do out[k] = val end
    for k, val in pairs(t) do out[k] = val end
    return out
end

--[[
    Library:CreateWindow{
        Title ("Nova Hub"), SubTitle (optional, appended after game name), GameName (optional override),
        Theme ("Dark" | table), Size (UDim2), ToggleKey (Enum.KeyCode),
        Snow (bool, default true), SnowCount (number), ScriptStatus, PlayerPlan
    }
]]
--------------------------------------------------------------------------
-- NOVA CUSTOM WINDOW ICON SUPPORT
-- Does NOT modify Novalib.lua.
--
-- Supports:
--   Icon = "rbxassetid://123456789"
--   Icon = "123456789"
--   Icon = "rbxthumb://type=GameIcon&id=5595353122&w=150&h=150"
--
-- Optional:
--   IconSize = 30
--   IconCornerRadius = 9
--------------------------------------------------------------------------

do
    local BaseCreateWindow = Library.CreateWindow

    Library.CreateWindow = function(self, opts)
        opts = opts or {}

        -- Copy options so we don't mutate the user's table.
        local newOpts = {}

        for k, v in pairs(opts) do
            newOpts[k] = v
        end

        local win = BaseCreateWindow(self, newOpts)

        ------------------------------------------------------------------
        -- Find the existing header icon created by NovaUI.
        ------------------------------------------------------------------
        local hubIcon = win.Main and win.Main:FindFirstChild("HubIcon", true)

        if hubIcon then
            local hasIcon =
                type(opts.Icon) == "string"
                and opts.Icon ~= ""

            ----------------------------------------------------------------
            -- No icon:
            -- remove the icon completely and reclaim the space.
            ----------------------------------------------------------------
            if not hasIcon then
                hubIcon.Visible = false

            ----------------------------------------------------------------
            -- Icon supplied:
            ----------------------------------------------------------------
            else
                hubIcon.Visible = true

                ------------------------------------------------------------
                -- Accept plain numeric Roblox asset IDs.
                ------------------------------------------------------------
                local icon = opts.Icon

                if icon:match("^%d+$") then
                    icon = "rbxassetid://" .. icon
                end

                hubIcon.Image = icon

                ------------------------------------------------------------
                -- User-configurable size.
                ------------------------------------------------------------
                local iconSize = tonumber(opts.IconSize) or 24

                iconSize = math.clamp(iconSize, 14, 40)

                hubIcon.Size = UDim2.fromOffset(iconSize, iconSize)

                ------------------------------------------------------------
                -- Center icon vertically in header.
                ------------------------------------------------------------
                hubIcon.Position = UDim2.new(
                    0,
                    12,
                    0.5,
                    0
                )

                hubIcon.AnchorPoint = Vector2.new(0, 0.5)

                ------------------------------------------------------------
                -- Rounded icon.
                ------------------------------------------------------------
                local corner = hubIcon:FindFirstChildOfClass("UICorner")

                if corner then
                    corner.CornerRadius = UDim.new(
                        0,
                        math.clamp(
                            tonumber(opts.IconCornerRadius) or 8,
                            0,
                            math.floor(iconSize / 2)
                        )
                    )
                end
            end

            ----------------------------------------------------------------
            -- Fix title positioning.
            --
            -- Existing NovaUI title is hardcoded to X = 44.
            ----------------------------------------------------------------
            local title

            for _, child in ipairs(win.Main:GetDescendants()) do
                if child:IsA("TextLabel")
                    and child.Text == tostring(opts.Title or "Nova Hub")
                then
                    title = child
                    break
                end
            end

            if title then
                if hasIcon then
                    local iconSize = math.clamp(
                        tonumber(opts.IconSize) or 24,
                        14,
                        40
                    )

                    title.Position = UDim2.fromOffset(
                        12 + iconSize + 10,
                        9
                    )
                else
                    title.Position = UDim2.fromOffset(
                        16,
                        9
                    )
                end
            end
        end

        -- Store the icon configuration on the window so you can
        -- change it later without recreating the UI.
        win.Icon = opts.Icon
        win.IconSize = tonumber(opts.IconSize) or 24

        ------------------------------------------------------------------
        -- Runtime icon changer.
        --
        -- Example:
        -- Window:SetIcon("123456789")
        ------------------------------------------------------------------
        function win:SetIcon(icon, size)
            local obj = self.Main
                and self.Main:FindFirstChild("HubIcon", true)

            if not obj then
                return
            end

            if type(icon) ~= "string" or icon == "" then
                obj.Visible = false
                self.Icon = nil
                return
            end

            if icon:match("^%d+$") then
                icon = "rbxassetid://" .. icon
            end

            local iconSize = math.clamp(
                tonumber(size) or self.IconSize or 24,
                14,
                40
            )

            obj.Visible = true
            obj.Image = icon
            obj.Size = UDim2.fromOffset(iconSize, iconSize)
            obj.Position = UDim2.new(0, 12, 0.5, 0)

            local corner = obj:FindFirstChildOfClass("UICorner")

            if corner then
                corner.CornerRadius = UDim.new(
                    0,
                    math.clamp(
                        math.floor(iconSize * 0.30),
                        0,
                        math.floor(iconSize / 2)
                    )
                )
            end

            self.Icon = icon
            self.IconSize = iconSize

            -- Update title position.
            local titleText = tostring(
                self._titleText or opts.Title or "Nova Hub"
            )

            for _, child in ipairs(self.Main:GetDescendants()) do
                if child:IsA("TextLabel")
                    and child.Text == titleText
                then
                    child.Position = UDim2.fromOffset(
                        12 + iconSize + 10,
                        9
                    )
                    break
                end
            end
        end

        return win
    end
end

    -- top bar (larger Nova Hub header: title + version pill, game name underneath)
    local top = New("Frame", { Size = UDim2.new(1, 0, 0, TOP_H), Parent = main })
    bind(win, top, "BackgroundColor3", "Surface")
    corner(top, 12)
    -- filler squares off the bottom corners so only the top ones stay round
    local topFill = New("Frame", { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), Parent = top })
    bind(win, topFill, "BackgroundColor3", "Surface")
    local topLine = New("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = top })
    bind(win, topLine, "BackgroundColor3", "Stroke")

    local hubIcon = New("ImageLabel", {
        Name = "HubIcon",
        AnchorPoint = Vector2.new(0,0.5),
        Position = UDim2.new(0,12,0,21),
        Size = UDim2.fromOffset(24,24),
        BackgroundTransparency = 1,
        Image = opts.Icon or "" ,
        Parent = top })
    corner(hubIcon, 8)
    task.spawn(function()
        while dot.Parent do
            tw(dotGlow, { Transparency = 0.42 }, 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.75)
            if not dot.Parent then break end
            tw(dotGlow, { Transparency = 0.86 }, 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.75)
        end
    end)

    local titleText = opts.Title or "Nova Hub"
    local titleMeasure = TextService:GetTextSize(titleText, 19, FONT_BOLD, Vector2.new(260, 30))
    local titleW = math.min(titleMeasure.X + 4, 200)
    local title = label(win, top, titleText, 19, "Text", FONT_BOLD)
    title.Position = UDim2.fromOffset(44, 9)
    title.Size = UDim2.fromOffset(titleW, 24)

    -- the one and only version display
    local versionPill = New("Frame", {
        Position = UDim2.fromOffset(34 + titleW + 8, 12),
        Size = UDim2.fromOffset(50, 19), BackgroundTransparency = 0.84, Parent = top })
    bind(win, versionPill, "BackgroundColor3", "Accent"); corner(versionPill, 10)
    local versionText = label(win, versionPill, "v." .. tostring(Library.Version), 9, "Accent", FONT_BOLD)
    versionText.Size = UDim2.fromScale(1, 1)
    versionText.TextXAlignment = Enum.TextXAlignment.Center
    versionText.TextYAlignment = Enum.TextYAlignment.Center

    -- game name row
    local gameLbl = label(win, top, "", 11, "SubText")
    gameLbl.Position = UDim2.fromOffset(34, 34)
    gameLbl.Size = UDim2.new(1, -130, 0, 16)
    win._gameLbl = gameLbl
    win:_applyGameName()

    if not opts.GameName then
        task.spawn(function()
            local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
            if ok and info and info.Name and info.Name ~= "" and win.Gui and win.Gui.Parent then
                win:SetGameName(info.Name)
            end
        end)
    end

    local function topButton(text, xOff, hoverKey)
        local b = New("TextButton", {
            Text = text, TextSize = 18, Font = FONT_BOLD, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, xOff, 0.5, 0), Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 1, AutoButtonColor = false, Parent = top })
        bind(win, b, "TextColor3", "SubText")
        bind(win, b, "BackgroundColor3", "Element")
        corner(b, 7)
        b.MouseEnter:Connect(function()
            tw(b, { BackgroundTransparency = 0 }, 0.12); tw(b, { TextColor3 = win.Theme[hoverKey] }, 0.12)
        end)
        b.MouseLeave:Connect(function()
            tw(b, { BackgroundTransparency = 1 }, 0.12); tw(b, { TextColor3 = win.Theme.SubText }, 0.12)
        end)
        return b
    end
    local closeBtn = topButton("×", -12, "Danger")
    local minBtn   = topButton("–", -46, "Text")
    closeBtn.MouseButton1Click:Connect(function() win:Destroy() end)
    minBtn.MouseButton1Click:Connect(function()
        win:Toggle()
        win:Notify({ Title = "Window hidden", Content = "Press " .. win._toggleKey.Name .. " to open it again.", Duration = 3 })
    end)

    -- dragging
    do
        local dragging, startPos, startInput
        top.InputBegan:Connect(function(i)
            if isPress(i) then
                dragging = true; startInput = i.Position; startPos = main.Position
            end
        end)
        table.insert(win._conns, UIS.InputChanged:Connect(function(i)
            if dragging and isMove(i) then
                local d = i.Position - startInput
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end))
        table.insert(win._conns, UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
    end

    -- sidebar
    local side = New("Frame", {
        Position = UDim2.fromOffset(0, TOP_H), Size = UDim2.new(0, 145, 1, -TOP_H), Parent = main })
    bind(win, side, "BackgroundColor3", "Surface")
    side.BackgroundTransparency = 0.26
    corner(side, 14)
    -- fillers square off the top and right corners; only bottom-left stays round (matches the window)
    local sideFillTop = New("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, Parent = side })
    bind(win, sideFillTop, "BackgroundColor3", "Surface")
    local sideFillRight = New("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 12, 1, 0), BackgroundTransparency = 1, Parent = side })
    bind(win, sideFillRight, "BackgroundColor3", "Surface")
    local sideLine = New("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundTransparency = 1, Parent = side })
    bind(win, sideLine, "BackgroundColor3", "Stroke")
    local navLabel = label(win, side, "NAVIGATION", 9, "SubText", FONT_BOLD)
    navLabel.Position = UDim2.fromOffset(14, 12)
    navLabel.Size = UDim2.new(1, -28, 0, 14)

    local tabList = New("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -1, 1, -28), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0, BackgroundTransparency = 1, Parent = side })
    pad(tabList, 10, 7, 10, 10)
    New("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabList })
    win.TabList = tabList

    -- content
    local content = New("Frame", {
        Position = UDim2.fromOffset(145, TOP_H), Size = UDim2.new(1, -145, 1, -TOP_H),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = main })
    win.Content = content

    -- snowflake GFX layer (decorative, never blocks input)
    if opts.Snow ~= false then
        createSnow(win, main, opts.SnowCount or 18)
    end

    -- notifications (fixed-size holder: no AutomaticSize, so nothing can jitter)
    win._notifyHolder = New("Frame", { BackgroundTransparency = 1, Active = false, Name = "Notifications", Parent = gui })
    win._notifyLayout = New("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = win._notifyHolder })
    win._notifyCount, win._notifyList = 0, {}
    win._notifyWidth = opts.NotifyWidth or 300
    local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled
    win:SetNotifyPosition(opts.NotifyPosition or (touchOnly and "TopRight" or "BottomRight"))

    -- toggle key
    table.insert(win._conns, UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == win._toggleKey then win:Toggle() end
    end))

    table.insert(Library.Windows, win)
    return win
end

function Window:_applyGameName()
    local text = tostring(self._gameName or "Unknown Game")
    local header = self._subTitle and (text .. "  |  " .. tostring(self._subTitle)) or text
    if self._gameLbl and self._gameLbl.Parent then self._gameLbl.Text = header end
    if self._homeGameLbl and self._homeGameLbl.Parent then self._homeGameLbl.Text = text end
end

function Window:SetGameName(name)
    self._gameName = tostring(name or "Unknown Game")
    self:_applyGameName()
end

function Window:GetGameName()
    return self._gameName
end

function Window:SetSnow(on)
    if self._snow then self._snow.Visible = on and true or false end
end

function Window:Toggle()
    local showing = not self.Main.Visible
    if showing then
        self.Main.Visible = true
        local scale = self.Main:FindFirstChildOfClass("UIScale")
        if scale then
            scale.Scale = 0.96
            tw(scale, { Scale = 1 }, 0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    else
        local scale = self.Main:FindFirstChildOfClass("UIScale")
        if scale then
            tw(scale, { Scale = 0.96 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        end
        task.delay(0.15, function()
            if self.Main and self.Main.Parent and not showing then self.Main.Visible = false end
        end)
    end
end

function Window:SetScriptStatus(text, colorKey)
    self._scriptStatus = tostring(text or "Unknown")
    if self._mainStatus then self._mainStatus.Text = self._scriptStatus end
    if self._mainStatusDot and colorKey and self.Theme[colorKey] then
        self._mainStatusDot.BackgroundColor3 = self.Theme[colorKey]
        if self._mainStatusDotGlow then
            self._mainStatusDotGlow.Color = self.Theme[colorKey]
        end
    end
end

function Window:GetScriptStatus()
    return self._scriptStatus
end

function Window:SetPlayerPlan(text)
    self._playerPlan = tostring(text or "Freemium")
    if self._mainPlan then self._mainPlan.Text = string.upper(self._playerPlan) end
end

function Window:GetPlayerPlan()
    return self._playerPlan
end

function Window:Destroy()
    for _, c in ipairs(self._conns) do c:Disconnect() end
    self.Gui:Destroy()
end

function Window:SetTheme(t)
    local theme
    if type(t) == "string" then
        theme = Library.Themes[t]
        assert(theme, "NovaUI: unknown theme '" .. t .. "'")
    else
        theme = t
    end
    self.Theme = mergeTheme(theme)
    for i = #self._bound, 1, -1 do
        local b = self._bound[i]
        if b[1]:IsDescendantOf(self.Gui) then
            tw(b[1], { [b[2]] = self.Theme[b[3]] }, 0.25)
        else
            table.remove(self._bound, i)
        end
    end
    for _, fn in pairs(self._themeCbs) do task.spawn(fn) end
end

function Window:_select(tab)
    if self._active == tab then return end
    for _, t in ipairs(self.Tabs) do
        local on = t == tab
        t.Page.Visible = on
        tw(t._btn, {
            BackgroundTransparency = on and 0.94 or 1,
        }, 0.18, Enum.EasingStyle.Quint)
        tw(t._indicator, {
            BackgroundTransparency = on and 0 or 1,
            Size = UDim2.new(0, 3, 0, on and 20 or 7),
        }, 0.20, Enum.EasingStyle.Back)
        if on then
            t.Page.Position = UDim2.fromOffset(18, 0)
            tw(t.Page, { Position = UDim2.fromOffset(0, 0) }, 0.28, Enum.EasingStyle.Quint)
        else
            t.Page.Position = UDim2.fromOffset(0, 0)
        end
        if t._label then
            t._label.TextColor3 = on and self.Theme.Text or self.Theme.SubText
        end
        if t._iconPaint then
            t._iconPaint(on)
        elseif t._icon then
            if t._icon:IsA("ImageLabel") then
                t._icon.ImageColor3 = on and self.Theme.Accent or self.Theme.SubText
            elseif t._icon:IsA("TextLabel") then
                t._icon.TextColor3 = on and self.Theme.Accent or self.Theme.SubText
            end
        end
        if t._iconBubble then
            tw(t._iconBubble, { BackgroundTransparency = on and 0.90 or 1 }, 0.18)
        end
        if t._iconScale then
            tw(t._iconScale, { Scale = on and 1.08 or 1 }, 0.20, Enum.EasingStyle.Back)
        end
        if t._tabGlow then
            tw(t._tabGlow, { Transparency = on and 0.72 or 0.94 }, 0.20)
        end
    end
    self._active = tab
end

--[[ Window:Tab{ Title, Icon (asset id OR emoji/symbol OR native kind, optional), Badge (optional), Group (optional sidebar header) } ]]
function Window:Tab(opts)
    opts = opts or {}
    local win = self
    local tab = setmetatable({ Window = win }, Tab)

    -- sidebar group header (tab organisation)
    win._navOrder += 1
    if opts.Group and opts.Group ~= win._lastGroup then
        win._lastGroup = opts.Group
        local gl = New("TextButton", {
            Text = "▼  " .. string.upper(tostring(opts.Group)),
            Font = FONT_BOLD,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 38),
            LayoutOrder = win._navOrder,
            Parent = win.TabList
        })
        bind(win, gl, "TextColor3", "SubText")
        pad(gl, 8, 4, 0, 0)

        local groupChildren = {}
        local collapsed = false
        gl.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            gl.Text = collapsed and "▶  " .. string.upper(tostring(opts.Group)) or "▼  " .. string.upper(tostring(opts.Group))
            for _, child in ipairs(groupChildren) do
                if collapsed then
                    local tw = TweenService:Create(child, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0)})
                    tw:Play()
                    task.delay(0.22, function() if collapsed then child.Visible = false end end)
                else
                    child.Visible = true
                    child.Size = UDim2.new(1,0,0,0)
                    local tw = TweenService:Create(child, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2.new(1,0,0,26)})
                    tw:Play()
                end
            end
        end)

        win._activeGroupChildren = groupChildren
        win._navOrder += 1
    end

    local btn = New("TextButton", {
        Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1, LayoutOrder = win._navOrder, Parent = win.TabList })
    btn.BackgroundColor3 = win.Theme.Accent
    table.insert(win._bound, { btn, "BackgroundColor3", "Accent" })
    corner(btn, 9)

    if win._activeGroupChildren then
        table.insert(win._activeGroupChildren, btn)
    end

    local ind = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 7), BackgroundTransparency = 1, Parent = btn })
    bind(win, ind, "BackgroundColor3", "Accent"); corner(ind, 2)

    local tabGlow = glow(win, btn, 2.5, 0.94)

    local iconBubble = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Parent = btn })
    bind(win, iconBubble, "BackgroundColor3", "Accent")
    corner(iconBubble, 8)
    local iconScale = New("UIScale", { Scale = 1, Parent = iconBubble })

    local iconValue = opts.Icon
    if iconValue == nil then
        local kind = iconKindFor(opts.Title or "Tab")
        local iconInst, iconPaint = createNativeIcon(win, iconBubble, kind)
        tab._iconKind = kind
        tab._iconPaint = iconPaint
    else
        local iconInst
        if isImage(iconValue) then
            iconInst = New("ImageLabel", {
                Image = toImage(iconValue), BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(18, 18), ImageColor3 = win.Theme.SubText, Parent = iconBubble })
        else
            -- Explicit text/emoji remains supported; automatic icons use native shapes so unsupported glyphs never become squares.
            iconInst = New("TextLabel", {
                Text = tostring(iconValue), Font = FONT_BOLD, TextSize = 10,
                TextColor3 = win.Theme.SubText, TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = iconBubble })
        end
        tab._icon = iconInst
    end

    local iconInst = tab._icon or iconBubble:FindFirstChildOfClass("Frame")

    local lbl = New("TextLabel", {
        Text = opts.Title or "Tab", Font = FONT_BOLD, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(38, 0),
        Size = UDim2.new(1, -(opts.Badge and 68 or 48), 1, 0), TextColor3 = win.Theme.SubText, Parent = btn })

    local badge
    if opts.Badge ~= nil then
        badge = New("TextLabel", {
            Text = tostring(opts.Badge), Font = FONT_BOLD, TextSize = 9,
            TextColor3 = win.Theme.AccentText, BackgroundColor3 = win.Theme.Accent,
            BackgroundTransparency = 0.10, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(24, 17),
            TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, Parent = btn })
        corner(badge, 9)
        bind(win, badge, "BackgroundColor3", "Accent")
        bind(win, badge, "TextColor3", "AccentText")
    end

    local page = New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, BackgroundTransparency = 1, Visible = false, Parent = win.Content })
    page.ScrollBarImageColor3 = win.Theme.Accent
    table.insert(win._bound, { page, "ScrollBarImageColor3", "Accent" })
    pad(page, 16, 16, 16, 16)
    New("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    tab._btn, tab._label, tab._indicator, tab.Page = btn, lbl, ind, page
    tab._icon, tab._iconBubble, tab._iconScale, tab._tabGlow = iconInst, iconBubble, iconScale, tabGlow
    table.insert(win.Tabs, tab)

    btn.MouseEnter:Connect(function()
        if win._active ~= tab then
            tw(btn, { BackgroundTransparency = 0.91 }, 0.16, Enum.EasingStyle.Quint)
            tw(tabGlow, { Transparency = 0.86 }, 0.16, Enum.EasingStyle.Quint)
        end
        tw(iconScale, { Scale = win._active == tab and 0.98 or 0.94 }, 0.18, Enum.EasingStyle.Back)
    end)
    btn.MouseLeave:Connect(function()
        if win._active ~= tab then
            tw(btn, { BackgroundTransparency = 1 }, 0.18, Enum.EasingStyle.Quint)
            tw(tabGlow, { Transparency = 0.96 }, 0.18, Enum.EasingStyle.Quint)
        end
        tw(iconScale, { Scale = win._active == tab and 0.97 or 0.91 }, 0.18, Enum.EasingStyle.Back)
    end)
    btn.MouseButton1Down:Connect(function()
        tw(iconScale, { Scale = 0.86 }, 0.08, Enum.EasingStyle.Quad)
    end)
    btn.MouseButton1Up:Connect(function()
        tw(iconScale, { Scale = win._active == tab and 0.98 or 0.94 }, 0.14, Enum.EasingStyle.Back)
    end)
    btn.MouseButton1Click:Connect(function() win:_select(tab) end)

    onTheme(win, function()
        local on = win._active == tab
        lbl.TextColor3 = on and win.Theme.Text or win.Theme.SubText
        iconBubble.BackgroundColor3 = win.Theme.Accent
        if tab._iconPaint then
            tab._iconPaint(on)
        elseif iconInst:IsA("ImageLabel") then
            iconInst.ImageColor3 = on and win.Theme.Accent or win.Theme.SubText
        elseif iconInst:IsA("TextLabel") then
            iconInst.TextColor3 = on and win.Theme.Accent or win.Theme.SubText
        end
        if badge then
            badge.BackgroundColor3 = win.Theme.Accent
            badge.TextColor3 = win.Theme.AccentText
        end
    end)

    local tabTitleLower = string.lower(tostring(opts.Title or ""))
    if tabTitleLower == "home" or tabTitleLower:find("home", 1, true) then
        createHomeDashboard(win, tab)
    end

    if #win.Tabs == 1 then win:_select(tab) end
    return tab
end

--[[
    Window:MiscTab{ Title ("Misc"), Group ("Hub"), FastKeys = { Title, Description, Keys = {...} } }
    New Misc tab: Fast Keys card + a few utilities. Returns the tab so you can add more.
]]
function Window:MiscTab(opts)
    opts = opts or {}
    local win = self
    local tab = win:Tab({ Title = opts.Title or "Misc", Icon = opts.Icon, Group = opts.Group or "Hub" })

    local fk = opts.FastKeys or {}
    tab:FastKeys({
        Title = fk.Title or "Fast Keys",
        Description = fk.Description or "Click a key to rebind it. Backspace clears, Escape cancels.",
        Keys = fk.Keys or {},
    })

    tab:Section("Utilities")
    tab:Button({
        Title = "Copy Place ID", Description = "Copies this game's Place ID to your clipboard.", Icon = "misc",
        Callback = function()
            local ok = pcall(function() setclipboard(tostring(game.PlaceId)) end)
            win:Notify({
                Title = ok and "Copied" or "Clipboard unavailable",
                Content = ok and ("Place ID " .. tostring(game.PlaceId) .. " copied.") or "Your executor has no setclipboard.",
                Type = ok and "Success" or "Warning", Duration = 2.4,
            })
        end,
    })
    tab:Button({
        Title = "Rejoin Server", Description = "Teleports you back into this same server.", Icon = "movement",
        Callback = function()
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            end)
        end,
    })
    return tab
end

--[[
    Window:SupportedGamesTab{ Title ("Supported Games"), Group ("Hub"), Games = { {Name, PlaceId, Status, Note}, ... } }
]]
function Window:SupportedGamesTab(opts)
    opts = opts or {}
    local tab = self:Tab({ Title = opts.Title or "Supported Games", Icon = opts.Icon, Group = opts.Group or "Hub" })
    tab:Section("Supported Games")
    tab:SupportedGames({ Games = opts.Games or {} })
    return tab
end

function Window:_notifyW()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize.X or 800
    return math.max(180, math.min(self._notifyWidth, vp - 32))
end

--[[ Window:SetNotifyPosition("TopRight" | "TopLeft" | "BottomRight" | "BottomLeft") ]]
function Window:SetNotifyPosition(pos)
    pos = pos or "BottomRight"
    local top, left = pos:find("Top") ~= nil, pos:find("Left") ~= nil
    self._notifyPos = { top = top, left = left }
    local m = 16
    local h = self._notifyHolder
    h.AnchorPoint = Vector2.new(left and 0 or 1, top and 0 or 1)
    h.Position = UDim2.new(left and 0 or 1, left and m or -m, top and 0 or 1, top and m + 4 or -m)
    h.Size = UDim2.new(0, self:_notifyW(), 1, -(m * 2 + 4))
    self._notifyLayout.VerticalAlignment = top and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
    self._notifyLayout.HorizontalAlignment = left and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
end

function Window:ClearNotifications()
    for _, n in ipairs(table.clone(self._notifyList)) do n.Close() end
end

--[[
    Window:Notify{ Title, Content, Duration (seconds, 0 = stays until clicked),
                   Type ("Info"|"Success"|"Warning"|"Error") }
    Returns a handle: handle.Close()
    Click a notification to dismiss it.
]]
function Window:Notify(opts)
    if type(opts) == "string" then opts = { Title = opts } end
    opts = opts or {}
    local win = self
    local T = win.Theme
    local kind = opts.Type or "Info"
    local color = T[({ Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger" })[kind] or "Accent"]
    local glyph = ({ Info = "ⓘ", Success = "✓", Warning = "⚠", Error = "✕" })[kind] or "ⓘ"
    local duration = opts.Duration
    if duration == nil then duration = 4 end
    local timed = type(duration) == "number" and duration > 0 and duration < 3600

    local width = win:_notifyW()
    local title = opts.Title or "Notification"
    local content = opts.Content or ""

    -- keep the stack tidy: max 5 at once
    while #win._notifyList >= 5 do win._notifyList[1].Close() end

    -- measure text up front so the card has a fixed, exact height (no layout feedback loops)
    local textX, textW = 50, width - 50 - 32
    local textH = 0
    if content ~= "" then
        textH = math.ceil(TextService:GetTextSize(content, 13, FONT, Vector2.new(textW, 1000)).Y)
    end
    local height = 12 + 18 + (textH > 0 and (3 + textH) or 0) + (timed and 20 or 14)
    height = math.max(height, 58)

    win._notifyCount += 1
    local wrap = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        LayoutOrder = win._notifyCount, Parent = win._notifyHolder })

    local slide = win._notifyPos.left and -40 or 40
    local card = New("CanvasGroup", {
        Size = UDim2.new(1, 0, 0, height), Position = UDim2.fromOffset(slide, 0),
        GroupTransparency = 1, BackgroundColor3 = T.Surface, Parent = wrap })
    corner(card, 10)
    New("UIStroke", { Color = T.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
    New("UIStroke", { Color = color, Thickness = 4, Transparency = 0.91, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })

    local hit = New("TextButton", { Text = "", Size = UDim2.fromScale(1, 1), Parent = card })

    local icon = New("Frame", {
        Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = color, BackgroundTransparency = 0.8, Parent = card })
    corner(icon, 14)
    New("TextLabel", {
        Text = glyph, Font = FONT_BOLD, TextSize = 16, TextColor3 = color,
        Size = UDim2.fromScale(1, 1), Parent = icon })

    New("TextLabel", {
        Text = title, Font = FONT_BOLD, TextSize = 14, TextColor3 = T.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Position = UDim2.fromOffset(textX, 12), Size = UDim2.fromOffset(textW, 18), Parent = card })
    if textH > 0 then
        New("TextLabel", {
            Text = content, TextSize = 13, TextColor3 = T.SubText, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
            Position = UDim2.fromOffset(textX, 33), Size = UDim2.fromOffset(textW, textH), Parent = card })
    end
    New("TextLabel", {
        Text = "×", Font = FONT_BOLD, TextSize = 16, TextColor3 = T.SubText,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
        Size = UDim2.fromOffset(16, 16), Parent = card })

    local fill
    if timed then
        local track = New("Frame", {
            Position = UDim2.new(0, 12, 1, -10), Size = UDim2.new(1, -24, 0, 3),
            BackgroundColor3 = T.Stroke, Parent = card })
        corner(track, 2)
        fill = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = track })
        corner(fill, 2)
    end

    -- handle / dismiss
    local closed = false
    local handle = {}
    function handle.Close()
        if closed then return end
        closed = true
        local i = table.find(win._notifyList, handle)
        if i then table.remove(win._notifyList, i) end
        tw(card, { Position = UDim2.fromOffset(slide, 0), GroupTransparency = 1 }, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function()
            tw(wrap, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
            task.delay(0.24, function() wrap:Destroy() end)
        end)
    end
    table.insert(win._notifyList, handle)
    hit.MouseButton1Click:Connect(handle.Close)

    -- animate in: stack makes room first, card glides in while fading
    tw(wrap, { Size = UDim2.new(1, 0, 0, height) }, 0.22)
    tw(card, { Position = UDim2.fromOffset(0, 0), GroupTransparency = 0 }, 0.35, Enum.EasingStyle.Quint)
    if timed then
        tw(fill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)
        task.delay(duration, handle.Close)
    end
    return handle
end


--------------------------------------------------------------------------
-- NOVA UI QUALITY LAYER (additive compatibility enhancements)
-- Keeps the existing library/API intact. This layer only augments windows
-- after the base implementation has finished building them.
--------------------------------------------------------------------------
local NOVA_QUALITY_GROUPS = {
    Main = 10,
    Features = 20,
    Hub = 30,
}

local function novaInferGroup(title)
    local s = string.lower(tostring(title or ""))
    if s == "home" or s == "main" or s:find("home", 1, true) or s:find("dashboard", 1, true) then
        return "Main"
    end
    if s:find("player", 1, true) or s:find("combat", 1, true) or s:find("aim", 1, true)
        or s:find("target", 1, true) or s:find("visual", 1, true) or s:find("esp", 1, true)
        or s:find("movement", 1, true) or s:find("speed", 1, true) or s:find("fly", 1, true) then
        return "Features"
    end
    if s:find("misc", 1, true) or s:find("key", 1, true) or s:find("game", 1, true)
        or s:find("setting", 1, true) or s:find("config", 1, true) or s:find("about", 1, true)
        or s:find("info", 1, true) then
        return "Hub"
    end
    return nil
end

local function novaFindTab(win, matcher)
    local wanted = string.lower(tostring(matcher or ""))
    for _, tab in ipairs(win.Tabs or {}) do
        local title = string.lower(tostring(tab.Title or (tab._label and tab._label.Text) or ""))
        if title == wanted or title:find(wanted, 1, true) then
            return tab
        end
    end
    return nil
end

local function novaThemeGlass(win, parent)
    local sheen = New("Frame", {
        Name = "NovaGlassSheen",
        Position = UDim2.fromScale(0, 0), Size = UDim2.new(1, 0, 0, 1),
        BackgroundTransparency = 0.72, ZIndex = 2, Parent = parent,
    })
    bind(win, sheen, "BackgroundColor3", "Accent")

    local strokeLine = New("UIStroke", {
        Thickness = 1,
        Transparency = 0.86,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = sheen,
    })
    bind(win, strokeLine, "Color", "Accent")

    return sheen
end

local function novaAddHomeQuickLaunch(win, tab)
    if not tab or tab._novaQuickLaunch then return end
    tab._novaQuickLaunch = true

    local holder = New("Frame", {
        Name = "NovaQuickLaunch",
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundTransparency = 1,
        LayoutOrder = -998,
        Parent = tab.Page,
    })

    local grid = New("UIGridLayout", {
        CellSize = UDim2.new(1 / 3, -6, 1, 0),
        CellPadding = UDim2.fromOffset(9, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = holder,
    })

    local function launchCard(order, icon, title, description, finder)
        local card = New("TextButton", {
            Text = "", AutoButtonColor = false,
            LayoutOrder = order, BackgroundTransparency = 0.14,
            ZIndex = 2, Parent = holder,
        })
        bind(win, card, "BackgroundColor3", "Element")
        corner(card, 13)
        local st = stroke(win, card, "Stroke", 1)
        local gl = glow(win, card, 3, 0.96)

        local iconBubble = New("Frame", {
            Position = UDim2.fromOffset(10, 11),
            Size = UDim2.fromOffset(28, 28),
            BackgroundTransparency = 0.84,
            Parent = card,
        })
        bind(win, iconBubble, "BackgroundColor3", "Accent")
        corner(iconBubble, 9)
        local _, iconPaint = createNativeIcon(win, iconBubble, icon)
        iconPaint(false)

        local t = label(win, card, title, 12, "Text", FONT_BOLD)
        t.Position = UDim2.fromOffset(48, 9)
        t.Size = UDim2.new(1, -58, 0, 17)

        local d = label(win, card, description, 10, "SubText")
        d.Position = UDim2.fromOffset(48, 28)
        d.Size = UDim2.new(1, -58, 0, 28)
        d.TextWrapped = true
        d.TextTruncate = Enum.TextTruncate.AtEnd
        d.TextYAlignment = Enum.TextYAlignment.Top

        card.MouseEnter:Connect(function()
            tw(card, { BackgroundColor3 = win.Theme.ElementHover }, 0.13, Enum.EasingStyle.Quint)
            tw(st, { Thickness = 1.35 }, 0.13, Enum.EasingStyle.Quint)
            tw(gl, { Transparency = 0.78 }, 0.13, Enum.EasingStyle.Quint)
            iconPaint(true)
        end)
        card.MouseLeave:Connect(function()
            tw(card, { BackgroundColor3 = win.Theme.Element }, 0.16, Enum.EasingStyle.Quint)
            tw(st, { Thickness = 1 }, 0.13, Enum.EasingStyle.Quint)
            tw(gl, { Transparency = 0.96 }, 0.16, Enum.EasingStyle.Quint)
            iconPaint(false)
        end)
        card.MouseButton1Click:Connect(function()
            local target = finder and finder()
            if target then win:_select(target) end
        end)
    end

    launchCard(1, "visual", "ESP", "Open visual features and overlays.", function()
        return novaFindTab(win, "visual") or novaFindTab(win, "esp")
    end)
    launchCard(2, "keys", "Fast Keys", "Jump to your quick-action bindings.", function()
        return novaFindTab(win, "misc") or novaFindTab(win, "key")
    end)
    launchCard(3, "games", "Supported Games", "Browse support status and the current game.", function()
        return novaFindTab(win, "supported games") or novaFindTab(win, "games")
    end)
end

local function novaAddESPFeatureCard(win, tab, title)
    if not tab or tab._novaESPCard then return end
    local lower = string.lower(tostring(title or ""))
    if not lower:find("visual", 1, true) and not lower:find("esp", 1, true) then return end

    local alreadyExists = false
    for _, d in ipairs(tab.Page:GetDescendants()) do
        if d:IsA("TextLabel") and string.lower(tostring(d.Text or "")) == "esp" then
            alreadyExists = true
            break
        end
    end
    if alreadyExists then return end

    tab._novaESPCard = tab:FeatureCard({
        Title = "ESP",
        Description = "Visual feature card placeholder for your ESP implementation.",
        Icon = "visual",
        Tag = "VISUAL",
        Default = false,
        Notify = false,
    })
end

local function novaApplyQuality(win)
    if not win or win._novaQualityApplied or not win.Main then return end
    win._novaQualityApplied = true

    -- A single extra glass sheen instead of introducing another competing
    -- version/status badge. The existing version pill remains the only one.
    novaThemeGlass(win, win.Main)

    -- Refine the existing header without changing its public API.
    if win.Main then
        local top = win.Main:FindFirstChildWhichIsA("Frame")
        if top then
            local topHighlight = New("Frame", {
                Name = "NovaHeaderHighlight",
                Position = UDim2.new(0, 12, 1, -2),
                Size = UDim2.new(1, -24, 0, 2),
                BackgroundTransparency = 0.20,
                ZIndex = 3,
                Parent = top,
            })
            bind(win, topHighlight, "BackgroundColor3", "Accent")
            corner(topHighlight, 1)
            task.spawn(function()
                while topHighlight.Parent do
                    tw(topHighlight, { BackgroundTransparency = 0.58 }, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(1.6)
                    if not topHighlight.Parent then break end
                    tw(topHighlight, { BackgroundTransparency = 0.16 }, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(1.6)
                end
            end)
        end
    end

    -- Rebalance sidebar spacing by giving group labels a little more breathing room.
    if win.TabList then
        local list = win.TabList:FindFirstChildOfClass("UIListLayout")
        if list then list.Padding = UDim.new(0, 6) end
        local navLabel = win.TabList.Parent and win.TabList.Parent:FindFirstChild("TextLabel")
        if navLabel then navLabel.Text = "NOVA NAVIGATION" end
    end

    -- Make the existing notification stack slightly more glass-like.
    if win._notifyHolder then
        win._notifyHolder.ZIndex = 60
    end
end

-- Wrap the finished CreateWindow function rather than rewriting the base window
-- implementation. Existing callers continue to use the same CreateWindow API.
do
    local _NovaBaseCreateWindow = Library.CreateWindow

    Library.CreateWindow = function(self, opts)
        local userOpts = opts or {}
        local win = _NovaBaseCreateWindow(self, userOpts)
        novaApplyQuality(win)

        local baseTab = win.Tab
        if not win._novaTabWrapper then
            win._novaTabWrapper = true
            win.Tab = function(w, tabOpts)
                tabOpts = tabOpts or {}
                local nextOpts = {}
                for k, v in pairs(tabOpts) do nextOpts[k] = v end
                if nextOpts.Group == nil then
                    nextOpts.Group = novaInferGroup(nextOpts.Title)
                end

                local tab = baseTab(w, nextOpts)
                tab._novaGroup = nextOpts.Group
                tab._novaTitle = tostring(nextOpts.Title or "Tab")

                -- Keep the requested ESP card UI confined to relevant tabs and
                -- avoid duplicating it when the user already supplied one.
                novaAddESPFeatureCard(w, tab, tab._novaTitle)
                if string.lower(tab._novaTitle) == "home" or string.lower(tab._novaTitle):find("home", 1, true) then
                    novaAddHomeQuickLaunch(w, tab)
                end
                return tab
            end
        end

        return win
    end
end

return Library
