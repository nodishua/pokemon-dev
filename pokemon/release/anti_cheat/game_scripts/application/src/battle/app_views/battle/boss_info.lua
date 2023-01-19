--
-- boss 信息面板
--


local ViewBase = cc.load("mvc").ViewBase
local BossInfoPanel = class("BossInfoPanel", ViewBase)

BossInfoPanel.RESOURCE_FILENAME = "battle_boss_info.json"
BossInfoPanel.RESOURCE_BINDING = {
	["refreshBtnL"] = {
		varname = "refreshBtnL",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefreshBtnLClick")}
		},
	},
	["centerPanel"] = "centerPanel",
	["refreshBtnR"] = {
		varname = "refreshBtnR",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefreshBtnRClick")}
		},
	},
}

function BossInfoPanel:onCreate(battleView, waitEffect)
	self.battleView = battleView
	local pnode = self:getResourceNode()

	local effect1 = widget.addAnimationByKey(self, "level/qiangdilaixi.skel", "MainEffect", "hou", 0):xy(display.center):scale(2)
	local effect2 = widget.addAnimationByKey(self, "level/qiangdilaixi.skel", "QainEffect", "qian", 20):xy(display.center):scale(2)

	effect1:addPlay("effect_loop")

	effect2:setSpriteEventHandler(function(_type, event)
		if _type == sp.EventType.ANIMATION_COMPLETE then
			effect2:hide()
			self.centerPanel:show()
		end
	end)

	-- 点空白处返回
	pnode:onClick(function()
		-- 手动恢复展示boss信息时暂停
		waitEffect:stop()
		ViewBase.onClose(self)
	end)

	local sceneID = self.battleView.sceneID
	local waveId = self.battleView:getPlayModel().curWave
	local cfg = self.battleView._play:getMonsterCsv(sceneID,waveId)
	self.bossTb = {}
	for i=1, 6 do
		local markId = cfg.bossMark[i]
		local bossId = cfg.monsters[i] or 0
		if (markId == 1) and (bossId > 0) then
			table.insert(self.bossTb, bossId)
		end
	end

	-- 基础字
	self.centerPanel:get("attrText"):setString(gLanguageCsv.attribute .. ":")
	self.centerPanel:get("rareText"):setString(gLanguageCsv.rarity .. ":")
	self.centerPanel:get("descArea1.title"):setString(gLanguageCsv.summary .. ":")
	self.centerPanel:get("descArea2.title"):setString(gLanguageCsv.uniqueSkill .. ":")

	self.refreshBtnL:hide()
	if table.length(self.bossTb) <= 1 then
		self.refreshBtnR:hide()
	end

	-- 默认显示第一个boss的信息
	self.curBossIdx = 1
	self:showBossInfo(self.curBossIdx)
end

-- 显示信息
function BossInfoPanel:showBossInfo(id)
	local bossId = self.bossTb[id]
	local bossCfg = csv.unit[bossId]
	if not bossCfg then return end
	local pnode = self:getResourceNode()

	-- boss名称
	self.centerPanel:get("nameText"):setString(bossCfg.name)
	-- 属性
	local attr1res = ui.ATTR_ICON[bossCfg.natureType]
	local attr2res = ui.ATTR_ICON[bossCfg.natureType2]
	self.centerPanel:get("attrIcon1"):loadTexture(attr1res)
	self.centerPanel:get("attrIcon2"):setVisible(attr2res ~= nil)
	if attr2res then
		self.centerPanel:get("attrIcon2"):loadTexture(attr2res)
	end
	-- 稀有度
	self.centerPanel:get("rareImg"):loadTexture(ui.RARITY_ICON[bossCfg.rarity])
	-- 立绘
	self.centerPanel:get("potrait"):loadTexture(bossCfg.show)
	-- 介绍
	-- 介绍2 必杀技
	local function addDescRichText(idx, str)
		str = str or ""
		local descArea = self.centerPanel:get("descArea" .. idx)
		local textArea = descArea:get("textArea")
		local tsize = textArea:size()
		local px, py = textArea:getPosition()
		local richtext = rich.createWithWidth("#C0x5b545b#" .. str, 40, deltaSize, tsize.width)
		richtext:setAnchorPoint(cc.p(0, 1))
		richtext:xy(px, py)
		descArea:add(richtext, 3)
	end

	-- TODO: 配置未就位
	local str1 = csv.cards[bossCfg.cardID].introduction
	-- local str1 = "TEST: 等配置不报错，去掉这里代码"
	addDescRichText(1, str1)
	local skillList = bossCfg.skillList
	local str2
	if table.length(skillList) ~= 0 then
		local skillCfg = csv.skill[skillList[table.length(skillList)]]
		str2 = skillCfg.simDesc
	end
	addDescRichText(2, str2)
end

-- 刷新其它 boss 信息
function BossInfoPanel:onRefreshBtnLClick()
	if table.length(self.bossTb) == 1 then return end
	self.curBossIdx = self.curBossIdx - 1
	if self.curBossIdx <= 1 then
		self.curBossIdx = 1
	end
	self:showBossInfo(self.curBossIdx)

	local pnode = self:getResourceNode()
	if self.curBossIdx == 1 then
		self.refreshBtnL:hide()
	end
	self.refreshBtnR:show()
end

function BossInfoPanel:onRefreshBtnRClick()
	if #self.bossTb == 1 then return end
	self.curBossIdx = self.curBossIdx + 1
	if self.curBossIdx >= table.length(self.bossTb) then
		self.curBossIdx = table.length(self.bossTb)
	end
	self:showBossInfo(self.curBossIdx)

	local pnode = self:getResourceNode()
	if self.curBossIdx == table.length(self.bossTb) then
		self.refreshBtnR:hide()
	end
	self.refreshBtnL:show()
end


return BossInfoPanel

