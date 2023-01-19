-- @date:   2021-03-08
-- @desc:   勇者挑战
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")


local ACTION_TIME = 0.5
local START_TIME  = 1

local UI_START =
{
	{ scale = 1.2, posY = 432},
	{ scale = 1, posY = 864},
	{ scale = 1, posY = 576}
}


local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeView = class("BraveChallengeView",ViewBase)

BraveChallengeView.RESOURCE_FILENAME = "activity_brave_challenge_view.json"
BraveChallengeView.RESOURCE_BINDING = {
	["panelOpt"] = "panelOpt",
	["panelOpt.img01"]     = "img01",
	["panelOpt.viewPanel"] = "viewPanel",
	["panelOpt.doorPanel"] = "doorPanel",
	["panelOpt.txtTime"] = {
    	varname = "txtTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT,  size = 4}}
		}
    },
    ["panelOpt.panelCard"] = "panelCard",
}

function BraveChallengeView:onCreate(id, typ)
	self.topuiBiew = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
        :init({title = gLanguageCsv.braveChallenge, subTitle = "BRAVE CHALLENGE"})

	BCAdapt.set(typ or game.BRAVE_CHALLENGE_TYPE.anniversary)
	self:initModel()
	self:initBg()

	self.subViews = self.subViews or {}
	self.curStatus = idler.new(self.curStatus or 1)
	self.panelPos = self.panelPos or {}

	if #self.subViews == 0 then
		self:addView("city.activity.brave_challenge.main", 1)
		self.curStatus:set(1)
	else
		self:resetView()
	end

	self.curStatus:addListener(function(val, oldVal)
		if val == oldVal then
			self:setBGStatus(val)
		else
			self:playActionByType(oldVal, val)
		end
		self:updateTitle(val)
	end)

	self:initPanelPos()

	--时间
	self:updateTime()

	self.effect = widget.addAnimationByKey(self.doorPanel, "effect/men.skel", "effect", "standby_loop", 10)
			:xy(118,-10)
			:scale(2.7)
end

function BraveChallengeView:initModel()
	--通关次数
    self.id = gGameModel.brave_challenge:getIdler("yyID")
    self.gameInfo = gGameModel.brave_challenge:getIdler("game")
    self.baseID = gGameModel.brave_challenge:getIdler("baseCfgID")
    self.clearanceTimesNum = idler.new(self.passTimes)

end

function BraveChallengeView:initBg()
	local info = self:getBaseInfo()
	self.img01:texture(info.background)
end

function BraveChallengeView:getBaseInfo()
	local base = 1
	if BCAdapt.typ == game.BRAVE_CHALLENGE_TYPE.common then
		base = 101
	end
	return csv.brave_challenge.base[self.baseID:read()] or csv.brave_challenge.base[base]
end

-- 游戏返回重置状态
function BraveChallengeView:resetView()
	for index, data in ipairs(self.subViews) do
		local view = gGameUI:createView(data.name, self):init({parent = self})
		data.view = view
		if index < #self.subViews then
			data.view:hide()
		end
	end
end

-- 设置背景状态
function BraveChallengeView:setBGStatus(val)
	self.panelOpt:scale(UI_START[val].scale)
	self.panelOpt:y(UI_START[val].posY)
end

-- 背景切换动画
function BraveChallengeView:playActionByType(oldVal, val)
	local lastStatus = UI_START[oldVal]
	local curStatus = UI_START[val]
	local posX = self.panelOpt:x()

	self.panelOpt:runAction(cc.EaseOut:create(cc.ScaleTo:create(ACTION_TIME, curStatus.scale), ACTION_TIME))
	self.panelOpt:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(posX,curStatus.posY)), ACTION_TIME))
end


-- 添加界面数据进list
function BraveChallengeView:addView(name, typ, datas)
	local data = {}
	data.name = name
	data.typ  = typ
	data.datas = datas
	data.view = gGameUI:createView(name, self):init({parent = self, data = data})
	table.insert(self.subViews, data)
end

