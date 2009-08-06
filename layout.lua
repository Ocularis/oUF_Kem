--[[
	
	oUF_Kem

	Author:		Ocularis
	Mail:		andreas.ocularis@gmail.com
	URL:		
	
	Credits:
				Rothar for buff border (and Neal for the edited version)
				p3lim for party toggle function (Party is commented out though)
				Lyn for base, TsoHG as initial Base.
--]]

-- ------------------------------------------------------------------------
-- local horror
-- ------------------------------------------------------------------------
local select = select
local UnitClass = UnitClass
local UnitIsDead = UnitIsDead
local UnitIsPVP = UnitIsPVP
local UnitIsGhost = UnitIsGhost
local UnitIsPlayer = UnitIsPlayer
local UnitReaction = UnitReaction
local UnitIsConnected = UnitIsConnected
local UnitCreatureType = UnitCreatureType
local UnitClassification = UnitClassification
local UnitReactionColor = UnitReactionColor
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

-- ------------------------------------------------------------------------
-- font, fontsize and textures
-- ------------------------------------------------------------------------
local font = "Interface\\AddOns\\oUF_Kem\\fonts\\font.ttf"
local upperfont = "Interface\\AddOns\\oUF_Kem\\fonts\\upperfont.ttf"
local fontsize = 9
local bartex = "Interface\\AddOns\\oUF_Kem\\textures\\dP"
local bufftex = "Interface\\AddOns\\oUF_Kem\\textures\\border"
local playerClass = select(2, UnitClass("player"))
local ClassColor = false
local ClassColorMana = true
local OwnColor = { 0.306, 0.396, 0.322 }
local OwnPowerColor = { 0.2, 0.2, 1 }

-- castbar position
local playerCastBar_x = 0
local playerCastBar_y = -300
local targetCastBar_x = 11
local targetCastBar_y = -200

-- ------------------------------------------------------------------------
-- change some colors :)
-- ------------------------------------------------------------------------
oUF.colors.happiness = {
	[1] = {182/225, 34/255, 32/255},	-- unhappy
	[2] = {220/225, 180/225, 52/225},	-- content
	[3] = {143/255, 194/255, 32/255},	-- happy
}

local corb = 1
local cogb = 0
local cobb = 0

-- ------------------------------------------------------------------------
-- right click
-- ------------------------------------------------------------------------
local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

-- ------------------------------------------------------------------------
-- reformat everything above 9999, i.e. 10000 -> 10k
-- ------------------------------------------------------------------------
local numberize = function(v)
	if v <= 9999 then return v end
	if v >= 1000000 then
		local value = string.format("%.1fm", v/1000000)
		return value
	elseif v >= 10000 then
		local value = string.format("%.1fk", v/1000)
		return value
	end
end

-- ------------------------------------------------------------------------
-- level update
-- ------------------------------------------------------------------------
local updateLevel = function(self, unit, name)
	local lvl = UnitLevel(unit)
	local typ = UnitClassification(unit)
	
	local color = GetQuestDifficultyColor(lvl)  
	
	if lvl <= 0 then	lvl = "??" end
            
	if typ=="worldboss" then
	    self.Level:SetText("|cffff0000"..lvl.."b|r")
	elseif typ=="rareelite" then
	    self.Level:SetText(lvl.."r+")
		self.Level:SetTextColor(color.r, color.g, color.b)
	elseif typ=="elite" then
	    self.Level:SetText(lvl.."+")
		self.Level:SetTextColor(color.r, color.g, color.b)
	elseif typ=="rare" then
		self.Level:SetText(lvl.."r")
		self.Level:SetTextColor(color.r, color.g, color.b)
	else
		if UnitIsConnected(unit) == nil then
			self.Level:SetText("??")
		else
			self.Level:SetText(lvl)
		end
		if(not UnitIsPlayer(unit)) then  
			self.Level:SetTextColor(color.r, color.g, color.b)
		else
			local _, class = UnitClass(unit) 
			color = self.colors.class[class] 
			self.Level:SetTextColor(color[1], color[2], color[3])  
		end			
	end
