-- WBButton.lua

local _, Addon = ...
Addon.Frame = CreateFrame("Frame") -- 用于注册事件
Addon.Sync = {}
Addon.Core = {}
Addon.Reorder = {}
Addon.Settings = {}
Addon.Widget = {}

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
Addon.Frame:SetScript("OnEvent", function(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end)

Addon.Frame:RegisterEvent("PLAYER_LOGIN")
Addon.Frame:RegisterEvent("BANKFRAME_OPENED")
Addon.Frame:RegisterEvent("BANKFRAME_CLOSED")

function Addon.Frame:PLAYER_LOGIN()
    -- 等完全初始化
    Delay(1, function()
        WBB_Characters = WBB_Characters or {}
        WBB_Config = WBB_Config or {}
        Addon:RegisterCurrentCharacter()
        Addon:TreeDataInit()

        Addon.Frame:CreateToolbar()
        Addon.Frame:CreateProgressBar()
        Addon.Settings:InitConfig()
        Addon.Settings:CreateConfigUI()
        Addon.Widget:CreateItemWidgetUI()
    end)
end

function Addon:GetCurrentCharacter()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function Addon:RegisterCurrentCharacter()
    local key = self:GetCurrentCharacter()
    local count = 0
    for _ in pairs(WBB_Characters) do
        count = count + 1
    end
    if WBB_Characters[key] == nil then
        WBB_Characters[key] = count
    end
end

function Addon.Frame.BANKFRAME_OPENED(...)
    if Addon.IsWarbandBankOpen() then
        Addon.Toolbar:Show()
    end
end

function Addon.Frame.BANKFRAME_CLOSED(...)
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
    toolbar:SetSize(265, 30)                        -- 宽200，高30
    toolbar:SetPoint("TOP", UIParent, "TOP", 0, -5) -- 顶部中间，向下偏移5

    local bg = toolbar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0, 0, 0, 0.5) -- 半透明黑

    toolbar:Hide()

    local buttons = {}
    local buttonNames = { "整理", "存/取", "小工具", "设置" }

    for i, name in ipairs(buttonNames) do
        local btn = CreateFrame("Button", "WB_Toolbar_Button" .. i, toolbar, "UIPanelButtonTemplate")
        btn:SetSize(60, 24)
        btn:SetText(name)
        btn:SetPoint("LEFT", toolbar, "LEFT", (i - 1) * 65 + 5, 0) -- 65间隔
        buttons[name] = btn
    end

    -- 整理
    buttons["整理"]:SetScript("OnClick", function()
        Addon:OnReorderClick()
    end)

    -- 存取
    buttons["存/取"]:SetScript("OnClick", function()
        Addon:OnSyncClick()
    end)

    -- 小工具
    buttons["小工具"]:SetScript("OnClick", function()
        Addon:OnWidgetClick()
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

    if Addon.Reorder.Execute then
        Addon.Reorder:Execute()
    end
end

function Addon:OnSyncClick()
    print("|cff00ff00[WBB]|r 点击存取按钮")

    if Addon.Sync.Execute then
        Addon.Sync:Execute()
    end
end

function Addon:OnWidgetClick()
    if Addon.Widget.WidgetDialog then
        Addon.Widget.WidgetDialog:Show()
    end
end

function Addon:OnSettingClick()
    if self.Settings.Execute then
        self.Settings:Execute()
    end
end

--------------------------------------------------
-- 进度条
--------------------------------------------------
function Addon.Frame:CreateProgressBar()
    local bar = CreateFrame("StatusBar", nil, UIParent)
    bar:SetSize(200, 20)
    bar:SetPoint("TOP", Addon.Toolbar, "BOTTOM", 0, 0) -- 紧挨着工具条底部

    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetMinMaxValues(0, 1)
    bar:SetStatusBarColor(0, 0.8, 0)
    bar:Hide()

    -- 背景
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    -- 文字
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.text:SetPoint("CENTER")

    local oldSetValue = bar.SetValue
    function bar:SetValue(v)
        oldSetValue(self, v)
        self.text:SetText(string.format("%.0f%%", v * 100))
    end

    Addon.ProgressBar = bar
end
