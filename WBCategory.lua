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

function Category:GetCategory(itemID)
    local info = Addon:GetItemInfo(itemID)

    if (info.classID == 7) then
        if info.subClassID == 9 or info.subClassID == 7 then
            return info.classID * 10000 + info.subClassID * 100 + info.expansionID
        end
    end

    return 10000 * 100;
end
