local _, Addon = ...
local Category = Addon.Category

function Category:MatchRules(itemID)
    local info = Addon:GetItemInfo(itemID)

    if info.bindType ~= 0 then
        return false
    end

    if (info.classID == 0) then
        -- 药水/合剂
        if info.subClassID == 1 or info.subClassID == 2 then
            if info.expansionID == 9 then
                return true
            end
        end
    end
    if (info.classID == 7) then
        -- 皮/矿/食材/草药/元素
        if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 8 or info.subClassID == 9 or info.subClassID == 10 then
            if info.expansionID == 7 or info.expansionID == 8 or info.expansionID == 9 or info.expansionID == 10 then
                return true
            end
            -- if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 9 then
            --     if info.expansionID == 11 then
            --         return true
            --     end
            -- end
        end
    elseif info.classID == 19 then
        -- 专业材料
        if info.expansionID == 9 or info.expansionID == 10 then
            return true
        end
    end

    return false
end

function Category:MaxCategory()
    return 30 * 10000
end

function Category:CategoryIndex(info)
    local idx = info.classID * 10000 + info.subClassID * 100 + info.expansionID
    if info.expansionID == 11 then
        idx = idx + self:MaxCategory()
    end
    return idx
end

function Category:GetCategory(itemID)
    local info = Addon:GetItemInfo(itemID)

    if info.bindType ~= 0 then
        return 0
    end

    if (info.classID == 0) then
        -- 药水/合剂
        if info.subClassID == 1 or info.subClassID == 2 then
            return self:CategoryIndex(info)
        end
    end
    if (info.classID == 7) then
        -- 皮/矿/食材/草药/元素
        if info.subClassID == 6 or info.subClassID == 7 or info.subClassID == 8 or info.subClassID == 9 or info.subClassID == 10 then
            return self:CategoryIndex(info)
        end
    elseif info.classID == 19 then
        -- 专业材料
        return self:CategoryIndex(info)
    end

    return self:MaxCategory()
end

function Category:GetOrderIndex(itemID)
    local category = self:GetCategory(itemID)
    return category * 1000000 + itemID
end

function Category:IsOverOrder(itemID)
    return self:GetCategory(itemID) > self:MaxCategory()
end
