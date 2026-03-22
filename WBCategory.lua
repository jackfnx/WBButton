local _, Addon = ...
local Category = Addon.Category

Category.ExpansionNames = {
    [0] = "经典旧世",
    [1] = "燃烧的远征",
    [2] = "巫妖王之怒",
    [3] = "大地的裂变",
    [4] = "熊猫人之谜",
    [5] = "德拉诺之王",
    [6] = "军团再临",
    [7] = "争霸艾泽拉斯",
    [8] = "暗影国度",
    [9] = "巨龙时代",
    [10] = "地心之战",
    [11] = "至暗之夜",
    [12] = "最后的泰坦"
}

-- 使用函数封装
function Category:GetExpansionName(id)
    return self.ExpansionNames[id] or "未知资料片"
end

function Category:GetItemInfo(itemID)
    local values = { C_Item.GetItemInfo(itemID) }
    local info = {
        itemName = values[1],
        itemType = values[6],
        itemSubType = values[7],
        classID = values[12],
        subClassID = values[13],
        expansionID = values[15]
    }
    return info
end

function Category:ItemStr(itemID, itemInfo)
    if itemInfo == nil then
        itemInfo = self:GetItemInfo(itemID)
    end
    return string.format("%s[%d], %s, %s", itemInfo.itemName, itemID, itemInfo.itemSubType,
        self:GetExpansionName(itemInfo.expansionID))
end

function Category:MatchRules(itemID)
    local info = self:GetItemInfo(itemID)

    if info and info.classID == 7 then
        if info.subClassID == 9 or info.subClassID == 7 then
            if info.expansionID == 11 then
                return true
            end
        end
    end

    return false
end
