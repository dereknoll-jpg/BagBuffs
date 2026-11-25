local _, P = ...
P.name, P.version = "SatchelSense", "1.0.4"
P.media = "Interface\\AddOns\\SatchelSense\\Media\\"
P.categories = {"health", "mana", "potion", "scroll", "food", "weapon", "elixir", "flask", "bandage", "utility", "refreshment"}
P.categoryNames = {health="Health", mana="Mana", potion="Utility potions", scroll="Scrolls", food="Buff food",
    weapon="Item enhancements", elixir="Elixirs", flask="Flasks", bandage="Bandages", utility="Other self buffs", refreshment="Plain food / drink"}
P.defaults = {columns=3, rows=3, size=32, gap=4, scale=1, locked=true, logo=true,
    enabled={}, ignored={}, favorites={}, included={}, sortMode="type", autoSort=true, autoSortBy="type", highlightNew=true,
    order={}, slots={}, bindings={}}
for _, key in ipairs(P.categories) do P.defaults.enabled[key] = key ~= "refreshment" end

function P:Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

function P:Number(value)
    return self:Readable(value) and type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end

function P:Call(fn, ...)
    if type(fn)~="function" then return nil end
    local ok, a,b,c,d,e,f,g,h,i,j,k,l,m = pcall(fn, ...)
    if ok then return a,b,c,d,e,f,g,h,i,j,k,l,m end
end

local function copy(t)
    local result={}
    for k,v in pairs(t) do result[k]=type(v)=="table" and copy(v) or v end
    return result
end

function P:InitializeDB()
    local imported=type(SatchelSenseDB)~="table" and type(PocketBuffsDB)=="table"
    local db=type(SatchelSenseDB)=="table" and SatchelSenseDB or (imported and copy(PocketBuffsDB) or {})
    if imported then db.migratedFrom="PocketBuffs" end
    -- The new default applies once to older profiles. Retain their exact manual
    -- layout so choosing Manual can restore it instead of destroying it.
    if type(db.autoSort)~="boolean" and db.sortMode=="manual" and type(db.slots)=="table" and #db.slots>0 then db.order=copy(db.slots) end
    if db.autoSortBy~="type" and db.autoSortBy~="name" then db.autoSortBy=db.sortMode=="name" and "name" or "type" end
    for k,v in pairs(self.defaults) do
        if type(db[k])~=type(v) then db[k]=type(v)=="table" and copy(v) or v end
    end
    for _,key in ipairs(self.categories) do
        if type(db.enabled[key])~="boolean" then db.enabled[key]=self.defaults.enabled[key] end
    end
    for key,range in pairs({columns={1,8}, rows={1,8}, size={20,56}, gap={0,16}, scale={.5,2}}) do
        local n=tonumber(db[key])
        db[key]=self:Number(n) and math.max(range[1],math.min(range[2],n)) or self.defaults[key]
        if key~="scale" then db[key]=math.floor(db[key]) end
    end
    if db.sortMode~="type" and db.sortMode~="name" and db.sortMode~="manual" then db.sortMode="type" end
    db.sortMode=db.autoSort and db.autoSortBy or "manual"
    self.db=db; SatchelSenseDB=db; self.page=1; self.bindingsDirty=true
    self.inventorySnapshot=nil; self.pendingNew={}; self.newUntil={}
end

function P:Message(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffefc778SatchelSense|r  "..message) end
end

function P:CanChange()
    if InCombatLockdown() then self:Message("Changes wait until combat ends."); return false end
    return true
end

function P:SortedItems(items,mode)
    local selected={}
    local priority={}
    for i,key in ipairs(self.categories) do priority[key]=i end
    for _,item in ipairs(items) do
        if not self.db.ignored[item.id] and self.db.enabled[item.category] then selected[#selected+1]=item end
    end
    table.sort(selected,function(a,b)
        local af,bf=self.db.favorites[a.id] and 1 or 0,self.db.favorites[b.id] and 1 or 0
        if af~=bf then return af>bf end
        if mode~="name" and priority[a.category]~=priority[b.category] then return priority[a.category]<priority[b.category] end
        if a.name~=b.name then return a.name<b.name end
        return a.id<b.id
    end)
    return selected
end

function P:SelectItems(items)
    local selected=self:SortedItems(items,self.db.sortMode)
    local rank={}
    for slot,id in ipairs(self.db.slots) do if id>0 then rank[id]=slot end end
    table.sort(selected,function(a,b) return (rank[a.id] or math.huge)<(rank[b.id] or math.huge) end)
    return selected
end

function P:PageItems(items)
    local capacity=self.db.columns*self.db.rows
    local byID={}; for _,item in ipairs(items) do byID[item.id]=item end
    local last=0; self.slotItems={}
    for slot,id in ipairs(self.db.slots) do if byID[id] then self.slotItems[slot]=byID[id]; last=slot end end
    local pages=math.max(1, math.ceil(last/capacity))
    self.page=math.min(pages,math.max(1,self.page or 1))
    local result={}
    for i=1,capacity do result[i]=self.slotItems[(self.page-1)*capacity+i] end
    return result,pages
end

function P:ChangePage(delta)
    if not self:CanChange() then return end
    self.page=math.max(1,math.min(self.pages or 1,self.page+delta)); self:Refresh()
end

function P:Refresh()
    if InCombatLockdown() then self.pending=true; self:UpdateVisuals(); return end
    if self.gridDragItemID or self.dragItemID or self.gridMoving then self.pending=true; self:UpdateVisuals(); return end
    self.pending=false
    self.items=self:ScanBags()
    self:TrackNewItems(self.items)
    self:EnsureSlots(self.items)
    self.selected=self:SelectItems(self.items)
    local visible,pages=self:PageItems(self.selected)
    self.pages=pages
    self:Layout(visible)
    self:SyncItemBindings()
    if self.settings and self.settings:IsShown() then self:SyncSettings() end
end
