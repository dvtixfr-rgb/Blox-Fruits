--// Aether.lua (Compact & Refactored)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Aether = {}
Aether.__index = Aether

local COLORS = {
    Background  = Color3.fromRGB(15, 17, 20),
    Sidebar     = Color3.fromRGB(11, 13, 15),
    SidebarItem = Color3.fromRGB(22, 25, 29),
    Panel       = Color3.fromRGB(19, 22, 26),
    Control     = Color3.fromRGB(25, 28, 33),
    Border      = Color3.fromRGB(38, 42, 48),
    Divider     = Color3.fromRGB(30, 33, 38),
    Text        = Color3.fromRGB(240, 242, 245),
    Muted       = Color3.fromRGB(140, 145, 155),
    Dim         = Color3.fromRGB(90, 95, 102),
    Accent      = Color3.fromRGB(53, 115, 255),
    Success     = Color3.fromRGB(89, 207, 115),
}

local function tween(object, duration, properties)
    return TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties):Play()
end

local function corner(parent, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 4)
    object.Parent = parent
    return object
end

local function stroke(parent, color, thickness)
    local object = Instance.new("UIStroke")
    object.Color = color or COLORS.Border
    object.Thickness = thickness or 1
    object.Parent = parent
    return object
end

local function padding(parent, left, right, top, bottom)
    local object = Instance.new("UIPadding")
    object.PaddingLeft = UDim.new(0, left or 0)
    object.PaddingRight = UDim.new(0, right or 0)
    object.PaddingTop = UDim.new(0, top or 0)
    object.PaddingBottom = UDim.new(0, bottom or 0)
    object.Parent = parent
    return object
end

local function label(parent, text, size, font, color)
    local object = Instance.new("TextLabel")
    object.BackgroundTransparency = 1
    object.Text = text or ""
    object.Font = font or Enum.Font.Gotham
    object.TextSize = size or 12
    object.TextColor3 = color or COLORS.Text
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function makeButton(parent)
    local object = Instance.new("TextButton")
    object.AutoButtonColor = false
    object.BackgroundTransparency = 1
    object.BorderSizePixel = 0
    object.Text = ""
    object.Parent = parent
    return object
end

function Aether.new(options)
    options = options or {}
    local self = setmetatable({}, Aether)

    self.Name = options.Name or "AETHER"
    self.Version = options.Version or "v1.0"
    self.Width = options.Width or 480
    self.Height = options.Height or 320
    self.Minimized = false
    self.Destroyed = false

    self.Tabs = {}
    self.ActiveTab = nil
    self.Connections = {}

    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name:gsub("%W", "") .. "_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    self.Gui = gui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(self.Width, self.Height)
    main.BackgroundColor3 = COLORS.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    corner(main, 6)
    stroke(main, COLORS.Border, 1)
    self.Main = main

    local HEADER_HEIGHT = 32
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundColor3 = COLORS.Sidebar
    header.BorderSizePixel = 0
    header.Parent = main

    local headerDivider = Instance.new("Frame")
    headerDivider.Position = UDim2.new(0, 0, 1, -1)
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.BackgroundColor3 = COLORS.Divider
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = header

    local title = label(header, self.Name, 13, Enum.Font.GothamBold, COLORS.Text)
    title.Position = UDim2.fromOffset(10, 0)
    title.Size = UDim2.new(0, 200, 1, 0)

    local close = makeButton(header)
    close.Size = UDim2.fromOffset(28, HEADER_HEIGHT)
    close.Position = UDim2.new(1, -28, 0, 0)
    local closeGlyph = label(close, "x", 14, Enum.Font.GothamBold, COLORS.Muted)
    closeGlyph.Size = UDim2.fromScale(1, 1)
    closeGlyph.TextXAlignment = Enum.TextXAlignment.Center

    local minimize = makeButton(header)
    minimize.Size = UDim2.fromOffset(28, HEADER_HEIGHT)
    minimize.Position = UDim2.new(1, -56, 0, 0)
    local minGlyph = label(minimize, "-", 16, Enum.Font.GothamBold, COLORS.Muted)
    minGlyph.Size = UDim2.fromScale(1, 1)
    minGlyph.TextXAlignment = Enum.TextXAlignment.Center

    close.MouseButton1Click:Connect(function() self:Destroy() end)
    minimize.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        tween(main, 0.15, { Size = UDim2.fromOffset(self.Width, self.Minimized and HEADER_HEIGHT or self.Height) })
    end)

    local dragging, dragStart, startPosition
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)

    table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))

    table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    local SIDEBAR_WIDTH = 110
    local navigation = Instance.new("Frame")
    navigation.Name = "Navigation"
    navigation.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
    navigation.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
    navigation.BackgroundColor3 = COLORS.Sidebar
    navigation.BorderSizePixel = 0
    navigation.Parent = main

    local navDivider = Instance.new("Frame")
    navDivider.Position = UDim2.new(1, -1, 0, 0)
    navDivider.Size = UDim2.new(0, 1, 1, 0)
    navDivider.BackgroundColor3 = COLORS.Divider
    navDivider.BorderSizePixel = 0
    navDivider.Parent = navigation

    local navList = Instance.new("ScrollingFrame")
    navList.Name = "TabList"
    navList.Position = UDim2.fromOffset(6, 6)
    navList.Size = UDim2.new(1, -12, 1, -12)
    navList.BackgroundTransparency = 1
    navList.BorderSizePixel = 0
    navList.ScrollBarThickness = 0
    navList.CanvasSize = UDim2.fromOffset(0, 0)
    navList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navList.Parent = navigation

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 3)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = navList
    self.NavList = navList

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, HEADER_HEIGHT)
    content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
    content.BackgroundColor3 = COLORS.Background
    content.BorderSizePixel = 0
    content.Parent = main
    self.Content = content

    if options.ToggleKey then
        table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.ToggleKey then
                gui.Enabled = not gui.Enabled
            end
        end))
    end

    return self
