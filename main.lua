--// Aether.lua
--// Compact Rayfield-style Roblox UI library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Aether = {}
Aether.__index = Aether

--==============================================================
-- COLORS
--==============================================================

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

--==============================================================
-- HELPERS
--==============================================================

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),
        properties
    )

    animation:Play()

    return animation
end

local function corner(parent, radius)
    local object = Instance.new("UICorner")

    object.CornerRadius =
        UDim.new(0, radius or 5)

    object.Parent = parent

    return object
end

local function stroke(parent, color, thickness, transparency)
    local object = Instance.new("UIStroke")

    object.Color =
        color or COLORS.Border

    object.Thickness =
        thickness or 1

    object.Transparency =
        transparency or 0

    object.Parent = parent

    return object
end

local function padding(parent, left, right, top, bottom)
    local object = Instance.new("UIPadding")

    object.PaddingLeft =
        UDim.new(0, left or 0)

    object.PaddingRight =
        UDim.new(0, right or 0)

    object.PaddingTop =
        UDim.new(0, top or 0)

    object.PaddingBottom =
        UDim.new(0, bottom or 0)

    object.Parent = parent

    return object
end

local function label(parent, text, size, font, color)
    local object = Instance.new("TextLabel")

    object.BackgroundTransparency = 1
    object.Text = text or ""
    object.Font = font or Enum.Font.Gotham
    object.TextSize = size or 14

    object.TextColor3 =
        color or COLORS.Text

    object.TextXAlignment =
        Enum.TextXAlignment.Left

    object.TextYAlignment =
        Enum.TextYAlignment.Center

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

local function getTextWidth(text, font, size)
    local result =
        TextService:GetTextSize(
            text,
            size,
            font,
            Vector2.new(1000, 100)
        )

    return result.X
end

local function viewportSize()
    local camera = workspace.CurrentCamera

    if camera then
        return camera.ViewportSize
    end

    return Vector2.new(1280, 720)
end

local function clampWindowSize(width, height)
    local viewport = viewportSize()

    local maxWidth =
        math.max(520, viewport.X - 30)

    local maxHeight =
        math.max(360, viewport.Y - 30)

    width =
        math.clamp(
            width,
            520,
            maxWidth
        )

    height =
        math.clamp(
            height,
            360,
            maxHeight
        )

    return
        math.floor(width),
        math.floor(height)
end

--==============================================================
-- WINDOW
--==============================================================

