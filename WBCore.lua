local _, Addon = ...
local Core = Addon.Core

local CURRENT_EXP = 11

local ExpansionNames = {
    [0] = "1.x 经典旧世",
    [1] = "2.x 燃烧的远征",
    [2] = "3.x 巫妖王之怒",
    [3] = "4.x 大地的裂变",
    [4] = "5.x 熊猫人之谜",
    [5] = "6.x 德拉诺之王",
    [6] = "7.x 军团再临",
    [7] = "8.x 争霸艾泽拉斯",
    [8] = "9.x 暗影国度",
    [9] = "10.x 巨龙时代",
    [10] = "11.x 地心之战",
    [11] = "12.x 至暗之夜",
    [12] = "13.x 最后的泰坦"
}

local ExpansionIcons = {
    [0] = "Icons/classic.blp",
    [1] = "Icons/bc.blp",
    [2] = "Icons/wotlk.blp",
    [3] = "Icons/cata.blp",
    [4] = "Icons/mop.blp",
    [5] = "Icons/wod.blp",
    [6] = "Icons/legion.blp",
    [7] = "Icons/bfa.blp",
    [8] = "Icons/shadowlands.blp",
    [9] = "Icons/dragonflight.blp",
    [10] = "Icons/tww.blp",
    [11] = "Icons/tww.blp",
}

-- 使用函数封装
function Core:GetExpansionName(id)
    local expName = ExpansionNames[id] or "未知资料片"
    return expName

    -- local iconWidth = 0   -- 默认 16px 宽
    -- local iconHeight = 4  -- 默认 16px 高
    -- local spaceBefore = 1 -- 默认文字前空格 1

    -- local iconString = ""
    -- local icon = ExpansionIcons[id]
    -- if icon then
    --     -- 有图标
    --     iconString = string.format(" |TInterface\\AddOns\\WBButton\\%s:%d:%d|t", icon, iconWidth, iconHeight)
    -- else
    --     -- 没有图标，用空占位
    --     iconString = string.format(" |TInterface\\Buttons\\WHITE8X8:0:%d|t", iconHeight)
    -- end

    -- return string.rep(" ", spaceBefore) .. iconString .. expName
end

Addon.NODE = {
    ROOT = 1,   --根节点
    ANCHOR = 2, --手工锚节点
    ITEM = 3,   --手工物品节点
    NORMAL = 4, --普通过路节点
    ACTIVE = 5, --真正可以设置的分类节点
}

Addon.SAVE2 = {
    NONE = 1, --不存入
    ALL = 2,  --全部存入
    ONE = 3,  --集中角色
}

function Core:NewNode(text, val, icon, parent, expanded, nodeType)
    -- 如果第一个参数是 table → 命名参数
    if type(text) == "table" then
        local args = text

        text       = args.text
        val        = args.val
        icon       = args.icon
        parent     = args.parent
        expanded   = args.expanded
        nodeType   = args.nodeType
    end

    return {
        Text = text,
        Val = parent and (parent * 100 + val) or val,
        Icon = icon,
        Children = {},
        Expanded = expanded,
        NodeType = nodeType or Addon.NODE.NORMAL,
    }
end

local TopClass = {
    TopPriority = Core:NewNode { text = "优先特殊物品", val = 2, nodeType = Addon.NODE.ANCHOR },
    Material = Core:NewNode { text = "材料", val = 3, nodeType = Addon.NODE.NORMAL },
    BottomPriority = Core:NewNode { text = "低优先级杂物", val = 5, nodeType = Addon.NODE.ANCHOR },
}

local MaterialClass = {
    BanBenTeShu = Core:NewNode { text = "版本特殊物品", val = 1, nodeType = Addon.NODE.ACTIVE },
    JinShu = Core:NewNode { text = "矿/金属", val = 2, nodeType = Addon.NODE.ACTIVE },
    Cao = Core:NewNode { text = "草药", val = 3, nodeType = Addon.NODE.ACTIVE },
    Pi = Core:NewNode { text = "皮", val = 4, nodeType = Addon.NODE.ACTIVE },
    Bu = Core:NewNode { text = "布", val = 5, nodeType = Addon.NODE.ACTIVE },
    FuMo = Core:NewNode { text = "附魔材料", val = 6, nodeType = Addon.NODE.ACTIVE },
    GongCheng = Core:NewNode { text = "工程半成品", val = 7, nodeType = Addon.NODE.ACTIVE },
    MingWen = Core:NewNode { text = "铭文半成品", val = 8, nodeType = Addon.NODE.ACTIVE },
    YuanSu = Core:NewNode { text = "元素", val = 9, nodeType = Addon.NODE.ACTIVE },
    Yao = Core:NewNode { text = "药剂/药水", val = 10, nodeType = Addon.NODE.ACTIVE },
    Cai = Core:NewNode { text = "食材", val = 11, nodeType = Addon.NODE.ACTIVE },
    Yu = Core:NewNode { text = "鱼", val = 12, nodeType = Addon.NODE.ACTIVE },
}

