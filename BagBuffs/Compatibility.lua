local _, P = ...

function P:CreateLegacySlotButtons()
    -- Existing native binding profiles can refer to CLICK PocketBuffsButtonN.
    -- Keep secure aliases instead of rewriting the player's binding profile.
    self.legacySlotButtons={}
    local owner=CreateFrame("Frame","BagBuffsExistingKeys",UIParent)
    for _,prefix in ipairs({"PocketBuffs","SatchelSense"}) do
        for i=1,9 do
            local b=CreateFrame("Button",prefix.."Button"..i,owner,"SecureActionButtonTemplate")
            b.slotIndex=i; b:SetSize(1,1); b:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0)
            b:EnableMouse(false); b:RegisterForClicks("AnyUp","AnyDown"); b:SetAttribute("type1","item")
            self.legacySlotButtons[#self.legacySlotButtons+1]=b
        end
    end
end

function P:SyncLegacySlotButtons(items)
    if InCombatLockdown() then return end
    for i,b in ipairs(self.legacySlotButtons or {}) do
        local item=items[b.slotIndex]
        b:SetAttribute("item1",item and ("item:"..item.id) or nil)
        if item and item.category=="weapon" then b:SetAttribute("unit",nil) else b:SetAttribute("unit","player") end
    end
end
