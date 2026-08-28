local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Aether = {}
Aether.__index = Aether

local COLORS = {
    Background   = Color3.fromRGB(15, 17, 20),
    Sidebar      = Color3.fromRGB(11, 13, 15),
    SidebarItem  = Color3.fromRGB(22, 25, 29),
    Panel        = Color3.fromRGB(19, 22, 26),
    Control      = Color3.fromRGB(25, 28, 33),
    ControlHover = Color3.fromRGB(42, 47, 56), 
    ControlPress = Color3.fromRGB(65, 72, 85),
    Divider      = Color3.fromRGB(30, 33, 38),
    Text         = Color3.fromRGB(240, 242, 245),
    Muted        = Color3.fromRGB(140, 145, 155),
    Accent       = Color3.fromRGB(53, 115, 255),
}

local function tween(object, duration, properties)
    return TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties):Play()
end

local function corner(parent, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 3)
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
    object.TextSize = size or 14
    object.TextColor3 = color or COLORS.Text
    object.TextXAlignment = Enum.TextXAlignment.Left
    object.TextYAlignment = Enum.TextYAlignment.Center
    object.Parent = parent
    return object
end

local function makeButton(parent, transparent)
    local object = Instance.new("TextButton")
    object.AutoButtonColor = false
    object.BackgroundTransparency = transparent and 1 or 0
    object.BorderSizePixel = 0
    object.Text = ""
    object.Parent = parent
    return object
end

local function attachButtonEffects(btn, baseColor, hoverColor, pressColor)
    baseColor = baseColor or COLORS.Control
    hoverColor = hoverColor or COLORS.ControlHover
    pressColor = pressColor or COLORS.ControlPress

    btn.BackgroundColor3 = baseColor

    btn.MouseEnter:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = hoverColor })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = baseColor })
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, 0.05, { BackgroundColor3 = pressColor })
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, 0.15, { BackgroundColor3 = hoverColor })
    end)
end

