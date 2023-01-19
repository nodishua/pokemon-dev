-- 本地引导记录

local insert = table.insert

local GuideManager = require("app.views.guide.manager")
local GuideManagerLocal = class("GuideManagerLocal", GuideManager)

local NextGuideActionTag = GuideManager.NextGuideActionTag

function GuideManagerLocal:ctor()
	self.curGuideId = nil
	self.inGuiding = false -- 是否在新手引导
	self.guidePanel = nil
	self.ignoreGuide = false
	self.choicesFunc = nil
	local stageCsv = {}
	local lastStage
	for k, v in orderCsvPairs(csv.new_guide_local) do
		if lastStage ~= v.stage and not stageCsv[v.stage] then
			lastStage = v.stage
			stageCsv[v.stage] = {
				begin = k,
				specialName = v.specialName,
			}
		end
	end
	self.guideCsv = csv.new_guide_local
	self.stageCsv = stageCsv
end

-- 是否完成某阶段引导
function GuideManagerLocal:checkFinished(stageId)
	local guideIds = userDefault.getForeverLocalKey("guideLocal", {})
	for _, id in ipairs(guideIds) do
		if stageId == id then
			return true
		end
	end
	return false
end

function GuideManagerLocal:onSaveStage(cb, stageId)
	local guideIds = userDefault.getForeverLocalKey("guideLocal", {})
	local hashIds = arraytools.hash(guideIds)
	if not hashIds[stageId] then
		insert(guideIds, stageId)
		userDefault.setForeverLocalKey("guideLocal", guideIds, {new = true})
		printInfo("save guide local stage: " .. stageId)
		cb()
	else
		gGameUI:showTip("guideID error")
	end
end

-- 检测当前状态是否有引导
-- @param params {specialName(特殊场景), name(startSceen场景符合触发判断), awardCb, endCb}
function GuideManagerLocal:checkGuide(params)
	params = params or {}
	log.guide("local check name:", params.name, "specialName:", params.specialName, "isInGuiding:", self:isInGuiding(), self.ignoreGuide, self.continueLastGuide)
	if dev.GUIDE_CLOSED or FOR_SHENHE or self.ignoreGuide then
		return
	end
	if gGameUI.rootViewName == "login.view" then
		return
	end
	local guideIds = userDefault.getForeverLocalKey("guideLocal", {})
	if self:isInGuiding() then
		return
	end

	if self.continueLastGuide then
		self.curGuideId = self.continueLastGuide
		self.continueLastGuide = nil
		self.inGuiding = true
		self:nextGuide()
		return true
	end

	self.curGuideId = nil
	if not self.orderStageCsv then
		self.orderStageCsv = {}
		local hashIds = arraytools.hash(guideIds)
		for stage, v in pairs(self.stageCsv) do
			if not hashIds[stage] then
				insert(self.orderStageCsv, self.guideCsv[v.begin])
			end
		end
		table.sort(self.orderStageCsv, function(a, b)
			if a.order ~= b.order then
				return a.order < b.order
			end
			return a.stage < b.stage
		end)
	end
	-- 查找可以触发的引导
	for i, cfg in ipairs(self.orderStageCsv) do
		if self:canTriggerGuide(cfg, params) then
			table.remove(self.orderStageCsv, i)
			self:triggerGuide(cfg.id, params)
			return true
		end
	end
end

function GuideManagerLocal:triggerGuide(guideId, params)
	params.log = "local trigger:"
	GuideManager.triggerGuide(self, guideId, params)
end

-- 目前这种回调只支持获得奖励那条数据字在引导的最后面(如果要出现获得弹框的话)
-- 不然会导致二级弹框出现之后引导还继续下去
function GuideManagerLocal:quiteGiveAward(cfg, guideId, params)
	printWarn("local guide no award")
	self:nextGuide(params)
end

-- 删除某阶段引导，存在则删除返回true，不存在则返回false
function GuideManagerLocal:onDeleteStage(stageId)
	if dev.GUIDE_CLOSED or FOR_SHENHE or self.ignoreGuide or not stageId then
		return false
	end
	local guideIds = userDefault.getForeverLocalKey("guideLocal", {})
	for i, id in ipairs(guideIds) do
		if stageId == id then
			table.remove(guideIds, i)
			userDefault.setForeverLocalKey("guideLocal", guideIds, {new = true})
			insert(self.orderStageCsv, self.guideCsv[self.stageCsv[stageId].begin])
			printInfo("del guide local stage: " .. stageId)
			return true
		end
	end
	return false
end

return GuideManagerLocal