--[[
    NovaUI  |  A clean, themeable Luau UI library inspired by WindUI
    ---------------------------------------------------------------
    Elements (each one is its own independent function):
        Tab:Section / Label / Paragraph / Divider
        Tab:Button / Toggle / Slider / Input / Dropdown / Keybind / ColorPicker
    Window:
        Window:Tab, Window:Notify, Window:SetTheme, Window:Toggle, Window:Destroy
    Themes:
        Dark, Light, Ocean, Rose, Emerald, Amethyst  (or pass your own table)
]]

local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local Players      = game:GetService("Players")
local CoreGui      = game:GetService("CoreGui")
local TextService  = game:GetService("TextService")

local Library = { Version = "1.1.0", Windows = {} }

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
    if s:find("main") or s:find("home") or s:find("dashboard") then return "home" end
    if s:find("player") then return "player" end
    if s:find("aim") or s:find("combat") or s:find("target") then return "combat" end
    if s:find("visual") or s:find("esp") or s:find("render") then return "visual" end
    if s:find("movement") or s:find("speed") or s:find("fly") then return "movement" end
    if s:find("setting") or s:find("config") then return "settings" end
    if s:find("info") or s:find("about") then return "info" end
    if s:find("script") or s:find("misc") then return "misc" end
    return "misc"
end

local function newIconPart(parent, size, position, color, radius, rotation)
    local f = New("Frame", {
        Size = size, Position = position, BackgroundColor3 = color, BackgroundTransparency = 0, Parent = parent })
    if radius then corner(f, radius) end
    if rotation then f.Rotation = rotation end
    return f
end

