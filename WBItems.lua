local _, Addon = ...

local BAG_ID_LIST = {
    inventory = { 0, 1, 2, 3, 4, 5 },
    account = { 12, 13, 14, 15, 16 }
}

function Addon:GetSlotsNum(...)
    local slotsNum = {}
    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        local bags = BAG_ID_LIST[arg]
        for _, bag in ipairs(bags) do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            table.insert(slotsNum, numSlots)
        end
    end
    return slotsNum
end

function Addon:GetSlot(arg, slotsNum, i)
    local bags = BAG_ID_LIST[arg]
    for j, num in ipairs(slotsNum) do
        local bag = bags[j]
        if num >= i then
            return bag, i
        else
            i = i - num
        end
    end

    return -1, -1
end

function Addon:UpdateItem(items, bag, slot, newBag, newSlot)
    for _, item in ipairs(items) do
        if item.bag == bag and item.slot == slot then
            item.bag = newBag
            item.slot = newSlot
            return
        end
    end
end

function Addon:DeleteItem(items, bag, slot)
    for i, item in ipairs(items) do
        if item.bag == bag and item.slot == slot then
            table.remove(items, i)
            return
        end
    end
end

function Addon:SlotInList(items, bag, slot)
    for _, item in ipairs(items) do
        if item.bag == bag and item.slot == slot then
            return true
        end
    end
    return false
end

-- 取得物品列表（根据物品还是空格，以及容器类型）
function Addon:GetItems(yn, ...)
    local items = {}
    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        local argItems = {}
        local bags = BAG_ID_LIST[arg]
        for _, bag in ipairs(bags) do
            local numSlots = C_Container.GetContainerNumSlots(bag)

            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                local itemID = info and info.itemID
                local itemCount = info and info.stackCount

                if (itemID and yn) or (not itemID and not yn) then
                    table.insert(argItems, {
                        itemID = itemID,
                        itemCount = itemCount,
                        bag = bag,
                        slot = slot
                    })
                end
            end
        end
        table.insert(items, argItems)
    end

    return unpack(items)
end

Addon.ExpansionNames = {
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
function Addon:GetExpansionName(id)
    return self.ExpansionNames[id] or "未知资料片"
end

function Addon:GetItemInfo(itemID)
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

function Addon:ItemStr(itemID, itemInfo)
    if itemInfo == nil then
        itemInfo = self:GetItemInfo(itemID)
    end
    return string.format("%s[%d], %s, %s", itemInfo.itemName, itemID, itemInfo.itemSubType,
        self:GetExpansionName(itemInfo.expansionID))
end