function Aether.new(options)
    options = options or {}

    local self =
        setmetatable({}, Aether)

    self.Name =
        options.Name or "AETHER"

    self.Version =
        options.Version or "v1.0"

    self.Width =
        options.Width or 780

    self.Height =
        options.Height or 500

    self.Width,
    self.Height =
        clampWindowSize(
            self.Width,
            self.Height
        )

    self.Minimized = false
    self.Destroyed = false

    self.Tabs = {}
    self.ActiveTab = nil
    self.Connections = {}

    --==========================================================
    -- SCREEN GUI
    --==========================================================

    local gui =
        Instance.new("ScreenGui")

    gui.Name =
        self.Name:gsub("%W", "")
        .. "_UI"

    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true

    gui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    gui.Parent =
        LocalPlayer:WaitForChild("PlayerGui")

    self.Gui = gui

    --==========================================================
    -- SHADOW
    --==========================================================

    local shadow =
        Instance.new("Frame")

    shadow.Name = "Shadow"

    shadow.AnchorPoint =
        Vector2.new(0.5, 0.5)

    shadow.Position =
        UDim2.fromScale(0.5, 0.5)

    shadow.Size =
        UDim2.fromOffset(
            self.Width + 12,
            self.Height + 12
        )

    shadow.BackgroundColor3 =
        Color3.new(0, 0, 0)

    shadow.BackgroundTransparency =
        0.55

    shadow.BorderSizePixel = 0

    shadow.Parent = gui

    corner(shadow, 8)

    self.Shadow = shadow

    --==========================================================
    -- MAIN
    --==========================================================

    local main =
        Instance.new("Frame")

    main.Name = "Main"

    main.AnchorPoint =
        Vector2.new(0.5, 0.5)

    main.Position =
        UDim2.fromScale(0.5, 0.5)

    main.Size =
        UDim2.fromOffset(
            self.Width,
            self.Height
        )

    main.BackgroundColor3 =
        COLORS.Background

    main.BorderSizePixel = 0

    main.ClipsDescendants = true

    main.Parent = gui

    -- Only corner radius.
    -- No UIStroke on the entire GUI.

    corner(main, 7)

    self.Main = main

    --==========================================================
    -- HEADER
    --==========================================================

    local HEADER_HEIGHT = 50

    local header =
        Instance.new("Frame")

    header.Name = "Header"

    header.Size =
        UDim2.new(
            1,
            0,
            0,
            HEADER_HEIGHT
        )

    header.BackgroundColor3 =
        COLORS.Background

    header.BorderSizePixel = 0

    header.Parent = main

    self.Header = header

    local headerDivider =
        Instance.new("Frame")

    headerDivider.Position =
        UDim2.new(0, 0, 1, -1)

    headerDivider.Size =
        UDim2.new(1, 0, 0, 1)

    headerDivider.BackgroundColor3 =
        COLORS.Divider

    headerDivider.BorderSizePixel = 0

    headerDivider.Parent = header

    --==========================================================
    -- HEADER TITLE
    --==========================================================

    local title =
        label(
            header,
            self.Name,
            19,
            Enum.Font.GothamMedium,
            COLORS.Text
        )

    title.Position =
        UDim2.fromOffset(22, 0)

    title.Size =
        UDim2.fromOffset(
            getTextWidth(
                self.Name,
                Enum.Font.GothamMedium,
                19
            ) + 8,
            HEADER_HEIGHT
        )

    local version =
        label(
            header,
            self.Version,
            11,
            Enum.Font.Gotham,
            COLORS.Muted
        )

    version.Position =
        UDim2.fromOffset(
            title.Position.X.Offset +
            title.Size.X.Offset,
            0
        )

    version.Size =
        UDim2.fromOffset(
            45,
            HEADER_HEIGHT
        )

    --==========================================================
    -- MINIMIZE
    --==========================================================

    local minimize =
        makeButton(header)

    minimize.Size =
        UDim2.fromOffset(
            38,
            HEADER_HEIGHT
        )

    minimize.Position =
        UDim2.new(
            1,
            -78,
            0,
            0
        )

    local minGlyph =
        label(
            minimize,
            "—",
            19,
            Enum.Font.Gotham,
            COLORS.Muted
        )

    minGlyph.Size =
        UDim2.fromScale(1, 1)

    minGlyph.TextXAlignment =
        Enum.TextXAlignment.Center

    --==========================================================
    -- CLOSE
    --==========================================================

    local close =
        makeButton(header)

    close.Size =
        UDim2.fromOffset(
            38,
            HEADER_HEIGHT
        )

    close.Position =
        UDim2.new(
            1,
            -40,
            0,
            0
        )

    local closeGlyph =
        label(
            close,
            "×",
            26,
            Enum.Font.Gotham,
            COLORS.Muted
        )

    closeGlyph.Size =
        UDim2.fromScale(1, 1)

    closeGlyph.TextXAlignment =
        Enum.TextXAlignment.Center

    close.MouseEnter:Connect(function()
        tween(
            closeGlyph,
            0.12,
            {
                TextColor3 = COLORS.Text
            }
        )
    end)

    close.MouseLeave:Connect(function()
        tween(
            closeGlyph,
            0.12,
            {
                TextColor3 = COLORS.Muted
            }
        )
    end)

    minimize.MouseEnter:Connect(function()
        tween(
            minGlyph,
            0.12,
            {
                TextColor3 = COLORS.Text
            }
        )
    end)

    minimize.MouseLeave:Connect(function()
        tween(
            minGlyph,
            0.12,
            {
                TextColor3 = COLORS.Muted
            }
        )
    end)

    close.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    minimize.MouseButton1Click:Connect(function()
        self.Minimized =
            not self.Minimized

        if self.Minimized then
            tween(
                main,
                0.18,
                {
                    Size =
                        UDim2.fromOffset(
                            self.Width,
                            HEADER_HEIGHT
                        )
                }
            )

            tween(
                shadow,
                0.18,
                {
                    Size =
                        UDim2.fromOffset(
                            self.Width + 12,
                            HEADER_HEIGHT + 12
                        )
                }
            )
        else
            tween(
                main,
                0.18,
                {
                    Size =
                        UDim2.fromOffset(
                            self.Width,
                            self.Height
                        )
                }
            )

            tween(
                shadow,
                0.18,
                {
                    Size =
                        UDim2.fromOffset(
                            self.Width + 12,
                            self.Height + 12
                        )
                }
            )
        end
    end)

    --==========================================================
    -- DRAGGING
    --==========================================================

    local dragging = false
    local dragStart
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType ==
            Enum.UserInputType.MouseButton1 then

            dragging = true

            dragStart =
                input.Position

            startPosition =
                main.Position

            input.Changed:Connect(function()
                if input.UserInputState ==
                    Enum.UserInputState.End then

                    dragging = false
                end
            end)
        end
    end)

    table.insert(
        self.Connections,

        UserInputService.InputChanged:Connect(
            function(input)
                if not dragging then
                    return
                end

                if input.UserInputType ==
                    Enum.UserInputType.MouseMovement then

                    local delta =
                        input.Position -
                        dragStart

                    main.Position =
                        UDim2.new(
                            startPosition.X.Scale,
                            startPosition.X.Offset + delta.X,

                            startPosition.Y.Scale,
                            startPosition.Y.Offset + delta.Y
                        )

                    shadow.Position =
                        main.Position
                end
            end
        )
    )

    --==========================================================
    -- BODY
    --==========================================================

    local BODY_HEIGHT =
        self.Height -
        HEADER_HEIGHT

    local RAIL_WIDTH = 54
    local NAV_WIDTH = 138

    --==========================================================
    -- RAIL
    --==========================================================

    local rail =
        Instance.new("Frame")

    rail.Name = "Rail"

    rail.Position =
        UDim2.fromOffset(
            0,
            HEADER_HEIGHT
        )

    rail.Size =
        UDim2.fromOffset(
            RAIL_WIDTH,
            BODY_HEIGHT
        )

    rail.BackgroundColor3 =
        COLORS.SidebarDark

    rail.BorderSizePixel = 0

    rail.Parent = main

    self.Rail = rail

    local railDivider =
        Instance.new("Frame")

    railDivider.Position =
        UDim2.new(1, -1, 0, 0)

    railDivider.Size =
        UDim2.new(0, 1, 1, 0)

    railDivider.BackgroundColor3 =
        COLORS.Divider

    railDivider.BorderSizePixel = 0

    railDivider.Parent = rail

    local logo =
        label(
            rail,
            options.Logo or "A",
            22,
            Enum.Font.GothamBold,
            COLORS.Text
        )

    logo.Size =
        UDim2.new(1, 0, 0, 44)

    logo.Position =
        UDim2.fromOffset(0, 5)

    logo.TextXAlignment =
        Enum.TextXAlignment.Center

    local railTabs =
        Instance.new("ScrollingFrame")

    railTabs.Name = "RailTabs"

    railTabs.Position =
        UDim2.fromOffset(0, 56)

    railTabs.Size =
        UDim2.new(
            1,
            0,
            1,
            -64
        )

    railTabs.BackgroundTransparency = 1
    railTabs.BorderSizePixel = 0

    railTabs.ScrollBarThickness = 0

    railTabs.ScrollingDirection =
        Enum.ScrollingDirection.Y

    railTabs.CanvasSize =
        UDim2.fromOffset(0, 0)

    railTabs.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    railTabs.Parent = rail

    local railLayout =
        Instance.new("UIListLayout")

    railLayout.Padding =
        UDim.new(0, 6)

    railLayout.HorizontalAlignment =
        Enum.HorizontalAlignment.Center

    railLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    railLayout.Parent =
        railTabs

    self.RailTabs = railTabs

    --==========================================================
    -- NAVIGATION
    --==========================================================

    local navigation =
        Instance.new("Frame")

    navigation.Name =
        "Navigation"

    navigation.Position =
        UDim2.fromOffset(
            RAIL_WIDTH,
            HEADER_HEIGHT
        )

    navigation.Size =
        UDim2.fromOffset(
            NAV_WIDTH,
            BODY_HEIGHT
        )

    navigation.BackgroundColor3 =
        Color3.fromRGB(
            14,
            16,
            18
        )

    navigation.BorderSizePixel = 0
    navigation.Parent = main

    self.Navigation =
        navigation

    local navDivider =
        Instance.new("Frame")

    navDivider.Position =
        UDim2.new(1, -1, 0, 0)

    navDivider.Size =
        UDim2.new(0, 1, 1, 0)

    navDivider.BackgroundColor3 =
        COLORS.Divider

    navDivider.BorderSizePixel = 0
    navDivider.Parent = navigation

    -- ScrollingFrame instead of regular Frame
    -- so every tab remains accessible.

    local navList =
        Instance.new("ScrollingFrame")

    navList.Name = "TabList"

    navList.Position =
        UDim2.fromOffset(
            10,
            14
        )

    navList.Size =
        UDim2.new(
            1,
            -20,
            1,
            -28
        )

    navList.BackgroundTransparency = 1
    navList.BorderSizePixel = 0

    navList.ScrollBarThickness = 0

    navList.ScrollingDirection =
        Enum.ScrollingDirection.Y

    navList.CanvasSize =
        UDim2.fromOffset(0, 0)

    navList.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    navList.Parent =
        navigation

    local navLayout =
        Instance.new("UIListLayout")

    navLayout.Padding =
        UDim.new(0, 4)

    navLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    navLayout.Parent =
        navList

    self.NavList =
        navList

    --==========================================================
    -- CONTENT
    --==========================================================

    local content =
        Instance.new("Frame")

    content.Name = "Content"

    content.Position =
        UDim2.fromOffset(
            RAIL_WIDTH +
            NAV_WIDTH,
            HEADER_HEIGHT
        )

    content.Size =
        UDim2.new(
            1,
            -(RAIL_WIDTH + NAV_WIDTH),
            1,
            -HEADER_HEIGHT
        )

    content.BackgroundColor3 =
        COLORS.Background

    content.BorderSizePixel = 0

    content.Parent = main

    self.Content =
        content

    local pageTitle =
        label(
            content,
            "",
            21,
            Enum.Font.GothamMedium,
            COLORS.Text
        )

    pageTitle.Position =
        UDim2.fromOffset(
            20,
            14
        )

    pageTitle.Size =
        UDim2.new(
            1,
            -40,
            0,
            28
        )

    self.PageTitle =
        pageTitle

    --==========================================================
    -- UI TOGGLE KEY
    --==========================================================

    if options.ToggleKey then
        self.ToggleKey =
            options.ToggleKey

        table.insert(
            self.Connections,

            UserInputService.InputBegan:Connect(
                function(input, processed)
                    if processed then
                        return
                    end

                    if input.KeyCode ==
                        self.ToggleKey then

                        gui.Enabled =
                            not gui.Enabled
                    end
                end
            )
        )
    end

    return self