end

-- ------------------------------------------------------------------------
-- name update
-- ------------------------------------------------------------------------
local updateName = function(self, event, unit)
	if(self.unit ~= unit) then return end

	local name = UnitName(unit)
    self.Name:SetText(string.lower(name))
	
	if unit=="targettarget" then
		local totName = UnitName(unit)
		local pName = UnitName("player")
		if totName==pName then
			self.Name:SetTextColor(0.9, 0.5, 0.2)
		else
			self.Name:SetTextColor(1,1,1)
		end
	else
		self.Name:SetTextColor(1,1,1)
	end
	   
    if unit=="target" then -- Show level value on targets only
		updateLevel(self, unit, name)      
    end
end

-- ------------------------------------------------------------------------
-- health update
-- ------------------------------------------------------------------------
local updateHealth = function(self, event, unit, bar, min, max)  
    local cur, maxhp = min, max
    
    local d = floor(cur/maxhp*100)
    
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText"dead"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"offline"
    elseif(unit == "player") then
		if(min ~= max) then
			bar.value:SetText("|cff00FFFF"..numberize(cur))
		else
			bar.value:SetText("|cff00FFFF"..numberize(cur))
		end
	elseif(unit == "targettarget") then
		bar.value:SetText(d.."%")
    elseif(unit == "target") then
		if(d < 100) then
			bar.value:SetText("|cff00FFFF"..numberize(cur))
		else
			bar.value:SetText("|cff00FFFF"..numberize(cur))
		end

	elseif(min == max) then
        if unit == "pet" then
			bar.value:SetText(" ") -- just here if otherwise wanted
		else
			bar.value:SetText(" ")
		end
    else
        if((max-min) < max) then
			if unit == "pet" then
				bar.value:SetText("-"..maxhp-cur) -- negative values as for party, just here if otherwise wanted
			else
				bar.value:SetText("-"..maxhp-cur) -- this makes negative values (easier as a healer)
			end
	    end
    end

	
if(ClassColor==true) then   -- determine what color to use
        if(UnitIsPlayer(unit)) then
            local _, englass = UnitClass(unit)
            if(self.colors.class[englass]) then
                r, g, b = unpack(self.colors.class[englass])
            end
        else
            r, g, b = UnitSelectionColor(unit)
        end
    else
        r, g, b = unpack(OwnColor)
    end
    
    if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then  -- grey color for tapped mobs
        r, g, b = .6, .6, .6
    end
	
    bar:SetStatusBarColor(r, g, b)          -- hp bar coloring
    bar.bg:SetVertexColor(r, g, b, .2)      -- hp background - same color but 20% opacity
    if(self.Castbar) then                   -- same with castbar
        self.Castbar:SetStatusBarColor(r, g, b)
        self.Castbar.bg:SetVertexColor(r, g, b, .2)
    end

	
    self:UNIT_NAME_UPDATE(event, unit)
end


-- ------------------------------------------------------------------------
-- power update
-- ------------------------------------------------------------------------
local updatePower = function(self, event, unit, bar, min, max)  
	if UnitIsPlayer(unit)==nil then 
		bar.value:SetText()
	else
		local _, ptype = UnitPowerType(unit)
		local color = oUF.colors.power[ptype]
		if(min==0) then 
			bar.value:SetText()
		elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
			bar:SetValue(0)
		elseif(not UnitIsConnected(unit)) then
			bar.value:SetText()
		elseif unit=="player" then 
			if((max-min) > 0) then
	            bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			elseif(min==max) then
				bar.value:SetText("")
	        else
				bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			end
        else
			if((max-min) > 0) then
				bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			else
				bar.value:SetText(min)
				if color then
					bar.value:SetTextColor(color[1], color[2], color[3])
				else
					bar.value:SetTextColor(0.2, 0.66, 0.93)
				end
			end
		end
	end
	
	
	if(ClassColorMana==true) then   -- determine what color to use
        if(UnitIsPlayer(unit)) then
            local _, englass = UnitClass(unit)
            if(self.colors.class[englass]) then
                r, g, b = unpack(self.colors.class[englass])
            end
        else
            r, g, b = UnitSelectionColor(unit)
        end
    else
        r, g, b = unpack(OwnPowerColor)
    end
	
 bar:SetStatusBarColor(r, g, b)
 bar.bg:SetVertexColor(r, g, b, .2)
