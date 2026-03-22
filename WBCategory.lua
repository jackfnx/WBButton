local _, Addon = ...
local Category = Addon.Category

function Category:MatchRules(itemID)
    local info = Addon:GetItemInfo(itemID)

    if info and info.classID == 7 then
        if info.subClassID == 9 or info.subClassID == 7 then
            if info.expansionID == 11 then
                return true
            end
        end
    end

    return false
end

function Category:MaxCategory()
    return 30 * 10000
end

function Category:CategoryIndex(info)
    return info.classID * 10000 + info.subClassID * 100 + info.expansionID
end

function Category:GetCategory(itemID)
    local info = Addon:GetItemInfo(itemID)

    if (info.classID == 0) then
        if info.subClassID == 1 or info.subClassID == 2 then
            return self:CategoryIndex(info)
        end
    end
    if (info.classID == 7) then
        if info.subClassID == 9 or info.subClassID == 7 or info.subClassID == 6 or info.subClassID == 8 or info.subClassID == 10 then
            return self:CategoryIndex(info)
        end
    elseif info.classID == 19 then
        return self:CategoryIndex(info)
    end

    return self:MaxCategory() + 1
end

function Category:GetOrderIndex(itemID)
    local category = self:GetCategory(itemID)
    return category * 1000000 + itemID
end

function Category:IsOverOrder(itemID)
    return self:GetCategory(itemID) > self:MaxCategory()
end
