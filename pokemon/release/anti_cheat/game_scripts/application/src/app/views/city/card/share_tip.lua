-- @date:   2019-10-29 19:40:29
-- @desc:   精灵分享确认框

local FROM = {
	world = "world",
	union = "union",
}

local CardShareTipView = class("CardShareTipView", Dialog)

CardShareTipView.RESOURCE_FILENAME = "card_share_tip.json"
CardShareTipView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnCancel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShare")}
		},
	},
	["content"] = "content",
	["textLeftNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("shareTimes"),
			method = function(val)
				local leftTime = gCommonConfigCsv.shareTimesLimit - val
				return string.format("%s/%s", leftTime,  gCommonConfigCsv.shareTimesLimit)
			end,
		},
	},
	["checkBox1"] = {
		varname = "checkBox1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onSelTargetPos(FROM.world)
			end)}
		},
	},
	["checkBox2"] = {
		varname = "checkBox2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onSelTargetPos(FROM.union)
			end)}
		},
	},
}

function CardShareTipView:onCreate(dbId)
	self:initModel()

	self.dbId = dbId
	self.from = idler.new(FROM.world)
	idlereasy.when(self.from, function(_, from)
		self.checkBox1:get("checkBox"):setSelectedState(from == FROM.world)
		self.checkBox2:get("checkBox"):setSelectedState(from == FROM.union)
	end)
	local card = gGameModel.cards:find(dbId)
	local cardId = card:read("card_id")
	local advance = card:read("advance")
	local cfg = csv.cards[cardId]
	local quality, numStr = dataEasy.getQuality(advance)
	local color = ui.QUALITY_OUTLINE_COLOR[quality]
	local str = "#C0x5B545B#" .. string.format(gLanguageCsv.shareCardTo, color .. cfg.name .. numStr .. "#C0x5B545B#")
	local size = self.content:size()
	local richtext = rich.createWithWidth(str, 50, nil, size.width)
	richtext:alignCenter(size)
	richtext:addTo(self.content, 2)


	Dialog.onCreate(self)
end

function CardShareTipView:initModel()
	self.shareTimes = gGameModel.daily_record:getIdler("card_share_times")
	self.unionId = gGameModel.role:getIdler("union_db_id")
end

function CardShareTipView:onSelTargetPos(from, a, b)
	self.from:set(from)
end

function CardShareTipView:onShare()
	local shareTimes = gGameModel.daily_record:read("card_share_times")
	if shareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	if self.from:read() == FROM.union and not self.unionId:read() then
		gGameUI:showTip(gLanguageCsv.notUnionCantShare)
		return
	end
	gGameApp:requestServer("/game/card/share", function()
		gGameUI:showTip(gLanguageCsv.recordShareSuccess)
		self:onClose()
	end, self.dbId, self.from)
end

return CardShareTipView