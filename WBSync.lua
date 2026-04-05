local _, Addon = ...
local Sync = Addon.Sync
local Core = Addon.Core

function Sync:CurrentPlayerHasProf(prof)
    local prof1, prof2 = GetProfessions()
    local skillLine1 = select(7, GetProfessionInfo(prof1))
    local skillLine2 = select(7, GetProfessionInfo(prof2))
    return prof ~= 0 and (prof == skillLine1 or prof == skillLine2)
end

-- 此物与我有缘
function Sync:ItemProfMatchMe(itemID)
    local itemProf = Core:GetItemProf(itemID)
    return self:CurrentPlayerHasProf(itemProf)
end

function Sync:Execute()
    local inventories, accounts = Addon:GetItems(true, "inventory", "account")
    local spaceInv, spaceAcc = Addon:GetItems(false, "inventory", "account")
    local me = Addon:GetCurrentCharacter()

    local queue1 = {}
    for _, item1 in ipairs(inventories) do
        local cfg = Core:ReadConfig(item1.itemID)
        if cfg and cfg.val ~= Addon.SAVE2.NONE then
            if cfg.val == Addon.SAVE2.ONE and cfg.to == me then
                -- pass
            elseif cfg.val == Addon.SAVE2.ONE and self:ItemProfMatchMe(item1.itemID) then
                -- pass 如果这是一种‘集中模式’，但不是集中到我身上，但我也和他专业匹配，那这种物品我也不需要提交
            else
                table.insert(queue1, item1)
            end
        end
    end

    local queue2 = {}
    local queue3 = {}
    for _, item2 in ipairs(accounts) do
        for i, item1 in ipairs(queue1) do
            if (item2.itemID == item1.itemID) then
                item1.bankTabID = item2.bagID
                item1.bankSlot = item2.slot
                table.insert(queue2, {
                    itemID = item1.itemID,
                    srcBag = item1.bag,
                    srcSlot = item1.slot,
                    destBag = item2.bag,
                    destSlot = item2.slot
                })
                table.remove(queue1, i)
                break
            end
        end
        local cfg = Core:ReadConfig(item2.itemID)
        if cfg and cfg.val == Addon.SAVE2.ONE and cfg.to == me then
            table.insert(queue3, item2)
        end
    end

    for _, item1 in ipairs(queue1) do
        if #spaceAcc > 0 then
            for i, dest_kg in ipairs(spaceAcc) do
                table.insert(queue2, {
                    itemID = item1.itemID,
                    srcBag = item1.bag,
                    srcSlot = item1.slot,
                    destBag = dest_kg.bag,
                    destSlot = dest_kg.slot
                })
                table.remove(spaceAcc, i)
                break
            end
        else
            print("|cff00ff00[WBB]|r 银行满了，有物品没存进去")
            break
        end
    end

    local queue4 = {}
    for _, item1 in ipairs(inventories) do
        for i, item3 in ipairs(queue3) do
            if (item1.itemID == item3.itemID) then
                item3.bankTabID = item1.bagID
                item3.bankSlot = item1.slot
                table.insert(queue4, {
                    itemID = item3.itemID,
                    srcBag = item3.bag,
                    srcSlot = item3.slot,
                    destBag = item1.bag,
                    destSlot = item1.slot
                })
                table.remove(queue3, i)
                break
            end
        end
    end

    for _, item3 in ipairs(queue3) do
        if #spaceInv > 0 then
            for i, dest_kg in ipairs(spaceInv) do
                table.insert(queue4, {
                    itemID = item3.itemID,
                    srcBag = item3.bag,
                    srcSlot = item3.slot,
                    destBag = dest_kg.bag,
                    destSlot = dest_kg.slot
                })
                table.remove(spaceInv, i)
                break
            end
        else
            print("|cff00ff00[WBB]|r 背包满了，有物品没取出来")
            break
        end
    end

    local queue1000 = {}
    for _, v in ipairs(queue2) do
        table.insert(queue1000, v)
    end
    for _, v in ipairs(queue4) do
        table.insert(queue1000, v)
    end

    Addon:StartQueue(queue1000)
end