function Aether.new(options)
    options = options or {}
    local self = setmetatable({}, Aether)

    self.Name = options.Name or "AETHER"
    self.Version = options.Version or "v1.0"
    self.Width = options.Width or 650 
    self.Height = options.Height or 430
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

    local notifHolder = Instance.new("Frame")
    notifHolder.Name = "NotificationHolder"
    notifHolder.AnchorPoint = Vector2.new(1, 1)
    notifHolder.Position = UDim2.new(1, -20, 1, -20)
    notifHolder.Size = UDim2.new(0, 260, 1, -40)
    notifHolder.BackgroundTransparency = 1
    notifHolder.BorderSizePixel = 0
    notifHolder.ZIndex = 100
    notifHolder.Parent = gui
    self.NotifHolder = notifHolder

    local notifLayout = Instance.new("UIListLayout")
    notifLayout.Padding = UDim.new(0, 8)
    notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifLayout.Parent = notifHolder

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(self.Width, self.Height)
    main.BackgroundColor3 = COLORS.Sidebar
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui
    corner(main, 6)
    self.Main = main

    local HEADER_HEIGHT = 44 
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.ZIndex = 2
    header.Parent = main

    local headerDivider = Instance.new("Frame")
    headerDivider.Name = "HeaderDivider"
    headerDivider.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT - 1)
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.BackgroundColor3 = COLORS.Divider
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 10
    headerDivider.Parent = main

    local title = label(header, self.Name, 17, Enum.Font.GothamBold, COLORS.Text)
    title.Position = UDim2.fromOffset(14, 0)
    title.Size = UDim2.new(0, 200, 1, 0)

    local close = makeButton(header, true)
    close.Size = UDim2.fromOffset(40, HEADER_HEIGHT)
    close.Position = UDim2.new(1, -40, 0, 0)
    local closeGlyph = label(close, "x", 17, Enum.Font.GothamBold, COLORS.Muted)
    closeGlyph.Size = UDim2.fromScale(1, 1)
    closeGlyph.TextXAlignment = Enum.TextXAlignment.Center

    local minimize = makeButton(header, true)
    minimize.Size = UDim2.fromOffset(40, HEADER_HEIGHT)
    minimize.Position = UDim2.new(1, -80, 0, 0)
    local minGlyph = label(minimize, "-", 19, Enum.Font.GothamBold, COLORS.Muted)
    minGlyph.Size = UDim2.fromScale(1, 1)
    minGlyph.TextXAlignment = Enum.TextXAlignment.Center

    attachButtonEffects(close, COLORS.Sidebar, Color3.fromRGB(180, 40, 40), Color3.fromRGB(220, 60, 60))
    attachButtonEffects(minimize, COLORS.Sidebar, COLORS.ControlHover, COLORS.ControlPress)

    local SIDEBAR_WIDTH = 150
    local navigation = Instance.new("Frame")
    navigation.Name = "Navigation"
    navigation.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
    navigation.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
    navigation.BackgroundTransparency = 1
    navigation.BorderSizePixel = 0
    navigation.ClipsDescendants = true
    navigation.Parent = main

    local navDivider = Instance.new("Frame")
    navDivider.Position = UDim2.new(1, -1, 0, 0)
    navDivider.Size = UDim2.new(0, 1, 1, 0)
    navDivider.BackgroundColor3 = COLORS.Divider
    navDivider.BorderSizePixel = 0
    navDivider.Parent = navigation

    local navList = Instance.new("ScrollingFrame")
    navList.Name = "TabList"
    navList.Position = UDim2.fromOffset(8, 8)
    navList.Size = UDim2.new(1, -16, 1, -16)
    navList.BackgroundTransparency = 1
    navList.BorderSizePixel = 0
    navList.ScrollBarThickness = 0
    navList.CanvasSize = UDim2.fromOffset(0, 0)
    navList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    navList.Parent = navigation

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 5)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = navList
    self.NavList = navList

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(SIDEBAR_WIDTH, HEADER_HEIGHT)
    content.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -HEADER_HEIGHT)
    content.BackgroundColor3 = COLORS.Background
    content.BorderSizePixel = 0
    content.ClipsDescendants = true
    content.Parent = main
    corner(content, 6)

    local patchTL = Instance.new("Frame")
    patchTL.Size = UDim2.fromOffset(10, 10)
    patchTL.Position = UDim2.fromOffset(0, 0)
    patchTL.BackgroundColor3 = COLORS.Background
    patchTL.BorderSizePixel = 0
    patchTL.Parent = content

    local patchTR = Instance.new("Frame")
    patchTR.Size = UDim2.fromOffset(10, 10)
    patchTR.Position = UDim2.new(1, -10, 0, 0)
    patchTR.BackgroundColor3 = COLORS.Background
    patchTR.BorderSizePixel = 0
    patchTR.Parent = content

    local patchBL = Instance.new("Frame")
    patchBL.Size = UDim2.fromOffset(10, 10)
    patchBL.Position = UDim2.new(0, 0, 1, -10)
    patchBL.BackgroundColor3 = COLORS.Background
    patchBL.BorderSizePixel = 0
    patchBL.Parent = content

    self.Content = content

    close.MouseButton1Click:Connect(function() self:Destroy() end)
    minimize.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        headerDivider.Visible = not self.Minimized
        navigation.Visible = not self.Minimized
        content.Visible = not self.Minimized
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

    if options.ToggleKey then
        table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == options.ToggleKey then
                gui.Enabled = not gui.Enabled
            end
        end))
    end

    return self
end

function Aether:Notify(options)
    options = type(options) == "string" and { Title = "Notification", Content = options } or (options or {})
    local titleText = options.Title or "Notification"
    local contentText = options.Content or options.Text or ""
    local duration = options.Duration or 3

    if not self.NotifHolder then return end

    local card = Instance.new("CanvasGroup")
    card.Name = "NotificationCard"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = COLORS.Panel
    card.BorderSizePixel = 0
    card.GroupTransparency = 1
    card.Parent = self.NotifHolder
    corner(card, 6)
    padding(card, 12, 12, 10, 10)

    local notifTitle = label(card, titleText, 14, Enum.Font.GothamBold, COLORS.Text)
    notifTitle.Size = UDim2.new(1, 0, 0, 18)

    local notifDesc = label(card, contentText, 12, Enum.Font.Gotham, COLORS.Muted)
    notifDesc.Position = UDim2.fromOffset(0, 20)
    notifDesc.Size = UDim2.new(1, 0, 0, 0)
    notifDesc.AutomaticSize = Enum.AutomaticSize.Y
    notifDesc.TextWrapped = true

    tween(card, 0.25, { GroupTransparency = 0 })

    task.delay(duration, function()
        if card and card.Parent then
            local t = TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { GroupTransparency = 1 })
            t:Play()
            t.Completed:Connect(function()
                card:Destroy()
            end)
        end
    end)