end

function Aether:CreateTab(options)
    options = type(options) == "string" and { Name = options } or (options or {})
    local tab = { Library = self, Name = options.Name or "Tab", Sections = {} }

    local navButton = makeButton(self.NavList)
    navButton.Size = UDim2.new(1, 0, 0, 26)
    corner(navButton, 4)

    local navText = label(navButton, tab.Name, 12, Enum.Font.Gotham, COLORS.Muted)
    navText.Position = UDim2.fromOffset(8, 0)
    navText.Size = UDim2.new(1, -16, 1, 0)

    local page = Instance.new("ScrollingFrame")
    page.Name = tab.Name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = COLORS.Border
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self.Content
    padding(page, 8, 8, 8, 8)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 6)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    tab.Page = page
    tab.NavButton = navButton

    local function select()
        for _, other in ipairs(self.Tabs) do
            local active = (other == tab)
            other.Page.Visible = active
            other.NavButton.BackgroundColor3 = active and COLORS.SidebarItem or COLORS.Sidebar
            other.NavButton.TextLabel.TextColor3 = active and COLORS.Text or COLORS.Muted
        end
        self.ActiveTab = tab
    end

    navButton.MouseButton1Click:Connect(select)
    table.insert(self.Tabs, tab)

    if not self.ActiveTab then task.defer(select) end

    function tab:CreateSection(titleText)
        local section = { Name = titleText or "SECTION" }
        local container = Instance.new("Frame")
        container.Name = "Section"
        container.BackgroundColor3 = COLORS.Panel
        container.BorderSizePixel = 0
        container.Size = UDim2.new(1, 0, 0, 0)
        container.AutomaticSize = Enum.AutomaticSize.Y
        container.Parent = page
        corner(container, 4)
        stroke(container, COLORS.Border, 1)
        padding(container, 8, 8, 6, 6)

        local heading = label(container, string.upper(section.Name), 10, Enum.Font.GothamBold, COLORS.Muted)
        heading.Size = UDim2.new(1, 0, 0, 14)

        local items = Instance.new("Frame")
        items.Position = UDim2.fromOffset(0, 18)
        items.Size = UDim2.new(1, 0, 0, 0)
        items.AutomaticSize = Enum.AutomaticSize.Y
        items.BackgroundTransparency = 1
        items.Parent = container

        local itemsLayout = Instance.new("UIListLayout")
        itemsLayout.Padding = UDim.new(0, 4)
        itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        itemsLayout.Parent = items

        local function rowBase(height)
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, height or 28)
            row.Parent = items
            return row
        end

        function section:CreateToggle(opts)
            opts = opts or {}
            local row = rowBase(28)
            local textLabel = label(row, opts.Name or "Toggle", 12, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(1, -45, 1, 0)

            local toggle = Instance.new("Frame")
            toggle.Size = UDim2.fromOffset(32, 16)
            toggle.Position = UDim2.new(1, -32, 0.5, -8)
            toggle.BackgroundColor3 = COLORS.Control
            toggle.BorderSizePixel = 0
            toggle.Parent = row
            corner(toggle, 8)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(12, 12)
            knob.Position = UDim2.fromOffset(2, 2)
            knob.BackgroundColor3 = COLORS.Text
            knob.BorderSizePixel = 0
            knob.Parent = toggle
            corner(knob, 6)

            local hit = makeButton(row)
            hit.Size = UDim2.fromScale(1, 1)

            local state = opts.CurrentValue == true
            local function set(val, fire)
                state = val == true
                tween(toggle, 0.1, { BackgroundColor3 = state and COLORS.Accent or COLORS.Control })
                tween(knob, 0.1, { Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2) })
                if fire ~= false and opts.Callback then opts.Callback(state) end
            end

            set(state, false)
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
            return { Set = function(_, v) set(v, true) end, Get = function() return state end }
        end

        function section:CreateButton(opts)
            opts = opts or {}
            local row = rowBase(28)
            local button = makeButton(row)
            button.Size = UDim2.fromScale(1, 1)
            button.BackgroundColor3 = COLORS.Control
            corner(button, 4)
            stroke(button, COLORS.Border, 1)

            local btnText = label(button, opts.Name or "Button", 12, Enum.Font.Gotham, COLORS.Text)
            btnText.Size = UDim2.fromScale(1, 1)
            btnText.TextXAlignment = Enum.TextXAlignment.Center

            button.MouseButton1Click:Connect(function()
                if opts.Callback then opts.Callback() end
            end)
            return { Instance = row }
        end

        function section:CreateSlider(opts)
            opts = opts or {}
            local row = rowBase(36)
            local min = tonumber(opts.Min or (opts.Range and opts.Range[1])) or 0
            local max = tonumber(opts.Max or (opts.Range and opts.Range[2])) or 100
            local value = tonumber(opts.CurrentValue or opts.Default or min) or min

            local textLabel = label(row, opts.Name or "Slider", 12, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(1, -50, 0, 16)

            local valLabel = label(row, tostring(value), 11, Enum.Font.Gotham, COLORS.Muted)
            valLabel.Position = UDim2.new(1, -50, 0, 0)
            valLabel.Size = UDim2.new(0, 50, 0, 16)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame")
            track.Position = UDim2.new(0, 0, 0, 22)
            track.Size = UDim2.new(1, 0, 0, 4)
            track.BackgroundColor3 = COLORS.Control
            track.Parent = row
            corner(track, 2)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(0, 1)
            fill.BackgroundColor3 = COLORS.Accent
            fill.Parent = track
            corner(fill, 2)

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Size = UDim2.fromOffset(10, 10)
            knob.BackgroundColor3 = COLORS.Text
            knob.Parent = track
            corner(knob, 5)

            local hit = makeButton(row)
            hit.Position = UDim2.new(0, 0, 0, 16)
            hit.Size = UDim2.new(1, 0, 0, 16)

            local draggingSlider = false
            local function update(input)
                local posX = input.Position.X
                local trackX = track.AbsolutePosition.X
                local trackW = track.AbsoluteSize.X
                if trackW <= 0 then return end

                local alpha = math.clamp((posX - trackX) / trackW, 0, 1)
                local val = min + (max - min) * alpha
                if opts.Rounding and opts.Rounding > 0 then
                    val = math.floor(val / opts.Rounding + 0.5) * opts.Rounding
                end
                val = math.clamp(val, min, max)
                value = val

                valLabel.Text = tostring(value)
                fill.Size = UDim2.fromScale(alpha, 1)
                knob.Position = UDim2.new(alpha, 0, 0.5, 0)
                if opts.Callback then opts.Callback(value) end
            end

            hit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = true
                    update(input)
                end
            end)

            table.insert(tab.Library.Connections, UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end))

            table.insert(tab.Library.Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end))

            local alpha = (value - min) / (max - min)
            fill.Size = UDim2.fromScale(alpha, 1)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)

            return { Set = function(_, v) value = v; valLabel.Text = tostring(v); fill.Size = UDim2.fromScale((v-min)/(max-min), 1) end, Get = function() return value end }
        end

        function section:CreateDropdown(opts)
            opts = opts or {}
            local row = rowBase(28)
            local selected = opts.CurrentOption or (opts.Options and opts.Options[1]) or "None"

            local textLabel = label(row, opts.Name or "Dropdown", 12, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(0.5, 0, 1, 0)

            local dd = makeButton(row)
            dd.Position = UDim2.new(0.5, 0, 0, 0)
            dd.Size = UDim2.new(0.5, 0, 1, 0)
            dd.BackgroundColor3 = COLORS.Control
            corner(dd, 4)
            stroke(dd, COLORS.Border, 1)

            local valText = label(dd, tostring(selected), 11, Enum.Font.Gotham, COLORS.Text)
            valText.Position = UDim2.fromOffset(6, 0)
            valText.Size = UDim2.new(1, -12, 1, 0)

            return { Set = function(_, v) selected = v; valText.Text = tostring(v) end, Get = function() return selected end }
        end

        return section
    end

    return tab
end

function Aether:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    for _, conn in ipairs(self.Connections) do pcall(function() conn:Disconnect() end) end
    if self.Gui then self.Gui:Destroy() end
end

function Aether:CreateWindow(options) return Aether.new(options) end

return Aether
