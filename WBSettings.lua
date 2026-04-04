local _, Addon = ...
local Settings = Addon.Settings

-- ======================
-- 初始化配置
-- ======================
function Settings:InitConfig()
    WBB_Config = WBB_Config or {}

    Settings.Config = WBB_Config
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
    Addon:TreeDataInit()
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
    btn:SetPoint("LEFT", row, 0, 0)
    btn:SetSize(120, 20)

    -- 展开状态
    node.Expanded = node.Expanded or false

    -- +/-
    local toggle = btn:CreateTexture(nil, "ARTWORK")
    toggle:SetSize(12, 12)
    toggle:SetPoint("LEFT", btn, "LEFT", 0, 0)

    if not node.Children or #node.Children == 0 then
        toggle:SetTexture(nil)
    elseif node.Expanded then
        toggle:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    else
        toggle:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    end

    -- 图标
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", toggle, "RIGHT", 0, 0)

    if node.Icon then
        icon:SetTexture(node.Icon)
    else
        icon:SetTexture(nil)
    end

    -- 文本
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("LEFT", icon, "RIGHT", 0, 0)
    btn.text:SetText(node.Text)

    -- 点击展开
    btn:SetScript("OnClick", function()
        if node.Children then
            node.Expanded = not node.Expanded
            Settings:RefreshTree()
        end
    end)

    if node.NodeType == Addon.NODE.ANCHOR then
        local drop = CreateFrame("Frame", nil, row, "BackdropTemplate")
        drop:SetPoint("TOPLEFT", row, "TOP", 0, 0)
        drop:SetPoint("BOTTOMRIGHT", 0, "BOTTOMRIGHT", 0, 0)

        drop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8"
        })
        drop:SetBackdropColor(0, 0, 0, 0.9)

        -- 拖拽区域
        local dropText = drop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        dropText:SetPoint("CENTER", drop, "CENTER", 0, 0)
        dropText:SetText("把物品拖到这里")

        -- ======================
        -- 处理拖拽
        -- ======================
        drop:EnableMouse(true)
        drop:RegisterForDrag("LeftButton")

        local function AddItem(itemID)
            -- local info = Addon:GetItemInfo(itemID)
            WBB_Config[node.Val] = WBB_Config[node.Val] or { curr = 0 }
            WBB_Config[node.Val].curr = WBB_Config[node.Val].curr or 0
            WBB_Config[node.Val][itemID] = WBB_Config[node.Val].curr
            WBB_Config[node.Val].curr = WBB_Config[node.Val].curr + 1
            Addon.TreeData = { Addon.Core:BuildNodeTree(nil, nil, node.Val) }
            Settings:RefreshTree()
        end

        drop:SetScript("OnReceiveDrag", function()
            local type, itemID, link = GetCursorInfo()

            if type == "item" and itemID then
                AddItem(itemID)
            end

            ClearCursor()
        end)

        drop:SetScript("OnMouseUp", function()
            local type, itemID, link = GetCursorInfo()

            if type == "item" and itemID then
                AddItem(itemID)
            end

            ClearCursor()
        end)
    elseif node.NodeType == Addon.NODE.ACTIVE or node.NodeType == Addon.NODE.ITEM then
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

        local function CreateRadios(radio_parent, rs, prev, OnSelectedChanged)
            local radios = {}
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
            if (val == Addon.SAVE2.ONE) then
                row.dropdown:Show()
                local to = row.dropdown.selected
                WBB_Config[node.Val] = { val = val, to = to }
            elseif (val == Addon.SAVE2.ALL) then
                row.dropdown:Hide()
                WBB_Config[node.Val] = { val = val }
            else
                row.dropdown:Hide()
                WBB_Config[node.Val] = nil
            end
        end

        local radios = {}
        if node.NodeType == Addon.NODE.ITEM then
            local btnDel = CreateFrame("Button", nil, row)
            btnDel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            btnDel:SetSize(16, 16)
            btnDel:SetNormalTexture("Interface\\Buttons\\UI-StopButton")

            btnDel:SetScript("OnClick", function()
                local pNodeVal = node:SelfDelete()
                Addon.TreeData = { Addon.Core:BuildNodeTree(nil, nil, pNodeVal) }
                Settings:RefreshTree()
            end)

            radios = CreateRadios(row,
                { { "全存入", Addon.SAVE2.ALL }, { "集中到", Addon.SAVE2.ONE } },
                btnDel,
                OnSelectedChanged
            )
        elseif node.NodeType == Addon.NODE.ACTIVE then
            radios = CreateRadios(row,
                { { "不存入", Addon.SAVE2.NONE }, { "全存入", Addon.SAVE2.ALL }, { "集中到", Addon.SAVE2.ONE } },
                nil,
                OnSelectedChanged
            )
        end

        row.dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
        row.dropdown:SetPoint("RIGHT", radios[Addon.SAVE2.ONE], "LEFT", -2, 0)

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
            if radios[Addon.SAVE2.ONE]:GetChecked() then
                WBB_Config[node.Val] = { val = Addon.SAVE2.ONE, to = name }
            end
        end

        row.dropdown.onSelectedChanged = onDropdownSelectedChanged

        local defVal = {}
        if node.NodeType == Addon.NODE.ACTIVE then
            defVal = { val = Addon.SAVE2.NONE }
        elseif node.NodeType == Addon.NODE.ITEM then
            defVal = { val = Addon.SAVE2.ALL }
        end
        local curr = WBB_Config[node.Val] and WBB_Config[node.Val] or defVal
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

    local finalY = self:RenderTree(content, Addon.TreeData, 0, -10)
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
