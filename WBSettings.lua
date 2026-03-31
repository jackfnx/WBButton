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

Settings.MODE = {
    NONE = 1, --不存入
    ALL = 2,  --全部存入
    ONE = 3,  --集中角色
}

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
    btn:SetSize(120, 20)

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

        local function AddManualItem(itemID)
            local info = Addon:GetItemInfo(itemID)
            local newNode = Addon.Category.NewNode(info.itemName, info.itemID, node.Val)
            print(3, newNode.Text, newNode.Val)
            table.insert(node.Children, newNode)
            Settings:RefreshTree()
        end

        row:SetScript("OnReceiveDrag", function()
            local type, itemID, link = GetCursorInfo()
            print(1, type, itemID, link)

            if type == "item" and itemID then
                AddManualItem(itemID)
            end

            ClearCursor()
        end)

        row:SetScript("OnMouseUp", function()
            local type, itemID, link = GetCursorInfo()
            print(2, type, itemID, link)

            if type == "item" and itemID then
                AddManualItem(itemID)
            end

            ClearCursor()
        end)
    else
        local function CreateRadio(radio_parent, text, val, prev)
            local r = CreateFrame("CheckButton", nil, radio_parent, "UICheckButtonTemplate")
            r.text:SetText(text)
            r.text:ClearAllPoints()
            if prev == nil then
                r.text:SetPoint("RIGHT", radio_parent, "RIGHT", -10, 0)
            else
                r.text:SetPoint("RIGHT", prev, "LEFT", -5, 0)
            end

            r:ClearAllPoints()
            r:SetPoint("RIGHT", r.text, "LEFT", -1, 0)
            r.val = val

            return r
        end

        local function radiosSelect(radios, currVal)
            for r_val in pairs(radios) do
                radios[r_val]:SetChecked(r_val == currVal)
            end
        end

        local function CreateRadios(radio_parent, rs, OnSelectedChanged)
            local radios = {}
            local prev = nil
            for _, info in ipairs(rs) do
                local r = CreateRadio(radio_parent, info[1], info[2], prev)
                radios[r.val] = r
                prev = r
            end

            local function Select(v)
                radiosSelect(radios, v)
                OnSelectedChanged(v)
            end

            for r_val in pairs(radios) do
                radios[r_val]:SetScript("OnClick", function() Select(r_val) end)
            end

            return radios
        end

        local function OnSelectedChanged(val)
            if (val == self.MODE.ONE) then
                row.dropdown:Show()
                local to = row.dropdown.selected
                WBB_Config[node.Val] = { val = val, to = to }
            elseif (val == self.MODE.ALL) then
                row.dropdown:Hide()
                WBB_Config[node.Val] = { val = val }
            else
                row.dropdown:Hide()
                WBB_Config[node.Val] = nil
            end
        end

        local radios = CreateRadios(row,
            { { "不存入", self.MODE.NONE }, { "全存入", self.MODE.ALL }, { "集中到", self.MODE.ONE }, },
            OnSelectedChanged
        )

        row.dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        row.dropdown:SetPoint("RIGHT", radios[self.MODE.ONE], "LEFT", -2, 0)

        local function dropboxSelectItem(name)
            UIDropDownMenu_SetSelectedName(row.dropdown, name)
            row.dropdown.selected = name
            if row.dropdown.onSelectedChanged then
                row.dropdown:onSelectedChanged(name)
            end
        end

        UIDropDownMenu_SetWidth(row.dropdown, 120)
        UIDropDownMenu_Initialize(row.dropdown, function(self_, level_)
            local chars = {}
            for name in pairs(WBB_Characters) do
                chars[WBB_Characters[name] + 1] = name
            end
            for _, name in ipairs(chars) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = name
                info.value = name
                info.func = function() dropboxSelectItem(name) end
                UIDropDownMenu_AddButton(info)
            end
        end)


        local function onDropdownSelectedChanged(self_, name)
            if radios[self.MODE.ONE]:GetChecked() then
                WBB_Config[node.Val] = { val = self.MODE.ONE, to = name }
            end
        end

        row.dropdown.onSelectedChanged = onDropdownSelectedChanged

        local curr = WBB_Config[node.Val] and WBB_Config[node.Val] or { val = self.MODE.NONE }
        local to = curr.to or Addon:GetCurrentCharacter()
        dropboxSelectItem(to)
        radiosSelect(radios, curr.val)
        OnSelectedChanged(curr.val)
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