local function createNativeIcon(win, parent, kind)
    local holder = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = parent })
    holder:SetAttribute("NovaIconKind", kind)
    local iconScale = New("UIScale", { Scale = 0.72, Parent = holder })

    local parts = {}
    local function part(size, pos, radius, rotation, strokeMode)
        local f = newIconPart(holder, size, pos, win.Theme.SubText, radius, rotation)
        table.insert(parts, f)
        if strokeMode then
            local st = New("UIStroke", { Thickness = 1.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
            bind(win, st, "Color", "SubText")
        else
            bind(win, f, "BackgroundColor3", "SubText")
        end
        return f
    end

    if kind == "home" then
        part(UDim2.fromOffset(10, 9), UDim2.fromOffset(9, 12), 2, 0)
        part(UDim2.fromOffset(8, 6), UDim2.fromOffset(4, 8), 1, -45)
        part(UDim2.fromOffset(8, 6), UDim2.fromOffset(12, 8), 1, 45)
        part(UDim2.fromOffset(3, 5), UDim2.fromOffset(12, 16), 1, 0)
    elseif kind == "player" then
        part(UDim2.fromOffset(7, 7), UDim2.fromOffset(10, 4), 4, 0)
        part(UDim2.fromOffset(13, 8), UDim2.fromOffset(7, 13), 6, 0)
    elseif kind == "visual" then
        local ring = part(UDim2.fromOffset(17, 17), UDim2.fromOffset(5, 5), 9, 0, true)
        ring.BackgroundTransparency = 1
        part(UDim2.fromOffset(5, 5), UDim2.fromOffset(11, 11), 3, 0)
    elseif kind == "combat" then
        local ring = part(UDim2.fromOffset(17, 17), UDim2.fromOffset(5, 5), 9, 0, true)
        ring.BackgroundTransparency = 1
        part(UDim2.fromOffset(3, 11), UDim2.fromOffset(12, 7), 1, 0)
        part(UDim2.fromOffset(11, 3), UDim2.fromOffset(8, 12), 1, 0)
    elseif kind == "movement" then
        part(UDim2.fromOffset(15, 3), UDim2.fromOffset(6, 12), 2, -45)
        part(UDim2.fromOffset(8, 3), UDim2.fromOffset(5, 7), 2, 45)
        part(UDim2.fromOffset(3, 12), UDim2.fromOffset(12, 7), 1, 0)
    elseif kind == "settings" then
        local gear = part(UDim2.fromOffset(11, 11), UDim2.fromOffset(8, 8), 3, 0, true)
        gear.BackgroundTransparency = 1
        part(UDim2.fromOffset(3, 15), UDim2.fromOffset(12, 6), 1, 0)
        part(UDim2.fromOffset(15, 3), UDim2.fromOffset(6, 12), 1, 0)
        part(UDim2.fromOffset(5, 5), UDim2.fromOffset(11, 11), 3, 0)
    elseif kind == "info" then
        local ring = part(UDim2.fromOffset(17, 17), UDim2.fromOffset(5, 5), 9, 0, true)
        ring.BackgroundTransparency = 1
        local i = label(win, holder, "i", 13, "SubText", FONT_BOLD)
        i.Size = UDim2.fromScale(1, 1)
        i.TextXAlignment = Enum.TextXAlignment.Center
        i.TextYAlignment = Enum.TextYAlignment.Center
        table.insert(parts, i)
    else
        part(UDim2.fromOffset(11, 11), UDim2.fromOffset(8, 8), 2, 45)
        part(UDim2.fromOffset(3, 3), UDim2.fromOffset(12, 12), 2, 0)
    end

    local function setOn(on)
        for _, item in ipairs(parts) do
            if item:IsA("TextLabel") then
                item.TextColor3 = on and win.Theme.Accent or win.Theme.SubText
            elseif item:IsA("Frame") then
                local isStrokeOnly = item.BackgroundTransparency == 1
                if isStrokeOnly then
                    for _, c in ipairs(item:GetChildren()) do
                        if c:IsA("UIStroke") then c.Color = on and win.Theme.Accent or win.Theme.SubText end
                    end
                else
                    item.BackgroundColor3 = on and win.Theme.Accent or win.Theme.SubText
                end
            end
        end
    end

    return holder, setOn
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
-- Builds the standard card: [ title / description ............ right-control ]
local function makeRow(tab, title, desc, rightWidth)
    local win = tab.Window
    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = tab.Page })
    bind(win, row, "BackgroundColor3", "Element")
    corner(row, 11)
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
        Size = UDim2.new(1, 0, 0, desc and desc ~= "" and 54 or 42), Parent = row })
    pad(header, 14, 0, 14, 0)

    local hasDesc = desc and desc ~= ""
    local rw = rightWidth or 0
    local titleLbl = label(win, header, title or "", 14, "Text", FONT_BOLD)
    titleLbl.AnchorPoint = Vector2.new(0, 0.5)
    titleLbl.Position = UDim2.new(0, 0, 0.5, hasDesc and -9 or 0)
    titleLbl.Size = UDim2.new(1, -(rw + 8), 0, 18)

    local descLbl
    if hasDesc then
        descLbl = label(win, header, desc, 12, "SubText")
        descLbl.AnchorPoint = Vector2.new(0, 0.5)
        descLbl.Position = UDim2.new(0, 0, 0.5, 10)
        descLbl.Size = UDim2.new(1, -(rw + 8), 0, 14)
    end

    local obj = { Instance = row, Title = title }
    local cleanup = {}

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
--  opts: Title, Description, Style ("Default" | "Accent"), Callback
--------------------------------------------------------------------------
local function CreateButton(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj, cleanup = makeRow(tab, opts.Title or "Button", opts.Description, 30)

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
--  opts: Title, Description, Default, Flag, Callback(value)
--------------------------------------------------------------------------
local function CreateToggle(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local row, header, obj, cleanup = makeRow(tab, opts.Title or "Toggle", opts.Description, 50)
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
-- SLIDER
--  opts: Title, Description, Min, Max, Default, Increment, Suffix, Flag, Callback(value)
--------------------------------------------------------------------------
local function CreateSlider(tab, opts)
    opts = opts or {}
    local win = tab.Window
    local min, max = opts.Min or 0, opts.Max or 100
    local inc = opts.Increment or 1
    local dec = decimals(inc)
    local suffix = opts.Suffix or ""
    local value = clamp(opts.Default or min, min, max)

    local row, header, obj = makeRow(tab, opts.Title or "Slider", opts.Description, 70)
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
        Text = "▼", TextSize = 10, AnchorPoint = Vector2.new(1, 0.5),
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
local function CreateSection(tab, title)
    local win = tab.Window
    local holder = New("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = tab.Page })
    local l = label(win, holder, string.upper(title or "Section"), 12, "Accent", FONT_BOLD)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.Position = UDim2.fromOffset(4, 4)
    local obj = { Instance = holder }
    function obj:SetTitle(t) l.Text = string.upper(t) end
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
-- MAIN DASHBOARD
--------------------------------------------------------------------------
local function createMainDashboard(win, tab)
    local page = tab.Page
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, 128), BackgroundTransparency = 1, LayoutOrder = -1000, Parent = page })

    local statusCard = New("Frame", {
        Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 0, Parent = holder })
    bind(win, statusCard, "BackgroundColor3", "Surface")
    corner(statusCard, 14); local statusStroke = stroke(win, statusCard, "Stroke", 1); glow(win, statusCard, 3, 0.90)
    pad(statusCard, 14, 12, 14, 12)

    local statusDot = New("Frame", { Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(9, 9), Parent = statusCard })
    bind(win, statusDot, "BackgroundColor3", "Success"); corner(statusDot, 5)
    local statusTitle = label(win, statusCard, "SCRIPT STATUS", 10, "SubText", FONT_BOLD)
    statusTitle.Position = UDim2.fromOffset(31, 10); statusTitle.Size = UDim2.new(1, -45, 0, 15)
    local statusValue = label(win, statusCard, win._scriptStatus, 18, "Text", FONT_BOLD)
    statusValue.Position = UDim2.fromOffset(14, 32); statusValue.Size = UDim2.new(1, -28, 0, 24)
    local statusDesc = label(win, statusCard, "Ready for feature initialization", 11, "SubText")
    statusDesc.Position = UDim2.fromOffset(14, 63); statusDesc.Size = UDim2.new(1, -28, 0, 16)
    local statusLine = New("Frame", { Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(1, -28, 0, 2), Parent = statusCard })
    bind(win, statusLine, "BackgroundColor3", "Success"); corner(statusLine, 2)

    local playerCard = New("Frame", {
        Position = UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 1, 0), BackgroundTransparency = 0, Parent = holder })
    bind(win, playerCard, "BackgroundColor3", "Surface")
    corner(playerCard, 14); glow(win, playerCard, 3, 0.90); pad(playerCard, 14, 12, 14, 12)

    local avatar = New("Frame", { Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(38, 38), Parent = playerCard })
    bind(win, avatar, "BackgroundColor3", "Accent"); corner(avatar, 19)
    local avatarHead = New("Frame", { Position = UDim2.fromOffset(12, 7), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1,1,1), Parent = avatar })
    corner(avatarHead, 7)
    local avatarBody = New("Frame", { Position = UDim2.fromOffset(8, 22), Size = UDim2.fromOffset(22, 10), BackgroundColor3 = Color3.new(1,1,1), Parent = avatar })
    corner(avatarBody, 6)

    local playerTitle = label(win, playerCard, "PLAYER", 10, "SubText", FONT_BOLD)
    playerTitle.Position = UDim2.fromOffset(62, 11); playerTitle.Size = UDim2.new(1, -76, 0, 15)
    local playerName = label(win, playerCard, Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player", 15, "Text", FONT_BOLD)
    playerName.Position = UDim2.fromOffset(62, 29); playerName.Size = UDim2.new(1, -76, 0, 20)
    local playerUser = label(win, playerCard, "@" .. (Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"), 10, "SubText")
    playerUser.Position = UDim2.fromOffset(62, 50); playerUser.Size = UDim2.new(1, -76, 0, 15)

    local planPill = New("Frame", { Position = UDim2.new(0, 14, 1, -42), Size = UDim2.new(1, -28, 0, 27), Parent = playerCard })
    bind(win, planPill, "BackgroundColor3", "Accent"); planPill.BackgroundTransparency = 0.86; corner(planPill, 9)
    local planLabel = label(win, planPill, "PLAN", 9, "Accent", FONT_BOLD)
    planLabel.Position = UDim2.fromOffset(10, 0); planLabel.Size = UDim2.fromOffset(32, 27); planLabel.TextYAlignment = Enum.TextYAlignment.Center
    local planValue = label(win, planPill, win._playerPlan, 10, "Text", FONT_BOLD)
    planValue.Position = UDim2.fromOffset(45, 0); planValue.Size = UDim2.new(1, -55, 1, 0); planValue.TextXAlignment = Enum.TextXAlignment.Right

    win._mainStatus = statusValue
    win._mainStatusDot = statusDot
    win._mainPlan = planValue

    local pulse = glow(win, statusCard, 5, 0.84)
    task.spawn(function()
        while statusCard.Parent do
            tw(pulse, { Transparency = 0.58 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
            if not statusCard.Parent then break end
            tw(pulse, { Transparency = 0.88 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
        end
    end)
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
}

function Tab:Button(o)      return CreateButton(self, o) end
function Tab:Toggle(o)      return CreateToggle(self, o) end
function Tab:Slider(o)      return CreateSlider(self, o) end
function Tab:Input(o)       return CreateInput(self, o) end
function Tab:Dropdown(o)    return CreateDropdown(self, o) end
function Tab:Keybind(o)     return CreateKeybind(self, o) end
function Tab:ColorPicker(o) return CreateColorPicker(self, o) end
function Tab:Section(t)     return CreateSection(self, t) end
function Tab:Label(t)       return CreateLabel(self, t) end
function Tab:Paragraph(o)   return CreateParagraph(self, o) end
function Tab:Divider()      return CreateDivider(self) end
function Tab:Select()       self.Window:_select(self) end

local function mergeTheme(t)
    local out = {}
    for k, val in pairs(Library.Themes.Dark) do out[k] = val end
    for k, val in pairs(t) do out[k] = val end
    return out
end

--[[
    Library:CreateWindow{
        Title, SubTitle, Theme ("Dark" | table), Size (UDim2), ToggleKey (Enum.KeyCode)
    }
]]
function Library:CreateWindow(opts)
    opts = opts or {}
    local themeName = type(opts.Theme) == "string" and opts.Theme or "Dark"
    local theme = type(opts.Theme) == "table" and opts.Theme or self.Themes[themeName] or self.Themes.Dark

    local win = setmetatable({
        Theme = mergeTheme(theme), Flags = {}, Tabs = {},
        _bound = {}, _themeCbs = {}, _conns = {}, _active = nil, _toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
        _scriptStatus = opts.ScriptStatus or "Operational",
        _playerPlan = opts.PlayerPlan or "Freemium",
    }, Window)

    local gui = New("ScreenGui", {
        Name = "NovaUI_" .. tostring(math.random(1000, 9999)), ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true })
    mountGui(gui)
    win.Gui = gui

    local size = opts.Size or UDim2.fromOffset(620, 430)
    local main = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = size, ClipsDescendants = true, Parent = gui })
    bind(win, main, "BackgroundColor3", "Background")
    corner(main, 16); stroke(win, main, "Stroke")
    glow(win, main, 5, 0.91)
    local mainGradient = New("UIGradient", { Rotation = 35, Parent = main })
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, win.Theme.Background:Lerp(win.Theme.Accent, 0.06)),
        ColorSequenceKeypoint.new(0.55, win.Theme.Background),
        ColorSequenceKeypoint.new(1, win.Theme.Background:Lerp(win.Theme.Accent, 0.03)),
    })
    local scale = New("UIScale", { Scale = 0.92, Parent = main })
    tw(scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
    win.Main = main
    task.spawn(function()
        while main.Parent do
            tw(mainGradient, { Rotation = 125 }, 5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(5.5)
            if not main.Parent then break end
            tw(mainGradient, { Rotation = 35 }, 5.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(5.5)
        end
    end)

    -- top bar
    local top = New("Frame", { Size = UDim2.new(1, 0, 0, 46), Parent = main })
    bind(win, top, "BackgroundColor3", "Surface")
    corner(top, 12)
    -- filler squares off the bottom corners so only the top ones stay round
    local topFill = New("Frame", { Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), Parent = top })
    bind(win, topFill, "BackgroundColor3", "Surface")
    local topLine = New("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = top })
    bind(win, topLine, "BackgroundColor3", "Stroke")

    local dot = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(10, 10), Parent = top })
    bind(win, dot, "BackgroundColor3", "Accent"); corner(dot, 5)
    local dotGlow = glow(win, dot, 4, 0.72)
    task.spawn(function()
        while dot.Parent do
            tw(dotGlow, { Transparency = 0.42 }, 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.75)
            if not dot.Parent then break end
            tw(dotGlow, { Transparency = 0.86 }, 0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.75)
        end
    end)
    -- compact brand row: title -> version -> subtitle, with fixed bounds so nothing overlaps
    local title = label(win, top, opts.Title or "NovaUI", 15, "Text", FONT_BOLD)
    title.Position = UDim2.fromOffset(34, 0)
    title.Size = UDim2.fromOffset(145, 46)
    title.TextTruncate = Enum.TextTruncate.AtEnd

    local versionPill = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 186, 0.5, 0),
        Size = UDim2.fromOffset(54, 19), BackgroundTransparency = 0.84, Parent = top })
    bind(win, versionPill, "BackgroundColor3", "Accent"); corner(versionPill, 10)
    local versionText = label(win, versionPill, "v" .. tostring(Library.Version), 9, "Accent", FONT_BOLD)
    versionText.Size = UDim2.fromScale(1, 1)
    versionText.TextXAlignment = Enum.TextXAlignment.Center
    versionText.TextYAlignment = Enum.TextYAlignment.Center

    if opts.SubTitle then
        local sub = label(win, top, opts.SubTitle, 11, "SubText")
        sub.Position = UDim2.fromOffset(248, 0)
        sub.Size = UDim2.new(0, 170, 1, 0)
        sub.TextTruncate = Enum.TextTruncate.AtEnd
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
        Position = UDim2.fromOffset(0, 46), Size = UDim2.new(0, 164, 1, -46), Parent = main })
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
        Position = UDim2.fromOffset(164, 46), Size = UDim2.new(1, -164, 1, -46),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = main })
    win.Content = content

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
    end
