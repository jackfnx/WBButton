
local _, Addon = ...


function Addon.Deposit:ExecuteTransfer()

    local items1, items2 = self:GetAllItems()

    for _, item in ipairs(items1) do
        if self:ShouldMove(item.itemID) then
            print(GetItemInfoInstant(item.itemID))
            self:MoveItemToBank(item.bag, item.slot)
        end
    end

    for _, item in ipairs(items2) do
        if self:ShouldMove(item.itemID) then
            print(GetItemInfoInstant(item.itemID))
            self:MoveItemToBank(item.bag, item.slot)
        end
    end
end

function Addon.Deposit:GetAllItems()
    local bagItems = {}
    local wbbItems = {}

    local bags = {
        inventory = {0,1,2,3,4,5},
        account = {12,13,14,15,16}
    }

    for groupName, group in pairs(bags) do
        if groupName == "inventory" or groupName == "account" then
            local items = (groupName == "inventory") and bagItems or wbbItems
            for _, bag in ipairs(group) do
                local numSlots = C_Container.GetContainerNumSlots(bag)

                for slot = 1, numSlots do
                    local itemID = C_Container.GetContainerItemID(bag, slot)

                    if itemID then
                        table.insert(items, {
                            bag = bag,
                            slot = slot,
                            itemID = itemID
                        })
                    end
                end
            end
        end
    end

    return bagItems, wbbItems
end

function Addon.Deposit:ShouldMove(itemID)
    local classID = select(6, GetItemInfoInstant(itemID))

    if (itemID == 237364) then
        return true
    end
    -- -- 示例：只存“材料”
    -- if classID == 7 then
    --     return true
    -- end

    return false
end

function Addon.Deposit:MoveItemToBank(bag, slot)
    -- 拿起物品
    C_Container.PickupContainerItem(bag, slot)

    -- 放到银行（自动找空位）
end

function Addon.Deposit:StartProcessing()
    self:SetScript("OnUpdate", function(_, elapsed)
        if not self.queue or #self.queue == 0 then
            self:SetScript("OnUpdate", nil)
            return
        end

        local item = table.remove(self.queue, 1)

        C_Container.PickupContainerItem(item.bag, item.slot)
    end)
end
