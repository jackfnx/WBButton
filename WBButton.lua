-- WBButton.lua

-- local Addon = CreateFrame("Frame")
-- Addon.name = ...
local _, Addon = ...
Addon.Frame = CreateFrame("Frame")  -- 用于注册事件
Addon.Deposit = {}

--------------------------------------------------
-- 工具：延迟执行
--------------------------------------------------
local function Delay(seconds, func)
    local f = CreateFrame("Frame")
    local t = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        t = t + elapsed
        if t >= seconds then
            self:SetScript("OnUpdate", nil)
            func()
        end
    end)
end

--------------------------------------------------
-- 入口
--------------------------------------------------
Addon.Frame:SetScript("OnEvent", function(self, event, id, ...)
    if self[event] then
        self[event](self, id, ...)
    end
end)

Addon.Frame:RegisterEvent("PLAYER_LOGIN")
Addon.Frame:RegisterEvent("BANKFRAME_OPENED")
Addon.Frame:RegisterEvent("BANKFRAME_CLOSED")

function Addon.Frame:PLAYER_LOGIN()
    -- 等完全初始化
    Delay(1, function()
        Addon.Frame:CreateToolbar()
    end)
end

function Addon.Frame.BANKFRAME_OPENED(_, id)
    if Addon.IsWarbandBankOpen() then
        Addon.Toolbar:Show()
    end
end

function Addon.Frame.BANKFRAME_CLOSED(_, id)
    Addon.Toolbar:Hide()
end

function Addon.IsWarbandBankOpen()
    local types = C_Bank.FetchViewableBankTypes()
    if not types then return false end

    for _, bankType in ipairs(types) do
        if bankType == Enum.BankType.Account then
            return true
        end
    end

    return false
end

--------------------------------------------------
-- 创建按钮
--------------------------------------------------
function Addon.Frame:CreateToolbar()
    if Addon.Toolbar then return end

    -- 创建工具条框架
    local toolbar = CreateFrame("Frame", "WB_Toolbar", UIParent, BackdropTemplateMixin)
    toolbar:SetSize(200, 30) -- 宽200，高30
    toolbar:SetPoint("TOP", UIParent, "TOP", 0, -5) -- 顶部中间，向下偏移5
    local bg = toolbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0,0,0,0.5) -- 半透明黑
    toolbar:Hide()

    local buttons = {}
    local buttonNames = {"整理", "存入", "设置"}

    for i, name in ipairs(buttonNames) do
        local btn = CreateFrame("Button", "WB_Toolbar_Button"..i, toolbar, "UIPanelButtonTemplate")
        btn:SetSize(60, 24)
        btn:SetText(name)
        btn:SetPoint("LEFT", toolbar, "LEFT", (i-1)*65 + 5, 0) -- 65间隔
        buttons[name] = btn
    end

    -- 整理
    buttons["整理"]:SetScript("OnClick", function()
        Addon:OnReorderClick()
    end)

    -- 存入
    buttons["存入"]:SetScript("OnClick", function()
        Addon:OnDepositClick()
    end)

    -- 设置
    buttons["设置"]:SetScript("OnClick", function()
        Addon:OnSettingClick()
    end)

    Addon.Toolbar = toolbar
end

--------------------------------------------------
-- 点击逻辑入口
--------------------------------------------------
function Addon:OnReorderClick()
    print("|cff00ff00[WBB]|r 点击整理按钮")

    print("|cffffff00[WBB]|r Reorder 未实现")
end

function Addon:OnDepositClick()
    print("|cff00ff00[WBB]|r 点击存入按钮")

    -- TODO：接入你的执行器
    if Addon.Deposit.ExecuteTransfer then
        Addon.Deposit:ExecuteTransfer()
    else
        print("|cffffff00[WBB]|r ExecuteTransfer 未实现")
    end
end

function Addon:OnSettingClick()
    print("|cff00ff00[WBB]|r 点击设置按钮")

    print("|cffffff00[WBB]|r Setting 未实现")
end
