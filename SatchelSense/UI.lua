local _, P = ...
local gold={.94,.78,.47}

function P:Label(parent,value,size,r,g,b)
    local t=parent:CreateFontString(nil,"OVERLAY")
    t:SetFont("Fonts\\ARIALN.TTF",size or 12,"")
    t:SetTextColor(r or .87,g or .85,b or .80); t:SetText(value); return t
end

function P:Backdrop(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(.030,.039,.052,.98); frame:SetBackdropBorderColor(.52,.43,.27,.45)
end

function P:QuietButton(parent,value,width,callback)
    local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
    b:SetSize(width,24); self:Backdrop(b)
    b.label=self:Label(b,value,12); b.label:SetPoint("CENTER")
    b:SetScript("OnClick",callback)
    b:SetScript("OnEnter",function() b:SetBackdropBorderColor(.85,.68,.36,.8) end)
    b:SetScript("OnLeave",function() b:SetBackdropBorderColor(.52,.43,.27,.45) end)
    return b
end

function P:Position()
    local f=self.frame; f:ClearAllPoints()
    local pos=self.db.position
    if type(pos)=="table" and self:Number(pos.x) and self:Number(pos.y) then f:SetPoint("CENTER",UIParent,"CENTER",pos.x,pos.y)
    else f:SetPoint("CENTER",UIParent,"CENTER",210,-150) end
    f:SetScale(self.db.scale)
end

function P:CreateUI()
    local f=CreateFrame("Frame","SatchelSenseFrame",UIParent)
    self.frame=f; self.buttons={}
    f:SetClampedToScreen(true); f:SetMovable(true); f:SetFrameStrata("MEDIUM"); f:EnableMouse(false)
    self.anchor=CreateFrame("Button",nil,f,"BackdropTemplate")
    local anchor=self.anchor
    anchor:SetHeight(20); anchor:SetPoint("BOTTOMLEFT",f,"TOPLEFT",0,4); anchor:RegisterForDrag("LeftButton")
    self:Backdrop(anchor); anchor:SetFrameLevel(f:GetFrameLevel()+5)
    self:Label(anchor,"DRAG",9,gold[1],gold[2],gold[3]):SetPoint("CENTER")
    anchor:SetScript("OnDragStart",function() self:StartGridMove() end)
    anchor:SetScript("OnDragStop",function() self:StopGridMove() end)
    self.launcher=CreateFrame("Button",nil,f)
    self.launcher:SetSize(18,18); self.launcher:SetPoint("BOTTOMRIGHT",f,"TOPRIGHT",0,5)
    local art=self.launcher:CreateTexture(nil,"ARTWORK"); art:SetAllPoints(); art:SetTexture(self.media.."AddonIcon")
    self.launcher:RegisterForClicks("LeftButtonUp","RightButtonUp"); self.launcher:RegisterForDrag("LeftButton")
    self.launcher:SetScript("OnDragStart",function() self:StartGridMove() end)
    self.launcher:SetScript("OnDragStop",function() self:StopGridMove() end)
    self.launcher:SetAlpha(.7); self.launcher:SetScript("OnClick",function(_,button)
        if button=="RightButton" and IsShiftKeyDown() then self:ToggleMoveLock() else self:ToggleSettings() end
    end)
    self.launcher:SetScript("OnEnter",function(b)
        b:SetAlpha(1); GameTooltip:SetOwner(b,"ANCHOR_TOP"); GameTooltip:SetText("SatchelSense",unpack(gold))
        GameTooltip:AddLine("Click: settings\nShift-right-click: lock / unlock\nUnlocked: drag the pouch to move the grid; drag items to reorder.\nMouse wheel: item pages",.8,.8,.8,true)
        GameTooltip:AddLine(self.db.locked and "Position locked" or "Position unlocked",.94,.78,.47); GameTooltip:Show()
    end)
    self.launcher:SetScript("OnLeave",function(b) b:SetAlpha(.7); GameTooltip:Hide() end)
    self.pager=self:QuietButton(f,"",72,function() self:ChangePage(self.page<self.pages and 1 or 1-self.pages) end)
    self.pager:SetPoint("TOPLEFT",f,"BOTTOMLEFT",0,-4)
    self.pager:EnableMouseWheel(true); self.pager:SetScript("OnMouseWheel",function(_,delta) self:ChangePage(delta>0 and -1 or 1) end)
    for i=1,64 do
        local b=CreateFrame("Button","SatchelSenseButton"..i,f,"SecureActionButtonTemplate")
        self.buttons[i]=b; b:RegisterForClicks("AnyUp","AnyDown")
        b:SetAttribute("type1","item"); b:SetAttribute("unit","player")
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetPoint("TOPLEFT",1,-1); b.icon:SetPoint("BOTTOMRIGHT",-1,1)
        b.icon:SetTexCoord(.08,.92,.08,.92)
        if b.CreateMaskTexture and b.icon.AddMaskTexture then
            b.mask=b:CreateMaskTexture(); b.mask:SetTexture(self.media.."IconFace","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
            b.mask:SetAllPoints(b.icon); b.icon:AddMaskTexture(b.mask)
        end
        b.rim=b:CreateTexture(nil,"OVERLAY"); b.rim:SetAllPoints(); b.rim:SetTexture(self.media.."IconRim")
        b.rim:SetVertexColor(gold[1],gold[2],gold[3],.45)
        b.cooldown=CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate"); b.cooldown:SetAllPoints(b.icon)
        b.cooldown:SetDrawEdge(false); b.cooldown:SetHideCountdownNumbers(true)
        b.textLayer=CreateFrame("Frame",nil,b); b.textLayer:SetAllPoints(); b.textLayer:SetFrameLevel(b.cooldown:GetFrameLevel()+2)
        b.cooldownText=self:Label(b.textLayer,"",14,.99,.91,.72); b.cooldownText:SetPoint("CENTER")
        b.cooldownText:SetShadowColor(0,0,0,1); b.cooldownText:SetShadowOffset(1,-1)
        b.count=self:Label(b.textLayer,"",10); b.count:SetPoint("BOTTOMRIGHT",-1,1)
        b.count:SetShadowColor(0,0,0,1); b.count:SetShadowOffset(0,-1)
        b.star=self:Label(b.textLayer,"",9,gold[1],gold[2],gold[3]); b.star:SetPoint("TOPLEFT",1,-1)
        b.keyText=self:Label(b.textLayer,"",8); b.keyText:SetPoint("TOPRIGHT",-1,-1)
        b:SetScript("OnEnter",function(button) self:ShowItemTooltip(button) end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        b:SetScript("PostClick",function(_,button,down)
            if button=="RightButton" and not down then self:ToggleSettings() end
        end)
        b:EnableMouseWheel(true); b:SetScript("OnMouseWheel",function(_,delta) self:ChangePage(delta>0 and -1 or 1) end)
        b:Hide()
    end
    self:Position()
    self:CreateLegacySlotButtons()
    self:CreateGridEditor()
end

function P:ShowItemTooltip(button)
    local item=button.item
    if not item then return end
    GameTooltip:SetOwner(button,"ANCHOR_TOP")
    local bag,slot=self:FindBagItem(item.id)
    if bag then GameTooltip:SetBagItem(bag,slot) else GameTooltip:SetText(item.name) end
    GameTooltip:AddLine(" ")
    if item.category=="weapon" then
        GameTooltip:AddLine("Click, then choose the item to enhance.",.94,.78,.47,true)
    else GameTooltip:AddLine("Left-click: use on yourself.",.94,.78,.47,true) end
    GameTooltip:AddLine("Right-click: settings  /  Wheel: pages",.6,.65,.68,true)
    local binding=self.db.bindings[item.id]
    if type(binding)=="table" and type(binding.key)=="string" then GameTooltip:AddLine("Key: "..binding.key,.94,.78,.47) end
    if item.category=="bandage" then
        local present=self:RecentlyBandaged(GetTime())
        if present then GameTooltip:AddLine("Recently Bandaged: wait for the debuff to expire.",.94,.65,.4,true) end
    end
    if InCombatLockdown() then GameTooltip:AddLine("Slots stay fixed until combat ends.",.6,.65,.68,true) end
    GameTooltip:Show()
end

function P:Layout(items)
    if InCombatLockdown() then self.pending=true; return end
    local d=self.db
    local width=d.columns*(d.size+d.gap)-d.gap
    local height=d.rows*(d.size+d.gap)-d.gap
    self.frame:SetSize(width,height); self:Position()
    self.anchor:SetWidth(math.max(16,width-24)); self.anchor:SetShown(not d.locked and width>=64)
    self.launcher:SetShown(d.logo and (next(items)~=nil or not d.locked))
    self.pager:SetShown(self.pages>1)
    self.pager.label:SetText(self.page.." / "..self.pages.."  >")
    for i,b in ipairs(self.buttons) do
        b.item=items[i]
        if i<=d.columns*d.rows then
            b:SetSize(d.size,d.size); b:ClearAllPoints()
            b:SetPoint("TOPLEFT",((i-1)%d.columns)*(d.size+d.gap),-math.floor((i-1)/d.columns)*(d.size+d.gap))
        end
        if b.item then
            b.cooldownText:SetFont("Fonts\\ARIALN.TTF",math.max(9,math.min(18,math.floor(d.size*.4))),"OUTLINE")
            b:SetAttribute("item1","item:"..b.item.id)
            if b.item.category=="weapon" then b:SetAttribute("unit",nil) else b:SetAttribute("unit","player") end
            b.icon:SetTexture(b.item.icon); b.star:SetText(d.favorites[b.item.id] and "+" or "")
            b:Show()
        else b:SetAttribute("item1",nil); b:Hide() end
    end
    self:SyncLegacySlotButtons(items); self:SyncGridEditing(); self:UpdateVisuals()
end

function P:UpdateVisuals()
    local counts=self:BagCounts()
    local now=GetTime()
    local bandaged,bandageStart,bandageDuration,bandageEnd=self:RecentlyBandaged(now)
    for index,b in ipairs(self.buttons or {}) do
        if b.item then
            local count=counts[b.item.id] or 0
            b.count:SetText(count>1 and count or (count==0 and "0" or ""))
            local level=self:Call(UnitLevel,"player")
            local tooHigh=self:Number(level) and b.item.minLevel>level
            local start,duration,remaining,blocked=self:ItemCooldown(b.item,now,bandaged,bandageStart,bandageDuration,bandageEnd)
            b.icon:SetDesaturated(count==0 or tooHigh or blocked)
            b.icon:SetAlpha(count==0 and .25 or (tooHigh and .5 or 1))
            if start and duration then
                b.cooldown:SetCooldown(start,duration)
            else b.cooldown:Clear() end
            b.cooldownText:SetText(remaining and self:CooldownText(remaining) or (blocked and "?" or ""))
            local key=self:BindingLabel(b.item.id)
            if key=="Bind key" then key=self:Call(GetBindingKey,"CLICK SatchelSenseButton"..index..":LeftButton") or "" end
            if key=="" then key=self:Call(GetBindingKey,"CLICK PocketBuffsButton"..index..":LeftButton") or "" end
            if type(key)~="string" then key="" end
            key=key:gsub("ALT%-","A-"):gsub("CTRL%-","C-"):gsub("SHIFT%-","S-"):gsub("NUMPAD","N"):gsub("MOUSEWHEELUP","WU"):gsub("MOUSEWHEELDOWN","WD"):gsub("BUTTON","M")
            b.keyText:SetWidth(math.max(16,self.db.size-4)); b.keyText:SetText(key)
        end
    end
end