end


-- ------------------------------------------------------------------------
-- aura reskin
-- ------------------------------------------------------------------------
local auraIcon = function(self, button, icons)
	icons.showDebuffType = true -- show debuff border type color  
	
	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
	
	button.overlay:SetTexture(bufftex)
	button.overlay:SetTexCoord(0,1,0,1)
	button.overlay.Hide = function(self) self:SetVertexColor(0.3, 0.3, 0.3) end

	button.cd:SetReverse()
	button.cd:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2) 
	button.cd:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)     
end

-- ------------------------------------------------------------------------
-- the layout starts here
-- ------------------------------------------------------------------------
local func = function(self, unit)
	self.menu = menu -- Enable the menus

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
    
	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	--
	-- background
	--
	self:SetBackdrop{
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
	insets = {left = -1, right = -1, top = -1, bottom = -1},
	}
	self:SetBackdropColor(0,0,0,1) -- and color the backgrounds
    
	--
	-- healthbar
	--
	self.Health = CreateFrame"StatusBar"
	self.Health:SetHeight(8) -- Custom height
	self.Health:SetStatusBarTexture(bartex)
    self.Health:SetParent(self)
	self.Health:SetPoint"BOTTOM"
	self.Health:SetPoint"LEFT"
	self.Health:SetPoint"RIGHT"
	self.Health.frequentUpdates = true

	--
	-- healthbar background
	--
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(bartex)
	self.Health.bg:SetAlpha(0.30)  
	
	--
	-- healthbar text
	--
	self.Health.value = self.Health:CreateFontString(nil, "OVERLAY")
	self.Health.value:SetPoint("RIGHT", 0, 0)
	self.Health.value:SetFont(upperfont, 9, "OUTLINE")
	self.Health.value:SetTextColor(1,1,1)
	self.Health.value:SetShadowOffset(1, -1)

	--
	-- healthbar functions
	--
	self.Health.colorClass = true 
	self.Health.colorReaction = true
	self.Health.colorDisconnected = false 
	self.Health.colorTapping = false  
	self.PostUpdateHealth = updateHealth -- let the colors be  

	--
	-- powerbar
	--
	self.Power = CreateFrame"StatusBar"
	self.Power:SetHeight(2)
	self.Power:SetStatusBarTexture(bartex)
	self.Power:SetParent(self)
	self.Power:SetPoint"TOP"
	self.Power:SetPoint"LEFT"
	self.Power:SetPoint"RIGHT"

	--
	-- powerbar background
	--
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(bartex)
	self.Power.bg:SetAlpha(0.30)  

	--
	-- powerbar text
	--
	self.Power.value = self.Power:CreateFontString(nil, "OVERLAY")
    self.Power.value:SetPoint("RIGHT", self.Health.value, "RIGHT", 0, 0) -- powerbar text in health box
	self.Power.value:SetFont(font, fontsize, "OUTLINE")
	self.Power.value:SetTextColor(1,1,1)
	self.Power.value:SetShadowOffset(1, -1)
    self.Power.value:Hide()
    
    --
	-- powerbar functions
	--
	self.Power.colorTapping = true 
	self.Power.colorDisconnected = true 
	self.Power.colorClass = true 
	self.Power.colorPower = true 
	self.Power.colorHappiness = false
	self.Power.frequentUpdates = true	
	self.PostUpdatePower = updatePower -- let the colors be  

	--
	-- names
	--
	self.Name = self.Health:CreateFontString(nil, "OVERLAY")
    self.Name:SetPoint("CENTER", self, 0, 9)
    self.Name:SetJustifyH"CENTER"
	self.Name:SetFont(font, fontsize, "OUTLINE")
	self.Name:SetShadowOffset(1, -1)
    self.UNIT_NAME_UPDATE = updateName

	--
	-- level
	--
	self.Level = self.Health:CreateFontString(nil, "OVERLAY")
	self.Level:SetPoint("RIGHT", self.Health, 0, -9)
	self.Level:SetJustifyH("LEFT")
	self.Level:SetFont(font, fontsize, "OUTLINE")
    self.Level:SetTextColor(1,1,1)
	self.Level:SetShadowOffset(1, -1)
	self.UNIT_LEVEL = updateLevel
	
	-- ------------------------------------	
	-- oUF_Smooth support for all frames
	-- ------------------------------------	
		if(unit) or (self:GetParent():GetName():match"oUF_Raid") or (self:GetParent():GetName():match"oUF_Party") then 
		self.Power.Smooth = true
		self.Health.Smooth = true
		end
	
	-- ------------------------------------
	-- player
	-- ------------------------------------
    if unit=="player" then
        self:SetWidth(285)
      	self:SetHeight(14.5)
		self.Health:SetHeight(11.5)
		self.Name:Hide()
		self.Health.value:ClearAllPoints()
		self.Health.value:SetPoint("RIGHT", 0, 19)
	    self.Power.value:ClearAllPoints()
		self.Power:SetHeight(2.5)
        self.Power.value:Show()
		self.Power.value:SetPoint("LEFT", 0, 13)
		self.Level:Hide()
