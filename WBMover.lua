local _, Addon = ...

function Addon:ProcessNext()
    if self.isMoving then return end

    local job = table.remove(self.queue, 1)
    if not job then
        print("|cff00ff00[WBB]|r 全部完成")
        if self.ProgressBar then
            self.ProgressBar:SetValue(1)
            C_Timer.After(1, function()
                self.ProgressBar:Hide()
            end)
        end
        return
    end

    self.isMoving = true

    if job.itemID then
        print("|cff00ff00[WBB]|r 正在移动", Addon:ItemStr(job.itemID))
    end

    ClearCursor()

    -- 从源拿起
    C_Container.PickupContainerItem(job.srcBag, job.srcSlot)

    -- 放到目标
    C_Container.PickupContainerItem(job.destBag, job.destSlot)
end

function Addon:UpdateProgress()
    if self.totalJobs == 0 then return end

    local progress = self.jobsDone / self.totalJobs

    if self.ProgressBar then
        self.ProgressBar:SetValue(progress)
    else
        print(string.format("进度: %.1f%%", progress * 100))
    end
end

function Addon:StartQueue(queue)
    self.queue = queue
    self.totalJobs = #queue
    self.jobsDone = 0
    self.isMoving = false

    if self.ProgressBar then
        self.ProgressBar:Show()
        self.ProgressBar:SetValue(0)
    end

    self:UpdateProgress()
    self:ProcessNext()
end

function Addon:StopQueue()
    self.queue = nil
    self.totalJobs = 0
    self.jobsDone = 0
    self.isMoving = false

    if self.ProgressBar then
        self.ProgressBar:Hide()
    end
end

Addon.Frame:RegisterEvent("BAG_UPDATE_DELAYED")

function Addon.Frame:BAG_UPDATE_DELAYED()
    if Addon.isMoving then
        Addon.isMoving = false

        Addon.jobsDone = Addon.jobsDone + 1

        Addon:UpdateProgress()
        Addon:ProcessNext()
    end
end
