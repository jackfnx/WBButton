local _, Addon = ...

local BAG_ID_LIST = {
    inventory = { 0, 1, 2, 3, 4, 5 },
    account = { 12, 13, 14, 15, 16 }
}

-- 取得某一类或几类背包的SLOTS_NUM
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

-- 在某一类背包里，根据SLOTS_NUM，查找第i个格子是第几个背包的第几个格子
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

-- 更新列表中物品的格子
function Addon:UpdateItem(items, bag, slot, newBag, newSlot)
    for _, item in ipairs(items) do
        if item.bag == bag and item.slot == slot then
            item.bag = newBag
            item.slot = newSlot
            return
        end
    end
end

-- 根据格子，从列表里删除物品
function Addon:DeleteItem(items, bag, slot)
    for i, item in ipairs(items) do
        if item.bag == bag and item.slot == slot then
            table.remove(items, i)
            return
        end
    end
end

-- 格子是否在列表里
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

function Addon:GetItemIsBindToWarband(itemID)
    local tooltip = C_TooltipInfo.GetItemByID(itemID)
    for _, line in ipairs(tooltip.lines) do
        if line.type == 20 then
            return line.bonding == 5
        end
    end
    return false
end

function Addon:GetItemInfo(itemID, ls)
    local values = { C_Item.GetItemInfo(itemID) }
    local isBindToWarband = self:GetItemIsBindToWarband(itemID)
    local info = {
        itemID = itemID,
        itemName = values[1],
        itemLink = values[2],
        itemQuality = values[3],
        itemLevel = values[4],
        itemMinLevel = values[5],
        itemType = values[6],
        itemSubType = values[7],
        itemStackCount = values[8],
        itemEquipLoc = values[9],
        itemTexture = values[10],
        sellPrice = values[11],
        classID = values[12],
        subClassID = values[13],
        bindType = values[14],
        expansionID = values[15],
        moveable = values[14] == 0 or values[14] == 2 or isBindToWarband
    }
    if ls then
        info = {
            [1] = { 'itemID', itemID },
            [2] = { 'itemName', values[1] },
            [3] = { 'itemLink', values[2] },
            [4] = { 'itemQuality', values[3] },
            [5] = { 'itemLevel', values[4] },
            [6] = { 'itemMinLevel', values[5] },
            [7] = { 'itemType', values[6] },
            [8] = { 'itemSubType', values[7] },
            [9] = { 'itemStackCount', values[8] },
            [10] = { 'itemEquipLoc', values[9] },
            [11] = { 'itemTexture', values[10] },
            [12] = { 'sellPrice', values[11] },
            [13] = { 'classID', values[12] },
            [14] = { 'subClassID', values[13] },
            [15] = { 'bindType', values[14] },
            [16] = { 'expansionID', values[15] },
            [17] = { 'moveable', values[14] == 0 or values[14] == 2 or isBindToWarband }
        }
    end
    return info
end

function Addon:ItemStr(itemID, itemInfo)
    if itemInfo == nil then
        itemInfo = self:GetItemInfo(itemID)
    end
    return string.format("%s[%d], %s, %s", itemInfo.itemName, itemID, itemInfo.itemSubType,
        Addon:GetExpansionName(itemInfo.expansionID))
end