--[[	self.Portrait = CreateFrame('PlayerModel', nil, self)
		self.Portrait.type = '3D'
		self.Portrait:SetAlpha(0.8)
		self.Portrait:SetPoint('TOPLEFT', self, 'TOPLEFT', -55, 15)
		self.Portrait:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -205, -55)
		self.Portrait:SetFrameStrata(BACKGROUND)
		self.Portraitbg2 = self.Portrait:CreateTexture(nil, "BORDER")
--]]
--		self.Portraitbg2:SetTexture[[Interface\AddOns\oUF_Kem\textures\unitcolorbordertga.tga]]
--[[        self.Portraitbg2:SetPoint("TOPLEFT",self.Portrait,"TOPLEFT",-7,7)
        self.Portraitbg2:SetPoint("BOTTOMRIGHT",self.Portrait,"BOTTOMRIGHT",7,-7)
		self.Portraitbg2:SetAlpha(.7)
		self.Portraitbg2:SetDrawLayer("BORDER")
		self.Portraitoverlay = self.Portrait:CreateTexture(nil, "OVERLAY")
        self.Portraitoverlay:SetPoint("TOPLEFT",self.Portrait,"TOPLEFT",-5,5)
        self.Portraitoverlay:SetPoint("BOTTOMRIGHT",self.Portrait,"BOTTOMRIGHT",5,-5)
--]]
    --    self.Portraitoverlay:SetTexture[[Interface\AddOns\oUF_Kem\textures\unitborder.tga]]
