local _, P = ...

function P:SelectSettingsTab(key)
    self.settingsTab=key
    self.layoutPage:SetShown(key=="layout"); self.itemsPage:SetShown(key=="items")
    self:SyncSettings()
end

function P:ToggleSettings()
    if self.settings then
        self.settings:SetShown(not self.settings:IsShown())
        if self.settings:IsShown() then self:SyncSettings() else self:CancelBinding() end
        return
    end
    local panel=CreateFrame("Frame","PocketBuffsSettings",UIParent,"BackdropTemplate")
    self.settings=panel; panel:SetSize(690,650); panel:SetPoint("CENTER"); panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true); self:Backdrop(panel); panel:EnableMouse(true)
    panel:SetMovable(true); panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart",function(f) f:StartMoving() end)
    panel:SetScript("OnDragStop",function(f) f:StopMovingOrSizing() end)
    panel:SetScript("OnHide",function(f) f:StopMovingOrSizing(); self:CancelBinding(); self.dragItemID=nil; self:CancelGridDrag(); self:SyncGridEditing() end)
    table.insert(UISpecialFrames,"PocketBuffsSettings")
    local art=panel:CreateTexture(nil,"ARTWORK"); art:SetSize(70,70); art:SetPoint("TOPLEFT",18,-18); art:SetTexture(self.media.."PouchArt")
    self:Label(panel,"POCKETBUFFS",24,.96,.83,.60):SetPoint("TOPLEFT",103,-26)
    self:Label(panel,"GOOD THINGS. ALREADY IN YOUR BAGS.",10,.55,.60,.63):SetPoint("TOPLEFT",104,-56)
    self:Label(panel,"Drag the header or background to move this window.",10,.55,.60,.63):SetPoint("TOPLEFT",104,-78)
    self:QuietButton(panel,"x",24,function() panel:Hide() end):SetPoint("TOPRIGHT",-15,-15)
    local line=panel:CreateTexture(nil,"ARTWORK"); line:SetTexture(self.media.."Rail"); line:SetVertexColor(.84,.67,.36,.4)
    line:SetSize(650,1); line:SetPoint("TOPLEFT",20,-99)
    self.layoutTab=self:QuietButton(panel,"Layout",110,function() self:SelectSettingsTab("layout") end); self.layoutTab:SetPoint("TOPLEFT",22,-113)
    self.itemsTab=self:QuietButton(panel,"Items & Keys",140,function() self:SelectSettingsTab("items") end); self.itemsTab:SetPoint("TOPLEFT",140,-113)
    local layout=CreateFrame("Frame",nil,panel); self.layoutPage=layout
    local items=CreateFrame("Frame",nil,panel); self.itemsPage=items
    for _,page in ipairs({layout,items}) do page:SetSize(690,475); page:SetPoint("TOPLEFT",0,-153) end
    self:Label(layout,"Make a little room.",18):SetPoint("TOPLEFT",22,0)
    for i,preset in ipairs({{3,3,"3 x 3"},{1,8,"1 x 8"},{8,1,"8 x 1"},{4,2,"4 x 2"}}) do
        self:QuietButton(layout,preset[3],74,function()
            if self:CanChange() then self.db.columns=preset[1]; self.db.rows=preset[2]; self.page=1; self:Refresh() end
        end):SetPoint("TOPLEFT",22+(i-1)*82,-30)
    end
    self.layoutLabel=self:Label(layout,"",11,.6,.65,.68); self.layoutLabel:SetPoint("TOPLEFT",22,-66)
    for i,spec in ipairs({{"columns","Columns",1,8,1},{"rows","Rows",1,8,1},{"size","Icon size",20,56,2},{"gap","Spacing",0,16,1}}) do
        local x=22+(i-1)*160
        self:Label(layout,spec[2],11):SetPoint("TOPLEFT",x,-98)
        for j,delta in ipairs({-spec[5],spec[5]}) do
            self:QuietButton(layout,delta<0 and "-" or "+",30,function()
                if self:CanChange() then self.db[spec[1]]=math.max(spec[3],math.min(spec[4],self.db[spec[1]]+delta)); self:Refresh() end
            end):SetPoint("TOPLEFT",x+(j-1)*36,-118)
        end
    end
    self.lockButton=self:QuietButton(layout,"",130,function()
        if self:CanChange() then self.db.locked=not self.db.locked; self:Refresh() end
    end); self.lockButton:SetPoint("TOPLEFT",22,-158)
    self.logoButton=self:QuietButton(layout,"",130,function()
        if self:CanChange() then self.db.logo=not self.db.logo; self:Refresh() end
    end); self.logoButton:SetPoint("TOPLEFT",160,-158)
    self:Label(layout,"Show what matters.",18):SetPoint("TOPLEFT",22,-210)
    self.categoryChecks={}
    for i,key in ipairs(self.categories) do
        local c=CreateFrame("CheckButton",nil,layout,"UICheckButtonTemplate"); self.categoryChecks[key]=c
        c:SetSize(22,22); c:SetPoint("TOPLEFT",20+((i-1)%3)*218,-240-math.floor((i-1)/3)*28)
        self:Label(c,self.categoryNames[key],11):SetPoint("LEFT",c,"RIGHT",2,0)
        c:SetScript("OnClick",function()
            if self:CanChange() then self.db.enabled[key]=not self.db.enabled[key]; self:Refresh() else c:SetChecked(self.db.enabled[key]) end
        end)
    end
    self:Label(layout,"Unlock the grid to drag items into slots. Lock it to keep them in place.",12,.6,.65,.68):SetPoint("TOPLEFT",22,-374)
    self:Label(layout,"Cooldown numbers appear automatically. Bandages follow Recently Bandaged.",11,.6,.65,.68):SetPoint("TOPLEFT",22,-400)

    self:Label(items,"A place for everything.",18):SetPoint("TOPLEFT",22,0)
    self:Label(items,"Drag item icons or use arrows to reorder. Click Bind key, then press a key.",11,.6,.65,.68):SetPoint("TOPLEFT",22,-28)
    self.sortButtons={}
    for i,spec in ipairs({{"type","By type"},{"name","A - Z"},{"manual","My order"}}) do
        local b=self:QuietButton(items,spec[2],90,function() self:SetSortMode(spec[1]) end)
        b:SetPoint("TOPLEFT",22+(i-1)*98,-52); self.sortButtons[spec[1]]=b
    end
    self:Label(items,"Keys stay with the item, through sorting and page changes.",10,.6,.65,.68):SetPoint("TOPLEFT",22,-86)
    self.itemRows={}; self.listPage=1; self.rowsPerPage=9
    for i=1,self.rowsPerPage do
        local row={}; self.itemRows[i]=row
        row.frame=CreateFrame("Frame",nil,items); row.frame:SetSize(646,28); row.frame:SetPoint("TOPLEFT",22,-108-(i-1)*31)
        row.icon=CreateFrame("Button",nil,row.frame); row.icon:SetSize(24,24); row.icon:SetPoint("LEFT",0,0); row.icon:RegisterForDrag("LeftButton")
        row.art=row.icon:CreateTexture(nil,"ARTWORK"); row.art:SetAllPoints(); row.art:SetTexCoord(.08,.92,.08,.92)
        row.icon:SetScript("OnDragStart",function()
            if row.item and self:CanChange() then self.dragItemID=row.item.id; row.art:SetAlpha(.4) end
        end)
        row.icon:SetScript("OnDragStop",function() self:EndItemDrag() end)
        row.icon:SetScript("OnEnter",function(b)
            if not row.item then return end
            GameTooltip:SetOwner(b,"ANCHOR_TOP"); GameTooltip:SetText(row.item.name)
            GameTooltip:AddLine("Drag to another row to change its grid position.",.8,.8,.8,true); GameTooltip:Show()
        end)
        row.icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.label=self:Label(row.frame,"",11); row.label:SetPoint("LEFT",32,0); row.label:SetWidth(205); row.label:SetJustifyH("LEFT")
        row.up=self:QuietButton(row.frame,"<",26,function() if row.item then self:MoveItem(row.item.id,-1) end end); row.up:SetPoint("LEFT",244,0)
        row.down=self:QuietButton(row.frame,">",26,function() if row.item then self:MoveItem(row.item.id,1) end end); row.down:SetPoint("LEFT",274,0)
        row.bind=self:QuietButton(row.frame,"Bind key",128,function() self:StartBinding(row.item) end); row.bind:SetPoint("LEFT",310,0)
        row.favorite=self:QuietButton(row.frame,"Keep",76,function()
            if row.item then self:ToggleFavorite(row.item.id) end
        end); row.favorite:SetPoint("LEFT",446,0)
        row.ignore=self:QuietButton(row.frame,"Hide",76,function()
            if row.item and self:CanChange() then local id=row.item.id; self.db.ignored[id]=not self.db.ignored[id]; self:Refresh() end
        end); row.ignore:SetPoint("LEFT",530,0)
    end
    self:QuietButton(items,"<",28,function() self.listPage=math.max(1,self.listPage-1); self:SyncSettings() end):SetPoint("TOPLEFT",22,-399)
    self:QuietButton(items,">",28,function()
        self.listPage=math.min(math.max(1,math.ceil(#self:EditorItems()/self.rowsPerPage)),self.listPage+1); self:SyncSettings()
    end):SetPoint("TOPLEFT",57,-399)
    self.listStatus=self:Label(items,"",11,.6,.65,.68); self.listStatus:SetPoint("TOPLEFT",99,-406)
    self:Label(items,"Manual order wins over favorites. Hidden / filtered items are listed last.",10,.6,.65,.68):SetPoint("TOPLEFT",22,-438)
    self:Label(panel,"Missing something? /pbuff include ITEMID   |   /pbuff help",11,.6,.65,.68):SetPoint("BOTTOMLEFT",22,14)
    self:SelectSettingsTab("layout")
end

function P:SyncSettings()
    if not self.settings then return end
    local d=self.db
    self.layoutLabel:SetText(d.columns.." columns  /  "..d.rows.." rows  /  "..d.size.." px icons  /  "..d.gap.." px spacing")
    self.lockButton.label:SetText(d.locked and "Unlock position" or "Lock position")
    self.logoButton.label:SetText(d.logo and "Hide pouch icon" or "Show pouch icon")
    for key,c in pairs(self.categoryChecks) do c:SetChecked(d.enabled[key]) end
    for key,b in pairs(self.sortButtons) do b.label:SetText((d.sortMode==key and "+ " or "")..({type="By type",name="A - Z",manual="My order"})[key]) end
    local items=self:EditorItems()
    local pages=math.max(1,math.ceil(#items/self.rowsPerPage))
    self.listPage=math.min(self.listPage or 1,pages)
    for i,row in ipairs(self.itemRows) do
        local index=(self.listPage-1)*self.rowsPerPage+i
        row.item=items[index]; local item=row.item
        row.frame:SetShown(item~=nil)
        if item then
            local visible=not d.ignored[item.id] and d.enabled[item.category]
            row.label:SetText((visible and ((self:SlotForItem(item.id) or index)..". ") or "[Hidden] ")..item.name.."  x"..item.count)
            row.art:SetTexture(item.icon); row.art:SetAlpha(self.dragItemID==item.id and .4 or 1)
            row.up:SetShown(visible); row.down:SetShown(visible)
            row.bind.label:SetText(self:BindingLabel(item.id))
            row.favorite.label:SetText(d.favorites[item.id] and "Kept +" or "Keep")
            row.ignore.label:SetText(d.ignored[item.id] and "Restore" or "Hide")
        end
    end
    self.listStatus:SetText(#items.." item types  /  "..self.listPage.." of "..pages)
    self:SyncGridEditing()
end
