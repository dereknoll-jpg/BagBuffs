unpack=table.unpack
TEST_NS,SlashCmdList,UISpecialFrames={},{},{}
COMBAT=false
NOW=100
function GetTime() return NOW end
function IsAltKeyDown() return ALT or false end
function IsControlKeyDown() return CTRL or false end
function IsShiftKeyDown() return SHIFT or false end
function MouseIsOver(frame) return frame==HOVERED_FRAME end
function GetCursorPosition() return CURSOR_X or 400,CURSOR_Y or 300 end
function IsMouseButtonDown(button) assert(button=="LeftButton"); return LEFT_DOWN~=false end
STATE_DRIVERS={}
function RunStateDrivers()
    for frame,driver in pairs(STATE_DRIVERS) do frame.shown=driver~="hide" and not COMBAT end
end
function RegisterStateDriver(frame,state,driver)
    assert(not COMBAT and state=="visibility"); frame.secure=true; STATE_DRIVERS[frame]=driver; RunStateDrivers()
end
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
function InCombatLockdown() return COMBAT end
function UnitLevel() return 60 end
SECRET=setmetatable({},{__tostring=function() error("secret conversion") end,__lt=function() error("secret comparison") end,__eq=function() error("secret equality") end})
function issecretvalue(v) return rawequal(v,SECRET) end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
local methods={}
for _,name in ipairs({"SetHeight","SetWidth","SetClampedToScreen","SetMovable","SetFrameStrata","EnableMouse","RegisterForDrag","SetFrameLevel","SetAllPoints","SetVertexColor","SetTexCoord","AddMaskTexture","SetDrawEdge","SetHideCountdownNumbers","SetShadowColor","SetShadowOffset","RegisterForClicks","EnableMouseWheel","EnableKeyboard","SetPropagateKeyboardInput","SetFont","SetTextColor","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","StartMoving","StopMovingOrSizing","SetOwner","SetBagItem","AddLine"}) do methods[name]=function() end end
local function protected(self)
    if not COMBAT then return end
    local f=self
    while f do if f.secure then error("protected mutation in combat: "..(self.name or "frame")) end; f=f.parent end
    if self.hasSecure then error("protected ancestor mutation") end
end
function methods:SetAttribute(k,v) protected(self); self.attributes[k]=v end
function methods:SetPoint(...) protected(self); self.point={...} end
function methods:ClearAllPoints() protected(self) end
function methods:SetSize(w,h) protected(self); self.width=w; self.height=h end
function methods:SetScale(s) protected(self); self.scale=s end
function methods:Show() protected(self); local was=self.shown; self.shown=true; if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() protected(self); local was=self.shown; self.shown=false; if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.shown end
function methods:SetScript(k,fn) self.scripts[k]=fn end
function methods:RegisterEvent(k) self.events[k]=true end
function methods:SetText(t) assert(not issecretvalue(t)); self.text=t end
function methods:SetTexture(t) self.texture=t end
function methods:SetAlpha(a) self.alpha=a end
function methods:SetDesaturated(d) self.desaturated=d end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:SetCooldown(s,d) self.cooldown={s,d} end
function methods:Clear() self.cooldown=nil end
function methods:GetCenter() return 400,300 end
function methods:GetLeft() return self.left end
function methods:GetTop() return self.top end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return 1 end
local function object(name,parent,secure)
    local f=setmetatable({name=name,parent=parent,secure=secure,attributes={},scripts={},events={},shown=true}, {__index=methods})
    if name then _G[name]=f end
    return f
end
function methods:CreateTexture() return object() end
function methods:CreateMaskTexture() return object() end
function methods:CreateFontString() return object() end
function CreateFrame(_,name,parent,template)
    local secure=template=="SecureActionButtonTemplate"
    if secure then assert(not COMBAT); local f=parent; while f do f.hasSecure=true; f=f.parent end end
    return object(name,parent,secure)
end
UIParent=object("UIParent")
GameTooltip=object("GameTooltip")
BAGS,DEFS,TIPS,COOLDOWNS={},{},{},{}
C_Container={
    GetContainerNumSlots=function(bag) return #(BAGS[bag] or {}) end,
    GetContainerItemInfo=function(bag,slot) local item=(BAGS[bag] or {})[slot]; if item then return {itemID=item[1],stackCount=item[2]} end end,
}
C_Item={
    GetItemInfo=function(id)
        local d=DEFS[id]; if not d or d.uncached then return end
        return d.name,"item:"..id,1,20,d.minLevel or 1,"Consumable","",20,"",134400,0,d.class or 0,d.subclass or 0
    end,
    RequestLoadItemDataByID=function(id) REQUESTED=id end,
    GetItemCooldown=function(id) return unpack(COOLDOWNS[id] or {0,0,1}) end,
}
C_TooltipInfo={GetBagItem=function(bag,slot)
    local item=BAGS[bag][slot]; return {lines={{leftText=TIPS[item[1]] or ""}}}
end}
HARMFUL={}
C_UnitAuras={GetAuraDataByIndex=function(_,index,filter)
    if AURA_ERROR then error("restricted aura data") end
    assert(filter=="HARMFUL"); return HARMFUL[index]
end}
C_Spell={GetSpellInfo=function(id) if id==11196 or id==1305047 then return {name="Recently Bandaged"} end end}
OVERRIDES,BASE_BINDINGS={},{}
function ClearOverrideBindings(owner) assert(not COMBAT); OVERRIDES[owner]={} end
function SetOverrideBindingClick(owner,priority,key,name,button)
    assert(not COMBAT); assert(priority); OVERRIDES[owner]=OVERRIDES[owner] or {}
    OVERRIDES[owner][key]="CLICK "..name..":"..button
end
function GetBindingAction(key,overrides)
    if overrides then for _,bindings in pairs(OVERRIDES) do if bindings[key] then return bindings[key] end end end
    return BASE_BINDINGS[key] or ""
end
function GetBindingKey(command)
    for key,action in pairs(BASE_BINDINGS) do if action==command then return key end end
end
