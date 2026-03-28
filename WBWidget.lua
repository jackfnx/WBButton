local _, Addon = ...
local Widget = Addon.Widget

-- ======================
-- 创建窗口
-- ======================
function Widget:CreateItemWidgetUI()
    local frame = CreateFrame("Frame", "WBB_Widget", UIParent, "BackdropTemplate")
    frame:SetSize(400, 500)
    frame:SetPoint("CENTER")
    frame.backdropInfo = {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile     = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 }
    }
    frame:ApplyBackdrop()

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)

    table.insert(UISpecialFrames, "WBB_Widget")

    local titleBg = frame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetPoint("TOPLEFT", 8, -8)
    titleBg:SetPoint("TOPRIGHT", -8, -8)
    titleBg:SetHeight(24)
    titleBg:SetColorTexture(0, 0, 0, 0.6)

    -- 标题
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Item查看")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)

    -- 拖拽区域
    local drop = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    drop:SetSize(360, 40)
    drop:SetPoint("TOP", 0, -40)

    drop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8"
    })
    drop:SetBackdropColor(0, 0, 0, 0.5)

    local dropText = drop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropText:SetPoint("CENTER")
    dropText:SetText("把物品拖到这里")

    local editBox = CreateFrame("EditBox", nil, frame)

    editBox:SetPoint("TOPLEFT", drop, "BOTTOMLEFT", 0, -10)
    editBox:SetPoint("BOTTOMRIGHT", -30, 10)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(340)
    editBox:SetAutoFocus(false)

    frame.editBox = editBox

    -- ======================
    -- 处理拖拽
    -- ======================
    drop:EnableMouse(true)
    drop:RegisterForDrag("LeftButton")

    drop:SetScript("OnReceiveDrag", function()
        local type, itemID, link = GetCursorInfo()

        if type == "item" and itemID then
            Widget:ShowItemInfo(itemID)
        end

        ClearCursor()
    end)

    drop:SetScript("OnMouseUp", function()
        local type, itemID, link = GetCursorInfo()

        if type == "item" and itemID then
            Widget:ShowItemInfo(itemID)
        end

        ClearCursor()
    end)

    frame:Hide()

    self.WidgetDialog = frame
end

-- ======================
-- 显示信息
-- ======================
function Widget:ShowItemInfo(itemID)
    local info = Addon:GetItemInfo(itemID, true)

    if not info then
        self.ItemDebugFrame.editBox:SetText("数据未加载，请稍后再试")
        return
    end

    local text = ""

    for i, v in ipairs(info) do
        text = text .. "[" .. tostring(i - 1) .. "] " .. v[1] .. " = " .. tostring(v[2]) .. "\n"
    end

    self.WidgetDialog.editBox:SetText(text)
end
