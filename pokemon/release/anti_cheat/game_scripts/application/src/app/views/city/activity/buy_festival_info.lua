
--春节发红包弹框
local INPUT_LIMIT = 30
local ViewBase = cc.load("mvc").ViewBase
local BuyFestivalInfoView = class("BuyFestivalInfoView", Dialog)

BuyFestivalInfoView.RESOURCE_FILENAME = "common_send_text.json"
BuyFestivalInfoView.RESOURCE_BINDING = {
	["title"] = "title",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["buyBtn"] = {
		varname = "buyBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyItem")}
		},
	},
	["input"] = "input",
	["num2"] = "num2",
	["num3"] = "num3",
	["buyBtn.text"] = "text",
}

function BuyFestivalInfoView:initModel()
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.sendredPacket = gGameModel.daily_record:getIdler("huodong_redPacket_send")
	if self.activity.type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
		self.sendredPacket = gGameModel.daily_record:getIdler("huodong_cross_redPacket_send")
	end
end

--# num2对应次数,num3对应钻石的数量
function BuyFestivalInfoView:onCreate(id, cb)
	self.cb = cb
	local activity = csv.yunying.yyhuodong[id]
	self.activity = activity
	self:initModel()
	if not activity then return false end
	self.num2:text('x'..activity.paramMap["totalCount"])
	self.num3:text(activity.paramMap["totalVal"])
	-- self.input:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	blacklist:addListener(self.input, "*", functools.partial(self.nameAdapt, self))
	self.text:text(gLanguageCsv.commonTextOk)
	Dialog.onCreate(self)
end

function BuyFestivalInfoView:nameAdapt(txt)
	txt = txt or self.input:text()
	self.input:text(string.utf8limit(txt, INPUT_LIMIT, true))
end

--# 发红包
function BuyFestivalInfoView:onBuyItem()
	self:nameAdapt()
	local sendVipNum = gVipCsv[self.vipLevel:read()].huodongRedPacketSend
	if self.sendredPacket:read() == sendVipNum then
		gGameUI:showTip(gLanguageCsv.redPacketSendLimit)
		return false
	end

	local text
	if string.len(self.input:text()) >= 1 and self.input:text() ~= gLanguageCsv.festival then
		text = self.input:text()
	else
		text = gLanguageCsv.festival
	end

	local interface = "/game/yy/red/packet/send"
	if self.activity.type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
		interface = "/game/yy/cross/red/packet/send"
	end
	gGameApp:requestServer(interface, function(data)
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end, text)
end

return BuyFestivalInfoView