local TalentDetailView = class("TalentDetailView", Dialog)
TalentDetailView.RESOURCE_FILENAME = "talent_detail.json"
TalentDetailView.RESOURCE_BINDING = {
	["icon"] = "icon",
	["bg1"] = "bg1",
	["lock"] = "lock",
	["name"] = "nodeName",
	["lockPanel"] = "lockPanel",
	["upgradePanel"] = "upgradePanel",
	["level"] = "Upgradelevel",
	["upgradePanel.btnUpgrade"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onUpgrade")}
		},
	},
	["upgradePanel.static"] = "upgradeStatic",
	["upgradePanel.num1"] = "num1",
	["upgradePanel.icon1"] = "icon1",
	["upgradePanel.num2"] = "num2",
	["upgradePanel.icon2"] = "icon2",

	["max"] = "max",
	["desc"] = "desc",
	["descAttr"] = "descAttr",
	["upgradePanel.btnUpgrade.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color=ui.COLORS.GLOW.WHITE}},
		}
	},
	["mask"] = "mask",
	["lockPanel.condition1"] = "condition1",
	["lockPanel.level"] = "lockLevel",
	["lockPanel.condition2"] = "condition2",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["static"] = "static",
}

function TalentDetailView:onCreate(params)
	self.treeId, self.id, self.isLock, self.talentTree, self.ids = params()
	self:initModel()
	self.lock:visible(self.isLock)
	self.mask:visible(self.isLock)
	self.lockPanel:visible(self.isLock)
	local cfg = csv.talent[self.id]
	if self.isLock then
		itertools.invoke({self.upgradePanel, self.max, self.Upgradelevel, self.static}, "hide")
		idlereasy.when(self.level, function (_, level)
			local color = level >= cfg.roleLevel and "C0x60C456" or "C0xF76B45"
			local showText = string.format(gLanguageCsv.talentDetailRoleLevel,color,cfg.roleLevel)
			local richText = rich.createWithWidth(showText, 40, nil, 550)
			richText:addTo(self.condition1,2)
				:anchorPoint(0, 0)
			local preLevel = 0
			local talentTree = self.talentTree:read()[self.treeId]
			if talentTree and talentTree.talent and talentTree.talent[cfg.preTalentID] then
				preLevel = talentTree.talent[cfg.preTalentID]
			end

			self.condition2:visible(cfg.preTalentLevel > 0)
			self.lockLevel:visible(cfg.preTalentLevel > 0)
			self.condition2:text(gLanguageCsv.talentLevelReach)
			self.lockLevel:text(string.format("(%d/%d)",preLevel, cfg.preTalentLevel))
			self.lockLevel:setTextColor(cfg.preTalentLevel > preLevel and cc.c4b(252,53,0,255) or cc.c4b(169,245,72,255))
			adapt.oneLinePos(self.condition2, self.lockLevel, cc.p(5,0), "left")
			self:getDesc(cfg, 0)
		end)
	else
		self.goldEnough = false
		self.talentPointEnough = false
		self.upgradePanel:show()
		idlereasy.any({self.talentTree, self.talentPoint, self.gold}, function (_, talentTree, talentPoint, gold)
			local level = talentTree[self.treeId].talent[self.id]

			self.max:visible(level == cfg.levelUp)
			self.Upgradelevel:text(level.."/"..cfg.levelUp)
			self.upgradePanel:visible(level ~= cfg.levelUp)
			self.Upgradelevel:setTextColor(level < cfg.levelUp and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT)
			self:getDesc(cfg, level)
			if level == cfg.levelUp then
				return
			end
			local cfgCost = csv.talent_cost[level]
			local costGold = cfgCost["costGold"..cfg.costID]
			local costTalent = cfgCost["costTalent" .. cfg.costID]
			self.num1:text(costGold)
			self.goldEnough = costGold <= gold
			self.num1:setTextColor(costGold > gold and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT)
			self.num2:text(costTalent)
			self.talentPointEnough = costTalent <= talentPoint
			self.num2:setTextColor(costTalent > talentPoint and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT)
			adapt.oneLineCenterPos(cc.p(self.upgradePanel:width()/2, self.upgradePanel:height()/2), {self.upgradeStatic, self.num1, self.icon1, self.num2, self.icon2}, cc.p(10, 0))
		end)
	end

	self.icon:texture(cfg.icon)
	self.nodeName:text(cfg.name)
	self.nodeName:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	Dialog.onCreate(self)
end

function TalentDetailView:onUpgrade()
	if not self.talentPointEnough then
		gGameUI:showTip(gLanguageCsv.talentLevelPointUp)
		return
	end
	if not self.goldEnough then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)
		return
	end
	gGameApp:requestServer("/game/talent/levelup_ready",function (tb)
		self.ids[self.id] = true
		local size = self.icon:getContentSize()
		widget.addAnimationByKey(self.icon, "effect/jineng.skel", nil, "effect", 555)
			:xy(size.width/2, size.height/2)
			:scale(0.8)
		audio.playEffectWithWeekBGM("circle.mp3")
	end, self.id)
end

function TalentDetailView:initModel()
	self.talentPoint = gGameModel.role:getIdler("talent_point")
	self.gold = gGameModel.role:getIdler("gold")
	self.level = gGameModel.role:getIdler("level")
end

function TalentDetailView:getAttributeNum(type, baseNum, level)
	local pos = string.find(baseNum, "%%")
	local ret = ""
	if pos ~= nil then
		ret = tonumber(string.sub(baseNum, 1, pos - 1)) * level .. "%"
	else
		ret = tonumber(baseNum) * level
	end
	return dataEasy.getAttrValueString(type, ret)
end

function TalentDetailView:getDesc(cfg, level)
	local attrNum = cfg.attrType1 and cfg.attrNum1 or cfg.damageRelation1[2]
	local strs = {}
	local space = matchLanguage({"en"}) and " " or ""
	table.insert(strs, cfg.attrAddDesc1.. space .. self:getAttributeNum(cfg.attrType1, attrNum, level))
	if cfg.attrNum2 ~= "" then
		table.insert(strs, cfg.attrAddDesc2 .. space .. self:getAttributeNum(cfg.attrType2, cfg.attrNum2, level))
	end
	local str = table.concat(strs, "\n")
	self.desc:text(str)
	self.desc:setTextColor(ui.COLORS.NORMAL.FRIEND_GREEN)
	self.descAttr:text(cfg.attrDesc)
	self.descAttr:setTextColor(ui.COLORS.NORMAL.DEFAULT)
end

return TalentDetailView