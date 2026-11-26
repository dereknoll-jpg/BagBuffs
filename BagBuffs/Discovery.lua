local _, P = ...
-- Small, source-checked exceptions only. Ordinary items are discovered from the client.
P.known = {[9421]="health", [8008]="mana", [13444]="mana", [13935]="food", [20744]="weapon", [10309]="scroll", [18251]="weapon", [12662]="mana"}

local function contains(s, patterns)
    for _,pattern in ipairs(patterns) do if s:find(pattern) then return true end end
    return false
end

function P:Plain(value)
    if not self:Readable(value) or type(value)~="string" then return "" end
    return value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
end

function P:TooltipText(bag,slot)
    local data=self:Call(C_TooltipInfo and C_TooltipInfo.GetBagItem,bag,slot)
    if not data or not self:Readable(data) or type(data)~="table" or not self:Readable(data.lines) or type(data.lines)~="table" then return "" end
    local lines={}
    for _,line in ipairs(data.lines) do
        if self:Readable(line) and type(line)=="table" then
            lines[#lines+1]=self:Plain(line.leftText); lines[#lines+1]=self:Plain(line.rightText)
        end
    end
    return table.concat(lines," ")
end

function P:Classify(item)
    if self.db.included[item.id] then return "utility" end
    if self.known[item.id] then return self.known[item.id] end
    local name,tip=self:Plain(item.name),item.tip or ""
    -- Some self-use items are also trade goods or quest rewards. Match a narrow
    -- family list before the class gate; never turn all quest/trade items into buttons.
    if item.class==7 or item.class==12 then
        if name=="demonic rune" or name=="dark rune" then return "mana" end
        if contains(name,{"^juju ","^crystal force$","^crystal ward$","^crystal spire$","^crystal restore$"}) then return "utility" end
    end
    -- Avoid recipes, quest objects, equipment and raw crafting ingredients.
    if item.class~=0 and item.class~=8 then return nil end
    -- Consumable/potion also includes some offensive objects. Do not surface an
    -- explicitly hostile damage effect unless its text also describes a self buff.
    if (tip:find("enemies") or tip:find("enemy")) and (tip:find("deals.*damage") or tip:find("inflicts.*damage"))
        and not contains(tip,{"increases your","increases the player's","restores.*health","restores.*mana"}) then return nil end
    local both=name.." "..tip
    if contains(name,{"healthstone","healing potion","health potion","healing draught"}) then return "health" end
    if contains(name,{"mana potion","mana gem","mana agate","mana jade","mana citrine","mana ruby","mana draught"}) then return "mana" end
    if contains(name,{"weightstone","sharpening stone","wizard oil","mana oil","frost oil","shadow oil","instant poison","deadly poison","crippling poison","wound poison","mind%-numbing poison","armor kit","shield spike","weapon oil","counterweight","scope","shiny bauble","bright baubles","nightcrawlers","fishing lure","aquadynamic fish attractor"}) then
        return "weapon"
    end
    if item.class==8 or item.subclass==6 or item.subclass==15 then return "weapon" end
    if contains(name,{"^scroll of "}) or item.subclass==4 then return "scroll" end
    if name:find("bandage") or item.subclass==7 then return "bandage" end
    if name:find("^flask of ") or item.subclass==3 then return "flask" end
    if name:find("elixir") or item.subclass==2 then return "elixir" end
    if item.subclass==5 then
        if contains(both,{"well fed","well%-fed","spend at least", "food buff","increases your","increases.*for %d+ min"}) then return "food" end
        -- Unknown localized food remains available through explicit include.
        return "refreshment"
    end
    if item.subclass==1 or name:find("potion") then
        if tip:find("restores") and tip:find("health") and not tip:find("mana") then return "health" end
        if tip:find("restores") and tip:find("mana") and not tip:find("health") then return "mana" end
        return "potion"
    end
    if contains(name,{"^juju ","^crystal force$","^crystal ward$","^crystal spire$","^crystal restore$","demonic rune","dark rune","whipper root","night dragon","winterfall firewater","noggenfogger","r%.o%.i%.d%.s%.","lung juice","ground scorpok"}) then return "utility" end
    if contains(tip,{"increases your", "increases the player's", "restores.*health", "restores.*mana", "transforms you"}) then return "utility" end
    return nil
end

function P:ScanBags()
    local found={}
    if not C_Container or not C_Item then return {} end
    for bag=0,(NUM_BAG_SLOTS or 4) do
        local slots=self:Call(C_Container.GetContainerNumSlots,bag)
        if self:Number(slots) then for slot=1,slots do
            local info=self:Call(C_Container.GetContainerItemInfo,bag,slot)
            if info and self:Readable(info) and type(info)=="table" and self:Number(info.itemID) then
                local id=info.itemID
                if found[id] then
                    if self:Number(info.stackCount) then found[id].count=found[id].count+info.stackCount end
                else
                    local name,link,_,level,minLevel,_,_,_,_,icon,_,class,subclass=self:Call(C_Item.GetItemInfo,id)
                    if not name then self:Call(C_Item.RequestLoadItemDataByID,id) end
                    if self:Readable(name) and type(name)=="string" and self:Number(class) and self:Number(subclass) then
                        local item={id=id,name=name,link=self:Readable(link) and link or nil,
                            level=self:Number(level) and level or 0, minLevel=self:Number(minLevel) and minLevel or 0,
                            class=class,subclass=subclass,icon=self:Readable(icon) and icon or 134400,
                            bag=bag,slot=slot,count=self:Number(info.stackCount) and info.stackCount or 0}
                        item.tip=self:TooltipText(bag,slot)
                        item.category=self:Classify(item)
                        if item.category then found[id]=item end
                    end
                end
            end
        end end
    end
    local items={}
    for _,item in pairs(found) do items[#items+1]=item end
    table.sort(items,function(a,b) if a.name~=b.name then return a.name<b.name end return a.id<b.id end)
    return items
end

function P:BagCounts()
    local counts={}
    for bag=0,(NUM_BAG_SLOTS or 4) do
        local slots=self:Call(C_Container and C_Container.GetContainerNumSlots,bag)
        if self:Number(slots) then for slot=1,slots do
            local info=self:Call(C_Container.GetContainerItemInfo,bag,slot)
            if info and self:Readable(info) and self:Number(info.itemID) and self:Number(info.stackCount) then
                counts[info.itemID]=(counts[info.itemID] or 0)+info.stackCount
            end
        end end
    end
    return counts
end

function P:FindBagItem(id)
    for bag=0,(NUM_BAG_SLOTS or 4) do
        local slots=self:Call(C_Container and C_Container.GetContainerNumSlots,bag)
        if self:Number(slots) then for slot=1,slots do
            local info=self:Call(C_Container.GetContainerItemInfo,bag,slot)
            if info and self:Readable(info) and self:Number(info.itemID) and info.itemID==id then return bag,slot end
        end end
    end
end
