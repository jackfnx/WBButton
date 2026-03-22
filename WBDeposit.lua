local _, Addon = ...
local Deposit = Addon.Deposit
local Category = Addon.Category


function Deposit:Execute()
    local inventories, accounts = self:GetItems(true, "inventory", "account")
    local accountsN = self:GetItems(false, "account")

    local queue1 = {}
    for _, item in ipairs(inventories) do
        if Category:MatchRules(item.itemID) then
            table.insert(queue1, item)
        end
    end

    local queue2 = {}
    for _, dest_item in ipairs(accounts) do
        for i, src_item in ipairs(queue1) do
            if (dest_item.itemID == src_item.itemID) then
                src_item.bankTabID = dest_item.bagID
                src_item.bankSlot = dest_item.slot
                table.insert(queue2, {
                    itemID = src_item.itemID,
                    srcBag = src_item.bag,
                    srcSlot = src_item.slot,
                    destBag = dest_item.bag,
                    destSlot = dest_item.slot
                })
                table.remove(queue1, i)
                break
            end
        end
    end

    for _, item in ipairs(queue1) do
        if #accountsN > 0 then
            for i, dest_kg in ipairs(accountsN) do
                table.insert(queue2, {
                    itemID = item.itemID,
                    srcBag = item.bag,
                    srcSlot = item.slot,
                    destBag = dest_kg.bag,
                    destSlot = dest_kg.slot
                })
                table.remove(accountsN, i)
                break;
            end
        else
            print("|cff00ff00[WBB]|r 银行满了，有物品没存进去")
            break
        end
    end

    self.queue = queue2
    self:StartProcessing()
end

-- 取得物品列表（根据物品还是空格，以及容器类型）
function Deposit:GetItems(yn, ...)
    local bagsList = {
        inventory = { 0, 1, 2, 3, 4, 5 },
        account = { 12, 13, 14, 15, 16 }
    }

    local items = {}
    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        local argItems = {}
        local bags = bagsList[arg]
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

function Deposit:MoveItemToBank(srcBag, srcSlot, destBag, destSlot)
    ClearCursor()

    C_Container.PickupContainerItem(srcBag, srcSlot)
    C_Container.PickupContainerItem(destBag, destSlot)
end

function Deposit:StartProcessing()
    Addon.Frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.queue or #self.queue == 0 then
            Addon.Frame:SetScript("OnUpdate", nil)
            return
        end

        local item = table.remove(self.queue, 1)

        print("|cff00ff00[WBB]|r 正在存入", Category:ItemStr(item.itemID))

        self:MoveItemToBank(item.srcBag, item.srcSlot, item.destBag, item.destSlot)
    end)
end