--[[		self.Portraitoverlay:SetVertexColor(0.6, 0.6, 0.6) 
        self.Portraitoverlay:SetDrawLayer("OVERLAY")
--]]
		self.Health.colorClass = true

		
		--[[
		if(playerClass=="DRUID") then
			-- bar
			self.DruidMana = CreateFrame('StatusBar', nil, self)
			self.DruidMana:SetPoint('TOP', self, 'BOTTOM', 0, -6)
			self.DruidMana:SetStatusBarTexture(bartex)
			self.DruidMana:SetStatusBarColor(45/255, 113/255, 191/255)
			self.DruidMana:SetHeight(10)
			self.DruidMana:SetWidth(250)
			-- bar bg
			self.DruidMana.bg = self.DruidMana:CreateTexture(nil, "BORDER")
			self.DruidMana.bg:SetAllPoints(self.DruidMana)
			self.DruidMana.bg:SetTexture(bartex)
			self.DruidMana.bg:SetAlpha(0.30)  
			-- black bg
			self.DruidMana:SetBackdrop{
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
				insets = {left = -2, right = -2.5, top = -2.5, bottom = -2},
				}
			self.DruidMana:SetBackdropColor(0,0,0,1)
			-- text
			self.DruidManaText = self.DruidMana:CreateFontString(nil, 'OVERLAY')
			self.DruidManaText:SetPoint("CENTER", self.DruidMana, "CENTER", 0, 1)
			self.DruidManaText:SetFont(font, 12, "OUTLINE")
			self.DruidManaText:SetTextColor(1,1,1)
			self.DruidManaText:SetShadowOffset(1, -1)
		end
		--]]
		
		--
		-- leader icon
		--
		self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
		self.Leader:SetHeight(12)
		self.Leader:SetWidth(12)
		self.Leader:SetPoint("BOTTOMRIGHT", self, -2, 4)
		self.Leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("TOP", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
        
		--
		-- oUF_PowerSpark support
		--
        self.Spark = self.Power:CreateTexture(nil, "OVERLAY")
		self.Spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		self.Spark:SetVertexColor(1, 1, 1, 1)
		self.Spark:SetBlendMode("ADD")
		self.Spark:SetHeight(self.Power:GetHeight()*2.5)
		self.Spark:SetWidth(self.Power:GetHeight()*2)
        -- self.Spark.rtl = true -- Make the spark go from Right To Left instead
		-- self.Spark.manatick = true -- Show mana regen ticks outside FSR (like the energy ticker)
		-- self.Spark.highAlpha = 1 	-- What alpha setting to use for the FSR and energy spark
		-- self.Spark.lowAlpha = 0.25 -- What alpha setting to use for the mana regen ticker
		
		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end



	
	-- ------------------------------------
	-- pet
	-- ------------------------------------
	if unit=="pet" then
		self:SetWidth(121)
		self:SetHeight(11)
		self.Health:SetHeight(10)
		self.Health:SetWidth(119)
		self.Power:Hide()
		self.Power.value:Hide()
		self.Health.value:Hide()
		self.Name:SetWidth(95)
		self.Name:SetHeight(18)
		
		if playerClass=="HUNTER" then
			self.Health.colorReaction = false
			self.Health.colorClass = false
			self.Health.colorHappiness = true  
		end
		
		--
		-- oUF_BarFader
		--
		self.BarFade = true
		self.BarFadeAlpha = 0.2
	end
	
	-- ------------------------------------
	-- target
	-- ------------------------------------
    if unit=="target" then
		self:SetWidth(285)
		self:SetHeight(14.5)
		self.Health:SetHeight(11.5)
		self.Power:SetHeight(2)
		self.Power.value:Hide()
		self.Health.value:ClearAllPoints()
		self.Health.value:SetPoint("LEFT", 0, 19)
		self.Level:ClearAllPoints()
		self.Level:SetPoint("RIGHT", self.Name, "LEFT",  0, 0)
		self.Name:ClearAllPoints()
		self.Name:SetPoint("RIGHT", 0, 19)
		
			
		self.Health.colorClass = false
		
		--
		-- combo points
		--
		if(playerClass=="ROGUE" or playerClass=="DRUID") then
			self.CPoints = self:CreateFontString(nil, "OVERLAY")
			self.CPoints:SetPoint("RIGHT", self, "LEFT", -10, 0)
			self.CPoints:SetFont(font, 38, "OUTLINE")
			self.CPoints:SetTextColor(0, 0.81, 1)
			self.CPoints:SetShadowOffset(1, -1)
			self.CPoints:SetJustifyH"RIGHT" 
		end
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("RIGHT", self, 30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		
		--
		-- buffs
		--
		self.Buffs = CreateFrame("Frame", nil, self) -- buffs
		self.Buffs.size = 22
		self.Buffs:SetHeight(self.Buffs.size)
		self.Buffs:SetWidth(self.Buffs.size * 4)
		self.Buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", -2, 17)
		self.Buffs.initialAnchor = "BOTTOMLEFT"
		self.Buffs["growth-y"] = "TOP"
		self.Buffs.num = 20
		self.Buffs.spacing = 2
		
		--
		-- debuffs
		--
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs.size = 28
		self.Debuffs:SetHeight(self.Debuffs.size)
		self.Debuffs:SetWidth(self.Debuffs.size * 9)
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", -2, -6)
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-y"] = "DOWN"
		self.Debuffs.filter = false
		self.Debuffs.num = 40
		self.Debuffs.spacing = 2
		self.Debuffs.onlyShowPlayer = true
		
		--
		-- Portraits
		--
		
--[[		self.Portrait = CreateFrame('PlayerModel', nil, self)
		self.Portrait.type = '3D'
		self.Portrait:SetAlpha(0.8)
		self.Portrait:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 55, 15)
		self.Portrait:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 205, -55)
		self.Portrait:SetFrameStrata(BACKGROUND)
		
	self.Portraitbg2 = self.Portrait:CreateTexture(nil, "BORDER")
	--]]	--self.Portraitbg2:SetTexture[[Interface\AddOns\oUF_Kem\textures\unitcolorbordertga2.tga]]
