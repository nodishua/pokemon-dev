local TrainSkillUpgrade = class("TrainSkillUpgrade", Dialog)

TrainSkillUpgrade.RESOURCE_FILENAME = "trainer_skill_upgrade.json"
TrainSkillUpgrade.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["icon"] = "icon",
	["name"] = "nodeName",
	["lv1"] = "lv1",
	["lv2"] = "lv2",
	["center"] = "center",
	["center.total"] = "total",
	["center.money"] = "money",
	["center.percent"] = "percent",
	["arrow"] = "arrow",
	["curr"] = "curr",
	["next"] = "next",
	["btnUp"] = {
		varname = "btnUp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUp")}
		},
	},
	["btnUp.txt"] = {
		varname = "txt",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		},
	},
	["center"] = "center",
	["pos"] = "pos",
	["max"] = "max"
}

function TrainSkillUpgrade:getStr(cfg, level)
	local value = cfg.nums[level]
	local isPercent = string.find(tostring(value), ".", 1, true) ~= nil
	if isPercent then
		value = value * 100
	end
	return string.format(cfg.desc2, value)..(isPercent and "%" or "")
end

function TrainSkillUpgrade:onCreate(data)
	self:initModel()
	self.data = data
	local cfg = csv.trainer.skills[self.data.id]
	self.levelMax = cfg.levelMax
	self.needId, self.needCost = csvNext(cfg.upCost)
	self.total:text("/"..self.needCost)
	self.icon:texture(cfg.icon)
		:scale(2)
	self.nodeName:text(cfg.name)
	idlereasy.when(self.trainerSkills, function (_, val)
		local level = val[self.data.id] or 0
		self.level = level
		self.lv1:text("Lv."..level)
		self.lv2:text("Lv."..level + 1)
		if level == cfg.levelMax then
			itertools.invoke({self.total, self.money, self.percent, self.arrow, self.lv2, self.btnUp}, "hide")
			self.curr:text(self:getStr(cfg, level))
			self.next:text(gLanguageCsv.none)
			self.max:show()
		elseif level ~= 0 then
			itertools.invoke({self.total, self.money, self.percent, self.arrow, self.lv2, self.btnUp}, "show")
			self.curr:text(self:getStr(cfg, level))
			self.max:hide()
			self.next:text(self:getStr(cfg, level + 1))
		else
			itertools.invoke({self.total, self.money, self.percent, self.arrow, self.lv2, self.btnUp}, "show")
			self.curr:text(gLanguageCsv.none)
			self.next:text(self:getStr(cfg, level + 1))
			self.max:hide()
		end

	end)
	idlereasy.when(self.items, function (_, val)
		local cost = val[self.needId] or 0
		self.percent:text(cost)
		local isEnough = self.needCost <= cost
		text.addEffect(self.percent, {color = isEnough and cc.c4b(92,153,112,255) or cc.c4b(231,116,32,255)})
		if isEnough then
			text.addEffect(self.txt, {glow = {color = ui.COLORS.GLOW.WHITE}})
		else
			text.deleteAllEffect(self.txt)
		end
		cache.setShader(self.btnUp, false, isEnough and "normal" or "hsl_gray")
		self.btnUp:setTouchEnabled(isEnough)
		adapt.oneLineCenterPos(cc.p(100, 25), {self.percent, self.total, self.money})
	end)
	Dialog.onCreate(self)
end

function TrainSkillUpgrade:initModel()
	self.trainerSkills = gGameModel.role:getIdler("trainer_skills")
	self.items = gGameModel.role:getIdler("items")
end

function TrainSkillUpgrade:onUp()
	if self.levelMax == self.level then
		gGameUI:showTip(gLanguageCsv.levelMax)
		return
	end
	gGameApp:requestServer("/game/trainer/skill/levelup",function (tb)
		self:floatTip()
		local size = self.icon:getContentSize()
		widget.addAnimationByKey(self.icon, "koudai_gonghuixunlian/gonghuixunlian.skel", nil, "fangguang", 555)
			:xy(size.width/2, 0)
			:scale(1/2)
		audio.playEffectWithWeekBGM("square.mp3")
	end, self.data.id)
end

function TrainSkillUpgrade:floatTip()
	local panel = self.pos:get("tip")
	if not panel then
		panel = ccui.ImageView:create("city/develop/train/txt_sjcg.png")
			:addTo(self.pos, 1)
			:alignCenter(self.pos:size())
	end
	panel:xy(self.pos:size().width/2, 80):show():opacity(255)
	transition.executeSequence(panel)
		:moveBy(0.4, 0, 100)
		:fadeOut(0.3)
		:done()
end


return TrainSkillUpgrade
