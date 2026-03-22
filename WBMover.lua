local _, Addon = ...

function Addon:MoveItemToBank(srcBag, srcSlot, destBag, destSlot)
    ClearCursor()

    C_Container.PickupContainerItem(srcBag, srcSlot)
    C_Container.PickupContainerItem(destBag, destSlot)
end

function Addon:StartQueue(queue)
    self.queue = queue
    Addon.Frame:SetScript("OnUpdate", function(_, elapsed)
        if not self.queue or #self.queue == 0 then
            Addon.Frame:SetScript("OnUpdate", nil)
            return
        end

        local item = table.remove(self.queue, 1)

        if item.itemID then
            print("|cff00ff00[WBB]|r 正在移动", Addon:ItemStr(item.itemID))
        end

        self:MoveItemToBank(item.srcBag, item.srcSlot, item.destBag, item.destSlot)
    end)
end
