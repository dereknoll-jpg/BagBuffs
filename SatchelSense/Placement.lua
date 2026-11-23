local _, P = ...

function P:CopySlots(slots)
    local result,seen={},{}
    for index=1,math.min(#slots,4096) do
        local id=slots[index]
        if self:Number(id) and id>0 and id==math.floor(id) and not seen[id] then
            result[index]=id; seen[id]=true
        else result[index]=0 end
    end
    return result,seen
end

function P:EnsureSlots(items)
    -- Migrate the last manual order, or initialize using the previous type/name
    -- view. After that, a bag update only appends IDs; it never sorts old slots.
    if #self.db.slots==0 and self.db.sortMode=="manual" then self.db.slots=self:CopySlots(self.db.order) end
    local slots,seen=self:CopySlots(self.db.slots)
    for _,item in ipairs(self:SortedItems(items,self.db.sortMode)) do
        if not seen[item.id] then slots[#slots+1]=item.id; seen[item.id]=true end
    end
    self.db.slots=slots
end

function P:RememberManualSlots()
    self.db.order=self:CopySlots(self.db.slots); self.db.sortMode="manual"
end

function P:SlotForItem(id)
    for slot,existing in ipairs(self.db.slots) do if existing==id then return slot end end
end

function P:MoveItemToSlot(id,target)
    if not self:CanChange() then return false end
    if not self:Number(target) or target<1 or target>4096 or target~=math.floor(target) then return false end
    local from=self:SlotForItem(id)
    if not from or from==target then return false end
    for slot=#self.db.slots+1,target do self.db.slots[slot]=0 end
    self.db.slots[from],self.db.slots[target]=self.db.slots[target] or 0,id
    self:RememberManualSlots(); self:Refresh(); return true
end

function P:ToggleFavorite(id)
    if not self:CanChange() then return end
    self.db.favorites[id]=not self.db.favorites[id]
    if self.db.sortMode~="manual" then self:SetSortMode(self.db.sortMode) else self:Refresh() end
end