end

function Window:GetScriptStatus()
    return self._scriptStatus
end

function Window:SetPlayerPlan(text)
    self._playerPlan = tostring(text or "Freemium")
    if self._mainPlan then self._mainPlan.Text = self._playerPlan end
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
            BackgroundTransparency = on and 0.90 or 1,
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

--[[ Window:Tab{ Title, Icon (asset id OR emoji/symbol, optional), Badge (optional) } ]]
function Window:Tab(opts)
    opts = opts or {}
    local win = self
    local tab = setmetatable({ Window = win }, Tab)

    local btn = New("TextButton", {
        Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1, LayoutOrder = #win.Tabs + 1, Parent = win.TabList })
    btn.BackgroundColor3 = win.Theme.Accent
    table.insert(win._bound, { btn, "BackgroundColor3", "Accent" })
    corner(btn, 9)

    local ind = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(2, 7), BackgroundTransparency = 1, Parent = btn })
    bind(win, ind, "BackgroundColor3", "Accent"); corner(ind, 2)

    local tabGlow = glow(win, btn, 2.5, 0.94)

    local iconBubble = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Parent = btn })
    bind(win, iconBubble, "BackgroundColor3", "Accent")
    corner(iconBubble, 7)
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
                Size = UDim2.fromOffset(14, 14), ImageColor3 = win.Theme.SubText, Parent = iconBubble })
        else
            -- Explicit text/emoji remains supported; automatic icons use native shapes so unsupported glyphs never become squares.
            iconInst = New("TextLabel", {
                Text = tostring(iconValue), Font = FONT_BOLD, TextSize = 12,
                TextColor3 = win.Theme.SubText, TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = iconBubble })
        end
        tab._icon = iconInst
    end

    local iconInst = tab._icon or iconBubble:FindFirstChildOfClass("Frame")

    local lbl = New("TextLabel", {
        Text = opts.Title or "Tab", Font = FONT_BOLD, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(40, 0),
        Size = UDim2.new(1, -(opts.Badge and 72 or 50), 1, 0), TextColor3 = win.Theme.SubText, Parent = btn })

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
    New("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    tab._btn, tab._label, tab._indicator, tab.Page = btn, lbl, ind, page
    tab._icon, tab._iconBubble, tab._iconScale, tab._tabGlow = iconInst, iconBubble, iconScale, tabGlow
    table.insert(win.Tabs, tab)

    btn.MouseEnter:Connect(function()
        if win._active ~= tab then
            tw(btn, { BackgroundTransparency = 0.91 }, 0.16, Enum.EasingStyle.Quint)
            tw(tabGlow, { Transparency = 0.86 }, 0.16, Enum.EasingStyle.Quint)
        end
        tw(iconScale, { Scale = win._active == tab and 1.06 or 1.04 }, 0.18, Enum.EasingStyle.Back)
    end)
    btn.MouseLeave:Connect(function()
        if win._active ~= tab then
            tw(btn, { BackgroundTransparency = 1 }, 0.18, Enum.EasingStyle.Quint)
            tw(tabGlow, { Transparency = 0.96 }, 0.18, Enum.EasingStyle.Quint)
        end
        tw(iconScale, { Scale = win._active == tab and 1.05 or 1 }, 0.18, Enum.EasingStyle.Back)
    end)
    btn.MouseButton1Down:Connect(function()
        tw(iconScale, { Scale = 0.96 }, 0.08, Enum.EasingStyle.Quad)
    end)
    btn.MouseButton1Up:Connect(function()
        tw(iconScale, { Scale = win._active == tab and 1.06 or 1.04 }, 0.14, Enum.EasingStyle.Back)
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

    if string.lower(tostring(opts.Title or "")):find("main", 1, true) then
        createMainDashboard(win, tab)
    end

    if #win.Tabs == 1 then win:_select(tab) end
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

return Library
