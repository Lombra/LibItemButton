local lib = LibStub:NewLibrary("LibItemButton", 4)

if not lib then return end

local GetItemInfo = GetItemInfo

lib.callbacks = lib.callbacks or { }

lib.frame = lib.frame or CreateFrame("Frame")
lib.frame:SetScript("OnEvent", lib.frame.Show)
lib.frame:SetScript("OnUpdate", onUpdate)
lib.frame:Hide()

lib.buttonRegistry = lib.buttonRegistry or { }
lib.buttonCategory = lib.buttonCategory or { }
lib.buttonItems = lib.buttonItems or { }

function lib:RegisterButton(button, category)
	self.buttonRegistry[button] = true
	self.buttonCategory[button] = category
	self:Fire("OnButtonRegistered", button, category)
end

function lib:UpdateButton(button, item)
	-- if item == self.buttonItems[button] then return end
	self.buttonItems[button] = item
	self:Fire("OnButtonUpdate", button, item, self.buttonCategory[button])
end

function lib:GetRegisteredButtons(category)
	return self.buttonRegistry
end

function lib:GetButtonCategory(button)
	return self.buttonCategory[button]
end

function lib:Fire(event, ...)
	if not self.callbacks[event] then return end
	for k, v in pairs(self.callbacks[event]) do
		v(k, ...)
	end
end

function lib:RegisterInitCallback(target, callback, category)
	if type(callback) == "string" then
		callback = target[callback]
	end
	
	for button in pairs(self:GetRegisteredButtons()) do
		local category2 = self.buttonCategory[button]
		if not category or category2 == category then
			callback(target, button, category2)
		end
	end
	
	self.callbacks["OnButtonRegistered"] = self.callbacks["OnButtonRegistered"] or {}
	self.callbacks["OnButtonRegistered"][target] = callback
end

function lib:RegisterUpdateCallback(target, callback, category)
	if type(callback) == "string" then
		callback = target[callback]
	end
	
	self.callbacks["OnButtonUpdate"] = self.callbacks["OnButtonUpdate"] or {}
	self.callbacks["OnButtonUpdate"][target] = callback
end

function lib:ComplementButton(button, icon, count, stock, searchOverlay, border)
	if not button.icon then
		if icon then
			button.icon = icon
		else
		end
	end
	if not button.Count then
		if count then
			button.Count = count
		else
			button.Count = button:CreateFontString(nil, nil, "NumberFontNormal", 2)
			button.Count:SetJustifyH("RIGHT")
			button.Count:SetPoint("BOTTOMRIGHT", -5, 2)
			button.Count:Hide()
		end
	end
	if not button.Stock then
		if stock then
			button.Stock = stock
		else
			-- button.Stock = button:CreateFontString(nil, nil, "NumberFontNormalYellow", 2)
			-- button.Stock:SetPoint("TOPLEFT", 0, -2)
			-- button.Stock:SetJustifyH("LEFT")
			-- button.Stock:Hide()
		end
	end
	if not button.searchOverlay then
		if searchOverlay then
			button.searchOverlay = searchOverlay
		else
			-- button.searchOverlay = button:CreateTexture(nil, "OVERLAY")
			-- button.searchOverlay:SetAllPoints()
			-- button.searchOverlay:SetTexture(0, 0, 0, 0.8)
			-- button.searchOverlay:Hide()
		end
	end
	if not button.IconBorder then
		if border then
			button.IconBorder = border
		else
			-- button.IconBorder = button:CreateTexture(nil, "OVERLAY")
			-- button.IconBorder:SetSize(37, 37)
			-- button.IconBorder:SetPoint("CENTER")
			-- button.IconBorder:SetTexture([[Interface\Common\WhiteIconFrame]])
			-- button.IconBorder:Hide()
		end
	end
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

local addonHandlers = { }

function frame:ADDON_LOADED(addonName)
	if addonHandlers[addonName] then
		addonHandlers[addonName]()
		addonHandlers[addonName] = nil
	end
	
	if not next(addonHandlers) then
		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil
	end
end

function frame:RegisterAddonHandler(addonName, func)
	if IsAddOnLoaded(addonName) then
		func()
		return
	end

	addonHandlers[addonName] = func
end

