local _, P = ...

function P:SetAppearance(style)
    if not self:CanChange() then return end
    self.db.appearance=style=="trim" and "trim" or "minimal"
    self:Refresh()
end

function P:CreateBagTrim()
    local f=CreateFrame("Frame",nil,self.frame)
    self.bagTrim=f; f:EnableMouse(false); f:SetFrameLevel(self.frame:GetFrameLevel())
    f.parts={}
    for _,name in ipairs({"TL","TR","BL","BR","Top","Bottom","Left","Right","Tab"}) do
        local t=f:CreateTexture(nil,"ARTWORK"); f.parts[name]=t
        t:SetHorizTile(false); t:SetVertTile(false)
        if name=="Tab" then t:SetTexture(self.media.."BagLeatherTab","CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE") end
    end
    f:Hide()
end

function P:LayoutAppearance(items)
    local d=self.db; local trim=self.bagTrim
    local minCol,minRow,maxCol,maxRow=d.columns,d.rows,-1,-1
    for slot,item in pairs(items) do
        if item then
            local col,row=(slot-1)%d.columns,math.floor((slot-1)/d.columns)
            minCol=math.min(minCol,col); maxCol=math.max(maxCol,col)
            minRow=math.min(minRow,row); maxRow=math.max(maxRow,row)
        end
    end
    local active=d.appearance=="trim" and maxCol>=0
    trim:SetShown(active)
    self.launcher:ClearAllPoints(); self.anchor:ClearAllPoints(); self.pager:ClearAllPoints()
    if not active then
        self.launcher:SetSize(18,18); self.launcher:SetAlpha(.7)
        self.launcher:SetPoint("BOTTOMRIGHT",self.frame,"TOPRIGHT",0,5)
        self.anchor:SetPoint("BOTTOMLEFT",self.frame,"TOPLEFT",0,4)
        self.anchor:SetWidth(math.max(16,d.columns*(d.size+d.gap)-d.gap-24))
        self.pager:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",0,-4)
        return
    end
    local stride=d.size+d.gap
    local x,y=minCol*stride,minRow*stride
    local width=(maxCol-minCol)*stride+d.size
    local height=(maxRow-minRow)*stride+d.size
    trim:ClearAllPoints(); trim:SetPoint("TOPLEFT",self.frame,"TOPLEFT",x-20,20-y)
    trim:SetSize(width+40,height+40)
    local p=trim.parts
    local columns,rows=maxCol-minCol+1,maxRow-minRow+1
    local skin="BagSkin"..columns.."x"..rows
    local sourceWidth,sourceHeight=columns*36+36,rows*36+36
    local textureWidth,textureHeight=64,64
    while textureWidth<sourceWidth do textureWidth=textureWidth*2 end
    while textureHeight<sourceHeight do textureHeight=textureHeight*2 end
    trim.skin=skin
    local function art(t,left,top,right,bottom)
        t:SetTexture(self.media..skin,"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE")
        t:SetTexCoord(left/textureWidth,right/textureWidth,top/textureHeight,bottom/textureHeight)
    end
    for _,spec in ipairs({{"TL","TOPLEFT",0,0},{"TR","TOPRIGHT",sourceWidth-28,0},{"BL","BOTTOMLEFT",0,sourceHeight-28},{"BR","BOTTOMRIGHT",sourceWidth-28,sourceHeight-28}}) do
        local t=p[spec[1]]; t:ClearAllPoints(); t:SetPoint(spec[2],trim,spec[2],0,0); t:SetSize(28,28)
        art(t,spec[3],spec[4],spec[3]+28,spec[4]+28)
    end
    local function edge(t,point,dx,dy,w,h,left,top,right,bottom)
        -- Sample each complete, layout-specific edge once. Never repeat its folds.
        t:ClearAllPoints(); t:SetPoint(point,trim,point,dx,dy); t:SetSize(w,h)
        art(t,left,top,right,bottom)
    end
    edge(p.Top,"TOPLEFT",28,0,width-16,28,28,0,sourceWidth-28,28)
    edge(p.Bottom,"BOTTOMLEFT",28,0,width-16,28,28,sourceHeight-28,sourceWidth-28,sourceHeight)
    edge(p.Left,"TOPLEFT",0,-28,28,height-16,0,28,28,sourceHeight-28)
    edge(p.Right,"TOPRIGHT",0,-28,28,height-16,sourceWidth-28,28,sourceWidth,sourceHeight-28)
    p.Tab:ClearAllPoints(); p.Tab:SetPoint("TOP",trim,"BOTTOM",0,8); p.Tab:SetSize(36,36)
    p.Tab:SetAlpha(d.logo and 1 or 0)
    self.launcher:SetSize(24,24); self.launcher:SetAlpha(.95)
    self.launcher:SetPoint("CENTER",trim,"BOTTOM",0,-10)
    self.anchor:SetPoint("BOTTOMLEFT",self.frame,"TOPLEFT",x,24-y)
    self.anchor:SetWidth(math.max(16,width-24)); self.anchor:SetShown(not d.locked and width>=64)
    self.pager:SetPoint("TOPLEFT",self.frame,"TOPLEFT",x,-y-height-(d.logo and 58 or 26))
end
