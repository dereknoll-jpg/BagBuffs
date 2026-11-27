local _, P = ...

function P:ToggleItemMenu(item,button)
    if not item or not self:CanChange() then return end
    local menu=self.itemMenu
    if menu and menu:IsShown() and menu.item.id==item.id then menu:Hide(); return end
    if self.pouchMenu then self.pouchMenu:Hide() end
    GameTooltip:Hide()
    if not menu then
        menu=CreateFrame("Frame","BagBuffsItemMenu",UIParent,"BackdropTemplate"); self.itemMenu=menu
        menu:SetSize(224,202); menu:SetFrameStrata("DIALOG"); menu:SetClampedToScreen(true)
        menu:EnableMouse(true); self:Backdrop(menu); table.insert(UISpecialFrames,"BagBuffsItemMenu")
        menu.title=self:Label(menu,"",12,.94,.78,.47)
        menu.title:SetPoint("TOPLEFT",12,-12); menu.title:SetSize(200,28); menu.title:SetJustifyH("LEFT")
        menu.commands={}
        local function action(key,title,row,callback)
            local b=self:QuietButton(menu,title,200,function()
                local target=menu.item; menu:Hide(); callback(target)
            end)
            b:SetPoint("TOPLEFT",12,-46-(row-1)*29); menu.commands[key]=b; return b
        end
        action("favorite","",1,function(target) self:ToggleFavorite(target.id) end)
        action("bind","Bind key...",2,function(target) self:StartBinding(target) end)
        action("hide","Hide item",3,function(target) self:HideGridItem(target) end)
        action("settings","Settings",4,function()
            if not self.settings or not self.settings:IsShown() then self:ToggleSettings() end
            self:SelectSettingsTab("items")
        end)
        action("close","Close",5,function() end)
    end
    menu.item=item; menu.title:SetText(item.name)
    menu.commands.favorite.label:SetText(self.db.favorites[item.id] and "Remove favorite" or "Favorite item")
    menu:ClearAllPoints(); menu:SetPoint("TOPLEFT",button,"TOPRIGHT",6,0); menu:Show()
end
