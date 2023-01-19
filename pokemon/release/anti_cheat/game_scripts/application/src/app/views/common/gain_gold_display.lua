-- @date: 2018-11-6
-- @desc: 聚宝(点金)界面

local GainGoldDisplayView = class("GainGoldDisplayView", Dialog)

GainGoldDisplayView.RESOURCE_FILENAME = "common_gain_gold_display.json"
GainGoldDisplayView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["panel1"] = "panel1",
	["panel10"] = "panel10",
}

function GainGoldDisplayView:onCreate(data, flag)
	local multiple = 0
	local gold = 0
	local times = 0
	for k,v in pairs(data) do
		multiple = multiple + v.multiple - 1
		gold = gold + v.gold
		times = times + 1
	end
	if flag == 1 then
		self.panel1:show()
		if multiple > 0 then
			self.panel1:get("title"):text(string.format(gLanguageCsv.gainGoldMultiple, multiple + 1))
		end
		self.panel1:get("gold"):text("+"..gold)
	else
		self.panel10:show()
		self.panel10:get("times"):text(times)
		self.panel10:get("critTimes"):text(multiple)
		self.panel10:get("gold"):text("+"..gold)
		adapt.oneLineCenterPos(cc.p(450, 270), {self.panel10:get("info1"), self.panel10:get("times"),
			self.panel10:get("info2"), self.panel10:get("critTimes"), self.panel10:get("info3")}, cc.p(5, 0))
	end

	self:playEffect()

	Dialog.onCreate(self)
end

function GainGoldDisplayView:playEffect()
	audio.playEffectWithWeekBGM("golden.mp3")
	local size = self.bg:size()
	local effect = widget.addAnimation(self:getResourceNode(),"effect/jubao.skel","effect",self.bg:z() - 1)
		:xy(display.center)
		:scale(2)

	self.goldEffect = effect
end

function GainGoldDisplayView:onClose()
	if self.goldEffect then
		self.goldEffect:removeFromParent() 		-- 不移除会造成关闭的时候有闪图
	end

	Dialog.onClose(self)
end

return GainGoldDisplayView