do	-- inventory
	local INVENTORY_BUTTONS = {
		[INVSLOT_HEAD] 		= CharacterHeadSlot,
		[INVSLOT_NECK]		= CharacterNeckSlot,
		[INVSLOT_SHOULDER]	= CharacterShoulderSlot,
		[INVSLOT_BACK]		= CharacterBackSlot,
		[INVSLOT_CHEST]		= CharacterChestSlot,
		[INVSLOT_BODY]		= CharacterShirtSlot,
		[INVSLOT_TABARD]	= CharacterTabardSlot,
		[INVSLOT_WRIST]		= CharacterWristSlot,
		[INVSLOT_HAND]		= CharacterHandsSlot,
		[INVSLOT_WAIST]		= CharacterWaistSlot,
		[INVSLOT_LEGS]		= CharacterLegsSlot,
		[INVSLOT_FEET]		= CharacterFeetSlot,
		[INVSLOT_FINGER1]	= CharacterFinger0Slot,
		[INVSLOT_FINGER2]	= CharacterFinger1Slot,
		[INVSLOT_TRINKET1]	= CharacterTrinket0Slot,
		[INVSLOT_TRINKET2]	= CharacterTrinket1Slot,
		[INVSLOT_MAINHAND]	= CharacterMainHandSlot,
		[INVSLOT_OFFHAND]	= CharacterSecondaryHandSlot,
	}
	
	for i, button in pairs(INVENTORY_BUTTONS) do
		lib:RegisterButton(button, "INVENTORY", true)
	end
	
	frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	function frame:PLAYER_EQUIPMENT_CHANGED(slotID, hasItem)
		if slotID <= INVSLOT_LAST_EQUIPPED then
			lib:UpdateButton(INVENTORY_BUTTONS[slotID], GetInventoryItemLink("player", slotID))
		end
	end
end

do	-- bags
	local MAX_CONTAINER_ITEMS = 36
	
	for bag = 1, NUM_CONTAINER_FRAMES do
		for slot = 1, MAX_CONTAINER_ITEMS do
			lib:RegisterButton(_G[format("ContainerFrame%dItem%d", bag, slot)], "BAG", true)
		end
	end
	
	frame:RegisterEvent("BAG_UPDATE_DELAYED")
	function frame:BAG_UPDATE_DELAYED()
		for button in pairs(lib:GetRegisteredButtons()) do
			if lib.buttonCategory[button] == "BAG" then
				lib:UpdateButton(button, C_Container.GetContainerItemLink(button:GetParent():GetID(), button:GetID()))
			end
		end
	end
	
	hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, size, id)
		local frameName = frame:GetName()
		if not frameName:match("^ContainerFrame%d+$") then return end
		for i = 1, size do
			local button = _G[frameName.."Item"..i]
			lib:UpdateButton(button, C_Container.GetContainerItemLink(id, button:GetID()))
		end
	end)
end

do	-- bank
	local bankButtons = {}
	
	for slot = 1, NUM_BANKGENERIC_SLOTS do
		lib:RegisterButton(BankSlotsFrame["Item"..slot], "BANK", true)
		bankButtons[slot] = BankSlotsFrame["Item"..slot]
	end
	
	frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
	function frame:PLAYERBANKSLOTS_CHANGED(slot)
		if slot <= NUM_BANKGENERIC_SLOTS then
			lib:UpdateButton(bankButtons[slot], C_Container.GetContainerItemLink(BANK_CONTAINER, slot))
		end
	end
	
	frame:RegisterEvent("BANKFRAME_OPENED")
	function frame:BANKFRAME_OPENED()
		for slot, button in ipairs(bankButtons) do
			lib:UpdateButton(button, C_Container.GetContainerItemLink(BANK_CONTAINER, slot))
		end
	end
	
	
	local reagentBankButtons = {}
	
	local reagentSlotsRegistered
	
	ReagentBankFrame:HookScript("OnShow", function(self)
		if not reagentSlotsRegistered then
			for slot = 1, 98 do
				local button = ReagentBankFrame["Item"..slot]
				lib:RegisterButton(button, "REAGENTBANK", true)
				lib:UpdateButton(button, C_Container.GetContainerItemLink(REAGENTBANK_CONTAINER, slot))
				reagentBankButtons[slot] = button
			end
			
			frame:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED")
			function frame:PLAYERREAGENTBANKSLOTS_CHANGED(slot)
				lib:UpdateButton(reagentBankButtons[slot], C_Container.GetContainerItemLink(REAGENTBANK_CONTAINER, slot))
			end
			
			reagentSlotsRegistered = true
		end
	end)