-- 设置进场动画
function BraveChallengeView:setType(typ)
	local lastNum = #self.subViews - 1
	local lastDatas = self.subViews[lastNum]
	lastDatas.view:runEndAction()
	self.curStatus:set(typ)

	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(ACTION_TIME),
		cc.CallFunc:create(function()
			if lastDatas.sign  then
				self:removeView(lastNum)
			else
				lastDatas.view:hide()
			end
		end),
		nil))

	self:runDoorEndAction()
end

-- 移除界面
function BraveChallengeView:removeView(num)
	num = num or #self.subViews
	local data = self.subViews[num]
	data.view:onClose()
	table.remove(self.subViews, num)
end

-- 打开新的界面
function BraveChallengeView:openOtherView(name, typ, isCloseSelf, data)
	if name then
		local curDatas = self.subViews[#self.subViews]
		-- 预防动画期间的点击
		if curDatas.typ == typ then
			return
		end
		curDatas.sign = isCloseSelf
		self:addView(name, typ, data)
	end
end

-- 关闭
function BraveChallengeView:onClose()
	if #self.subViews == 1 then
		ViewBase.onClose(self)
	else
		local curDatas = self.subViews[#self.subViews]
		local lastDatas = self.subViews[#self.subViews - 1]
		curDatas.view:runEndAction()
		self.curStatus:set(lastDatas.typ)

		gGameUI:disableTouchDispatch(nil, false)
		self:runAction(cc.Sequence:create(
			cc.DelayTime:create(ACTION_TIME),
			cc.CallFunc:create(function()
				self:removeView()
				lastDatas.view:show()
				lastDatas.view:runStartAction()

				gGameUI:disableTouchDispatch(nil, true)
				if #self.subViews == 1 then
					self:showCardPanel(false)
					self:runDoorStartAction()
				end
			end),
		nil))
	end
end

--进入游戏保存数据
function BraveChallengeView:saveData()
	for index, data in pairs(self.subViews) do
		data.view:onClose()
	end
	self.curStatus = self.curStatus:read()
end

-- 发起战斗
function BraveChallengeView:startFighting(view, battleCards)
	if self.comingSoon then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	battleEntrance.battleRequest(BCAdapt.url("battleStart"), self.gameInfo:read().floorID, self.gameInfo:read().monsterID, battleCards ,self.id:read())
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
				self:saveData()
			end
		end)
		:show()
end

--活动倒计时
-- nextEndTime 下一期开启倒计时
function BraveChallengeView:updateTime(nextEndTime)
	local endTime = nextEndTime or self:getEndTime()
	bind.extend(self, self.txtTime, {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			strFunc = function(t)
				if nextEndTime then
					return string.format(gLanguageCsv.bcActivityNextTime, t.str)
				end
				return string.format(gLanguageCsv.bcActivityTime, t.str)
			end,
			endFunc = function()
				if nextEndTime then
					performWithDelay(self, function()
						gGameApp:requestServer(BCAdapt.url("main"), function()
							self.subViews[1].view:setCenterPanelVisible(true)
							self:updateTime()
						end)
					end, 1)
				else
					self.comingSoon = true
					self.subViews[1].view:setCenterPanelVisible(false)
					local delay = self.updateTimeEnd and 1 or 0
					self.updateTimeEnd = true
					self.txtTime:text("")
					performWithDelay(self, function()
						gGameApp:requestServer(BCAdapt.url("main"), function()
							-- 特殊处理，显示第一期预告时间
							local info = gGameModel.global_record:read("normal_brave_challenge") or {}
							local endTime = info.endTime or 0
							if endTime == 0 and csv.brave_challenge.open[1] then
								endTime = time.getNumTimestamp(csv.brave_challenge.open[1].startTime, time.getRefreshHour())
								self:updateTime(endTime)
								return
							end
							local endTime = self:getEndTime()
							self.comingSoon = true
							if (endTime + 7 * 24 * 3600) < time.getTime() then
								self.txtTime:text(gLanguageCsv.comingSoon)
							else
								self:updateTime(endTime + 7 * 24 * 3600)
							end
						end)
					end, 0)
				end
			end,
		}
	})
end

-- 更新标题
function BraveChallengeView:updateTitle(val)
	 if val == 2 then
		self.topuiBiew:updateTitle(gLanguageCsv.bcTitle, "BRAVE CHALLENGE")
	else
		local info = self:getBaseInfo()
		self.topuiBiew:updateTitle(info.title or gLanguageCsv.braveChallenge, "BRAVE CHALLENGE")
	end
end


--门开启动画
function BraveChallengeView:runDoorStartAction()
	local fadeIn
	fadeIn = function(view)
		for _ , childView in pairs(view:getChildren()) do
			if childView:getChildrenCount()	== 0 then
				childView:runAction(cc.EaseOut:create(cc.FadeIn:create(ACTION_TIME), ACTION_TIME))
			else
				fadeIn(childView)
			end
		end
	end
	fadeIn(self.doorPanel)
end

-- 门消失动画
function BraveChallengeView:runDoorEndAction()
	local fadeOut
	fadeOut = function(view)
		for _ , childView in pairs(view:getChildren()) do
			if childView:getChildrenCount()	== 0 then
				childView:runAction(cc.EaseOut:create(cc.FadeOut:create(ACTION_TIME), ACTION_TIME))
			else
				fadeOut(childView)
			end
		end
	end
	fadeOut(self.doorPanel)
end
----------------------------------------------------------------------------------------------------
-- 关卡界面精灵展示
-----------------------------------------------------------------------------------------------------
-- 保存初始位置
function BraveChallengeView:initPanelPos()
	for index = 1, 6 do
		local panel = self.panelCard:get(string.format("item%d", index))
		self.panelPos[index] = cc.p(panel:xy())
	end
end

-- 设置精灵的形象
function BraveChallengeView:showCardsDeployments(cardDatas)

	for index = 1, 6  do
		local data = cardDatas[index]
		local panel = self.panelCard:get(string.format("item%d", index))
		panel:xy(self.panelPos[index].x, self.panelPos[index].y)
		if not data then
			if panel:getChildByName("sprite") then
				panel:getChildByName("sprite"):hide()
			end
		else

			local csvUnit  =  csv.unit[data.unit_id]
			if panel.csvID == data.csvID and panel:getChildByName("sprite") then
				panel:getChildByName("sprite"):show()

			else
				panel:removeChildByName("sprite")
				local cardSprite = widget.addAnimationByKey(panel, csvUnit.unitRes, "sprite", "standby_loop", 4)
					:scale(csvUnit.scale * (0.8+(index - 1)%3*0.1))
					:xy( 175, 75)
				cardSprite:setSkin(csvUnit.skin)
				panel.csvID = data.csvID
			end
		end
	end
end

--精灵跑动
function BraveChallengeView:runCardAction()
	for index = 1, 6 do
		local panel = self.panelCard:get(string.format("item%d", index))
		local sprite = panel:getChildByName("sprite")
		if sprite then
			sprite:play("run_loop")
		end

		local x, y = panel:xy()
		panel:runAction(cc.MoveTo:create(START_TIME, cc.p(x + 1000, y)))
	end
end

--设置精灵panel的显示和隐藏
function BraveChallengeView:showCardPanel(isShow)
	self.panelCard:visible(isShow)
end

-- 重置精灵的状态和坐标
function BraveChallengeView:resetPanelPos()
	for index = 1, 6 do
		local panel = self.panelCard:get(string.format("item%d", index))
		panel:xy(self.panelPos[index].x, self.panelPos[index].y)
		local sprite = panel:getChildByName("sprite")
		if sprite then
			sprite:play("standby_loop")
		end
	end
end
-----------------------------------------------------------------------------------------------------------------
--adapt
---------------------------------------------------------------------------------------------------------------
function BraveChallengeView:getEndTime()
	if BCAdapt.typ == game.BRAVE_CHALLENGE_TYPE.anniversary then
		local yyEndtime = gGameModel.role:read("yy_endtime")
		return yyEndtime[self.id:read()]
	else
		-- common在调用之后会重置成false 警惕重置bug
		self.comingSoon = false
		local info = gGameModel.global_record:read("normal_brave_challenge") or {}
		local endTime = info.endTime or 0
		gGameModel.forever_dispatch:getIdlerOrigin("braveChallengeEachClick"):set(endTime)
		if endTime == 0 then
			return time.getNumTimestamp(20210101, time.getRefreshHour())
		end
		return time.getNumTimestamp(info.endTime, time.getRefreshHour())
	end
end
return BraveChallengeView