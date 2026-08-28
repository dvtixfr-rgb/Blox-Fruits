local Aether = loadstring([[
-- Aether.lua
-- Compact Rayfield-style UI library for Roblox.
-- Designed for normal Roblox ScreenGui / LocalScript environments.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Aether = {}
Aether.__index = Aether

local COLORS = {
    Background  = Color3.fromRGB(13, 15, 17),
    SidebarDark = Color3.fromRGB(10, 12, 14),
    SidebarItem = Color3.fromRGB(24, 26, 29),
    Panel       = Color3.fromRGB(17, 19, 21),
    Control     = Color3.fromRGB(20, 22, 25),
    Border      = Color3.fromRGB(42, 45, 49),
    Divider     = Color3.fromRGB(34, 37, 40),
    Text        = Color3.fromRGB(235, 236, 238),
    Muted       = Color3.fromRGB(151, 155, 162),
    Dim         = Color3.fromRGB(105, 109, 116),
    Accent      = Color3.fromRGB(53, 115, 255),
    AccentSoft  = Color3.fromRGB(84, 139, 255),
    Success     = Color3.fromRGB(89, 207, 115),
}

local function tween(obj, duration, props)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        props
    )

    tw:Play()
    return tw
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 5)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function padding(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function label(parent, text, size, font, color)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.Font = font or Enum.Font.Gotham
    l.TextSize = size or 14
    l.TextColor3 = color or COLORS.Text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end

local function makeButton(parent)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BackgroundTransparency = 1
    b.BorderSizePixel = 0
    b.Text = ""
    b.Parent = parent
    return b
end

local function icon(parent, glyph)
    local l = label(
        parent,
        glyph,
        18,
        Enum.Font.GothamMedium,
        COLORS.Muted
    )

    l.TextXAlignment = Enum.TextXAlignment.Center

    return l
end

local function getTextWidth(text, font, size)
    local result = TextService:GetTextSize(
        text,
        size,
        font,
        Vector2.new(1000, 100)
    )

    return result.X
end

local function getViewportSize()
    local camera = workspace.CurrentCamera

    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function clampWindowSize(width, height)
    local viewport = getViewportSize()

    local maxWidth = math.max(520, viewport.X - 40)
    local maxHeight = math.max(360, viewport.Y - 40)

    width = math.min(width, maxWidth)
    height = math.min(height, maxHeight)

    width = math.max(width, 520)
    height = math.max(height, 360)

    return math.floor(width), math.floor(height)
end

function Aether.new(options)
    options = options or {}

    local self = setmetatable({}, Aether)

    self.Name = options.Name or "AETHER"
    self.Version = options.Version or "v1.0"
    self.Width = options.Width or 780
    self.Height = options.Height or 500

    self.Width, self.Height = clampWindowSize(
        self.Width,
        self.Height
    )

    self.Minimized = false
    self.Tabs = {}
    self.ActiveTab = nil
    self.Destroyed = false
    self.Connections = {}

    local gui = Instance.new("ScreenGui")
    gui.Name = self.Name:gsub("%W", "") .. "_UI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    self.Gui = gui

    --==============================================================
    -- SHADOW
    --==============================================================

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.fromOffset(
        self.Width + 10,
        self.Height + 10
    )
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.55
    shadow.BorderSizePixel = 0
    shadow.Parent = gui

    corner(shadow, 7)

    self.Shadow = shadow

    --==============================================================
    -- MAIN
    --==============================================================

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.Size = UDim2.fromOffset(
        self.Width,
        self.Height
    )
    main.BackgroundColor3 = COLORS.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = gui

    corner(main, 6)
    stroke(main, COLORS.Border, 1)

    self.Main = main

    --==============================================================
    -- HEADER
    --==============================================================

    local HEADER_HEIGHT = 50

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    header.BackgroundColor3 = COLORS.Background
    header.BorderSizePixel = 0
    header.Parent = main

    self.Header = header

    local headerDivider = Instance.new("Frame")
    headerDivider.Position = UDim2.new(0, 0, 1, -1)
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.BackgroundColor3 = COLORS.Divider
    headerDivider.BorderSizePixel = 0
    headerDivider.Parent = header

    local title = label(
        header,
        self.Name,
        19,
        Enum.Font.GothamMedium,
        COLORS.Text
    )

    title.Position = UDim2.fromOffset(22, 0)
    title.Size = UDim2.new(
        0,
        getTextWidth(
            self.Name,
            Enum.Font.GothamMedium,
            19
        ) + 8,
        1,
        0
    )

    local version = label(
        header,
        self.Version,
        12,
        Enum.Font.Gotham,
        COLORS.Muted
    )

    version.Position = UDim2.fromOffset(
        title.Position.X.Offset +
        title.Size.X.Offset - 2,
        0
    )

    version.Size = UDim2.fromOffset(50, HEADER_HEIGHT)

    -- Minimize

    local minimize = makeButton(header)
    minimize.Size = UDim2.fromOffset(38, HEADER_HEIGHT)
    minimize.Position = UDim2.new(1, -82, 0, 0)

    local minGlyph = label(
        minimize,
        "—",
        20,
        Enum.Font.Gotham,
        COLORS.Muted
    )

    minGlyph.Size = UDim2.fromScale(1, 1)
    minGlyph.TextXAlignment = Enum.TextXAlignment.Center

    -- Close

    local close = makeButton(header)
    close.Size = UDim2.fromOffset(38, HEADER_HEIGHT)
    close.Position = UDim2.new(1, -40, 0, 0)

    local closeGlyph = label(
        close,
        "×",
        27,
        Enum.Font.Gotham,
        COLORS.Muted
    )

    closeGlyph.Size = UDim2.fromScale(1, 1)
    closeGlyph.TextXAlignment = Enum.TextXAlignment.Center

    close.MouseEnter:Connect(function()
        tween(closeGlyph, 0.12, {
            TextColor3 = COLORS.Text
        })
    end)

    close.MouseLeave:Connect(function()
        tween(closeGlyph, 0.12, {
            TextColor3 = COLORS.Muted
        })
    end)

    minimize.MouseEnter:Connect(function()
        tween(minGlyph, 0.12, {
            TextColor3 = COLORS.Text
        })
    end)

    minimize.MouseLeave:Connect(function()
        tween(minGlyph, 0.12, {
            TextColor3 = COLORS.Muted
        })
    end)

    close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    minimize.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized

        if self.Minimized then
            tween(
                main,
                0.18,
                {
                    Size = UDim2.fromOffset(
                        self.Width,
                        HEADER_HEIGHT
                    )
                }
            )

            tween(
                shadow,
                0.18,
                {
                    Size = UDim2.fromOffset(
                        self.Width + 10,
                        HEADER_HEIGHT + 10
                    )
                }
            )
        else
            tween(
                main,
                0.18,
                {
                    Size = UDim2.fromOffset(
                        self.Width,
                        self.Height
                    )
                }
            )

            tween(
                shadow,
                0.18,
                {
                    Size = UDim2.fromOffset(
                        self.Width + 10,
                        self.Height + 10
                    )
                }
            )
        end
    end)

    --==============================================================
    -- DRAGGING
    --==============================================================

    local dragging = false
    local dragStart
    local startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    table.insert(
        self.Connections,
        UserInputService.InputChanged:Connect(function(input)
            if dragging and
                input.UserInputType == Enum.UserInputType.MouseMovement then

                local delta = input.Position - dragStart

                main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )

                shadow.Position = main.Position
            end
        end)
    )

    --==============================================================
    -- BODY
    --==============================================================

    local BODY_HEIGHT = self.Height - HEADER_HEIGHT
    local RAIL_WIDTH = 54
    local NAV_WIDTH = 136

    --==============================================================
    -- RAIL
    --==============================================================

    local rail = Instance.new("Frame")
    rail.Name = "Rail"
    rail.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
    rail.Size = UDim2.fromOffset(
        RAIL_WIDTH,
        BODY_HEIGHT
    )
    rail.BackgroundColor3 = COLORS.SidebarDark
    rail.BorderSizePixel = 0
    rail.Parent = main

    self.Rail = rail

    local railDivider = Instance.new("Frame")
    railDivider.Position = UDim2.new(1, -1, 0, 0)
    railDivider.Size = UDim2.new(0, 1, 1, 0)
    railDivider.BackgroundColor3 = COLORS.Divider
    railDivider.BorderSizePixel = 0
    railDivider.Parent = rail

    local logo = label(
        rail,
        options.Logo or "A",
        23,
        Enum.Font.GothamBold,
        COLORS.Text
    )

    logo.Size = UDim2.new(1, 0, 0, 45)
    logo.Position = UDim2.fromOffset(0, 6)
    logo.TextXAlignment = Enum.TextXAlignment.Center

    local railTabs = Instance.new("Frame")
    railTabs.Name = "RailTabs"
    railTabs.BackgroundTransparency = 1
    railTabs.Position = UDim2.fromOffset(0, 60)
    railTabs.Size = UDim2.new(1, 0, 1, -70)
    railTabs.Parent = rail

    local railLayout = Instance.new("UIListLayout")
    railLayout.Padding = UDim.new(0, 6)
    railLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    railLayout.SortOrder = Enum.SortOrder.LayoutOrder
    railLayout.Parent = railTabs

    self.RailTabs = railTabs

    --==============================================================
    -- NAVIGATION
    --==============================================================

    local navigation = Instance.new("Frame")
    navigation.Name = "Navigation"
    navigation.Position = UDim2.fromOffset(
        RAIL_WIDTH,
        HEADER_HEIGHT
    )
    navigation.Size = UDim2.fromOffset(
        NAV_WIDTH,
        BODY_HEIGHT
    )
    navigation.BackgroundColor3 = Color3.fromRGB(14, 16, 18)
    navigation.BorderSizePixel = 0
    navigation.Parent = main

    self.Navigation = navigation

    local navDivider = Instance.new("Frame")
    navDivider.Position = UDim2.new(1, -1, 0, 0)
    navDivider.Size = UDim2.new(0, 1, 1, 0)
    navDivider.BackgroundColor3 = COLORS.Divider
    navDivider.BorderSizePixel = 0
    navDivider.Parent = navigation

    local navList = Instance.new("Frame")
    navList.BackgroundTransparency = 1
    navList.Position = UDim2.fromOffset(10, 14)
    navList.Size = UDim2.new(1, -20, 1, -28)
    navList.Parent = navigation

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 4)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = navList

    self.NavList = navList

    --==============================================================
    -- CONTENT
    --==============================================================

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(
        RAIL_WIDTH + NAV_WIDTH,
        HEADER_HEIGHT
    )
    content.Size = UDim2.new(
        1,
        -(RAIL_WIDTH + NAV_WIDTH),
        1,
        -HEADER_HEIGHT
    )
    content.BackgroundColor3 = COLORS.Background
    content.BorderSizePixel = 0
    content.Parent = main

    self.Content = content

    local pageTitle = label(
        content,
        "",
        21,
        Enum.Font.GothamMedium,
        COLORS.Text
    )

    pageTitle.Position = UDim2.fromOffset(22, 17)
    pageTitle.Size = UDim2.new(1, -44, 0, 30)

    self.PageTitle = pageTitle

    --==============================================================
    -- TOGGLE KEY
    --==============================================================

    if options.ToggleKey then
        self.ToggleKey = options.ToggleKey

        table.insert(
            self.Connections,
            UserInputService.InputBegan:Connect(
                function(input, processed)
                    if not processed and
                        input.KeyCode == self.ToggleKey then

                        gui.Enabled = not gui.Enabled
                    end
                end
            )
        )
    end

    self:AddCloseCorner()

    return self
