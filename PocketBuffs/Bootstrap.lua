local _, P = ...
BINDING_HEADER_POCKETBUFFS="PocketBuffs"
for i=1,9 do _G["BINDING_NAME_CLICK PocketBuffsButton"..i..":LeftButton"]="Use grid slot "..i end
local events=CreateFrame("Frame")
P.events=events
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,arg)
    if event=="ADDON_LOADED" then
        if arg~=P.name then return end
        P:InitializeDB()
        -- Secure buttons must be constructed outside combat, including load-on-demand situations.
        if not InCombatLockdown() then P:CreateUI(); P:Refresh() else P.pending=true end
        for _,name in ipairs({"PLAYER_ENTERING_WORLD","BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT", "TOOLTIP_DATA_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "BAG_UPDATE_COOLDOWN", "PLAYER_LEVEL_UP", "UNIT_AURA", "UPDATE_BINDINGS", "GLOBAL_MOUSE_UP"}) do events:RegisterEvent(name) end
    elseif P.db then
        if event=="PLAYER_REGEN_ENABLED" and not P.frame then P:CreateUI() end
        if not P.frame then P.pending=true; return end
        if event=="GLOBAL_MOUSE_UP" then
            if arg=="LeftButton" then
                if P.gridMoving then P:StopGridMove() end
                P:EndGridItemDrag()
                if P.dragItemID then P:EndItemDrag() end
            end
        elseif event=="PLAYER_REGEN_DISABLED" then P:CancelBinding(); P.dragItemID=nil; P:CancelGridDrag()
        elseif event=="UNIT_AURA" then if arg=="player" then P:UpdateVisuals() end
        elseif event=="UPDATE_BINDINGS" then P.bindingsDirty=true; P.dirty=true
        elseif event=="BAG_UPDATE_COOLDOWN" then P:UpdateVisuals()
        elseif event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
            if select(1,arg) then P.dirty=true end
        else P.dirty=true end
    end
end)
events:SetScript("OnUpdate",function(_,elapsed)
    if not P.frame then return end
    P.elapsed=(P.elapsed or 0)+elapsed
    if P.elapsed<.25 then return end
    P.elapsed=0
    if P.dirty or (P.pending and not InCombatLockdown()) then P.dirty=false; P:Refresh() else P:UpdateVisuals() end
end)

SLASH_POCKETBUFFS1="/pbuff"
SLASH_POCKETBUFFS2="/pocketbuffs"
SlashCmdList.POCKETBUFFS=function(message)
    if not P.db then return end
    local command,rest=message:match("^(%S*)%s*(.-)%s*$"); command=command:lower()
    if command=="" or command=="settings" then P:ToggleSettings(); return end
    if command=="help" then
        P:Message("/pbuff [settings | lock | unlock | next | prev | layout COLSxROWS | size 20-56 | scale 0.5-2 | include ID | exclude ID | forget ID | favorite ID | hide ID | restore ID]")
        return
    end
    if not P:CanChange() then return end
    if command=="unlock" or command=="lock" then P.db.locked=command=="lock"
    elseif command=="next" then P:ChangePage(1); return
    elseif command=="prev" then P:ChangePage(-1); return
    elseif command=="layout" then
        local columns,rows=rest:match("^(%d+)%s*[xX]%s*(%d+)$"); columns,rows=tonumber(columns),tonumber(rows)
        if not columns or columns<1 or columns>8 or rows<1 or rows>8 then P:Message("Use /pbuff layout 3x3 (each side 1-8)."); return end
        P.db.columns,P.db.rows,P.page=columns,rows,1
    elseif command=="size" or command=="scale" then
        local n=tonumber(rest); local min,max=command=="size" and 20 or .5,command=="size" and 56 or 2
        if not P:Number(n) or n<min or n>max then P:Message("Choose "..min.." to "..max.."."); return end
        P.db[command]=command=="size" and math.floor(n) or n
    else
        local id=tonumber(rest:match("item:(%d+)") or rest)
        if not P:Number(id) or id<1 or id~=math.floor(id) then P:Message("Use /pbuff help for commands."); return end
        if command=="include" then P.db.included[id]=true; P.db.ignored[id]=nil
        elseif command=="exclude" or command=="hide" then P.db.ignored[id]=true
        elseif command=="restore" then P.db.ignored[id]=nil
        elseif command=="forget" then P.db.included[id]=nil
        elseif command=="favorite" then P:ToggleFavorite(id); return
        else P:Message("Use /pbuff help for commands."); return end
    end
    P:Refresh()
end