end

do	-- void storage
	frame:RegisterAddonHandler("Blizzard_VoidStorageUI", function()
		for slot = 1, 80 do
			local button = _G["VoidStorageStorageButton"..slot]
			lib:RegisterButton(button, "VOIDSTORAGE", true)
			lib:UpdateButton(button, GetVoidItemHyperlinkString((VoidStorageFrame.page - 1) * 80 + slot))
		end
		
		hooksecurefunc("VoidStorage_ItemsUpdate", function(doDeposit, doContents)
			for slot = 1, 80 do
				lib:UpdateButton(_G["VoidStorageStorageButton"..slot], GetVoidItemHyperlinkString((VoidStorageFrame.page - 1) * 80 + slot))
			end
		end)
	end)
end

do	-- guild bank
	frame:RegisterEvent("GUILDBANKFRAME_OPENED")
	function frame:GUILDBANKFRAME_OPENED()
		for column = 1, NUM_GUILDBANK_COLUMNS do
			for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
				lib:RegisterButton(_G["GuildBankColumn"..column.."Button"..i], "GUILDBANK", true)
			end
		end
		
		hooksecurefunc("GuildBankFrame_Update", function()
			local tab = GetCurrentGuildBankTab()
			for column = 1, NUM_GUILDBANK_COLUMNS do
				for i = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
					local slot = (column - 1) * NUM_SLOTS_PER_GUILDBANK_GROUP + i
					lib:UpdateButton(_G["GuildBankColumn"..column.."Button"..i], GetGuildBankItemLink(tab, slot))
				end
			end
		end)
		
		self:UnregisterEvent("GUILDBANKFRAME_OPENED")
		self.GUILDBANKFRAME_OPENED = nil
	end
end

do	-- mail
	for i = 1, ATTACHMENTS_MAX_RECEIVE do
		lib:RegisterButton(_G["OpenMailAttachmentButton"..i], "MAIL", true)
	end
	
	hooksecurefunc("OpenMailFrame_UpdateButtonPositions", function()
		for i = 1, ATTACHMENTS_MAX_RECEIVE do
			lib:UpdateButton(_G["OpenMailAttachmentButton"..i], GetInboxItemLink(InboxFrame.openMailID, i))
		end
	end)
	
	-- for i = 1, ATTACHMENTS_MAX_SEND do
		-- lib:RegisterButton(_G["SendMailAttachment"..i], "MAIL", true)
	-- end
	
	-- hooksecurefunc("SendMailFrame_Update", function()
		-- for i = 1, ATTACHMENTS_MAX_SEND do
			-- lib:UpdateButton(_G["OpenMailAttachmentButton"..i], GetSendMailItemLink(i))
		-- end
	-- end)
end

do	-- merchant
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		lib:RegisterButton(_G["MerchantItem"..i.."ItemButton"], "MERCHANT", true)
	end
	
	lib:RegisterButton(MerchantBuyBackItemItemButton, "MERCHANT_BUYBACK", true)
	
	hooksecurefunc("MerchantFrame_UpdateMerchantInfo", function()
		for i = 1, min(MERCHANT_ITEMS_PER_PAGE, GetMerchantNumItems()) do
			local slot = MERCHANT_ITEMS_PER_PAGE * (MerchantFrame.page - 1) + i
			lib:UpdateButton(_G["MerchantItem"..i.."ItemButton"], GetMerchantItemLink(slot))
		end
		lib:UpdateButton(MerchantBuyBackItemItemButton, GetBuybackItemLink(GetNumBuybackItems()))
	end)
	
	for i = 1, BUYBACK_ITEMS_PER_PAGE do
		lib:RegisterButton(_G["MerchantItem"..i.."ItemButton"], "MERCHANT", true)
	end
	
	hooksecurefunc("MerchantFrame_UpdateBuybackInfo", function()
		for i = 1, BUYBACK_ITEMS_PER_PAGE do
			lib:UpdateButton(_G["MerchantItem"..i.."ItemButton"], GetBuybackItemLink(i))
		end
	end)
end

