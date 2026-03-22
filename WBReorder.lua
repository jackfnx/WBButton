local _, Addon = ...
local Reorder = Addon.Reorder
local Category = Addon.Category


function Reorder:Execute()
    local accounts = Addon:GetItems(true, "account")
    local spaces = Addon:GetItems(false, "account")

    local grouped = {}
    for _, item in ipairs(accounts) do
        if grouped[item.itemID] == nil then
            grouped[item.itemID] = {}
        end
        table.insert(grouped, item)
    end

    local queue1 = {}
    for _, items in ipairs(grouped) do
        if #items > 1 then
            Reorder:BuildMergePlan(items, queue1)
        end
    end

    if #queue1 > 0 then
        print("|cff00ff00[WBB]|r 需要合并，等合并完再点一次")
        Addon:StartQueue(queue1)
        return
    end

    accounts = Addon:GetItems(true, "account")
    spaces = Addon:GetItems(false, "account")

    table.sort(accounts, function(a, b)
        if a.itemID == b.itemID then
            return (a.bag * 100 + a.slot) < (b.bag * 100 + b.slot)
        end
        local type1 = Category:GetCategory(a.itemID)
        local type2 = Category:GetCategory(b.itemID)

        if (type1 == type2) then
            return (a.bag * 100 + a.slot) < (b.bag * 100 + b.slot)
        end

        return type1 < type2
    end)

    local queue2 = {}
    local slotsNum = Addon:GetSlotsNum("account")
    for i, item in ipairs(accounts) do
        local newBag, newSlot = Addon:GetSlot("account", slotsNum, i)
        if item.bag == newBag and item.slot == newSlot then
            -- do nothing
        elseif Addon:SlotInList(spaces, newBag, newSlot) then
            -- 如估计目标位置是空的，就直接把他挪过去
            table.insert(queue2, {
                srcBag = item.bag,
                srcSlot = item.slot,
                destBag = newBag,
                destSlot = newSlot
            })
            Addon:DeleteItem(spaces, newBag, newSlot)
            table.insert(spaces, {
                bag = item.bag,
                slot = item.slot
            })
        else
            -- 如果目标位置有东西，就把那个东西挪到下一个空格子里
            if #spaces == 0 then
                print("|cff00ff00[WBB]|r 没有足够的空格，无法完成排序")
                return
            end
            local space = table.remove(spaces, 1)
            table.insert(queue2, {
                srcBag = newBag,
                srcSlot = newSlot,
                destBag = space.bag,
                destSlot = space.slot
            })
            Addon:DeleteItem(spaces, space.bag, space.slot)
            table.insert(queue2, {
                srcBag = item.bag,
                srcSlot = item.slot,
                destBag = newBag,
                destSlot = newSlot
            })
            table.insert(spaces, {
                bag = item.bag,
                slot = item.slot
            })
        end
    end

    Addon:StartQueue(queue2)
end

function Reorder:BuildMergePlan(items, queue)
    if #items < 2 then
        return
    end
    local itemID = items[1].itemID
    local stackCount = select(8, C_Item.GetItemInfo(itemID))
    if stackCount < 2 then
        return
    end
    local itemCount = 0
    for _, item in ipairs(items) do
        if item.itemID ~= itemID then
            return
        end
        itemCount = itemCount + item.itemCount
    end

    -- 贪心合并：从第一堆开始，尽量填满
    for i = 1, #items - 1 do
        local receiver = items[i]
        -- 如果这堆已经满了，看下一堆
        if receiver.itemCount < stackCount then
            -- 从后面的堆中取物品来填满当前堆
            for j = i + 1, #items do
                local source = items[j]
                if source.itemCount > 0 then
                    -- 计算能移动多少
                    local space = stackCount - receiver.itemCount
                    local moveAmount = math.min(space, source.itemCount)

                    if moveAmount > 0 then
                        -- 记录操作
                        table.insert(queue, {
                            srcBag = source.bag,
                            srcSlot = source.slot,
                            destBag = receiver.bag,
                            destSlot = receiver.bag
                        })

                        -- 更新数量
                        receiver.itemCount = receiver.itemCount + moveAmount
                        source.itemCount = source.itemCount - moveAmount

                        -- 如果填满了，就处理下一堆
                        if receiver.itemCount >= stackCount then
                            break
                        end
                    end
                end
            end
        end
    end
end
