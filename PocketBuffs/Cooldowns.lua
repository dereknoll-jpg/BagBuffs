local _, P = ...
P.bandageDebuffs={11196,1305047}

function P:RecentlyBandaged(now)
    local names={}
    for _,id in ipairs(self.bandageDebuffs) do
        local info=self:Call(C_Spell and C_Spell.GetSpellInfo,id)
        if info and self:Readable(info) and type(info)=="table" and self:Readable(info.name) and type(info.name)=="string" then names[info.name]=true end
    end
    local present,start,duration,ending=false,nil,nil,0
    for index=1,255 do
        local aura=self:Call(C_UnitAuras and C_UnitAuras.GetAuraDataByIndex,"player",index,"HARMFUL")
        if not aura then break end
        if self:Readable(aura) and type(aura)=="table" then
            local id=aura.spellId
            local matched=self:Number(id) and (id==11196 or id==1305047)
            if not matched and self:Readable(aura.name) and type(aura.name)=="string" then matched=names[aura.name] or aura.name=="Recently Bandaged" end
            if matched then
                present=true
                if self:Number(aura.expirationTime) and self:Number(aura.duration) and aura.duration>0 and aura.expirationTime>now and aura.expirationTime>ending then
                    duration=aura.duration; ending=aura.expirationTime; start=ending-duration
                end
            end
        end
    end
    return present,start,duration,ending
end

function P:CooldownText(remaining)
    if not self:Number(remaining) or remaining<=0 then return "" end
    if remaining>=3600 then return math.ceil(remaining/3600).."h" end
    if remaining>=60 then
        local seconds=math.ceil(remaining)
        return math.floor(seconds/60)..":"..string.format("%02d",seconds%60)
    end
    return tostring(math.ceil(remaining))
end

function P:ItemCooldown(item,now,bandaged,bandageStart,bandageDuration,bandageEnd)
    local start,duration,enabled=self:Call(C_Item and C_Item.GetItemCooldown,item.id)
    local ending=0
    if self:Number(start) and self:Number(duration) and duration>0 and self:Readable(enabled) and enabled~=0 and enabled~=false and start+duration>now then
        ending=start+duration
    else start,duration=nil,nil end
    if item.category=="bandage" and bandaged then
        if not bandageStart then return nil,nil,nil,true end
        if bandageEnd>ending then return bandageStart,bandageDuration,bandageEnd-now,true end
    end
    return start,duration,ending>0 and ending-now or nil,item.category=="bandage" and bandaged or false
end