--[[        self.Portraitbg2:SetPoint("TOPRIGHT",self.Portrait,"TOPRIGHT",7,7)
        self.Portraitbg2:SetPoint("BOTTOMLEFT",self.Portrait,"BOTTOMLEFT",-7,-7)
		self.Portraitbg2:SetAlpha(.7)
		self.Portraitbg2:SetDrawLayer("BORDER")
		self.Portraitoverlay = self.Portrait:CreateTexture(nil, "OVERLAY")
        self.Portraitoverlay:SetPoint("TOPRIGHT",self.Portrait,"TOPRIGHT",5,5)
        self.Portraitoverlay:SetPoint("BOTTOMLEFT",self.Portrait,"BOTTOMLEFT",-5,-5)
    --]]
	--self.Portraitoverlay:SetTexture[[Interface\AddOns\oUF_Kem\textures\unitborder2.tga]]
	--[[	self.Portraitoverlay:SetVertexColor(0.6, 0.6, 0.6) 
        self.Portraitoverlay:SetDrawLayer("OVERLAY")
	--]]	self.Health.colorClass = true
	
	end
	
	-- ------------------------------------
	-- target of target and focus
	-- ------------------------------------
	if unit=="targettarget" or unit=="focus" then
		self:SetWidth(121)
		self:SetHeight(11)
		self.Health:SetHeight(10)
		self.Health:SetWidth(119)
		self.Power:Hide()
		self.Power.value:Hide()
		self.Health.value:Hide()
		self.Name:SetWidth(95)
		self.Name:SetHeight(18)
		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(16)
		self.RaidIcon:SetWidth(16)
		self.RaidIcon:SetPoint("RIGHT", self, 0, 9)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
		
		--
		-- oUF_BarFader
		--
		if unit=="focus" then
			self.BarFade = true
			self.BarFadeAlpha = 0.2
		end
	end
	
	
	-- ------------------------------------
	-- party 
	-- ------------------------------------
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetWidth(60)
		self:SetHeight(16)
		self.Health:SetHeight(13)
		self.Power:SetHeight(2)
		self.Power.value:Hide()
		self.Health.value:SetPoint("RIGHT", 0 , 20)
		self.Name:Hide()


		
		--
		-- raid target icons
		--
		self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.RaidIcon:SetHeight(24)
		self.RaidIcon:SetWidth(24)
		self.RaidIcon:SetPoint("LEFT", self, -30, 0)
		self.RaidIcon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	end

	-- ------------------------------------
	-- raid 
	-- ------------------------------------
    if(self:GetParent():GetName():match"oUF_Raid") then
		self:SetWidth(86) 
		self:SetHeight(12)
		self.Health:SetHeight(12)
		self.Power:Hide()
		self.Health:SetFrameLevel(2) 
		self.Power:SetFrameLevel(2)
		self.Power.value:Hide()
		self.Name:Hide()
		self.Health.value:ClearAllPoints()
		self.Health.value:SetFont(font, 9, "OUTLINE")
		self.Health.value:SetWidth(40)
		self.Health.value:SetHeight(15)
		self.Health.value:SetPoint("RIGHT", 0 , 7)


		--
		-- oUF_DebuffHighlight support
		--
		self.DebuffHighlight = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlight:SetAllPoints(self.Health)
		self.DebuffHighlight:SetTexture("Interface\\AddOns\\oUF_Kem\\textures\\highlight.tga")
		self.DebuffHighlight:SetBlendMode("ADD")
		self.DebuffHighlight:SetVertexColor(0, 0, 0, 0)
		self.DebuffHighlightAlpha = 0.8
		self.DebuffHighlightFilter = true
    end
    
	--
	-- fading for party and raid
	--
	if(not unit) then -- fadeout if units are out of range
		self.Range = true -- put true to make party/raid frames fade out if not in your range
		self.inRangeAlpha = 1.0 -- what alpha if IN range
		self.outsideRangeAlpha = 0.5 -- the alpha it will fade out to if not in range
   	end

	--
	-- custom aura textures
	--
	self.PostCreateAuraIcon = auraIcon
	self.SetAuraPosition = auraOffset
	
	if(self:GetParent():GetName():match"oUF_Party") then
		self:SetAttribute('initial-height', 16) 
		self:SetAttribute('initial-width', 91) 
	else 
		self:SetAttribute('initial-height', height) 
		self:SetAttribute('initial-width', width) 
	end  
	
	return self   