end

--==============================================================
-- TAB
--==============================================================

function Aether:CreateTab(options)
    options =
        type(options) == "string"
        and {
            Name = options
        }
        or (
            options or {}
        )

    local tab = {}

    tab.Library = self

    tab.Name =
        options.Name
        or (
            "Tab "
            .. tostring(#self.Tabs + 1)
        )

    -- ASCII-safe icon by default.
    tab.Icon =
        options.Icon
        or ""

    tab.Sections = {}

    tab.Order =
        #self.Tabs + 1

    --==========================================================
    -- NAV BUTTON
    --==========================================================

    local navButton =
        makeButton(self.NavList)

    navButton.Size =
        UDim2.new(
            1,
            0,
            0,
            40
        )

    navButton.LayoutOrder =
        tab.Order

    corner(navButton, 5)

    local navAccent =
        Instance.new("Frame")

    navAccent.Size =
        UDim2.new(
            0,
            2,
            1,
            -12
        )

    navAccent.Position =
        UDim2.fromOffset(
            0,
            6
        )

    navAccent.BackgroundColor3 =
        COLORS.Accent

    navAccent.BorderSizePixel = 0
    navAccent.Visible = false

    navAccent.Parent =
        navButton

    corner(navAccent, 1)

    local navIcon =
        label(
            navButton,
            tab.Icon ~= ""
                and tab.Icon
                or "•",
            13,
            Enum.Font.GothamMedium,
            COLORS.Muted
        )

    navIcon.Size =
        UDim2.fromOffset(
            20,
            40
        )

    navIcon.Position =
        UDim2.fromOffset(
            10,
            0
        )

    navIcon.TextXAlignment =
        Enum.TextXAlignment.Center

    local navText =
        label(
            navButton,
            tab.Name,
            13,
            Enum.Font.Gotham,
            COLORS.Muted
        )

    navText.Position =
        UDim2.fromOffset(
            36,
            0
        )

    navText.Size =
        UDim2.new(
            1,
            -42,
            1,
            0
        )

    --==========================================================
    -- RAIL BUTTON
    --==========================================================

    local railButton =
        makeButton(self.RailTabs)

    railButton.Size =
        UDim2.fromOffset(
            40,
            40
        )

    railButton.LayoutOrder =
        tab.Order

    corner(railButton, 5)

    local railIcon =
        label(
            railButton,
            tab.Icon ~= ""
                and tab.Icon
                or "•",
            13,
            Enum.Font.GothamMedium,
            COLORS.Muted
        )

    railIcon.Size =
        UDim2.fromScale(
            1,
            1
        )

    railIcon.TextXAlignment =
        Enum.TextXAlignment.Center

    --==========================================================
    -- PAGE
    --==========================================================

    local page =
        Instance.new("ScrollingFrame")

    page.Name =
        tab.Name:gsub("%W", "")
        .. "Page"

    page.Position =
        UDim2.fromOffset(
            16,
            50
        )

    page.Size =
        UDim2.new(
            1,
            -32,
            1,
            -60
        )

    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0

    page.ScrollBarThickness = 2

    page.ScrollBarImageColor3 =
        COLORS.Border

    page.ScrollBarImageTransparency =
        0

    page.CanvasSize =
        UDim2.fromOffset(0, 0)

    page.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    page.ScrollingDirection =
        Enum.ScrollingDirection.Y

    page.Visible = false

    page.Parent =
        self.Content

    padding(
        page,
        4,
        4,
        4,
        14
    )

    local pageLayout =
        Instance.new("UIListLayout")

    pageLayout.Padding =
        UDim.new(0, 12)

    pageLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    pageLayout.Parent =
        page

    tab.Page = page
    tab.NavButton = navButton
    tab.RailButton = railButton
    tab.NavAccent = navAccent
    tab.NavText = navText
    tab.NavIcon = navIcon
    tab.RailIcon = railIcon

    --==========================================================
    -- SELECT
    --==========================================================

    local function select()
        for _, other in ipairs(self.Tabs) do
            local active =
                other == tab

            other.Page.Visible =
                active

            other.NavAccent.Visible =
                active

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

        self.ActiveTab =
            tab

        self.PageTitle.Text =
            tab.Name
    end

    --==========================================================
    -- NAV HOVER
    --==========================================================

    navButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(
                navButton,
                0.12,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            20,
                            22,
                            24
                        )
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
                        Color3.new(
                            0,
                            0,
                            0
                        )
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
                        Color3.fromRGB(
                            19,
                            21,
                            23
                        )
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

    table.insert(
        self.Tabs,
        tab
    )

    -- Select first tab only.
    if not self.ActiveTab then
        task.defer(select)
    end

    --==========================================================
    -- SECTION
    --==========================================================

    function tab:CreateSection(
        titleText,
        sectionOptions
    )
        sectionOptions =
            sectionOptions or {}

        local section = {}

        section.Name =
            titleText or "SECTION"

        section.Controls = {}

        local container =
            Instance.new("Frame")

        container.Name =
            "Section"

        if sectionOptions.Filled == false then
            container.BackgroundTransparency = 1
        else
            container.BackgroundColor3 =
                COLORS.Panel
        end

        container.BorderSizePixel = 0

        container.Size =
            UDim2.new(
                1,
                0,
                0,
                0
            )

        container.AutomaticSize =
            Enum.AutomaticSize.Y

        container.LayoutOrder =
            #tab.Sections + 1

        container.Parent =
            page

        if sectionOptions.Filled ~= false then
            corner(container, 5)
            stroke(
                container,
                COLORS.Divider,
                1
            )
        end

        padding(
            container,
            14,
            14,
            10,
            10
        )

        local heading =
            label(
                container,
                string.upper(section.Name),
                12,
                Enum.Font.Gotham,
                COLORS.Muted
            )

        heading.Size =
            UDim2.new(
                1,
                0,
                0,
                20
            )

        local divider =
            Instance.new("Frame")

        divider.Position =
            UDim2.fromOffset(
                0,
                28
            )

        divider.Size =
            UDim2.new(
                1,
                0,
                0,
                1
            )

        divider.BackgroundColor3 =
            COLORS.Divider

        divider.BorderSizePixel = 0

        divider.Parent =
            container

        local items =
            Instance.new("Frame")

        items.Position =
            UDim2.fromOffset(
                0,
                38
            )

        items.Size =
            UDim2.new(
                1,
                0,
                0,
                0
            )

        items.AutomaticSize =
            Enum.AutomaticSize.Y

        items.BackgroundTransparency = 1

        items.Parent =
            container

        local itemsLayout =
            Instance.new("UIListLayout")

        itemsLayout.Padding =
            UDim.new(0, 1)

        itemsLayout.SortOrder =
            Enum.SortOrder.LayoutOrder

        itemsLayout.Parent =
            items

        section.Container =
            container

        section.Items =
            items

        section.Layout =
            itemsLayout

        --======================================================
        -- ROW
        --======================================================

        local function rowBase(height)
            local row =
                Instance.new("Frame")

            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0

            row.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    height or 44
                )

            row.Parent =
                items

            return row
        end

        --======================================================
        -- TOGGLE
        --======================================================

        function section:CreateToggle(opts)
            opts = opts or {}

            local row =
                rowBase(44)

            local textLabel =
                label(
                    row,
                    opts.Name or "Toggle",
                    14,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            textLabel.Size =
                UDim2.new(
                    1,
                    -70,
                    1,
                    0
                )

            local toggle =
                Instance.new("Frame")

            toggle.Size =
                UDim2.fromOffset(
                    38,
                    22
                )

            toggle.Position =
                UDim2.new(
                    1,
                    -38,
                    0.5,
                    -11
                )

            toggle.BackgroundColor3 =
                Color3.fromRGB(
                    42,
                    45,
                    49
                )

            toggle.BorderSizePixel = 0
            toggle.Parent = row

            corner(
                toggle,
                11
            )

            local knob =
                Instance.new("Frame")

            knob.Size =
                UDim2.fromOffset(
                    16,
                    16
                )

            knob.Position =
                UDim2.fromOffset(
                    3,
                    3
                )

            knob.BackgroundColor3 =
                Color3.fromRGB(
                    236,
                    237,
                    239
                )

            knob.BorderSizePixel = 0

            knob.Parent =
                toggle

            corner(
                knob,
                8
            )

            local hit =
                makeButton(row)

            hit.Size =
                UDim2.fromOffset(
                    58,
                    40
                )

            hit.Position =
                UDim2.new(
                    1,
                    -58,
                    0.5,
                    -20
                )

            local state =
                opts.CurrentValue == true

            local function set(value, fire)
                state =
                    value == true

                tween(
                    toggle,
                    0.13,
                    {
                        BackgroundColor3 =
                            state
                            and COLORS.Accent
                            or Color3.fromRGB(
                                42,
                                45,
                                49
                            )
                    }
                )

                tween(
                    knob,
                    0.13,
                    {
                        Position =
                            state
                            and UDim2.fromOffset(
                                19,
                                3
                            )
                            or UDim2.fromOffset(
                                3,
                                3
                            )
                    }
                )

                if fire ~= false
                    and opts.Callback then

                    opts.Callback(state)
                end
            end

            set(
                state,
                false
            )

            hit.MouseButton1Click:Connect(
                function()
                    set(
                        not state,
                        true
                    )
                end
            )

            return {
                Set = function(_, value)
                    set(value, true)
                end,

                Get = function()
                    return state
                end,

                Instance = row,
            }
        end

        --======================================================
        -- BUTTON
        --======================================================

        function section:CreateButton(opts)
            opts = opts or {}

            local row =
                rowBase(44)

            local name =
                opts.Name or "Button"

            local actionText =
                opts.ButtonText or "Action"

            local textLabel =
                label(
                    row,
                    name,
                    14,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            textLabel.Size =
                UDim2.new(
                    1,
                    -120,
                    1,
                    0
                )

            local button =
                makeButton(row)

            button.AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                )

            button.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            local width =
                math.clamp(
                    getTextWidth(
                        actionText,
                        Enum.Font.Gotham,
                        13
                    ) + 24,
                    68,
                    130
                )

            button.Size =
                UDim2.fromOffset(
                    width,
                    30
                )

            button.BackgroundColor3 =
                COLORS.Control

            button.BorderSizePixel = 0

            corner(
                button,
                4
            )

            stroke(
                button,
                COLORS.Border,
                1
            )

            local buttonText =
                label(
                    button,
                    actionText,
                    13,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            buttonText.Size =
                UDim2.fromScale(
                    1,
                    1
                )

            buttonText.TextXAlignment =
                Enum.TextXAlignment.Center

            button.MouseEnter:Connect(
                function()
                    tween(
                        button,
                        0.12,
                        {
                            BackgroundColor3 =
                                Color3.fromRGB(
                                    28,
                                    31,
                                    35
                                )
                        }
                    )
                end
            )

            button.MouseLeave:Connect(
                function()
                    tween(
                        button,
                        0.12,
                        {
                            BackgroundColor3 =
                                COLORS.Control
                        }
                    )
                end
            )

            button.MouseButton1Click:Connect(
                function()
                    if opts.Callback then
                        opts.Callback()
                    end
                end
            )

            return {
                Fire = function()
                    if opts.Callback then
                        opts.Callback()
                    end
                end,

                Instance = row,
            }
        end

        --======================================================
        -- DROPDOWN
        --======================================================

        function section:CreateDropdown(opts)
            opts = opts or {}

            local row =
                rowBase(50)

            local textLabel =
                label(
                    row,
                    opts.Name or "Dropdown",
                    14,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            textLabel.Size =
                UDim2.new(
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

            local dd =
                makeButton(row)

            dd.AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                )

            dd.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            dd.Size =
                UDim2.fromOffset(
                    math.min(
                        opts.Width or 190,
                        210
                    ),
                    32
                )

            dd.BackgroundColor3 =
                COLORS.Control

            corner(
                dd,
                4
            )

            stroke(
                dd,
                COLORS.Border,
                1
            )

            local valueText =
                label(
                    dd,
                    tostring(selected),
                    13,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            valueText.Position =
                UDim2.fromOffset(
                    11,
                    0
                )

            valueText.Size =
                UDim2.new(
                    1,
                    -38,
                    1,
                    0
                )

            valueText.TextTruncate =
                Enum.TextTruncate.AtEnd

            -- ASCII-safe arrow.
            local arrow =
                label(
                    dd,
                    "v",
                    11,
                    Enum.Font.GothamBold,
                    COLORS.Muted
                )

            arrow.AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                )

            arrow.Position =
                UDim2.new(
                    1,
                    -10,
                    0.5,
                    0
                )

            arrow.Size =
                UDim2.fromOffset(
                    16,
                    18
                )

            arrow.TextXAlignment =
                Enum.TextXAlignment.Center

            --==================================================
            -- DROPDOWN POPUP
            --==================================================

            local dropdownGui =
                Instance.new("Frame")

            dropdownGui.Name =
                "AetherDropdown"

            dropdownGui.BackgroundTransparency =
                1

            dropdownGui.Size =
                UDim2.fromScale(
                    1,
                    1
                )

            dropdownGui.Visible =
                false

            dropdownGui.ZIndex =
                1000

            dropdownGui.Parent =
                self.Library.Gui

            local popup =
                Instance.new("ScrollingFrame")

            popup.BackgroundColor3 =
                COLORS.Control

            popup.BorderSizePixel = 0

            popup.ZIndex =
                1000

            popup.ScrollBarThickness =
                2

            popup.ScrollBarImageColor3 =
                COLORS.Border

            popup.ScrollingDirection =
                Enum.ScrollingDirection.Y

            popup.Parent =
                dropdownGui

            corner(
                popup,
                4
            )

            stroke(
                popup,
                COLORS.Border,
                1
            )

            padding(
                popup,
                4,
                4,
                4,
                4
            )

            local popupLayout =
                Instance.new("UIListLayout")

            popupLayout.Padding =
                UDim.new(0, 2)

            popupLayout.Parent =
                popup

            local open = false

            local function close()
                open = false
                dropdownGui.Visible = false
            end

            local function rebuild()
                for _, child in ipairs(
                    popup:GetChildren()
                ) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                local optionsList =
                    opts.Options or {}

                local itemCount =
                    #optionsList

                local visibleCount =
                    math.min(
                        itemCount,
                        6
                    )

                popup.Size =
                    UDim2.fromOffset(
                        dd.AbsoluteSize.X,
                        visibleCount * 30 + 10
                    )

                for index, option in ipairs(
                    optionsList
                ) do
                    local item =
                        makeButton(popup)

                    item.Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            30
                        )

                    item.LayoutOrder =
                        index

                    item.ZIndex =
                        1001

                    corner(
                        item,
                        3
                    )

                    local itemText =
                        label(
                            item,
                            tostring(option),
                            13,
                            Enum.Font.Gotham,
                            COLORS.Text
                        )

                    itemText.Position =
                        UDim2.fromOffset(
                            8,
                            0
                        )

                    itemText.Size =
                        UDim2.new(
                            1,
                            -16,
                            1,
                            0
                        )

                    itemText.ZIndex =
                        1002

                    item.MouseEnter:Connect(
                        function()
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
                        end
                    )

                    item.MouseLeave:Connect(
                        function()
                            tween(
                                item,
                                0.1,
                                {
                                    BackgroundTransparency = 1
                                }
                            )
                        end
                    )

                    item.MouseButton1Click:Connect(
                        function()
                            selected =
                                option

                            valueText.Text =
                                tostring(
                                    option
                                )

                            close()

                            if opts.Callback then
                                opts.Callback(
                                    option
                                )
                            end
                        end
                    )
                end

                popup.CanvasSize =
                    UDim2.fromOffset(
                        0,
                        itemCount * 32 + 8
                    )
            end

            local function show()
                close()

                rebuild()

                local position =
                    dd.AbsolutePosition

                local size =
                    dd.AbsoluteSize

                local viewport =
                    viewportSize()

                local popupHeight =
                    popup.Size.Y.Offset

                local x =
                    position.X

                local y =
                    position.Y +
                    size.Y +
                    5

                if
                    y + popupHeight
                    >
                    viewport.Y - 8
                then

                    y =
                        position.Y -
                        popupHeight -
                        5
                end

                x =
                    math.clamp(
                        x,
                        8,
                        math.max(
                            8,
                            viewport.X -
                            size.X -
                            8
                        )
                    )

                popup.Position =
                    UDim2.fromOffset(
                        x,
                        y
                    )

                dropdownGui.Visible =
                    true

                open = true
            end

            dd.MouseButton1Click:Connect(
                function()
                    if open then
                        close()
                    else
                        show()
                    end
                end
            )

            table.insert(
                self.Library.Connections,

                UserInputService.InputBegan:Connect(
                    function(input)
                        if not open then
                            return
                        end

                        if input.UserInputType ~=
                            Enum.UserInputType.MouseButton1 then
                            return
                        end

                        local mouse =
                            input.Position

                        local popupPosition =
                            popup.AbsolutePosition

                        local popupSize =
                            popup.AbsoluteSize

                        local ddPosition =
                            dd.AbsolutePosition

                        local ddSize =
                            dd.AbsoluteSize

                        local insidePopup =
                            mouse.X >= popupPosition.X
                            and mouse.X <=
                                popupPosition.X +
                                popupSize.X
                            and mouse.Y >=
                                popupPosition.Y
                            and mouse.Y <=
                                popupPosition.Y +
                                popupSize.Y

                        local insideDropdown =
                            mouse.X >= ddPosition.X
                            and mouse.X <=
                                ddPosition.X +
                                ddSize.X
                            and mouse.Y >=
                                ddPosition.Y
                            and mouse.Y <=
                                ddPosition.Y +
                                ddSize.Y

                        if
                            not insidePopup
                            and
                            not insideDropdown
                        then
                            close()
                        end
                    end
                )
            )

            return {
                Set = function(_, value)
                    selected =
                        value

                    valueText.Text =
                        tostring(
                            value
                        )

                    if opts.Callback then
                        opts.Callback(
                            value
                        )
                    end
                end,

                Get = function()
                    return selected
                end,

                Close = close,

                Instance = row,
            }
        end

        --======================================================
        -- SLIDER
        --======================================================

        function section:CreateSlider(opts)
            opts = opts or {}

            local row =
                rowBase(58)

            local textLabel =
                label(
                    row,
                    opts.Name or "Slider",
                    14,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            textLabel.Size =
                UDim2.new(
                    0,
                    150,
                    0,
                    22
                )

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

            local valueLabel =
                label(
                    row,
                    tostring(value),
                    12,
                    Enum.Font.Gotham,
                    COLORS.Muted
                )

            valueLabel.AnchorPoint =
                Vector2.new(1, 0)

            valueLabel.Position =
                UDim2.new(
                    1,
                    0,
                    0,
                    0
                )

            valueLabel.Size =
                UDim2.fromOffset(
                    70,
                    22
                )

            valueLabel.TextXAlignment =
                Enum.TextXAlignment.Right

            --==================================================
            -- TRACK
            --==================================================

            local track =
                Instance.new("Frame")

            track.Position =
                UDim2.new(
                    0,
                    0,
                    0,
                    34
                )

            track.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    4
                )

            track.BackgroundColor3 =
                Color3.fromRGB(
                    43,
                    46,
                    50
                )

            track.BorderSizePixel = 0

            track.Parent =
                row

            corner(
                track,
                2
            )

            local fill =
                Instance.new("Frame")

            fill.Size =
                UDim2.fromScale(
                    0,
                    1
                )

            fill.BackgroundColor3 =
                COLORS.Accent

            fill.BorderSizePixel = 0

            fill.Parent =
                track

            corner(
                fill,
                2
            )

            local knob =
                Instance.new("Frame")

            knob.AnchorPoint =
                Vector2.new(
                    0.5,
                    0.5
                )

            knob.Size =
                UDim2.fromOffset(
                    12,
                    12
                )

            knob.BackgroundColor3 =
                COLORS.Text

            knob.BorderSizePixel = 0

            knob.Parent =
                track

            corner(
                knob,
                6
            )

            --==================================================
            -- HITBOX
            --==================================================

            local hit =
                Instance.new("TextButton")

            hit.BackgroundTransparency = 1
            hit.BorderSizePixel = 0
            hit.Text = ""

            hit.Position =
                UDim2.new(
                    0,
                    -6,
                    0,
                    22
                )

            hit.Size =
                UDim2.new(
                    1,
                    12,
                    0,
                    26
                )

            hit.ZIndex = 10

            hit.Parent =
                row

            local draggingSlider = false

            local function updateSlider(
                mouseX,
                fire
            )
                local trackStart =
                    track.AbsolutePosition.X

                local trackWidth =
                    track.AbsoluteSize.X

                if trackWidth <= 0 then
                    return
                end

                local alpha =
                    math.clamp(
                        (
                            mouseX -
                            trackStart
                        ) / trackWidth,
                        0,
                        1
                    )

                local newValue =
                    min +
                    (
                        max - min
                    ) * alpha

                if opts.Rounding then
                    local rounding =
                        tonumber(
                            opts.Rounding
                        ) or 1

                    if rounding > 0 then
                        newValue =
                            math.floor(
                                newValue /
                                    rounding
                                + 0.5
                            ) * rounding
                    end
                end

                newValue =
                    math.clamp(
                        newValue,
                        min,
                        max
                    )

                value =
                    newValue

                local finalAlpha =
                    (
                        value - min
                    ) /
                    (
                        max - min
                    )

                valueLabel.Text =
                    tostring(value)

                fill.Size =
                    UDim2.fromScale(
                        finalAlpha,
                        1
                    )

                knob.Position =
                    UDim2.new(
                        finalAlpha,
                        0,
                        0.5,
                        0
                    )

                if fire
                    and opts.Callback then

                    opts.Callback(value)
                end
            end

            hit.InputBegan:Connect(
                function(input)
                    if
                        input.UserInputType ==
                        Enum.UserInputType.MouseButton1
                    then

                        draggingSlider = true

                        updateSlider(
                            input.Position.X,
                            true
                        )
                    end
                end
            )

            table.insert(
                self.Library.Connections,

                UserInputService.InputChanged:Connect(
                    function(input)
                        if not draggingSlider then
                            return
                        end

                        if
                            input.UserInputType ==
                            Enum.UserInputType.MouseMovement
                        then

                            updateSlider(
                                UserInputService:GetMouseLocation().X,
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
                        if
                            input.UserInputType ==
                            Enum.UserInputType.MouseButton1
                        then

                            draggingSlider = false
                        end
                    end
                )
            )

            local function set(
                newValue,
                fire
            )
                newValue =
                    math.clamp(
                        tonumber(newValue)
                            or min,
                        min,
                        max
                    )

                if opts.Rounding then
                    local rounding =
                        tonumber(
                            opts.Rounding
                        ) or 1

                    if rounding > 0 then
                        newValue =
                            math.floor(
                                newValue /
                                    rounding
                                + 0.5
                            ) * rounding
                    end
                end

                newValue =
                    math.clamp(
                        newValue,
                        min,
                        max
                    )

                value =
                    newValue

                local alpha =
                    (
                        value - min
                    ) /
                    (
                        max - min
                    )

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

                if fire
                    and opts.Callback then

                    opts.Callback(value)
                end
            end

            set(
                value,
                false
            )

            return {
                Set = function(_, newValue)
                    set(
                        newValue,
                        true
                    )
                end,

                Get = function()
                    return value
                end,

                Instance = row,
            }
        end

        --======================================================
        -- KEYBIND
        --======================================================

        function section:CreateKeybind(opts)
            opts = opts or {}

            local row =
                rowBase(44)

            local textLabel =
                label(
                    row,
                    opts.Name or "Keybind",
                    14,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            textLabel.Size =
                UDim2.new(
                    1,
                    -108,
                    1,
                    0
                )

            local bind =
                opts.CurrentKeybind
                or opts.CurrentKey
                or opts.Key
                or Enum.KeyCode.RightShift

            local waiting = false

            local chip =
                makeButton(row)

            chip.AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                )

            chip.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            chip.Size =
                UDim2.fromOffset(
                    92,
                    30
                )

            chip.BackgroundColor3 =
                COLORS.Control

            chip.BorderSizePixel = 0

            corner(
                chip,
                4
            )

            stroke(
                chip,
                COLORS.Border,
                1
            )

            -- Keep key text completely ASCII.
            local chipText =
                label(
                    chip,
                    bind.Name,
                    12,
                    Enum.Font.Gotham,
                    COLORS.Text
                )

            chipText.Size =
                UDim2.fromScale(
                    1,
                    1
                )

            chipText.TextXAlignment =
                Enum.TextXAlignment.Center

            chip.MouseEnter:Connect(
                function()
                    tween(
                        chip,
                        0.12,
                        {
                            BackgroundColor3 =
                                Color3.fromRGB(
                                    27,
                                    30,
                                    34
                                )
                        }
                    )
                end
            )

            chip.MouseLeave:Connect(
                function()
                    if not waiting then
                        tween(
                            chip,
                            0.12,
                            {
                                BackgroundColor3 =
                                    COLORS.Control
                            }
                        )
                    end
                end
            )

            chip.MouseButton1Click:Connect(
                function()
                    waiting = true

                    chipText.Text =
                        "Press key..."

                    tween(
                        chip,
                        0.12,
                        {
                            BackgroundColor3 =
                                Color3.fromRGB(
                                    28,
                                    31,
                                    35
                                )
                        }
                    )
                end
            )

            local connection

            connection =
                UserInputService.InputBegan:Connect(
                    function(
                        input,
                        processed
                    )
                        if waiting then
                            if
                                input.UserInputType ==
                                Enum.UserInputType.Keyboard
                            then

                                bind =
                                    input.KeyCode

                                waiting = false

                                chipText.Text =
                                    bind.Name

                                tween(
                                    chip,
                                    0.12,
                                    {
                                        BackgroundColor3 =
                                            COLORS.Control
                                    }
                                )

                                if opts.SetCallback then
                                    opts.SetCallback(
                                        bind
                                    )
                                end

                                return
                            end
                        end

                        if
                            not processed
                            and
                            input.UserInputType ==
                                Enum.UserInputType.Keyboard
                            and
                            input.KeyCode ==
                                bind
                        then

                            if opts.Callback then
                                opts.Callback(
                                    input
                                )
                            end
                        end
                    end
                )

            return {
                Set = function(_, key)
                    if typeof(key) ~=
                        "EnumItem" then
                        return
                    end

                    bind =
                        key

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

        --======================================================
        -- STATUS
        --======================================================

        function section:CreateStatus(opts)
            opts = opts or {}

            local row =
                rowBase(40)

            local active =
                opts.Active == true

            local textLabel =
                label(
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

            local dot =
                Instance.new("Frame")

            dot.Size =
                UDim2.fromOffset(
                    7,
                    7
                )

            dot.AnchorPoint =
                Vector2.new(
                    0,
                    0.5
                )

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

            corner(
                dot,
                4
            )

            local statusText =
                label(
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
                Vector2.new(
                    1,
                    0.5
                )

            statusText.Position =
                UDim2.new(
                    1,
                    0,
                    0.5,
                    0
                )

            statusText.Size =
                UDim2.fromOffset(
                    68,
                    22
                )

            statusText.TextXAlignment =
                Enum.TextXAlignment.Right

            local function set(
                isActive,
                text
            )
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
-- NOTIFY
--==============================================================

function Aether:Notify(options)
    options = options or {}

    local holder =
        self.Gui:FindFirstChild(
            "Notifications"
        )

    if not holder then
        holder =
            Instance.new("Frame")

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

        holder.BackgroundTransparency =
            1

        holder.ZIndex =
            900

        holder.Parent =
            self.Gui

        local list =
            Instance.new("UIListLayout")

        list.VerticalAlignment =
            Enum.VerticalAlignment.Bottom

        list.HorizontalAlignment =
            Enum.HorizontalAlignment.Right

        list.Padding =
            UDim.new(0, 7)

        list.Parent =
            holder
    end

    local notification =
        Instance.new("Frame")

    notification.Size =
        UDim2.fromOffset(
            290,
            62
        )

    notification.BackgroundColor3 =
        COLORS.Panel

    notification.BorderSizePixel = 0

    notification.ZIndex = 901

    notification.Parent =
        holder

    corner(
        notification,
        5
    )

    stroke(
        notification,
        COLORS.Border,
        1
    )

    local title =
        label(
            notification,
            options.Title
            or self.Name,
            13,
            Enum.Font.GothamMedium,
            COLORS.Text
        )

    title.Position =
        UDim2.fromOffset(
            12,
            7
        )

    title.Size =
        UDim2.new(
            1,
            -24,
            0,
            18
        )

    title.ZIndex = 902

    local message =
        label(
            notification,
            options.Content or "",
            12,
            Enum.Font.Gotham,
            COLORS.Muted
        )

    message.Position =
        UDim2.fromOffset(
            12,
            26
        )

    message.Size =
        UDim2.new(
            1,
            -24,
            0,
            27
        )

    message.TextWrapped = true
    message.ZIndex = 902

    local duration =
        tonumber(
            options.Duration
        ) or 3

    task.delay(
        duration,
        function()
            if not notification.Parent then
                return
            end

            tween(
                notification,
                0.18,
                {
                    BackgroundTransparency = 1
                }
            )

            task.wait(0.18)

            if notification.Parent then
                notification:Destroy()
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

    for _, connection in ipairs(
        self.Connections
    ) do
        pcall(
            function()
                connection:Disconnect()
            end
        )
    end

    table.clear(
        self.Connections
    )

    if self.Gui then
        self.Gui:Destroy()
    end
end

--==============================================================
-- COMPATIBILITY
--==============================================================

function Aether:CreateWindow(options)
    return Aether.new(options)
end

return Aether
