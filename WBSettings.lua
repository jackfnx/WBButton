local _, Addon = ...
local Settings = Addon.Settings

-- ======================
-- 初始化配置
-- ======================
function Settings:InitConfig()
    WB_Config = WB_Config or {}
    WB_Config.include = WB_Config.include or {}

    Settings.Config = WB_Config
end

function Settings:CreateConfigUI()
    local configFrame = CreateFrame("Frame", "WB_ConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(800, 600)
    configFrame:SetPoint("CENTER")
    configFrame.backdropInfo = {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 }
    }
    configFrame:ApplyBackdrop()
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    local bg = configFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    -- bg:SetColorTexture(0, 0, 0, 0.75) -- 半透明黑

    local titleBg = configFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT", 8, -8)
    titleBg:SetPoint("TOPRIGHT", -8, -8)
    titleBg:SetHeight(24)
    titleBg:SetColorTexture(0, 0, 0, 0.6)

    local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    -- 标题
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("WBB 设置")

    -- ESC 关闭
    table.insert(UISpecialFrames, "WB_ConfigFrame")

    -- 滚动区域
    local scroll = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -40)
    scroll:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -36, 15)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(780, 1)
    content:SetPoint("TOPLEFT", 4, 0)
    scroll:SetScrollChild(content)

    configFrame:Hide()

    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetToplevel(true)

    configFrame.content = content
    configFrame.nodes = {}

    Settings.ConfigDialog = configFrame
    Settings.TreeData = { Addon.Category:BuildNodeTree() }
end

function Settings:Execute()
    Settings:RefreshTree()
    Settings.ConfigDialog:Show()
end

-- ======================
-- 创建节点
-- ======================
function Settings:CreateNode(parent, node, level, y)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetHeight(24)
    row:SetPoint("TOPLEFT", 10 + level * 15, y)
    row:SetPoint("RIGHT", parent, "RIGHT", -36, 0)

    row:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground", -- 简单纯色
        edgeFile = nil,
        edgeSize = 0,
        insets   = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    local color = (y % 48 > 24) and { 0, 0, 0, 0.2 } or { 0, 0, 0, 0.1 } -- 隔行变色
    row:SetBackdropColor(unpack(color))                                  -- {r,g,b,a}

    local btn = CreateFrame("Button", nil, row)
    btn:SetPoint("TOPLEFT", row, 0, 2)
    btn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    btn:SetHeight(20)

    -- 文本
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("LEFT")

    -- 展开状态
    node.Expanded = node.Expanded or false

    if node.Children and #node.Children > 0 then
        btn.text:SetText((node.Expanded and "- " or "+ ") .. node.Text)
    else
        btn.text:SetText(node.Text)
    end

    -- 点击展开
    btn:SetScript("OnClick", function()
        if node.Children then
            node.Expanded = not node.Expanded
            Settings:RefreshTree()
        end
    end)


    if node.IsManual then
        -- 拖拽区域
        local dropText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
        dropText:SetText("把物品拖到这里")

        -- ======================
        -- 处理拖拽
        -- ======================
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")

        function AddManualItem(itemID)
            local info = Addon:GetItemInfo(itemID)
            local newNode = Addon.Category.NewNode(info.itemName, info.itemID, node.Val)
            table.insert(node.Children, newNode)
            Settings:RefreshTree()
        end

        btn:SetScript("OnReceiveDrag", function()
            local type, itemID, link = GetCursorInfo()

            if type == "item" and itemID then
                AddManualItem(itemID)
            end

            ClearCursor()
        end)

        btn:SetScript("OnMouseUp", function()
            local type, itemID, link = GetCursorInfo()

            if type == "item" and itemID then
                AddManualItem(itemID)
            end

            ClearCursor()
        end)
    else
        -- 加 checkbox
        local check = CreateFrame("CheckButton", nil, btn, "UICheckButtonTemplate")
        check:SetPoint("RIGHT")

        -- 初始化状态
        -- local exp = node.expansionID or node.parentExp
        -- local sub = node.subclassID

        -- if Settings.Config.include[exp] and Settings.Config.include[exp][sub] then
        --     check:SetChecked(true)
        -- end

        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked()

            -- Settings.Config.include[exp] = Settings.Config.include[exp] or {}
            -- Settings.Config.include[exp][sub] = checked
        end)
    end

    return row
end

-- ======================
-- 渲染树（递归）
-- ======================
function Settings:RenderTree(parent, nodes, level, y)
    for _, node in ipairs(nodes) do
        local btn = self:CreateNode(parent, node, level, y)
        table.insert(Settings.ConfigDialog.nodes, btn)

        y = y - 26

        if node.Expanded and node.Children then
            y = self:RenderTree(parent, node.Children, level + 1, y)
        end
    end

    return y
end

-- ======================
-- 刷新树
-- ======================
function Settings:RefreshTree()
    local frame = Settings.ConfigDialog
    local content = Settings.ConfigDialog.content

    for _, node in ipairs(frame.nodes) do
        node:Hide()
    end
    frame.nodes = {}

    local finalY = self:RenderTree(content, self.TreeData, 0, -10)
    content:SetHeight(-finalY + 10)
end

-- ======================
-- 打开命令
-- ======================
SLASH_WBB1 = "/wbb"
SlashCmdList["WBB"] = function()
    local frame = Settings.ConfigDialog
    if frame:IsShown() then
        frame:Hide()
    else
        Settings:Execute()
    end
end
