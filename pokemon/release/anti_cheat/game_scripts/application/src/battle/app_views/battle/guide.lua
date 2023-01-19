--
-- @desc 战斗界面引导
--

local GuideManager = require("app.views.guide.manager")

local BattleGuideManager = class("BattleGuideManager", GuideManager)

local GuideView = GuideManager.GuideView
local BattleStoryPanelView = GuideManager.BattleStoryPanelView

function BattleGuideManager:ctor(battleView)
	self.battleView = battleView
	self.stroyDatas = {}
	self.totalTriggerTime = 0
	self.curGuideIdx = 0
	self.startGuideIdx = 0
	self.guidePanel = nil
	self.inGuiding = false

	self.choicesFunc = nil
end

function BattleGuideManager:initStoryDatas(cfgIds)
	self.stroyDatas = {}
	for _, id in ipairs(cfgIds) do
		for i = 0, 99 do
			local idx = id + i
			local cfg = csv.scene_monster_story[idx]
			if not cfg then
				break
			end
			table.insert(self.stroyDatas, {cfg = cfg, id = idx})
		end
	end
	self.curGuideIdx = 1

end

function BattleGuideManager:setData(cfgIds)
	self:initStoryDatas(cfgIds)

	self.totalTriggerTime = 0
	self.inGuiding = true
	gGameUI.guideLayer:show()
	gGameUI:disableTouchDispatch(nil, false)
end

function BattleGuideManager:update(delta)
	if not self.inGuiding or self.ignoreGuide then
		return
	end
	local data = self.stroyDatas[self.curGuideIdx]
	if not data then
		self:cleanGuidePanel()
		self.inGuiding = false
		gGameUI.guideLayer:hide()
		gGameUI:disableTouchDispatch(nil, true)
		self.battleView:showMainUI(true)
		self.battleView:onModelResume()
		return
	end
	local nextData = self.stroyDatas[self.curGuideIdx + 1]
	local cfg = data.cfg
	self.totalTriggerTime = self.totalTriggerTime + delta
	if not data.visit and self.totalTriggerTime >= cfg.triggerTime then
		log.battle.guide("update: id", data.id, "triggerTime", self.totalTriggerTime)
		data.visit = true
		if cfg.showType == 2 then
			gGameUI:disableTouchDispatch(nil, true)
			self:showDialog(cfg, function(choicesCfg)
				-- 有点击跳过，和等待点击的，需要最后重置下时间
				self.totalTriggerTime = cfg.triggerTime + cfg.lastTime
				self.curGuideIdx = self.curGuideIdx + 1
				self:updateChoice(cfg, choicesCfg)
				gGameUI:disableTouchDispatch(nil, false)
			end, {isBattle = true, skipCb = function()
				-- 跳过按钮，跳过多个 canSkip = true 的
				local lastSkipCfg = cfg
				for i = self.curGuideIdx + 1, table.length(self.stroyDatas) do
					if self.stroyDatas[i].cfg.canSkip then
						lastSkipCfg = self.stroyDatas[i].cfg
						self.curGuideIdx = i
					else
						break
					end
				end
				self.totalTriggerTime = lastSkipCfg.triggerTime + lastSkipCfg.lastTime
				self.curGuideIdx = self.curGuideIdx + 1
				gGameUI:disableTouchDispatch(nil, false)
			end})

		elseif cfg.showType == 3 then
			local objView = self.battleView:onViewProxyCall("getSceneObjBySeat", cfg.topTalkPos)
			if objView then
				objView:showGuide(cfg.topTalk, cfg.lastTime)
				self.curGuideIdx = self.curGuideIdx + 1
			else
				self.totalTriggerTime = cfg.triggerTime + cfg.lastTime
				self.curGuideIdx = self.curGuideIdx + 1
			end
		else
			-- showClickGuide 缩圈后触发 gGameUI:disableTouchDispatch(nil, true)
			self:showClickGuide(cfg, function()
				self.totalTriggerTime = cfg.triggerTime + cfg.lastTime
				self.curGuideIdx = self.curGuideIdx + 1
				gGameUI:disableTouchDispatch(nil, false)
			end, {isBattle = true})
		end
	end
end

function BattleGuideManager:updateChoice(cfg, data)
	-- 选择选项后需要跳转的引导
	local storyIdArray
	if data then
		if data.nextId and data.nextId > 0 then
			storyIdArray = {data.nextId}
		end
	end

	if table.length(cfg.gotoStep) > 0 then
		storyIdArray = cfg.gotoStep
	end

	if storyIdArray then
		self:initStoryDatas(storyIdArray)
	end
end

function BattleGuideManager:showDialog(cfg, cb, params)
	GuideManager.showDialog(self, cfg, cb, params)
	-- 战斗引导不显示灰底
	self.guidePanel:setBackGroundColorOpacity(0)
end

return BattleGuideManager