end

--==============================================================
-- EMPTY LOWER CORNER HOOK
--==============================================================

function Aether:AddCloseCorner()
    -- Reserved for game-specific implementations.
end

--==============================================================
-- CREATE TAB
--==============================================================

function Aether:CreateTab(options)
    options =
        type(options) == "string"
        and {Name = options}
        or (options or {})

    local tab = {}

    tab.Library = self
    tab.Name = options.Name or (
        "Tab " .. tostring(#self.Tabs + 1)
    )
    tab.Icon = options.Icon or ""
    tab.Sections = {}
    tab.Order = #self.Tabs + 1

    --==============================================================
    -- NAV BUTTON
    --==============================================================

    local navButton = makeButton(self.NavList)

    navButton.Size = UDim2.new(
        1,
        0,
        0,
        42
    )

    navButton.LayoutOrder = tab.Order

    corner(navButton, 5)

    local navAccent = Instance.new("Frame")
    navAccent.BackgroundColor3 = COLORS.Accent
    navAccent.Size = UDim2.new(0, 2, 1, -12)
    navAccent.Position = UDim2.fromOffset(0, 6)
    navAccent.Visible = false
    navAccent.Parent = navButton

    corner(navAccent, 1)

    local navIcon = icon(
        navButton,
        tab.Icon ~= "" and tab.Icon or "•"
    )

    navIcon.Size = UDim2.fromOffset(22, 42)
    navIcon.Position = UDim2.fromOffset(10, 0)

    local navText = label(
        navButton,
        tab.Name,
        14,
        Enum.Font.Gotham,
        COLORS.Muted
    )

    navText.Position = UDim2.fromOffset(37, 0)
    navText.Size = UDim2.new(1, -43, 1, 0)

    --==============================================================
    -- RAIL BUTTON
    --==============================================================

    local railButton = makeButton(self.RailTabs)

    railButton.Size = UDim2.fromOffset(40, 40)
    railButton.LayoutOrder = tab.Order

    corner(railButton, 5)

    local railIcon = icon(
        railButton,
        tab.Icon ~= "" and tab.Icon or "•"
    )

    railIcon.Size = UDim2.fromScale(1, 1)

    --==============================================================
    -- PAGE
    --==============================================================

    local page = Instance.new("ScrollingFrame")

    page.Name = tab.Name:gsub("%W", "") .. "Page"
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0

    page.Position = UDim2.fromOffset(
        16,
        54
    )

    page.Size = UDim2.new(
        1,
        -32,
        1,
        -64
    )

    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = COLORS.Border
    page.CanvasSize = UDim2.fromOffset(0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.Parent = self.Content

    padding(
        page,
        4,
        4,
        4,
        14
    )

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    tab.Page = page
    tab.NavButton = navButton
    tab.RailButton = railButton
    tab.NavAccent = navAccent
    tab.NavText = navText
    tab.NavIcon = navIcon
    tab.RailIcon = railIcon
    tab._order = tab.Order

    --==============================================================
    -- SELECTION
    --==============================================================

    local function select()
        for _, other in ipairs(self.Tabs) do
            local active = other == tab

            other.Page.Visible = active
            other.NavAccent.Visible = active

            other.NavButton.BackgroundColor3 =
                active
                and COLORS.SidebarItem
                or Color3.new(0, 0, 0)

            other.NavText.TextColor3 =
                active
                and COLORS.Text
                or COLORS.Muted

            other.NavIcon.TextColor3 =
                active
                and COLORS.Text
                or COLORS.Muted

            other.RailButton.BackgroundColor3 =
                active
                and COLORS.SidebarItem
                or COLORS.SidebarDark

            other.RailIcon.TextColor3 =
                active
                and COLORS.Text
                or COLORS.Muted
        end

        self.PageTitle.Text = tab.Name
        self.ActiveTab = tab
    end

    navButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(
                navButton,
                0.12,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(20, 22, 24)
                }
            )
        end
    end)

    navButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(
                navButton,
                0.12,
                {
                    BackgroundColor3 =
                        Color3.new(0, 0, 0)
                }
            )
        end
    end)

    railButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(
                railButton,
                0.12,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(19, 21, 23)
                }
            )
        end
    end)

    railButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(
                railButton,
                0.12,
                {
                    BackgroundColor3 =
                        COLORS.SidebarDark
                }
            )
        end
    end)

    navButton.MouseButton1Click:Connect(select)
    railButton.MouseButton1Click:Connect(select)

    table.insert(self.Tabs, tab)

    if not self.ActiveTab then
        task.defer(select)
    end

    --==============================================================
    -- CREATE SECTION
    --==============================================================

    function tab:CreateSection(titleText, sectionOptions)
        sectionOptions = sectionOptions or {}

        local section = {}

        section.Name = titleText or "SECTION"
        section.Controls = {}

        local container = Instance.new("Frame")

        container.Name = "Section"
        container.BackgroundColor3 =
            sectionOptions.Filled == false
            and Color3.new(0, 0, 0)
            or COLORS.Panel

        container.BackgroundTransparency =
            sectionOptions.Filled == false
            and 1
            or 0

        container.BorderSizePixel = 0

        container.Size = UDim2.new(
            1,
            0,
            0,
            0
        )

        container.AutomaticSize = Enum.AutomaticSize.Y
        container.LayoutOrder = #tab.Sections + 1
        container.Parent = page

        if sectionOptions.Filled ~= false then
            corner(container, 5)
            stroke(container, COLORS.Divider, 1)
        end

        padding(
            container,
            14,
            14,
            10,
            10
        )

        local heading = label(
            container,
            string.upper(section.Name),
            12,
            Enum.Font.Gotham,
            COLORS.Muted
        )

        heading.Size = UDim2.new(
            1,
            0,
            0,
            20
        )

        local divider = Instance.new("Frame")

        divider.Size = UDim2.new(
            1,
            0,
            0,
            1
        )

        divider.Position = UDim2.fromOffset(0, 28)
        divider.BackgroundColor3 = COLORS.Divider
        divider.BorderSizePixel = 0
        divider.Parent = container

        local items = Instance.new("Frame")

        items.BackgroundTransparency = 1
        items.Position = UDim2.fromOffset(0, 38)

        items.Size = UDim2.new(
            1,
            0,
            0,
            0
        )

        items.AutomaticSize = Enum.AutomaticSize.Y
        items.Parent = container

        local list = Instance.new("UIListLayout")

        list.Padding = UDim.new(0, 1)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = items

        section.Container = container
        section.Items = items
        section.Layout = list

        --==========================================================
        -- ROW BASE
        --==========================================================

        local function rowBase(height)
            local row = Instance.new("Frame")

            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0

            row.Size = UDim2.new(
                1,
                0,
                0,
                height or 44
            )

            row.Parent = items

            return row
        end

        --==========================================================
        -- TOGGLE
        --==========================================================

        function section:CreateToggle(opts)
            opts = opts or {}

            local row = rowBase(44)

            local textLabel = label(
                row,
                opts.Name or "Toggle",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Position = UDim2.fromOffset(0, 0)

            textLabel.Size = UDim2.new(
                1,
                -70,
                1,
                0
            )

            local toggle = Instance.new("Frame")

            toggle.Size = UDim2.fromOffset(38, 22)

            toggle.Position = UDim2.new(
                1,
                -38,
                0.5,
                -11
            )

            toggle.BackgroundColor3 =
                Color3.fromRGB(42, 45, 49)

            toggle.BorderSizePixel = 0
            toggle.Parent = row

            corner(toggle, 11)

            local knob = Instance.new("Frame")

            knob.Size = UDim2.fromOffset(16, 16)
            knob.Position = UDim2.fromOffset(3, 3)

            knob.BackgroundColor3 =
                Color3.fromRGB(236, 237, 239)

            knob.BorderSizePixel = 0
            knob.Parent = toggle

            corner(knob, 8)

            local hit = makeButton(row)

            hit.Size = UDim2.fromOffset(56, 40)

            hit.Position = UDim2.new(
                1,
                -56,
                0.5,
                -20
            )

            local state =
                opts.CurrentValue == true

            local function set(v, fire)
                state = v == true

                tween(
                    toggle,
                    0.13,
                    {
                        BackgroundColor3 =
                            state
                            and COLORS.Accent
                            or Color3.fromRGB(42, 45, 49)
                    }
                )

                tween(
                    knob,
                    0.13,
                    {
                        Position =
                            state
                            and UDim2.fromOffset(19, 3)
                            or UDim2.fromOffset(3, 3)
                    }
                )

                if fire ~= false and opts.Callback then
                    opts.Callback(state)
                end
            end

            set(state, false)

            hit.MouseButton1Click:Connect(function()
                set(not state)
            end)

            return {
                Set = function(_, v)
                    set(v, true)
                end,

                Get = function()
                    return state
                end,

                Instance = row,
            }
        end

        --==========================================================
        -- BUTTON
        --==========================================================

        function section:CreateButton(opts)
            opts = opts or {}

            local row = rowBase(44)

            local buttonTextValue =
                opts.ButtonText or "Action"

            local textLabel = label(
                row,
                opts.Name or "Button",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Position = UDim2.fromOffset(0, 0)

            textLabel.Size = UDim2.new(
                1,
                -120,
                1,
                0
            )

            local button = makeButton(row)

            button.AnchorPoint = Vector2.new(1, 0.5)

            button.Position = UDim2.new(
                1,
                0,
                0.5,
                0
            )

            local width = math.clamp(
                getTextWidth(
                    buttonTextValue,
                    Enum.Font.Gotham,
                    13
                ) + 24,
                68,
                130
            )

            button.Size = UDim2.fromOffset(
                width,
                30
            )

            button.BackgroundColor3 = COLORS.Control
            button.BorderSizePixel = 0

            corner(button, 4)
            stroke(button, COLORS.Border, 1)

            local buttonText = label(
                button,
                buttonTextValue,
                13,
                Enum.Font.Gotham,
                COLORS.Text
            )

            buttonText.Size = UDim2.fromScale(1, 1)
            buttonText.TextXAlignment =
                Enum.TextXAlignment.Center

            button.MouseEnter:Connect(function()
                tween(
                    button,
                    0.12,
                    {
                        BackgroundColor3 =
                            Color3.fromRGB(28, 31, 35)
                    }
                )
            end)

            button.MouseLeave:Connect(function()
                tween(
                    button,
                    0.12,
                    {
                        BackgroundColor3 =
                            COLORS.Control
                    }
                )
            end)

            button.MouseButton1Click:Connect(function()
                if opts.Callback then
                    opts.Callback()
                end
            end)

            return {
                Fire = function()
                    if opts.Callback then
                        opts.Callback()
                    end
                end,

                Instance = row,
            }
        end

        --==========================================================
        -- DROPDOWN
        --==========================================================

        function section:CreateDropdown(opts)
            opts = opts or {}

            local row = rowBase(50)

            local textLabel = label(
                row,
                opts.Name or "Dropdown",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Position = UDim2.fromOffset(0, 0)

            textLabel.Size = UDim2.new(
                0.45,
                0,
                1,
                0
            )

            local selected =
                opts.CurrentOption
                or opts.CurrentValue
                or (
                    opts.Options
                    and opts.Options[1]
                )
                or "None"

            local dd = makeButton(row)

            dd.AnchorPoint =
                Vector2.new(1, 0.5)

            dd.Position = UDim2.new(
                1,
                0,
                0.5,
                0
            )

            dd.Size = UDim2.fromOffset(
                math.min(
                    opts.Width or 190,
                    210
                ),
                32
            )

            dd.BackgroundColor3 = COLORS.Control

            corner(dd, 4)
            stroke(dd, COLORS.Border, 1)

            local valueText = label(
                dd,
                tostring(selected),
                13,
                Enum.Font.Gotham,
                COLORS.Text
            )

            valueText.Position =
                UDim2.fromOffset(11, 0)

            valueText.Size =
                UDim2.new(1, -38, 1, 0)

            valueText.TextTruncate =
                Enum.TextTruncate.AtEnd

            local chevron = label(
                dd,
                "⌄",
                17,
                Enum.Font.Gotham,
                COLORS.Muted
            )

            chevron.AnchorPoint =
                Vector2.new(1, 0.5)

            chevron.Position =
                UDim2.new(1, -9, 0.5, 0)

            chevron.Size =
                UDim2.fromOffset(18, 20)

            chevron.TextXAlignment =
                Enum.TextXAlignment.Center

            local dropdownGui = Instance.new("Frame")

            dropdownGui.Name =
                "AetherDropdown"

            dropdownGui.BackgroundTransparency = 1
            dropdownGui.Size =
                UDim2.fromScale(1, 1)

            dropdownGui.Visible = false
            dropdownGui.ZIndex = 1000
            dropdownGui.Parent = self.Library.Gui

            local popup = Instance.new("Frame")

            popup.BackgroundColor3 = COLORS.Control
            popup.BorderSizePixel = 0
            popup.ZIndex = 1000

            corner(popup, 4)
            stroke(popup, COLORS.Border, 1)

            popup.Parent = dropdownGui

            local popupPadding =
                padding(
                    popup,
                    4,
                    4,
                    4,
                    4
                )

            local popupList =
                Instance.new("UIListLayout")

            popupList.Padding =
                UDim.new(0, 2)

            popupList.Parent = popup

            local open = false

            local function close()
                open = false
                dropdownGui.Visible = false
            end

            local function rebuild()
                for _, child in ipairs(popup:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                local optionsList =
                    opts.Options or {}

                local visibleCount =
                    math.min(#optionsList, 6)

                popup.Size =
                    UDim2.fromOffset(
                        dd.AbsoluteSize.X,
                        visibleCount * 30 + 8
                    )

                for index, option in ipairs(optionsList) do
                    local item = makeButton(popup)

                    item.Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            30
                        )

                    item.LayoutOrder = index
                    item.ZIndex = 1001

                    corner(item, 3)

                    local itemText = label(
                        item,
                        tostring(option),
                        13,
                        Enum.Font.Gotham,
                        COLORS.Text
                    )

                    itemText.Position =
                        UDim2.fromOffset(8, 0)

                    itemText.Size =
                        UDim2.new(
                            1,
                            -16,
                            1,
                            0
                        )

                    itemText.ZIndex = 1002

                    item.MouseEnter:Connect(function()
                        tween(
                            item,
                            0.1,
                            {
                                BackgroundTransparency = 0,
                                BackgroundColor3 =
                                    Color3.fromRGB(
                                        27,
                                        30,
                                        34
                                    )
                            }
                        )
                    end)

                    item.MouseLeave:Connect(function()
                        tween(
                            item,
                            0.1,
                            {
                                BackgroundTransparency = 1
                            }
                        )
                    end)

                    item.MouseButton1Click:Connect(function()
                        selected = option
                        valueText.Text =
                            tostring(option)

                        close()

                        if opts.Callback then
                            opts.Callback(option)
                        end
                    end)
                end
            end

            local function show()
                close()

                rebuild()

                local absolutePos =
                    dd.AbsolutePosition

                local absoluteSize =
                    dd.AbsoluteSize

                local viewport =
                    getViewportSize()

                local popupHeight =
                    popup.Size.Y.Offset

                local x =
                    absolutePos.X

                local y =
                    absolutePos.Y +
                    absoluteSize.Y +
                    5

                if y + popupHeight > viewport.Y - 8 then
                    y =
                        absolutePos.Y -
                        popupHeight -
                        5
                end

                x = math.clamp(
                    x,
                    8,
                    math.max(
                        8,
                        viewport.X -
                        absoluteSize.X -
                        8
                    )
                )

                popup.Position =
                    UDim2.fromOffset(x, y)

                dropdownGui.Visible = true
                open = true
            end

            dd.MouseButton1Click:Connect(function()
                if open then
                    close()
                else
                    show()
                end
            end)

            table.insert(
                self.Library.Connections,
                UserInputService.InputBegan:Connect(
                    function(input)
                        if not open then
                            return
                        end

                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1 then

                            local mousePos =
                                input.Position

                            local pos =
                                popup.AbsolutePosition

                            local size =
                                popup.AbsoluteSize

                            local inside =
                                mousePos.X >= pos.X
                                and mousePos.X <=
                                    pos.X + size.X
                                and mousePos.Y >= pos.Y
                                and mousePos.Y <=
                                    pos.Y + size.Y

                            local ddPos =
                                dd.AbsolutePosition

                            local ddSize =
                                dd.AbsoluteSize

                            local inDropdown =
                                mousePos.X >=
                                    ddPos.X
                                and mousePos.X <=
                                    ddPos.X + ddSize.X
                                and mousePos.Y >=
                                    ddPos.Y
                                and mousePos.Y <=
                                    ddPos.Y + ddSize.Y

                            if not inside
                                and not inDropdown then

                                close()
                            end
                        end
                    end
                )
            )

            return {
                Set = function(_, value)
                    selected = value
                    valueText.Text =
                        tostring(value)

                    if opts.Callback then
                        opts.Callback(value)
                    end
                end,

                Get = function()
                    return selected
                end,

                Close = close,

                Instance = row,
            }
        end

        --==========================================================
        -- SLIDER
        --==========================================================

        function section:CreateSlider(opts)
            opts = opts or {}

            local row = rowBase(58)

            local textLabel = label(
                row,
                opts.Name or "Slider",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Position =
                UDim2.fromOffset(0, 0)

            textLabel.Size =
                UDim2.new(0, 150, 0, 22)

            local min =
                tonumber(
                    opts.Range
                    and opts.Range[1]
                )
                or tonumber(opts.Min)
                or 0

            local max =
                tonumber(
                    opts.Range
                    and opts.Range[2]
                )
                or tonumber(opts.Max)
                or 100

            if max <= min then
                max = min + 1
            end

            local value =
                tonumber(
                    opts.CurrentValue
                    or opts.Default
                    or min
                )
                or min

            local valueLabel = label(
                row,
                tostring(value),
                12,
                Enum.Font.Gotham,
                COLORS.Muted
            )

            valueLabel.AnchorPoint =
                Vector2.new(1, 0)

            valueLabel.Position =
                UDim2.new(1, 0, 0, 0)

            valueLabel.Size =
                UDim2.fromOffset(70, 22)

            valueLabel.TextXAlignment =
                Enum.TextXAlignment.Right

            local track = Instance.new("Frame")

            track.Position =
                UDim2.new(0, 0, 0, 34)

            track.Size =
                UDim2.new(1, 0, 0, 4)

            track.BackgroundColor3 =
                Color3.fromRGB(43, 46, 50)

            track.BorderSizePixel = 0
            track.Parent = row

            corner(track, 2)

            local fill = Instance.new("Frame")

            fill.Size =
                UDim2.fromScale(0, 1)

            fill.BackgroundColor3 =
                COLORS.Accent

            fill.BorderSizePixel = 0
            fill.Parent = track

            corner(fill, 2)

            local knob = Instance.new("Frame")

            knob.AnchorPoint =
                Vector2.new(0.5, 0.5)

            knob.Size =
                UDim2.fromOffset(12, 12)

            knob.BackgroundColor3 =
                COLORS.Text

            knob.BorderSizePixel = 0
            knob.Parent = track

            corner(knob, 6)

            local hit = makeButton(row)

            hit.Position =
                UDim2.new(0, 0, 0, 18)

            hit.Size =
                UDim2.new(1, 0, 0, 30)

            hit.ZIndex = 5

            local draggingSlider = false

            local function applyValue(newValue, fire)
                newValue = math.clamp(
                    newValue,
                    min,
                    max
                )

                if opts.Rounding then
                    local r =
                        tonumber(opts.Rounding)
                        or 1

                    if r > 0 then
                        newValue =
                            math.floor(
                                newValue / r + 0.5
                            ) * r
                    end
                end

                newValue = math.clamp(
                    newValue,
                    min,
                    max
                )

                value = newValue

                local alpha =
                    (value - min) /
                    (max - min)

                valueLabel.Text =
                    tostring(value)

                fill.Size =
                    UDim2.fromScale(
                        alpha,
                        1
                    )

                knob.Position =
                    UDim2.new(
                        alpha,
                        0,
                        0.5,
                        0
                    )

                if fire ~= false
                    and opts.Callback then

                    opts.Callback(value)
                end
            end

            local function setFromX(x, fire)
                local alpha =
                    math.clamp(
                        (
                            x -
                            track.AbsolutePosition.X
                        ) /
                        math.max(
                            track.AbsoluteSize.X,
                            1
                        ),
                        0,
                        1
                    )

                local raw =
                    min +
                    (
                        max - min
                    ) * alpha

                applyValue(
                    raw,
                    fire
                )
            end

            hit.InputBegan:Connect(function(input)
                if input.UserInputType ==
                    Enum.UserInputType.MouseButton1 then

                    draggingSlider = true

                    setFromX(
                        input.Position.X,
                        true
                    )
                end
            end)

            table.insert(
                self.Library.Connections,
                UserInputService.InputChanged:Connect(
                    function(input)
                        if draggingSlider
                            and
                            input.UserInputType ==
                                Enum.UserInputType.MouseMovement then

                            setFromX(
                                input.Position.X,
                                true
                            )
                        end
                    end
                )
            )

            table.insert(
                self.Library.Connections,
                UserInputService.InputEnded:Connect(
                    function(input)
                        if input.UserInputType ==
                            Enum.UserInputType.MouseButton1 then

                            draggingSlider = false
                        end
                    end
                )
            )

            applyValue(value, false)

            return {
                Set = function(_, v)
                    applyValue(
                        tonumber(v)
                            or min,
                        true
                    )
                end,

                Get = function()
                    return value
                end,

                Instance = row,
            }
        end

        --==========================================================
        -- KEYBIND
        --==========================================================

        function section:CreateKeybind(opts)
            opts = opts or {}

            local row = rowBase(44)

            local textLabel = label(
                row,
                opts.Name or "Keybind",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Size =
                UDim2.new(
                    1,
                    -110,
                    1,
                    0
                )

            local bind =
                opts.CurrentKeybind
                or opts.CurrentKey
                or opts.Key
                or Enum.KeyCode.RightShift

            local waiting = false

            local chip = makeButton(row)

            chip.AnchorPoint =
                Vector2.new(1, 0.5)

            chip.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            chip.Size =
                UDim2.fromOffset(92, 30)

            chip.BackgroundColor3 =
                COLORS.Control

            corner(chip, 4)
            stroke(chip, COLORS.Border, 1)

            local chipText = label(
                chip,
                bind.Name,
                12,
                Enum.Font.Gotham,
                COLORS.Text
            )

            chipText.Size =
                UDim2.fromScale(1, 1)

            chipText.TextXAlignment =
                Enum.TextXAlignment.Center

            local function fire(input)
                if opts.Callback then
                    opts.Callback(input)
                end
            end

            chip.MouseButton1Click:Connect(function()
                waiting = true
                chipText.Text = "Press key..."
            end)

            local connection

            connection =
                UserInputService.InputBegan:Connect(
                    function(input, processed)
                        if waiting
                            and
                            input.UserInputType ==
                                Enum.UserInputType.Keyboard then

                            bind = input.KeyCode
                            waiting = false

                            chipText.Text =
                                bind.Name

                            if opts.SetCallback then
                                opts.SetCallback(bind)
                            end

                            return
                        end

                        if not processed
                            and input.KeyCode == bind then

                            fire(input)
                        end
                    end
                )

            return {
                Set = function(_, key)
                    if typeof(key) ~= "EnumItem" then
                        return
                    end

                    bind = key
                    chipText.Text =
                        key.Name
                end,

                Get = function()
                    return bind
                end,

                Destroy = function()
                    if connection then
                        connection:Disconnect()
                        connection = nil
                    end

                    row:Destroy()
                end,

                Instance = row,
            }
        end

        --==========================================================
        -- STATUS
        --==========================================================

        function section:CreateStatus(opts)
            opts = opts or {}

            local row = rowBase(40)

            local active =
                opts.Active == true

            local textLabel = label(
                row,
                opts.Name or "Status",
                14,
                Enum.Font.Gotham,
                COLORS.Text
            )

            textLabel.Size =
                UDim2.new(
                    1,
                    -100,
                    1,
                    0
                )

            local dot = Instance.new("Frame")

            dot.Size =
                UDim2.fromOffset(7, 7)

            dot.AnchorPoint =
                Vector2.new(0, 0.5)

            dot.Position =
                UDim2.new(
                    1,
                    -78,
                    0.5,
                    0
                )

            dot.BackgroundColor3 =
                active
                and COLORS.Success
                or COLORS.Dim

            dot.BorderSizePixel = 0
            dot.Parent = row

            corner(dot, 4)

            local statusText = label(
                row,
                opts.Text
                    or (
                        active
                        and "Active"
                        or "Inactive"
                    ),
                13,
                Enum.Font.Gotham,
                active
                    and COLORS.Success
                    or COLORS.Muted
            )

            statusText.AnchorPoint =
                Vector2.new(1, 0.5)

            statusText.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            statusText.Size =
                UDim2.fromOffset(68, 22)

            statusText.TextXAlignment =
                Enum.TextXAlignment.Right

            local function set(isActive, text)
                dot.BackgroundColor3 =
                    isActive
                    and COLORS.Success
                    or COLORS.Dim

                statusText.TextColor3 =
                    isActive
                    and COLORS.Success
                    or COLORS.Muted

                statusText.Text =
                    text
                    or (
                        isActive
                        and "Active"
                        or "Inactive"
                    )
            end

            return {
                Set = set,
                Instance = row,
            }
        end

        table.insert(
            tab.Sections,
            section
        )

        return section
    end

    return tab
end

--==============================================================
-- NOTIFICATIONS
--==============================================================

function Aether:Notify(options)
    options = options or {}

    local holder =
        self.Gui:FindFirstChild("Notifications")

    if not holder then
        holder = Instance.new("Frame")

        holder.Name =
            "Notifications"

        holder.AnchorPoint =
            Vector2.new(1, 1)

        holder.Position =
            UDim2.new(
                1,
                -14,
                1,
                -14
            )

        holder.Size =
            UDim2.fromOffset(
                290,
                300
            )

        holder.BackgroundTransparency = 1

        holder.ZIndex = 900

        holder.Parent = self.Gui

        local list =
            Instance.new("UIListLayout")

        list.VerticalAlignment =
            Enum.VerticalAlignment.Bottom

        list.HorizontalAlignment =
            Enum.HorizontalAlignment.Right

        list.Padding =
            UDim.new(0, 7)

        list.Parent = holder
    end

    local n = Instance.new("Frame")

    n.Size =
        UDim2.fromOffset(290, 62)

    n.BackgroundColor3 =
        COLORS.Panel

    n.BorderSizePixel = 0
    n.ZIndex = 901
    n.Parent = holder

    corner(n, 5)
    stroke(n, COLORS.Border, 1)

    local title = label(
        n,
        options.Title or self.Name,
        13,
        Enum.Font.GothamMedium,
        COLORS.Text
    )

    title.Position =
        UDim2.fromOffset(12, 7)

    title.Size =
        UDim2.new(1, -24, 0, 18)

    title.ZIndex = 902

    local message = label(
        n,
        options.Content or "",
        12,
        Enum.Font.Gotham,
        COLORS.Muted
    )

    message.Position =
        UDim2.fromOffset(12, 26)

    message.Size =
        UDim2.new(1, -24, 0, 27)

    message.TextWrapped = true
    message.ZIndex = 902

    local duration =
        tonumber(options.Duration)
        or 3

    task.delay(
        duration,
        function()
            if n.Parent then
                tween(
                    n,
                    0.18,
                    {
                        BackgroundTransparency = 1
                    }
                )

                task.wait(0.18)

                if n.Parent then
                    n:Destroy()
                end
            end
        end
    )
end

--==============================================================
-- DESTROY
--==============================================================

function Aether:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(self.Connections)

    if self.Gui then
        self.Gui:Destroy()
    end
end

--==============================================================
-- RAYFIELD-STYLE COMPATIBILITY
--==============================================================

function Aether:CreateWindow(options)
    return Aether.new(options)
end

return Aether

]])()

return Aether