end

function Aether:CreateTab(options)
    options = type(options) == "string" and { Name = options } or (options or {})
    local tab = { Library = self, Name = options.Name or "Tab", Sections = {} }

    local navButton = makeButton(self.NavList, false)
    navButton.Size = UDim2.new(1, 0, 0, 34)
    corner(navButton, 4)

    local navText = label(navButton, tab.Name, 14, Enum.Font.GothamMedium, COLORS.Muted)
    navText.Position = UDim2.fromOffset(12, 0)
    navText.Size = UDim2.new(1, -24, 1, 0)

    attachButtonEffects(navButton, COLORS.Sidebar, COLORS.SidebarItem, COLORS.Control)

    local page = Instance.new("ScrollingFrame")
    page.Name = tab.Name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = COLORS.Divider
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self.Content
    padding(page, 12, 12, 12, 12)

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    tab.Page = page
    tab.NavButton = navButton

    local function select()
        for _, other in ipairs(self.Tabs) do
            local active = (other == tab)
            other.Page.Visible = active
            
            if active then
                tween(other.NavButton, 0.15, { BackgroundColor3 = COLORS.Control })
                other.NavButton.TextLabel.TextColor3 = COLORS.Text
            else
                tween(other.NavButton, 0.15, { BackgroundColor3 = COLORS.Sidebar })
                other.NavButton.TextLabel.TextColor3 = COLORS.Muted
            end
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
        corner(container, 3) 
        padding(container, 12, 12, 10, 10)

        local heading = label(container, string.upper(section.Name), 12, Enum.Font.GothamBold, COLORS.Muted)
        heading.Size = UDim2.new(1, 0, 0, 16)

        local items = Instance.new("Frame")
        items.Position = UDim2.fromOffset(0, 24)
        items.Size = UDim2.new(1, 0, 0, 0)
        items.AutomaticSize = Enum.AutomaticSize.Y
        items.BackgroundTransparency = 1
        items.Parent = container

        local itemsLayout = Instance.new("UIListLayout")
        itemsLayout.Padding = UDim.new(0, 7)
        itemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        itemsLayout.Parent = items

        local function rowBase(height)
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, height or 36)
            row.Parent = items
            return row
        end

        function section:CreateToggle(opts)
            opts = opts or {}
            local row = rowBase(36)
            local textLabel = label(row, opts.Name or "Toggle", 14, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(1, -55, 1, 0)

            local toggle = Instance.new("Frame")
            toggle.Size = UDim2.fromOffset(42, 22)
            toggle.Position = UDim2.new(1, -42, 0.5, -11)
            toggle.BackgroundColor3 = COLORS.Control
            toggle.BorderSizePixel = 0
            toggle.Parent = row
            corner(toggle, 11)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.fromOffset(18, 18)
            knob.Position = UDim2.fromOffset(2, 2)
            knob.BackgroundColor3 = COLORS.Text
            knob.BorderSizePixel = 0
            knob.Parent = toggle
            corner(knob, 9)

            local hit = makeButton(row, true) 
            hit.Size = UDim2.fromScale(1, 1)

            local state = opts.CurrentValue == true
            local function set(val, fire)
                state = val == true
                tween(toggle, 0.15, { BackgroundColor3 = state and COLORS.Accent or COLORS.Control })
                tween(knob, 0.15, { Position = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2) })
                if fire ~= false and opts.Callback then opts.Callback(state) end
            end

            set(state, false)
            hit.MouseButton1Click:Connect(function() set(not state, true) end)
            return { Set = function(_, v) set(v, true) end, Get = function() return state end }
        end

        function section:CreateButton(opts)
            opts = opts or {}
            local row = rowBase(36)
            local button = makeButton(row, false)
            button.Size = UDim2.fromScale(1, 1)
            corner(button, 3)

            local btnText = label(button, opts.Name or "Button", 14, Enum.Font.GothamMedium, COLORS.Text)
            btnText.Size = UDim2.fromScale(1, 1)
            btnText.TextXAlignment = Enum.TextXAlignment.Center

            attachButtonEffects(button, COLORS.Control, COLORS.ControlHover, COLORS.ControlPress)

            button.MouseButton1Click:Connect(function()
                if opts.Callback then opts.Callback() end
            end)
            return { Instance = row }
        end

        function section:CreateSlider(opts)
            opts = opts or {}
            local row = rowBase(46)
            local min = tonumber(opts.Min or (opts.Range and opts.Range[1])) or 0
            local max = tonumber(opts.Max or (opts.Range and opts.Range[2])) or 100
            local value = tonumber(opts.CurrentValue or opts.Default or min) or min

            local textLabel = label(row, opts.Name or "Slider", 14, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(1, -60, 0, 20)

            local valLabel = label(row, tostring(value), 13, Enum.Font.Gotham, COLORS.Muted)
            valLabel.Position = UDim2.new(1, -60, 0, 0)
            valLabel.Size = UDim2.new(0, 60, 0, 20)
            valLabel.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame")
            track.Position = UDim2.new(0, 0, 0, 29)
            track.Size = UDim2.new(1, 0, 0, 6)
            track.BackgroundColor3 = COLORS.Control
            track.Parent = row
            corner(track, 3) 

            local fill = Instance.new("Frame")
            fill.Size = UDim2.fromScale(0, 1)
            fill.BackgroundColor3 = COLORS.Accent
            fill.Parent = track
            corner(fill, 3)

            local knob = Instance.new("Frame")
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Size = UDim2.fromOffset(14, 14)
            knob.BackgroundColor3 = COLORS.Text
            knob.Parent = track
            corner(knob, 7)

            local hit = makeButton(row, true) 
            hit.Position = UDim2.new(0, 0, 0, 20)
            hit.Size = UDim2.new(1, 0, 0, 26)

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
            local optionsList = opts.Options or {}
            local selected = opts.CurrentOption or optionsList[1] or "None"
            local isOpen = false

            local container = Instance.new("Frame")
            container.Name = "DropdownContainer"
            container.BackgroundTransparency = 1
            container.Size = UDim2.new(1, 0, 0, 36)
            container.ClipsDescendants = true
            container.Parent = items

            local headerRow = Instance.new("Frame")
            headerRow.BackgroundTransparency = 1
            headerRow.Size = UDim2.new(1, 0, 0, 36)
            headerRow.Parent = container

            local textLabel = label(headerRow, opts.Name or "Dropdown", 14, Enum.Font.Gotham, COLORS.Text)
            textLabel.Size = UDim2.new(0.45, 0, 1, 0)

            local ddButton = makeButton(headerRow, false)
            ddButton.Position = UDim2.new(0.45, 0, 0, 0)
            ddButton.Size = UDim2.new(0.55, 0, 1, 0)
            corner(ddButton, 3)

            attachButtonEffects(ddButton, COLORS.Control, COLORS.ControlHover, COLORS.ControlPress)

            local valText = label(ddButton, tostring(selected) .. "  v", 13, Enum.Font.Gotham, COLORS.Text)
            valText.Position = UDim2.fromOffset(10, 0)
            valText.Size = UDim2.new(1, -20, 1, 0)

            local optFrame = Instance.new("Frame")
            optFrame.Position = UDim2.fromOffset(0, 42)
            optFrame.Size = UDim2.new(1, 0, 0, #optionsList * 32)
            optFrame.BackgroundColor3 = COLORS.Control
            optFrame.Parent = container
            corner(optFrame, 3)

            local optLayout = Instance.new("UIListLayout")
            optLayout.SortOrder = Enum.SortOrder.LayoutOrder
            optLayout.Parent = optFrame

            for _, optName in ipairs(optionsList) do
                local optBtn = makeButton(optFrame, false)
                optBtn.Size = UDim2.new(1, 0, 0, 32)
                local optTxt = label(optBtn, tostring(optName), 13, Enum.Font.Gotham, COLORS.Muted)
                optTxt.Position = UDim2.fromOffset(10, 0)
                optTxt.Size = UDim2.new(1, -20, 1, 0)

                attachButtonEffects(optBtn, COLORS.Control, COLORS.ControlHover, COLORS.ControlPress)

                optBtn.MouseButton1Click:Connect(function()
                    selected = optName
                    valText.Text = tostring(selected) .. "  v"
                    isOpen = false
                    tween(container, 0.15, { Size = UDim2.new(1, 0, 0, 36) })
                    if opts.Callback then opts.Callback(selected) end
                end)
            end

            ddButton.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                local targetH = isOpen and (42 + (#optionsList * 32) + 2) or 36
                tween(container, 0.15, { Size = UDim2.new(1, 0, 0, targetH) })
            end)

            return { Set = function(_, v) selected = v; valText.Text = tostring(v) .. "  v" end, Get = function() return selected end }
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