do	-- auction
	frame:RegisterEvent("AUCTION_HOUSE_SHOW")
	function frame:AUCTION_HOUSE_SHOW()
		for i = 1, NUM_BROWSE_TO_DISPLAY do
			local buttonName = "BrowseButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			lib:RegisterButton(button, "AUCTION_BROWSE", true)
		end
		
		hooksecurefunc("AuctionFrameBrowse_Update", function()
			for i = 1, NUM_BROWSE_TO_DISPLAY do
				local link = GetAuctionItemLink("list", BrowseScrollFrame.offset + i)
				lib:UpdateButton(_G["BrowseButton"..i.."Item"], link)
			end
		end)
		
		for i = 1, NUM_BIDS_TO_DISPLAY do
			local buttonName = "BidButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			lib:RegisterButton(button, "AUCTION_BID", true)
		end
		
		hooksecurefunc("AuctionFrameBid_Update", function()
			for i = 1, NUM_BIDS_TO_DISPLAY do
				local link = GetAuctionItemLink("bidder", BidScrollFrame.offset + i)
				lib:UpdateButton(_G["BidButton"..i.."Item"], link)
			end
		end)
		
		for i = 1, NUM_AUCTIONS_TO_DISPLAY do
			local buttonName = "AuctionsButton"..i.."Item"
			local button = _G[buttonName]
			button.icon = _G[buttonName.."IconTexture"]
			button.Count = _G[buttonName.."Count"]
			lib:RegisterButton(button, "AUCTION_BID", true)
		end
		
		hooksecurefunc("AuctionFrameAuctions_Update", function()
			for i = 1, NUM_AUCTIONS_TO_DISPLAY do
				local link = GetAuctionItemLink("owner", AuctionsScrollFrame.offset + i)
				lib:UpdateButton(_G["AuctionsButton"..i.."Item"], link)
			end
		end)
		
		self:UnregisterEvent("AUCTION_HOUSE_SHOW")
		self.AUCTION_HOUSE_SHOW = nil
	end
end

do	-- black market
	frame:RegisterAddonHandler("Blizzard_BlackMarketUI", function()
		frame:RegisterEvent("BLACK_MARKET_ITEM_UPDATE")
		function frame:BLACK_MARKET_ITEM_UPDATE()
			local button = BlackMarketFrame.HotDeal.Item
			button.icon = button.IconTexture
			lib:RegisterButton(button, "BLACKMARKET_HOT", true)
			
			hooksecurefunc("BlackMarketFrame_UpdateHotItem", function(self)
				local link = select(15,  C_BlackMarket.GetHotItem())
				lib:UpdateButton(BlackMarketFrame.HotDeal.Item, link)
			end)
			
			for i, button in ipairs(BlackMarketScrollFrame.buttons) do
				button.Item.icon = button.Item.IconTexture
				lib:RegisterButton(button.Item, "BLACKMARKET", true)
			end
			
			local function update()
				local buttons = BlackMarketScrollFrame.buttons
				for i = 1, min(#buttons, C_BlackMarket.GetNumItems()) do
					local link = select(15,  C_BlackMarket.GetItemInfoByIndex(BlackMarketScrollFrame.offset + i))
					lib:UpdateButton(buttons[i].Item, link)
				end
			end
			
			update()
			
			hooksecurefunc("BlackMarketScrollFrame_Update", update)
			
			self:UnregisterEvent("BLACK_MARKET_ITEM_UPDATE")
			self.BLACK_MARKET_ITEM_UPDATE = nil
		end
	end)
end

do	-- loot
	local function acquiredLootButtonCallback(lib, frame, elementData, isNew)
		if isNew then
			lib:RegisterButton(frame.Item, "LOOT", true)
		end
	end
	
	local function initializedLootButtonCallback(lib, frame, elementData)
		lib:UpdateButton(frame.Item, GetLootSlotLink(frame:GetSlotIndex()))
	end

	ScrollUtil.AddAcquiredFrameCallback(LootFrame.ScrollBox, acquiredLootButtonCallback, lib, true)
	ScrollUtil.AddInitializedFrameCallback(LootFrame.ScrollBox, initializedLootButtonCallback, lib, true)
	
	-- for i=1, NUM_GROUP_LOOT_FRAMES do
	-- 	local frame = _G["GroupLootFrame"..i]
	-- 	local button = frame.IconFrame
	-- 	button.icon = button.Icon
	-- 	lib:RegisterButton(button, "GROUPLOOT", true)
	-- 	frame:HookScript("OnShow", function(self)
	-- 		local link = GetLootRollItemLink(self.rollID)
	-- 		lib:UpdateButton(self.IconFrame, link)
	-- 	end)
	-- end
end
