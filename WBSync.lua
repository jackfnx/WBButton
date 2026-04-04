local _, Addon = ...
local Sync = Addon.Sync
local Category = Addon.Category


function Sync:Execute()
    local inventories, accounts = Addon:GetItems(true, "inventory", "account")
    local accountsN = Addon:GetItems(false, "account")
    local me = Addon:GetCurrentCharacter()

    local queue1 = {}
    for _, item in ipairs(inventories) do
        local cfg = Category:ReadConfig(item.itemID)
        if cfg and cfg.val ~= Addon.SAVE2.NONE then
            if cfg.val == Addon.SAVE2.ONE and cfg.to == me then
                -- pass
            else
                table.insert(queue1, item)
            end
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

    Addon:StartQueue(queue2)
end
