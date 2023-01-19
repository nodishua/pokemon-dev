--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Cards
--

local Card = class("Card", require("app.models.base"))

local Cards = class("Cards", require("app.models.bases"))

function Cards:newModel(t)
	return Card.new(self.game):init(t)
end

function Cards:syncFrom(t, new)
	for k, v in pairs(t) do
		local model = self:find(k)
		if model ~= nil then
			model:syncFrom(v, new and new[k])
		else
			model = self:newModel(v)
			self:insert(k, model)
			self:insertNewFlag_(k)
		end
	end
	self._statCache = nil
end

function Cards:getStat()
	if not self._statCache then
		local h = {
			level = {},
			advance = {},
			star = {},
			equip_advance = {},
			equip_star = {},
			equip_awake = {},
		}
		local card_id = {}
		local markID_star = {}
		for _, card in self:pairs() do
			local v = card:read('advance')
			h.advance[v] = (h.advance[v] or 0) + 1
			v = card:read('star')
			h.star[v] = (h.star[v] or 0) + 1
			v = card:read('level')
			h.level[v] = (h.level[v] or 0) + 1
			v = card:read('card_id')
			card_id[v] = (card_id[v] or 0) + 1

			local mark_id = csv.cards[card:read('card_id')].cardMarkID
			local star = markID_star[mark_id] or 0 
			if card:read('star') > star then
				star = card:read('star')
			end
			markID_star[mark_id] = star

			for _, equip in pairs(card:read('equips')) do
				v = equip.advance
				h.equip_advance[v] = (h.equip_advance[v] or 0) + 1
				v = equip.star
				h.equip_star[v] = (h.equip_star[v] or 0) + 1
				v = equip.awake
				h.equip_awake[v] = (h.equip_awake[v] or 0) + 1
			end
		end
		self._statCache = {
			level_sum = stat.summator.new(h.level),
			advance_sum = stat.summator.new(h.advance),
			star_sum = stat.summator.new(h.star),
			card_id = card_id,
			equip_advance_sum = stat.summator.new(h.equip_advance),
			equip_star_sum = stat.summator.new(h.equip_star),
			equip_awake_sum = stat.summator.new(h.equip_awake),
			markID_star = markID_star,
		}
	end
	return self._statCache
end

function Cards:getNewFlags()
	assert(self._newflags, "plz initNewFlag before")
	return idlereasy.assign(self._newflags)
end

function Cards:initNewFlag()
	local cardIDs = userDefault.getForeverLocalKey("newCards", {})
	local data = {}
	for id, v in pairs(cardIDs) do
		if v == true then
			data[id] = true
		end
	end
	self._newflags = idlereasy.new(data)
end

function Cards:insertNewFlag_(cardID)
	local id = stringz.bintohex(cardID)
	self._newflags = self._newflags or idlereasy.new({})
	self._newflags:proxy()[id] = true
	userDefault.setForeverLocalKey("newCards", {[id] = true})
end

function Cards:isNew(cardID)
	assert(self._newflags, "plz initNewFlag before")

	return self._newflags:read()[stringz.bintohex(cardID)] or false
end

function Cards:removeNewFlag(cardID)
	assert(self._newflags, "plz initNewFlag before")

	local id = stringz.bintohex(cardID)
	self._newflags:modify(function(t)
		local flag = t[id] ~= nil
		t[id] = nil
		return flag, t
	end)
	userDefault.setForeverLocalKey("newCards", {[id] = false}, {delete = true})
end

return Cards