local ExpansionClass = (function()
    local t = {}
    for i = 0, CURRENT_EXP do
        t[i] = Core:NewNode { text = Core:GetExpansionName(i), val = i, nodeType = Addon.NODE.NORMAL }
    end
    return t
end)()

local LeafClass = {
    PuTong = Core:NewNode { text = "普通", val = 0, nodeType = Addon.NODE.ACTIVE },
    TeShu = Core:NewNode { text = "特殊", val = 1, nodeType = Addon.NODE.ACTIVE },
}

local ClassLevel = {
    TopClass, ExpansionClass, MaterialClass --, LeafClass
}

function Addon:TreeDataInit()
    Addon.TreeData = Addon.TreeData or { Addon.Core:BuildNodeTree() }
    if (Addon.TreeData and #Addon.TreeData > 0) then
        Addon.TreeData.High = Core:GetTreeVal(Addon.TreeData[1], { TopClass.TopPriority }).Val
        Addon.TreeData.Low = Core:GetTreeVal(Addon.TreeData[1], { TopClass.BottomPriority }).Val
    else
        Addon.TreeData.High = 0
        Addon.TreeData.Low = 0
    end
end

function Core:BuildNodeTree(tree, level, expandNodeVal)
    tree = tree or Core:NewNode { text = "物品", val = 0, expanded = true, nodeType = Addon.NODE.ROOT }
    level = level or 1
    if ClassLevel[level] == nil then
        return
    end
    if tree.NodeType == Addon.NODE.ANCHOR then
        local items = WBB_Config[tree.Val] or {}
        for itemID in pairs(items) do
            if type(itemID) == "number" then
                local v = items[itemID]
                local info = Addon:GetItemInfo(itemID)
                local child = Core:NewNode(
                    info.itemName,
                    v,
                    info.itemTexture,
                    tree.Val,
                    false,
                    Addon.NODE.ITEM
                )
                child.Expanded = child.Expanded or child.Val == expandNodeVal
                child.SelfDelete = function()
                    WBB_Config[tree.Val][itemID] = nil
                    return tree.Val
                end
                table.insert(tree.Children, child)
            end
        end
    elseif tree.NodeType == Addon.NODE.ITEM then
        -- no child
    else
        for _, nodePrototype in pairs(ClassLevel[level]) do
            local child = Core:NewNode(
                nodePrototype.Text,
                nodePrototype.Val,
                nil,
                tree.Val,
                false,
                nodePrototype.NodeType)
            child.Expanded = child.Expanded or child.Val == expandNodeVal
            table.insert(tree.Children, child)
            self:BuildNodeTree(child, level + 1, expandNodeVal)
        end
    end
    table.sort(tree.Children, function(a, b) return a.Val < b.Val end)
    return tree
end

function Core:GetTreeVal(tree, path, prevVal)
    if path == nil or #path == 0 then
        return { Val = 0 }
    end

    prevVal = prevVal or 0

    local currVal = path[1].Val + prevVal * 100
    local sub_path = { unpack(path, 2) }
    if tree.Val ~= 0 and tree.Val ~= currVal then
        return { Val = 0 }
    elseif tree.Val == 0 then
        -- 根目录，则忽略这一层
        currVal = prevVal
        sub_path = path
    end

    if #sub_path == 0 then
        return tree
    end

    for _, child in ipairs(tree.Children) do
        local c = self:GetTreeVal(child, sub_path, currVal)
        if c.Val ~= 0 then
            return c
        end
    end
    return { Val = 0 }
end

function Core:GetItemVal(itemInfo, nodesVal, vals)
    for i, nodeVal in ipairs(nodesVal) do
        local nodeList = WBB_Config[nodeVal] or {}
        if nodeList[itemInfo.itemID] then
            return (nodeList[itemInfo.itemID] + vals[i] * 100)
        end
    end
    return 0
end

local NPC_SELLS = {
    [242646] = true, -- 香料包，12.0，烹饪
    [242643] = true, -- 大块黄油，12.0，烹饪
    [242642] = true, -- 萨拉斯草药，12.0，烹饪
}

function Core:GetMaterialClass(itemInfo)
    local materialClass = nil

    if NPC_SELLS[itemInfo.itemID] then
        -- do nothing
    elseif (itemInfo.classID == 0) then
        -- 药水/合剂
        if itemInfo.subClassID == 1 or itemInfo.subClassID == 2 then
            materialClass = MaterialClass.Yao
        end
    elseif (itemInfo.classID == 7) then
        -- 皮/矿/食材/草药/元素
        if itemInfo.subClassID == 6 then
            materialClass = MaterialClass.Pi
        elseif itemInfo.subClassID == 7 then
            materialClass = MaterialClass.JinShu
        elseif itemInfo.subClassID == 8 then
            materialClass = MaterialClass.Cai
        elseif itemInfo.subClassID == 9 then
            materialClass = MaterialClass.Cao
        elseif itemInfo.subClassID == 10 then
            materialClass = MaterialClass.YuanSu
        end
    elseif itemInfo.classID == 19 then
        -- 专业材料
        if itemInfo.expansionID == 9 then
            materialClass = MaterialClass.GongCheng
        elseif itemInfo.expansionID == 10 then
            materialClass = MaterialClass.MingWen
        end
    end

    local expClass = ExpansionClass[itemInfo.expansionID]

    return { materialClass = materialClass, expClass = expClass }
end

function Core:GetActiveVal(itemInfo, tree)
    local cls = self:GetMaterialClass(itemInfo)
    if cls.materialClass == nil or cls.expClass == nil then
        return 0
    end
    return self:GetTreeVal(tree, { TopClass.Material, cls.expClass, cls.materialClass }).Val or 0
end

function Core:ReadConfig(itemID)
    local tree = Addon.TreeData[1]
    local high = Addon.TreeData.High
    local low = Addon.TreeData.Low
    local info = Addon:GetItemInfo(itemID)

    if info.bindType > 2 then
        return { val = Addon.SAVE2.NONE }
    end

    local itemVal = self:GetItemVal(info, { high, low }, { TopClass.TopPriority.Val, TopClass.BottomPriority.Val })
    if itemVal > 0 then
        return WBB_Config[itemVal]
    end

    itemVal = self:GetActiveVal(info, tree)
    if itemVal > 0 then
        return WBB_Config[itemVal]
    end

    return { val = Addon.SAVE2.NONE }
end

function Core:MaxVal()
    return 100000000
end

function Core:GetOrderVal(itemID)
    local tree = Addon.TreeData[1]
    local high = Addon.TreeData.High
    local low = Addon.TreeData.Low
    local info = Addon:GetItemInfo(itemID)

    -- if info.bindType ~= 0 then
    --     return self:MaxVal() * 2
    -- end

    if info.classID == 2 or info.classID == 4 then
        return self:MaxVal() * 4 -- 装备放在最后面
    end

    local itemVal = self:GetItemVal(info, { high }, { TopClass.TopPriority.Val })
    if itemVal > 0 then
        return itemVal
    end

    local cls = self:GetMaterialClass(info)
    if cls.expClass ~= nil and cls.materialClass ~= nil then
        itemVal = TopClass.Material.Val
        itemVal = itemVal * 100 + cls.materialClass.Val
        itemVal = itemVal * 100 + cls.expClass.Val
        if info.expansionID == CURRENT_EXP then
            return itemVal + self:MaxVal() * 3
        end
        return itemVal
    end

    itemVal = self:GetItemVal(info, { low }, { TopClass.BottomPriority.Val })
    if itemVal > 0 then
        return itemVal + self:MaxVal()
    end

    return self:MaxVal() * 2 + 1
end

function Core:GetOrderIndex(itemID)
    local category = self:GetOrderVal(itemID)
    -- return category * 1000000 + itemID
    return category
end

function Core:IsOverOrder(itemID)
    return self:GetOrderVal(itemID) > self:MaxVal() * 5
end