end

-- ------------------------------------------------------------------------
-- spawning the frames
-- ------------------------------------------------------------------------

--
-- normal frames
--
oUF:RegisterStyle("Lyn", func)

oUF:SetActiveStyle("Lyn")
local player = oUF:Spawn("player", "oUF_Player")
player:SetPoint("CENTER", -350, -153)
local target = oUF:Spawn("target", "oUF_Target")
target:SetPoint("CENTER", 350, -153) 
local pet = oUF:Spawn("pet", "oUF_Pet")
pet:SetPoint("TOPLEFT", player, 61, 37) 
local tot = oUF:Spawn("targettarget", "oUF_TargetTarget")
tot:SetPoint("TOPRIGHT", target, -60, 37)
local focus	= oUF:Spawn("focus", "oUF_Focus")
focus:SetPoint("TOPLEFT", player, 61, 37) 


-- party

local party	= oUF:Spawn("header", "oUF_Party")
party:SetManyAttributes("showParty", true, "xOffset", 7)
party:SetPoint("CENTER", 0, -330)
party:Show()
party:SetAttribute("showRaid", false)
party:SetAttribute("point", "LEFT")



-- raid

--[[local Raid = {}
for i = 1, NUM_RAID_GROUPS do
	local RaidGroup = oUF:Spawn("header", "oUF_Raid" .. i)
	RaidGroup:SetAttribute("groupFilter", tostring(i))
	RaidGroup:SetAttribute("showRaid", true)
	RaidGroup:SetAttribute("yOffset", -5)
	RaidGroup:SetAttribute("point", "TOP")
	RaidGroup:SetAttribute("showRaid", true)
	table.insert(Raid, RaidGroup)
	if i == 1 then
		RaidGroup:SetPoint("TOPLEFT", UIParent, 27, -135) 
	else
		RaidGroup:SetPoint("TOP", Raid[i-1], "BOTTOM", 0, -5)	
	end
	RaidGroup:Show()
end

--]]

--
-- party toggle in raid
--
local partyToggle = CreateFrame('Frame')
partyToggle:RegisterEvent('PLAYER_LOGIN')
partyToggle:RegisterEvent('RAID_ROSTER_UPDATE')
partyToggle:RegisterEvent('PARTY_LEADER_CHANGED')
partyToggle:RegisterEvent('PARTY_MEMBER_CHANGED')
partyToggle:SetScript('OnEvent', function(self)
	if(InCombatLockdown()) then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	else
		self:UnregisterEvent('PLAYER_REGEN_DISABLED')
		if(HIDE_PARTY_INTERFACE == "1" and GetNumRaidMembers() > 0) then
			party:Hide()
		else
			party:Show()
		end
	end
end)
