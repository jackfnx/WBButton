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
        -- edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",     -- 131072
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

    -- 标题
    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("WBB 设置")

    -- ESC 关闭
    table.insert(UISpecialFrames, "WB_ConfigFrame")

    -- Cancel
    local cancel = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    cancel:SetSize(80, 25)
    cancel:SetPoint("BOTTOMRIGHT", -10, 10)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    -- OK
    local ok = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    ok:SetSize(80, 25)
    ok:SetPoint("BOTTOMRIGHT", -10, 10)
    ok:SetPoint("RIGHT", cancel, "LEFT", -10, 0)
    ok:SetText("OK")
    ok:SetScript("OnClick", function()
        configFrame:Hide()
    end)

    -- 滚动区域
    local scroll = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -40)
    scroll:SetPoint("BOTTOMRIGHT", cancel, "TOPRIGHT", -24, 15)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(260, 1)
    scroll:SetScrollChild(content)

    configFrame:Hide()

    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetToplevel(true)

    configFrame.content = content
    configFrame.nodes = {}

    Settings.ConfigDialog = configFrame
end

function Settings:Execute()
    Settings:RefreshTree()
    Settings.ConfigDialog:Show()
end

-- ======================
-- 树数据
-- ======================
Settings.TreeData = {
    {
        text = "材料",
        children = {
            {
                text = "Dragonflight",
                expansionID = 9,
                children = {
                    { text = "草药", classID = 7, subclassID = 9 },
                    { text = "矿石", classID = 7, subclassID = 0 },
                }
            },
            {
                text = "The War Within",
                expansionID = 10,
                children = {
                    { text = "草药", classID = 7, subclassID = 9 },
                    { text = "矿石", classID = 7, subclassID = 0 },
                }
            }
        }
    }
}

-- ======================
-- 创建节点
-- ======================
function Settings:CreateNode(parent, node, level, y)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(260, 20)
    btn:SetPoint("TOPLEFT", 10 + level * 15, y)

    -- 文本
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("LEFT")

    -- 展开状态
    node.expanded = node.expanded or false

    if node.children then
        btn.text:SetText((node.expanded and "- " or "+ ") .. node.text)
    else
        btn.text:SetText(node.text)
    end

    -- 点击展开
    btn:SetScript("OnClick", function()
        if node.children then
            node.expanded = not node.expanded
            Settings:RefreshTree()
        end
    end)

    -- 叶子节点加 checkbox
    if not node.children then
        local check = CreateFrame("CheckButton", nil, btn, "UICheckButtonTemplate")
        check:SetPoint("RIGHT")

        -- 初始化状态
        local exp = node.expansionID or node.parentExp
        local sub = node.subclassID

        if Settings.Config.include[exp] and Settings.Config.include[exp][sub] then
            check:SetChecked(true)
        end

        check:SetScript("OnClick", function(self)
            local checked = self:GetChecked()

            Settings.Config.include[exp] = Settings.Config.include[exp] or {}
            Settings.Config.include[exp][sub] = checked
        end)
    end

    return btn
end

-- ======================
-- 渲染树（递归）
-- ======================
function Settings:RenderTree(parent, nodes, level, y, parentExp)
    for _, node in ipairs(nodes) do
        if node.expansionID then
            parentExp = node.expansionID
        end

        node.parentExp = parentExp

        local btn = self:CreateNode(parent, node, level, y)
        table.insert(Settings.ConfigDialog.nodes, btn)

        y = y - 22

        if node.expanded and node.children then
            y = self:RenderTree(parent, node.children, level + 1, y, parentExp)
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

    local finalY = self:RenderTree(frame.content, self.TreeData, 0, -10)
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
