local _, Addon = ...
local Category = Addon.Category

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
function Category:GetExpansionName(id)
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

function Category:NewNode(text, val, icon, parent, expanded, nodeType)
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
    TopPriority = Category:NewNode { text = "优先特殊物品", val = 2, nodeType = Addon.NODE.ANCHOR },
    Material = Category:NewNode { text = "材料", val = 3, nodeType = Addon.NODE.NORMAL },
    BottomPriority = Category:NewNode { text = "低优先级杂物", val = 5, nodeType = Addon.NODE.ANCHOR },
}

local MaterialClass = {
    BanBenTeShu = Category:NewNode { text = "版本特殊物品", val = 0, nodeType = Addon.NODE.ACTIVE },
    JinShu = Category:NewNode { text = "矿/金属", val = 1, nodeType = Addon.NODE.ACTIVE },
    Cao = Category:NewNode { text = "草药", val = 2, nodeType = Addon.NODE.ACTIVE },
    Pi = Category:NewNode { text = "皮", val = 3, nodeType = Addon.NODE.ACTIVE },
    Bu = Category:NewNode { text = "布", val = 4, nodeType = Addon.NODE.ACTIVE },
    FuMo = Category:NewNode { text = "附魔材料", val = 5, nodeType = Addon.NODE.ACTIVE },
    GongCheng = Category:NewNode { text = "工程半成品", val = 6, nodeType = Addon.NODE.ACTIVE },
    MingWen = Category:NewNode { text = "铭文半成品", val = 7, nodeType = Addon.NODE.ACTIVE },
    YuanSu = Category:NewNode { text = "元素", val = 8, nodeType = Addon.NODE.ACTIVE },
    Yao = Category:NewNode { text = "药剂/药水", val = 9, nodeType = Addon.NODE.ACTIVE },
}

local ExpansionClass = (function()
    local t = {}
    for i = 0, CURRENT_EXP do
        t[i] = Category:NewNode { text = Category:GetExpansionName(i), val = i, nodeType = Addon.NODE.NORMAL }
    end
    return t
end)()

local LeafClass = {
    PuTong = Category:NewNode { text = "普通", val = 0, nodeType = Addon.NODE.ACTIVE },
    TeShu = Category:NewNode { text = "特殊", val = 1, nodeType = Addon.NODE.ACTIVE },
}

local ClassLevel = {
    TopClass, ExpansionClass, MaterialClass --, LeafClass
}

function Category:BuildNodeTree(tree, level, expandNodeVal)
    tree = tree or Category:NewNode { text = "物品", val = 0, expanded = true, nodeType = Addon.NODE.ROOT }
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
                local child = Category:NewNode(
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
            local child = Category:NewNode(
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

function Category:MatchRules(itemID)
    local info = Addon:GetItemInfo(itemID)

    if info.bindType ~= 0 then
        return false
    end

    if (info.classID == 0) then
        -- 药水/合剂
        if info.subClassID == 1 or info.subClassID == 2 then
            if info.expansionID == 9 then
                return true
            end
        end
    end
    if (info.classID == 7) then
        -- 皮/矿/食材/草药/元素
        if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 8 or info.subClassID == 9 or info.subClassID == 10 then
            if info.expansionID == 7 or info.expansionID == 8 or info.expansionID == 9 or info.expansionID == 10 then
                return true
            end
            -- if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 9 then
            --     if info.expansionID == 11 then
            --         return true
            --     end
            -- end
        end
    elseif info.classID == 19 then
        -- 专业材料
        if info.expansionID == 9 or info.expansionID == 10 then
            return true
        end
    end

    return false
end

function Category:MaxCategory()
    return 30 * 10000
end

function Category:CategoryIndex(info)
    local idx = info.classID * 10000 + info.subClassID * 100 + info.expansionID
    if info.expansionID == 11 then
        idx = idx + self:MaxCategory()
    end
    return idx
end

function Category:GetCategory(itemID)
    local info = Addon:GetItemInfo(itemID)

    if info.bindType ~= 0 then
        return 0
    end

    if (info.classID == 0) then
        -- 药水/合剂
        if info.subClassID == 1 or info.subClassID == 2 then
            return self:CategoryIndex(info)
        end
    end
    if (info.classID == 7) then
        -- 皮/矿/食材/草药/元素
        if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 8 or info.subClassID == 9 or info.subClassID == 10 then
            return self:CategoryIndex(info)
        end
    elseif info.classID == 19 then
        -- 专业材料
        return self:CategoryIndex(info)
    end

    return self:MaxCategory()
end

function Category:GetOrderIndex(itemID)
    local category = self:GetCategory(itemID)
    return category * 1000000 + itemID
end

function Category:IsOverOrder(itemID)
    return self:GetCategory(itemID) > self:MaxCategory()
end
