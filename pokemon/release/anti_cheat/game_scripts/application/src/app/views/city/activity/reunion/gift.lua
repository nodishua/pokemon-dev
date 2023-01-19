-- @date 2020-8-31
-- @desc 训练家重聚 重聚礼包

-- 未领取 (不可领取)，可领取，已领取
local STATE_TYPE = {
	noReach = 0,
	canReceive = 1,
	received = 2,
}

-- 礼包类型(1重聚礼包;2相逢有时)
local STATE_TYPE_GIFT =
{
	gift = 1,
	reunion = 2,
}

--奖励类型 1-重聚礼包 2-绑定奖励 3-任务奖励 4-积分奖励
local STATE_TYPE_GET =
{
	ReunionGift = 1,
	BindAward = 2,
	TaskAward = 3,
	PointAward = 4,
}

local ReunionGiftView = class("ReunionGiftView", cc.load("mvc").ViewBase)

ReunionGiftView.RESOURCE_FILENAME = "reunion_gift.json"
ReunionGiftView.RESOURCE_BINDING = {
	["rightPanel.title"] = {
		varname = "title",
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(242, 122, 96, 255), size = 4},
				shadow = {color = cc.c4b(195, 109, 72, 255), offset = cc.size(0,-6), size = 6}
			},
		},
	},
	["rightPanel.textList"] = "textList",
	["rightPanel.receivebtn"] = {
		varname = "receivebtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReceiveClick")}
		},
	},
	["rightPanel.receivebtn.label"] = "receivebtnLabel",
	["rightPanel.list"] = "list",
}

function ReunionGiftView:onCreate(yyID)
	self.yyID = yyID
	local cfg = csv.yunying.yyhuodong[yyID]

	self:initModel()

	for k, v in csvPairs(csv.yunying.reunion_gift) do
		if v.huodongID == cfg.huodongID and v.type == STATE_TYPE_GIFT.gift then
			uiEasy.createItemsToList(self, self.list, v.item)
			self.csvID = k
		end
	end

	local sceneId = self.reunion:read().info.gate
	local sceneConfig = csv.scene_conf[sceneId]
	local ChapterName = sceneConfig.sceneName or ""
	local showText = string.format(gLanguageCsv.reunionGiftText, self.reunion:read().info.days, ChapterName)
	beauty.textScroll({
		list = self.textList,
		strs = showText,
		isRich = true,
		verticalSpace = 20,
		fontSize = 40,
	})

	self.datas = idlers.new()
	idlereasy.when(self.reunion, function(_, reunion)
			text.deleteAllEffect(self.receivebtnLabel)
		if not reunion.gift then
			cache.setShader(self.receivebtn, false, "hsl_gray")
			self.receivebtnLabel:text(gLanguageCsv.notReach)
			self.receivebtn:setTouchEnabled(false)
		elseif reunion.gift.reunion and reunion.gift.reunion[1] == self.csvID and reunion.gift.reunion[2] == STATE_TYPE.canReceive then
			cache.setShader(self.receivebtn, false, "normal")
			self.receivebtnLabel:text(gLanguageCsv.spaceReceive)
			text.addEffect(self.receivebtnLabel, {glow = {color = ui.COLORS.GLOW.WHITE}})
			self.receivebtn:setTouchEnabled(true)
		elseif reunion.gift.reunion and reunion.gift.reunion[1] == self.csvID and reunion.gift.reunion[2] == STATE_TYPE.received then
			cache.setShader(self.receivebtn, false, "hsl_gray")
			self.receivebtnLabel:text(gLanguageCsv.received)
			self.receivebtn:setTouchEnabled(false)
		end
	end)
end

function ReunionGiftView:initModel()
	self.reunion = gGameModel.role:getIdler("reunion")
end

function ReunionGiftView:onReceiveClick()
	if self.reunion:read().info.end_time - time.getTime() < 0 then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameApp:requestServer("/game/yy/reunion/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.yyID, self.csvID, STATE_TYPE_GET.ReunionGift)
end

return ReunionGiftView