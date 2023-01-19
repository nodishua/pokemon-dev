-- 主城 - 界面精灵建筑子模块

local DEBUG_SPRITE_AREA
if device.platform == "windows" then
	-- DEBUG_SPRITE_AREA = true
end

local CityView = {}

local halloweenMessages = require("app.views.city.halloween_messages"):getInstance()

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

-- 定时器tag集合，防止重复
local SCHEDULE_TAG = {
	sceneSet = 1,
	cityMan = 2,
	mysteryShop = 3,
	-- onlineGift = 4,
	-- limitBuyGift = 5,
	-- dispatchTaskRefresh = 5,
}

-- 精灵冰冻X秒无点击则恢复
local UNFREEZE_TIME = 2
local UNFREEZE_ACTION_TAG = 2012211734
local UNFREEZE_CLICKS = {3, 9, 16} -- 对应 state 解冻时机

-- 节日主城特效
-- spine1 有昼夜渐变 固定spine名昼夜动画 day_loop night_loop
-- spine2 额外动画, shader昼夜程序渐变
local FESTIVAL_EFFECT = {
	springfestival = {
		spine1 = "zhuchangjing/chunjiezhucheng_light.skel",
		effectName1 = "day_loop",
		spineName1 = "dumpling",
		y1 = -320,
		z1 = 150,
		offx1 = 210,
		spine2 = "zhuchangjing/chunjiezhucheng.skel",
		effectName2 =  "effect_loop",
		spineName2 = "chunjieMan",
		y2 = -230,
		z2 = 120,
		offx2 = 50,
		callback = "onClickChunjieDumpling",
		pos = cc.p(1020,230),
		width = 700,
		height = 400,
		scale = 1.7,
	},
	christmastree = {
		spine1 = "christmastree/shengdanshu.skel",
		effectName1 = "day_loop",
		spineName1 = "shengdanshu",
		y1 = 200,
		z1 = 120,
		offx1 = 0,
		spine2 = "christmastree/shengdanxiong.skel",
		effectName2 =  "daiji_loop",
		effectNameActive2 = "dailingqu_loop",
		spineName2 = "shengdanxiong",
		y2 = 200,
		z2 = 150,
		offx2 = 0,
		callback = "onClickChristmastree",
		pos = cc.p(900,200),
		width = 850,
		height = 800,
		scale = 1.7,
	},
	midmoon = {
		spine2 = "event/huodongtandian.skel",
		effectName2 = "day2_loop",
		effectNameActive2 = "day_loop",
		spineName2 = "midmoon",
		y2 = 200,
		z2 = 120,
		offx2 = 0,
		callback = "onClickMidmoon",
		pos = cc.p(2900,200),
		width = 750,
		height = 650,
		scale = 1.4,
	},
	halloween = {
		spine2 = "wanshengjie/shadiao.skel",
		effectName2 = "effect_loop",
		spineName2 = "shadiao",
		y2 = 10,
		z2 = 0,
		offx2 = 0,
		callback = "onClickHalloweenFour",
		pos = cc.p(1005,245),
		width = 650,
		height = 200,
		scale = 2,
	},
}

local SCENE_SIZE = nil -- 场景滑动尺寸
local CHEZI_EFFECT_NAME = "zhuchangjing/chezi.skel"
local MYSTERY_SHOP_NAME = "zhuchangjing/shenmishangdian.skel"
local MYSTERY_SHOP_POS_TYPE = 1
local HALLOWEEN_CAR_POS = cc.p(2800,160)
local HALLOWEEN_BREAK_SHAN_NAME = "zhuchangjing/zhuchangjing_shan.skel"
local HALLOWEEN_BREAK_FANG_NAME = "zhuchangjing/zhuchangjing_fang.skel"
local HALLOWEEN_BREAK_CHE_NAME = "zhuchangjing/zhuchangjing_che.skel"
local HALLOWEEN_BREAK_SCALE = 1.55
local EFFECT_NAMES = {
	{res = "zhuchangjing/zhucj.skel", name = "zhucj", zOrder = 1},
	{res = "zhuchangjing/xiaowu.skel", name = "xiaowu", zOrder = 3},
	{res = "zhuchangjing/xiaodao.skel", name = "xiaodao", zOrder = 5},
	{res = "zhuchangjing/ta.skel", name = "ta", zOrder = 7},
	{res = "zhuchangjing/dawu_shitou.skel", name = "dawu_shitou", zOrder = 9},
	{res = "zhuchangjing/chezi.skel", name = "chezi", zOrder = 11},
	{res = "zhuchangjing/yezi.skel", name = "yezi", zOrder = 99},
}

-- 20年万圣节
CHEZI_EFFECT_NAME = "zhuchangjing/sd_chezi.skel"
EFFECT_NAMES = {
	{res = "zhuchangjing/sd_zhucj.skel", name = "zhucj", zOrder = 1},
	{res = "zhuchangjing/sd_xiaowu.skel", name = "xiaowu", zOrder = 3},
	{res = "zhuchangjing/sd_xiaodao.skel", name = "xiaodao", zOrder = 5},
	{res = "zhuchangjing/sd_ta.skel", name = "ta", zOrder = 7},
	{res = "zhuchangjing/sd_dawu_shitou.skel", name = "dawu_shitou", zOrder = 9},
	{res = "zhuchangjing/sd_chezi.skel", name = "chezi", zOrder = 11},
	{res = "zhuchangjing/sd_yezi.skel", name = "yezi", zOrder = 99},
}

-- 21年中秋国庆cn替换场景
if checkLanguage("cn") then
	SCENE_SIZE = cc.size(6618, 1440)
	CHEZI_EFFECT_NAME = "zhuchangjing/che.skel"
	MYSTERY_SHOP_NAME = "zhuchangjing/shenmishangdianxin.skel"
	MYSTERY_SHOP_POS_TYPE = 2
	FESTIVAL_EFFECT.midmoon.pos = cc.p(4000,200)
	FESTIVAL_EFFECT.halloween.pos = cc.p(1275,250)
	HALLOWEEN_CAR_POS = cc.p(3830,190)
	HALLOWEEN_BREAK_SHAN_NAME = "zhuchangjing/wsj2_shan.skel"
	HALLOWEEN_BREAK_FANG_NAME = "zhuchangjing/wsj2_zhucheng.skel"
	HALLOWEEN_BREAK_CHE_NAME = "zhuchangjing/wsj2_che.skel"
	HALLOWEEN_BREAK_SCALE = 2
	EFFECT_NAMES = {
		{res = "zhuchangjing/day.skel", name = "day", zOrder = 1},
		{res = "zhuchangjing/yuanfang.skel", name = "yuanfang", zOrder = 3},
		{res = "zhuchangjing/zuofang.skel", name = "zuofang", zOrder = 5},
		{res = "zhuchangjing/guoshanche.skel", name = "guoshanche", zOrder = 7},
		-- {res = "zhuchangjing/guiwu.skel", name = "guiwu", zOrder = 9},
		{res = "zhuchangjing/wsj2_genggui.skel", name = "genggui", zOrder = 9},
		{res = "zhuchangjing/che.skel", name = "chezi", zOrder = 11},
		{res = "zhuchangjing/tong.skel", name = "tong", zOrder = 13},
		{res = "zhuchangjing/yezi2.skel", name = "yezi", zOrder = 99},
	}
end

function CityView:initSceneData()
	self.bgPanel:setScrollBarEnabled(false)
	if SCENE_SIZE then
		self.bgPanel:setInnerContainerSize(SCENE_SIZE)
	end
	local innerSize = self.bgPanel:getInnerContainerSize()
	self.bgPanel:size(display.sizeInViewRect)
		:x(display.sizeInViewRect.x)
		:jumpToPercentHorizontal((1750 - display.sizeInViewRect.width / 2) / (innerSize.width - display.sizeInViewRect.width) * 100)

	self.refreshBgShade = idler.new(true)
	self.roleFigureNum = 1
	self.roleSprite = nil
	-- 当前场景是否黑夜
	self.isNight = idler.new(false)

	self:initHalloween()
	self:initBgPanel()
	self:addCitySprites()
	self:refreshMysteryShop()
	self:initSnowman()

	self:fishingGameTip()

	idlereasy.when(self.level, function(obj, level)
		self:dailyAssistantTip()
	end)

	-- 钓鱼大赛状态
	idlereasy.when(self.crossFishingRound, function(_, crossFishingRound)
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.fishing)
		self.fishPanel:visible(crossFishingRound == "start" and isUnlock == true)
	end)

	-- 界面都创建好后，设置背景渐变处理
	self:initBgShade()

	-- 百变怪判定请求延迟一帧处理
	performWithDelay(self, function()
		self:refreshBaibian()
	end, 0)
end

function CityView:initBgPanel()
	-- 建筑特效，带渐变特效动作
	self.effects = {}

	for i,v in ipairs(EFFECT_NAMES) do
		local effect = widget.addAnimationByKey(self.bgPanel, v.res, v.name, "day_loop", v.zOrder)
			:alignCenter(self.bgPanel:getInnerContainerSize())
			:scale(2)

		self.effects[v.name] = effect
	end

	idlereasy.any({self.yyOpen, self.yyhuodongs}, function (_, yyOpen, yyhuodongs)
		self.halloweenDailyAward:set(false)
		local isOpen = self:initLoginWeal()
		if not isOpen then
			for name, data in pairs(FESTIVAL_EFFECT) do
				if data.spineName1 then
					self.effects[data.spineName1] = nil
				end
				if data.spineName2 then
					self[data.spineName2] = nil
				end
				if self.bgPanel:get(name) then
					self.bgPanel:get(name):removeSelf()
				end
			end
		end
	end)
end

function CityView:initLoginWeal()
	local yyOpen = self.yyOpen:read()
	local yyhuodongs = self.yyhuodongs:read()
	local isOpen = false
	for _,id in ipairs(yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		local clientType = cfg.clientParam.type
		if cfg.type == YY_TYPE.loginWeal and cfg.independent == -1 and FESTIVAL_EFFECT[clientType] then
			isOpen = true
			local csvId = nil
			local huodong = yyhuodongs[id] or {}
			for k,v in pairs(huodong.stamps or {}) do
				if v > 0 then
					if not csvId or k < csvId then
						csvId = k
					end
				end
			end
			local data = FESTIVAL_EFFECT[clientType]
			local effectName1 = data.effectName1
			local effectName2 = data.effectName2
			if csvId then
				if data.effectNameActive2 then
					effectName2 = data.effectNameActive2
				end
			end
			local panel = self.bgPanel:get(clientType)
			if not panel then
				panel = ccui.Layout:create()
				panel:setTouchEnabled(true)
				panel:xy(data.pos)
				panel:addTo(self.bgPanel, 200, clientType)

				if DEBUG_SPRITE_AREA then
					panel:setBackGroundColorType(1)
					panel:setBackGroundColor(cc.c3b(200, 0, 0))
					panel:setBackGroundColorOpacity(100)
				end

				local box = nil
				if data.spine1 then
					local effect = widget.addAnimation(panel, data.spine1, effectName1, data.z1)
						:scale(data.scale)
					self.effects[data.spineName1] = effect
					if not box then
						box = effect:box()
						panel:size(data.width or box.width, data.height)
					end
					effect:xy(box.width/2 + data.offx1, data.y1)
				end
				if data.spine2 then
					local effect = widget.addAnimation(panel, data.spine2, effectName2, data.z2)
					self[data.spineName2] = effect
					if not box then
						box = effect:box()
						panel:size(data.width or box.width, data.height)
					end
					effect:xy(box.width/2 + data.offx2, data.y2)
						:scale(data.scale)
				end
			else
				if self.effects[data.spineName1] then
					self.effects[data.spineName1]:play(effectName1)
				end
				if data.spine2 and self[data.spineName2] then
					self[data.spineName2]:play(effectName2)
				end
			end
			bind.click(self, panel, {method = functools.partial(self[data.callback], self, id, csvId)})
			if clientType == "halloween" then
				self.halloweenDailyAward:set(true)
			end
		end
	end
	return isOpen
end

function CityView:initBgShade()
	-- 除citySpriteDatas外特殊的界面spine
	local speicalEffectNames = {
		"roleSprite",
		"dailyAssistantPanel",
	}
	for _, data in pairs(FESTIVAL_EFFECT) do
		if data.spineName2 then
			table.insert(speicalEffectNames, data.spineName2)
		end
	end
	-- change action
	local startTime = gCommonConfigCsv.cityBgStartTime * 60
	local data = {
		{
			changeAction = "morning",
			action = "day_loop",
			duration = gCommonConfigCsv.cityBgDayDuration * 60,
			shaderColor = cc.vec4(1, 1, 1, 1)
		},{
			changeAction = "dusk",
			action = "night_loop",
			duration = gCommonConfigCsv.cityBgNightDuration * 60,
			shaderColor = cc.vec4(0.75, 0.75, 1.2, 1)
		},
	}

	-- change action
	local totalTime = 0
	for _, v in ipairs(data) do
		totalTime = totalTime + v.duration
	end
	local idx = 1
	local nextTime = 0
	-- 动画变化时间
	local duration = 60
	-- 场景设置
	local function changeBg(init)
		local curData = data[idx]
		self:unSchedule(SCHEDULE_TAG.sceneSet)
		if init or not curData.changeAction then
			for _,effect in pairs(self.effects) do
				effect:play(curData.action)
			end
			for _, name in ipairs(speicalEffectNames) do
				if self[name] then
					cache.setColor2Shader(self[name], false, curData.shaderColor)
				end
			end
			for _, info in pairs(self.citySpriteDatas) do
				cache.setColor2Shader(info.target:get("effect"), false, curData.shaderColor)
			end
			-- 多次调用保持显示不变
			self.curChangIndex = 0
			self.isNight:set(idx == 2)
		else
			for _,effect in pairs(self.effects) do
				effect:play(curData.changeAction)
				effect:addPlay(curData.action)
			end
			local lastIdx = idx == 1 and #data or (idx - 1)
			local lastColor = data[lastIdx].shaderColor
			local targetColor = curData.shaderColor
			local index = self.curChangIndex or 0
			self:schedule(function(dt)
				index = index + 1
				self.curChangIndex = index
				local pow = index / (duration / dt)
				local color = {}
				for k, v in pairs(targetColor) do
					color[k] = lastColor[k] + pow * (v - lastColor[k])
				end
				for _, name in ipairs(speicalEffectNames) do
					if self[name] then
						cache.setColor2Shader(self[name], false, color)
					end
				end
				for _, info in pairs(self.citySpriteDatas) do
					cache.setColor2Shader(info.target:get("effect"), false, color)
				end
				if pow >= 1 then
					self.isNight:set(idx == 2)
					self.curChangIndex = 0
					for _,effect in pairs(self.effects) do
						effect:play(curData.action)
					end
					return false
				end
			end, 1/60, 0, SCHEDULE_TAG.sceneSet)
		end
		-- 下一次切换场景设置
		self.bgPanel:stopAllActions()
		performWithDelay(self.bgPanel, function()
			idx = idx % #data + 1
			nextTime = data[idx].duration
			changeBg()
		end, nextTime)
	end
	idlereasy.when(self.refreshBgShade, function()
		local nowDate = time.getNowDate()
		nextTime = nowDate.hour * 3600 + nowDate.min * 60 + nowDate.sec - startTime
		if nextTime < 0 then
			nextTime = nextTime + 24 * 3600
		end
		nextTime = nextTime % totalTime
		for i, v in ipairs(data) do
			if nextTime < v.duration then
				-- 剩余倒计时
				nextTime = v.duration - nextTime
				idx = i
				break
			end
			nextTime = nextTime - v.duration
		end
		changeBg(true)
	end)
end

function CityView:addCitySprites()
	idlereasy.when(self.figure, function(_, figure)
		local roleCfg = gRoleFigureCsv[figure]
		local name = roleCfg.resSpine
		if self.roleSprite then
			self.roleSprite:removeFromParent()
			self.roleSprite = nil
		end
		if name and name ~= "" then
			local time = 0
			local distance = 30
			local rand
			local baseTime = gCommonConfigCsv.citySpecialTimeMin

			local panel = ccui.Layout:create()
			panel:setTouchEnabled(true)
			panel:xy(roleCfg.pos)
			panel:addTo(self.bgPanel, roleCfg.zOrder)
			self.roleSprite = panel

			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(0, 0, 200))
				panel:setBackGroundColorOpacity(100)
			end
			bind.click(self, panel, {method = functools.partial(self.onClickRoleSprite, self, figure)})

			local effect = widget.addAnimationByKey(panel, name, "effect", "standby_loop1", 1)
				:scale(1)
			local box = effect:box()
			panel:size(box.width, box.height)
			effect:xy(box.width / 2, 0)

			-- 刷新
			self.refreshBgShade:notify()

			self:schedule(function()
				time = time + 1
				if time > baseTime then
					if not rand then
						rand = math.random(baseTime, baseTime + distance)
					end
					if time >= rand and self.roleSprite then
						time = 0
						rand = nil
						self.roleSprite:get("effect"):play("weixuanzhong")
						self:showRoleSpeak(figure, 2)
						self.roleSprite:get("effect"):setSpriteEventHandler(function(event, eventArgs)
							self.roleSprite:get("effect"):play("standby_loop1")
						end, sp.EventType.ANIMATION_COMPLETE)
					end
				end
			end, 1, 0, SCHEDULE_TAG.cityMan)
		end
	end)
	self.spriteUnfreezeYYData = idlereasy.new({})
	idlereasy.any({self.yyOpen, self.yyhuodongs}, function(_, yyOpen, yyhuodongs)
		for _, id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]
			if cfg.type == YY_TYPE.spriteUnfreeze then
				local yyData = yyhuodongs[id] or {}
				local stamps = clone(yyData.stamps or {})
				self.spriteUnfreezeYYData:set({
					yyId = id,
					stamps = stamps,
				})
				return
			end
		end
		self.spriteUnfreezeYYData:set({})
	end)

	self.citySpriteDatas = {}
	self.spriteUnfreezeData = {} -- 本地解冻计数
	idlereasy.any({self.citySprites, self.yyOpen, self.spriteUnfreezeYYData}, function(_, citySprites, yyOpen, spriteUnfreezeYYData)
		for k,v in pairs(self.citySpriteDatas) do
			v.target:removeFromParent()
		end
		local yyOpenHash = arraytools.hash(yyOpen)
		self.citySpriteDatas = {}

		local groups = citySprites.groups
		local baibian = citySprites.baibian or {}
		local mini = citySprites.miniQ
		local spriteUnfreezeStamps = spriteUnfreezeYYData.stamps or {}

		for _,v in ipairs(groups) do
			local sprites = gCitySpritesCsv[v]
			for _,data in ipairs(sprites) do
				local x, y = data.position.x, data.position.y
				local scale = data.scale
				for _, activityId in csvPairs(data.activityIds) do
					if yyOpenHash[activityId] then
						x, y = data.activityPosition.x, data.activityPosition.y
						scale = data.activityScale
						break
					end
				end
				local panel = ccui.Layout:create()
				panel:setTouchEnabled(true)
				panel:addTo(self.bgPanel, data.zOrder)
				panel:xy(x, y)
				local actionName = "effect_loop"
				local isBaibian = false
				if baibian.id and baibian.id == data.id then
					actionName = "effect1_loop"
					isBaibian = true
				end
				local obj = widget.addAnimationByKey(panel, data.res, "effect", actionName, 1)
					:scale(scale)
				local box
				if data.touchSize then
					box = {
						width = data.touchSize.width * scale,
						height = data.touchSize.height * scale,
					}
				else
					box = obj:box()
				end
				panel:size(box.width, box.height)
				obj:xy(box.width / 2, 0)
				if DEBUG_SPRITE_AREA then
					panel:setBackGroundColorType(1)
					panel:setBackGroundColor(cc.c3b(200, 0, 0))
					panel:setBackGroundColorOpacity(100)
				end
				bind.click(self, panel, {method = functools.partial(self.onClickSprite, self, {cfg = data, csvId = data.id})})
				self.citySpriteDatas[data.id] = {data = data, target = panel, isBaibian = isBaibian, isGet = false}
				-- 有解冻精灵可领奖励，数据界面保存
				if spriteUnfreezeStamps[data.id] == 1 then
					if not self.spriteUnfreezeData[data.id] then
						self.spriteUnfreezeData[data.id] = {
							state = 1, -- 1:冰冻时待机，2:解冻一小半，3:解冻一大半
							clickCount = 0, -- 点击计数
						}
					end
					self:onFreezeSprite(data)
				end


				idlereasy.any({self.isNight, self.halloweenAllSpriteClicked, self.halloweenDailyAward}, function (_, isNight, halloweenAllSpriteClicked, halloweenDailyAward)
					panel:show()
					if isNight and halloweenAllSpriteClicked == false then
						panel:hide()
					end
					if halloweenDailyAward then
						if data.type == 2 then
							panel:hide()
						end
					end
				end):anonyOnly(self, data.id)
			end
		end

		if mini and mini.id and mini.id ~= 0 then
			local cfg = csv.city_sprites[mini.id]
			local x, y = cfg.position.x, cfg.position.y
			local scale = cfg.scale
			for _, activityId in csvPairs(cfg.activityIds) do
				if yyOpenHash[activityId] then
					x, y = cfg.activityPosition.x, cfg.activityPosition.y
					scale = cfg.activityScale
					break
				end
			end
			local panel = ccui.Layout:create()
			panel:setTouchEnabled(true)
			panel:addTo(self.bgPanel, cfg.zOrder)
			panel:xy(x, y)
			local obj = widget.addAnimationByKey(panel, cfg.res, "effect", "effect_loop", 1)
				:scale(scale)

			local box
			if cfg.touchSize then
				box = {
					width = cfg.touchSize.width * scale,
					height = cfg.touchSize.height * scale,
				}
			else
				box = obj:box()
			end
			panel:size(box.width, box.height)
			obj:xy(box.width / 2, 0)
			local info = {}
			info.cfg = cfg
			info.csvId = mini.id
			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(200, 0, 0))
				panel:setBackGroundColorOpacity(100)
			end
			bind.click(self, panel, {method = functools.partial(self.onClickSprite, self, info)})
			self.citySpriteDatas[mini.id] = {data = cfg, target = panel, isMiniQ = true}
		end
		-- 刷新
		self.refreshBgShade:notify()
	end)
end

function CityView:refreshBaibian()
	local citySprites = self.citySprites:read()
	local curTime = time.getTime()
	local baibian = citySprites.baibian
	local endTime = curTime
	local baibianExist = baibian and next(baibian)
	if baibianExist and baibian.period then
		endTime = time.getNumTimestamp(baibian.period or 0, time.getRefreshHour()) + gCommonConfigCsv.citySpriteBaibianPeriodDay * 24 * 3600 + 1
	end
	-- 不在CD范围内 并且有次数 或者 不在当前周期内
	-- citySprites.baibian == nil 表示第一次进入没有数据
	if not baibianExist or ((curTime - baibian.last > gCommonConfigCsv.citySpriteBaibianCD) and
			(curTime > endTime or (baibian.times or 0) < gCommonConfigCsv.citySpriteBaibianTimeMax)) then
		local rand = math.random(1, 100)
		-- 如果有请求本次就不发送 （目前触发这部分还算是很频繁的 一次不触发 问题不大）
		if rand <= gCommonConfigCsv.citySpriteBaibianProbability then
			gGameApp:slientRequestServer("/game/role/city/sprite/active", nil, 1)
		end
	end

	local mini = citySprites.miniQ
	local miniExist = mini and next(mini)
	endTime = curTime
	if miniExist and mini.period then
		endTime = time.getNumTimestamp(mini.period or 0, time.getRefreshHour()) + gCommonConfigCsv.citySpriteMiniQPeriodDay * 24 * 3600 + 1
	end
	if not miniExist or ((curTime - mini.last > gCommonConfigCsv.citySpriteMiniQCD) and
			(curTime > endTime or (mini.times or 0) < gCommonConfigCsv.citySpriteMiniQTimeMax)) then
		local rand = math.random(1, 100)
		if rand <= gCommonConfigCsv.citySpriteMiniQProbability then
			gGameApp:slientRequestServer("/game/role/city/sprite/active", nil, 2)
		end
	end
end

function CityView:showRoleSpeak(csvId, flag)
	local parent, cfg, effect
	if flag == 1 then
		local info = self.citySpriteDatas[csvId]
		parent = info.target
		cfg = csv.city_sprites[csvId]
	elseif flag == 2 then
		parent = self.roleSprite
		cfg = gRoleFigureCsv[csvId]
	end
	effect = parent:getChildByName("effect")
	parent:removeChildByName("talkContent")
	parent:removeChildByName("talkBg")
	local content = {}
	local count = 0
	for i=1,10 do
		local str = cfg["chattext" .. i]
		if not str or str == "" then
			break
		end
		table.insert(content, str)
		count = count + 1
	end
	local box = effect:box()
	-- local idx = math.random(1, count)
	if self.roleFigureNum > count then
		self.roleFigureNum = math.random(1, count)
	end
	local offPos = cfg.offPos
	local width = 240

	local txt = rich.createWithWidth("#C0x5b545b#" .. content[self.roleFigureNum], 40, nil, width)
		:anchorPoint(0.5, 0)
		:xy(box.width / 2 + offPos.x, box.height + 40 + offPos.y)
		:addTo(parent, 3, "talkContent")
	local size = txt:size()
	local bg = ccui.Scale9Sprite:create()
	bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
	bg:size(size.width + 60, size.height + 60)
		:anchorPoint(0.5, 0)
		:xy(box.width / 2 + offPos.x, box.height + offPos.y)
		:scaleX(cfg.overture and -1 or 1)
		:addTo(parent, 2, "talkBg")
	parent:setTouchEnabled(false)
	performWithDelay(parent, function()
		parent:removeChildByName("talkContent")
		parent:removeChildByName("talkBg")
		parent:setTouchEnabled(true)
	end, 2)
	self.roleFigureNum = math.max((self.roleFigureNum + 1) % (count + 1), 1)
end

function CityView:addCar(z)
	local shopPanel = self.bgPanel:get("steryShop")
	if shopPanel then
		shopPanel:removeSelf()
	end
	local effect = self.bgPanel:getChildByName("chezi")
	if effect then
		return
	end
	effect = widget.addAnimationByKey(self.bgPanel, CHEZI_EFFECT_NAME, "chezi", "day_loop", z)
		:alignCenter(self.bgPanel:getInnerContainerSize())
		:scale(2)
		:setCascadeOpacityEnabled(true)
		:opacity(0)
	self.effects["chezi"] = effect
	transition.fadeIn(effect, {time = 1})
end

function CityView:refreshMysteryShop()
	-- 0:没出现 1:触发 但是没在主城出现 2:在主城出现
	local mysteryState = userDefault.getForeverLocalKey("mySteryState", 0)
	local isOpen = uiEasy.isOpenMystertShop()
	local state = 1
	if uiEasy.showMysteryShop() or isOpen then
		state = 2
	elseif not isOpen then
		state = 0
	end
	userDefault.setForeverLocalKey("mySteryState", state)

	local mystery = self.bgPanel:getChildByName("steryShop")
	if isOpen and state ~= 0 and not mystery then
		local carEft = self.bgPanel:getChildByName("chezi")
		local z = 11
		if carEft then
			z = carEft:z()
			carEft:removeFromParent()
		end
		mystery = ccui.Layout:create():size(600, 350)
		mystery:setTouchEnabled(true)
		mystery:addTo(self.bgPanel, z, "steryShop")
		mystery:xy(2180, 450)
		mystery:anchorPoint(0, 0)
		local effect = widget.addAnimation(mystery, MYSTERY_SHOP_NAME, "day_loop", 1)
			:scale(2)
			:xy(0, 250)
			:setCascadeOpacityEnabled(true)
			:opacity(0)
		if MYSTERY_SHOP_POS_TYPE ~= 1 then
			effect:xy(280, 100)
		end
		transition.fadeIn(effect, {time = 1})
		self.effects["chezi"] = effect
		self:schedule(function()
			local openState = uiEasy.isOpenMystertShop()
			if not openState then
				userDefault.setForeverLocalKey("mySteryState", 0)
				self:addCar(z)

				return false
			end
		end, 1, 0, SCHEDULE_TAG.mysteryShop)

		if DEBUG_SPRITE_AREA then
			mystery:setBackGroundColorType(1)
			mystery:setBackGroundColor(cc.c3b(200, 0, 0))
			mystery:setBackGroundColorOpacity(100)
		end
		bind.click(self, mystery, {method = function()
			gGameApp:requestServer("/game/mystery/get", function()
				gGameUI:stackUI("city.mystery_shop.view", nil, {full = true})
			end)
		end})

	elseif not isOpen and mystery then
		self:addCar(mystery:z())
	end
	-- 如果有万圣节活动，晚上未点完捣蛋精灵不显示神秘商店
	if self.isNight:read() and self.halloweenActivity:read() and not self.fixCar then
		local steryShop = self.bgPanel:get("steryShop")
		if steryShop then
			steryShop:hide()
		end
		local chezi = self.bgPanel:getChildByName("chezi")
		if chezi then
			chezi:hide()
		end
	end
	self.refreshBgShade:notify()
end

function CityView:onClickRoleSprite(csvId)
	local roleCfg = gRoleFigureCsv[csvId]
	local effect = self.roleSprite:get("effect")
	if not effect then
		return
	end
	effect:play("act")
	self.roleSprite:setTouchEnabled(false)
	self:showRoleSpeak(csvId, 2)
	effect:setSpriteEventHandler(function(event, eventArgs)
		self.roleSprite:setTouchEnabled(true)
		effect:play("standby_loop1")
	end, sp.EventType.ANIMATION_COMPLETE)
end

function CityView:onClickMidmoon(huodongId, csvId)
	if not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveMidmoon)
		return
	end
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/award/get")
			:params(huodongId, csvId)
			:onResponse(function (tb)
		showOver[1] = true
	end)
			:wait(showOver)
			:doit(function (tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onClickChristmastree(huodongId, csvId)
	local effect = self.shengdanxiong
	if not effect or not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)
		return
	end
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/award/get")
			:params(huodongId, csvId)
			:onResponse(function (tb)
		local effectGet = self:get("effectGet")
		if not effectGet then
			effectGet = widget.addAnimationByKey(self, "christmastree/shengdanxiong.skel", "effectGet", "lingqu", 150)
				:alignCenter(self:getContentSize())
				:scale(1.7)
		else
			effectGet:show():play("lingqu")
		end
		effectGet:setSpriteEventHandler(function(event, eventArgs)
			effect:play("daiji_loop")
			effectGet:hide()
			showOver[1] = true
		end, sp.EventType.ANIMATION_COMPLETE)
	end)
			:wait(showOver)
			:doit(function (tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onClickChunjieDumpling(huodongId, csvId)
	local effect = self.chunjieMan
	if not effect or not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)
		return
	end
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/award/get")
			:params(huodongId, csvId)
			:onResponse(function (tb)
		-- TODO 后续扩展
		showOver[1] = true
	end)
			:wait(showOver)
			:doit(function (tb)
		gGameUI:showGainDisplay(tb)
	end)
end

-- 万圣节活动, 捣蛋精灵
function CityView:onAllSaintsDaySpine(x, y, index)
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local panel = ccui.Layout:create()
	local halloweenData = halloweenMessages.get()
	local range = csvHalloween.range
	local x = x
	local y = y
	if halloweenData[index] then
		x = halloweenData[index].x
		y = halloweenData[index].y
	end
	panel:setTouchEnabled(true)
	panel:anchorPoint(0.5, 0.5)
	panel:xy(x, y)
	panel:addTo(self.bgPanel, 1000)
	local effect
	if csvHalloween.spcialAct ~= 0 and not halloweenData[index] then
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect" ,"standby1_loop", 1000)
	else
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect" ,"standby_loop", 1000)
	end
	local box = effect:box()
	local centerPosX = csvHalloween.normPos[1]
	local dir = x < centerPosX and -1 or 1
	effect:scale(csvHalloween.scale * dir, csvHalloween.scale)
	panel:size(150, 150)
	effect:xy(150/2, 150/2)
	if DEBUG_SPRITE_AREA then
		panel:setBackGroundColorType(1)
		panel:setBackGroundColor(cc.c3b(200, 0, 0))
		panel:setBackGroundColorOpacity(100)
	end
	bind.click(self, panel, {method = functools.partial(self.onClickhalloweenSpineChange, self, panel, index, dir)})
	self.halloweenTab["yexunling"..index] = panel
end

function CityView:onClickhalloweenSpineChange(targetPanel, index, dir)
	--点击的次数
	local halloweenData = halloweenMessages.get()

	local csvHalloween = csv.yunying.halloween_sprites[index]
	local isFisrt = false

	local range = csvHalloween.range
	local clickNumTab = csvHalloween.needClick
	local x = math.random(range[1][1], range[2][1])
	local y = math.random(range[1][2], range[2][2])
	local clickNum = math.random(clickNumTab[1], clickNumTab[2])
	if not halloweenData[index] and csvHalloween.spcialAct ~= 0 then
		x = csvHalloween.posClick[1]
		y = csvHalloween.posClick[2]
		isFisrt = true
	end

	halloweenData = halloweenMessages.getHalloweenMessages(halloweenData, x, y, index, clickNum)
	halloweenMessages.set(halloweenData)

	if halloweenMessages.get()[index].num >= halloweenMessages.get()[index].clickNum then
		local panel = targetPanel:clone()
		panel:addTo(self.bgPanel)
			:scale(targetPanel:scaleX(), targetPanel:scaleY())
			:xy(targetPanel:xy())

		targetPanel:removeSelf()
		self.halloweenTab["yexunling"..index] = nil
		local effect = panel:getChildByName("effect")
		if not effect then
			effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect" ,"standby_loop", 1000)
			effect:scale(csvHalloween.scale * dir, csvHalloween.scale)
			effect:xy(150/2, 150/2)
		end
		effect:play("effect_xiaoshi")
		effect:setSpriteEventHandler(function(event, eventArgs)
			performWithDelay(self, function()
				panel:removeSelf()
			end, 0)
		end, sp.EventType.ANIMATION_COMPLETE)

		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.halloweenId, index)
	else
		local effect = targetPanel:getChildByName("effect")
		effect:scale(csvHalloween.scale * dir, csvHalloween.scale)
		if csvHalloween.spcialAct ~= 0 and isFisrt then
			effect:play("effect_tiaochu")
			effect:addPlay("standby_loop")
		else
			effect:play("effect_xiaoshi")
			effect:addPlay("effect_chuxian")
			effect:addPlay("standby_loop")
		end
		if csvHalloween.spcialAct == 2 then
			effect:xy(-400, 500)
		else
			effect:xy(150/2, 150/2)
		end
		performWithDelay(self, function()
			if self.halloweenTab["yexunling"..index] and not tolua.isnull(targetPanel) then
				targetPanel:xy(x, y)
				if csvHalloween.spcialAct ~= 2 then
					local centerPosX = (range[1][1] + range[2][1])/2
					if x < centerPosX then
						effect:scaleX(-1 * csvHalloween.scale)
					else
						effect:scaleX(1 * csvHalloween.scale)
					end
				end
			end
		end, 0.5)
	end
end

function CityView:onClickhalloweenSpineMove(x, y, index)
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local range = csvHalloween.range

	local panel = ccui.Layout:create()
	panel:setTouchEnabled(true)

	local halloweenData = halloweenMessages.get()
	local x = x
	local y = y
	if halloweenData[index] then
		x = halloweenData[index].x
		y = halloweenData[index].y
	end
	panel:xy(x, y)
	panel:addTo(self.bgPanel, 1000)
	local effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect","standby_loop",1000)
	local box = effect:box()
	panel:size(box.width, box.height)
	effect:xy(box.width / 2, 0)
	effect:scale(csvHalloween.scale)

	if DEBUG_SPRITE_AREA then
		panel:setBackGroundColorType(1)
		panel:setBackGroundColor(cc.c3b(200, 0, 0))
		panel:setBackGroundColorOpacity(100)
	end
	bind.click(self, panel, {method = functools.partial(self.onClickhalloweenSpineMoveChange, self, x, y, panel, index)})
	self.halloweenTab["nanguajing"..index] = panel
end

function CityView:onClickhalloweenSpineMoveChange(x, y, targetPanel, index)
	local halloweenData = halloweenMessages.get()
	targetPanel:setTouchEnabled(false)

	local csvHalloween = csv.yunying.halloween_sprites[index]
	local range = csvHalloween.range
	local clickNumTab = csvHalloween.needClick
	local finalPos = csvHalloween.finalPos
	local clickNum = math.random(clickNumTab[1], clickNumTab[2])
	local lenX, lenY = csvHalloween.randDistance[1], csvHalloween.randDistance[2]

	local directionX, directionY, randomNum = halloweenMessages.getSpritesPos(x, y, index)
	lenX = directionX -	x
	lenY = directionY -	y
	local isFinal = false

	if (halloweenData[index] and halloweenData[index].num + 1 or 1) >= (halloweenData[index] and halloweenData[index].clickNum or clickNum) then
		directionX, directionY = finalPos[1], finalPos[2]
		lenX = directionX -	x
		lenY = directionY -	y
		if lenX >= 0 and lenY >= 0 then
			randomNum = 1
		elseif lenX >= 0 and lenY < 0 then
			randomNum = 2
		elseif lenX < 0 and lenY < 0 then
			randomNum = 3
		elseif lenX < 0 and lenY >= 0 then
			randomNum = 4
		end
		isFinal = true
	end

	local panel = self.bgPanel:get("tmpNanguajing" .. index)
	if panel then
		panel:removeSelf()
	end
	local panel = targetPanel:clone()
	panel:addTo(self.bgPanel)
		:scale(targetPanel:scale())
		:xy(targetPanel:xy())
		:name("tmpNanguajing" .. index)
	local effect = panel:get("effect")
	if not effect then
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect","standby_loop",1000)
		effect:scale(csvHalloween.scale)
		local box = effect:box()
		effect:xy(box.width / 2, 0)
	end
	effect:play("run_loop")

	targetPanel:removeSelf()
	self.halloweenTab["nanguajing"..index] = nil

	local function cb(x, y)
		self:unSchedule("nValueChange"..index)
		if isFinal then
			effect:play("standby_loop")
			performWithDelay(self.bgPanel, function()
				effect:play("effect_zhuazhu")
			end, 2)
			performWithDelay(self.bgPanel, function()
				panel:removeSelf()
				gGameApp:requestServer("/game/yy/award/get", function(tb)
					gGameUI:showGainDisplay(tb)
				end, self.halloweenId, index)
			end, 3)
		else
			panel:removeSelf()
			halloweenData = halloweenMessages.getHalloweenMessages(halloweenData, x, y, index, clickNum)
			halloweenMessages.set(halloweenData)
			self:onClickhalloweenSpineMove(x, y, index)
		end
	end
	self:enableSchedule():schedule(function()
		--存在一起随机数
		local tmp = math.abs(lenY)/math.abs(lenX)
		local tmpRandomX = lenX/60
		local tmpRandomY = lenY/60

		if lenX >= 0 then
			tmpRandomX = 4
		else
			tmpRandomX = -4
		end
		if lenY >= 0 then
			tmpRandomY = 4*tmp
		else
			tmpRandomY = -4*tmp
		end


		x = x + tmpRandomX
		y = y + tmpRandomY
		panel:xy(x, y)
		if randomNum == 1 then
			if x + tmpRandomX >= directionX or y + tmpRandomY >= directionY	then
				cb(x, y)
			end
		elseif randomNum == 2 then
			if x + tmpRandomX >= directionX or y + tmpRandomY <= directionY then
				cb(x, y)
			end
		elseif randomNum == 3 then
			if x + tmpRandomX <= directionX or y + tmpRandomY <= directionY then
				cb(x, y)
			end
		elseif randomNum == 4 then
			if x + tmpRandomX <= directionX or y + tmpRandomY >= directionY	then
				cb(x, y)
			end
		end

	end, 1/60, 1, "nValueChange"..index)
end

function CityView:onClickHalloweenCar()
	local yyhuodongs = self.yyhuodongs:read()
	local stamps = yyhuodongs[self.halloweenId] and yyhuodongs[self.halloweenId].stamps or {}
	local canHalloweenGet = stamps[0] == 1 -- 最终奖励是否领取
	if not canHalloweenGet then
		gGameUI:showTip(gLanguageCsv.halloweenInDay)
		return
	end
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.halloweenId, 0)
end

function CityView:onClickHalloweenFour(id, csvId)
	if not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)
		return
	end

	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/award/get")
		:params(id, csvId)
		:onResponse(function (tb)
			local effect = self["shadiao"]
			if effect then
				effect:play("effect_xiru")
				effect:addPlay("effect_loop")
				effect:setSpriteEventHandler(function(event, eventArgs)
					showOver[1] = true
				end, sp.EventType.ANIMATION_COMPLETE)
			else
				performWithDelay(self, function()
					showOver[1] = true
				end, 2)
			end
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay(tb)
		end)
end

function CityView:fixCarAndHouse()
	if self.fixCar then
		if self.bgPanel:getChildByName("halloweenBreakCar") then
			if self.bgPanel:get("halloweenBreakCar") then
				self.bgPanel:get("halloweenBreakCar"):removeSelf()
			end
			local effect = widget.addAnimationByKey(self.bgPanel, HALLOWEEN_BREAK_CHE_NAME, "halloweenBreakCar", "effect_xiufu", 120)
				:alignCenter(self.bgPanel:getInnerContainerSize())
				:scale(HALLOWEEN_BREAK_SCALE)
				:setCascadeOpacityEnabled(true)
				:opacity(0)
			performWithDelay(self, function()
				if self.bgPanel:get("halloweenBreakCar") then
					self.bgPanel:get("halloweenBreakCar"):removeSelf()
				end
			end, 2)
		end
	end

	if self.fixHouse then
		if self.bgPanel:getChildByName("halloweenFang") then
			if self.bgPanel:get("halloweenFang") then
				self.bgPanel:get("halloweenFang"):removeSelf()
			end
			local effect = widget.addAnimationByKey(self.bgPanel, HALLOWEEN_BREAK_FANG_NAME, "halloweenFang", "effect_xiufu", 9)
				:alignCenter(self.bgPanel:getInnerContainerSize())
				:scale(HALLOWEEN_BREAK_SCALE)
			performWithDelay(self, function()
				if self.bgPanel:get("halloweenFang") then
					self.bgPanel:get("halloweenFang"):removeSelf()
				end
			end, 2)
		end
	end
end

--堆雪人活动
function CityView:initSnowman()
	self.snowmanId = idler.new()
	idlereasy.any({self.yyOpen}, function (_, yyOpen)
		for _,id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]
			if cfg.type == YY_TYPE.huoDongCloth then
				self.snowmanId:set(id)
				return
			end
		end
		self.snowmanId:set()
	end)
	idlereasy.any({self.yyhuodongs, self.snowmanId}, function(_, yyhuodongs, snowmanId)
		if not snowmanId then
			local panel = self.bgPanel:get("snowman")
			if panel then
				panel:removeAllChildren()
			end
		else
			local yyData = self.yyhuodongs:read()[snowmanId] or {}
			local snowLevel = 0
			if yyData.info then
				snowLevel = yyData.info.level
			end
			local yyCfg = csv.yunying.yyhuodong[snowmanId]
			local huodongID = yyCfg.huodongID
			local panel = self.bgPanel:get("snowman")
			local size = cc.size(500, 540)
			local pos = cc.p(250, 170)
			if not panel then
				panel = ccui.Layout:create()
							:xy(cc.p(1330,380))
							:size(size)
							:addTo(self.bgPanel, 9, "snowman")
				panel:setTouchEnabled(true)
			else
				panel:removeAllChildren()
			end
			ccui.ImageView:create("activity/snowman/img_cs_snowman.png")
				:xy(pos)
				:addTo(panel, 30, "snow")
				:scale(1.6)
			if snowLevel == 0 then
				local tips = ccui.Scale9Sprite:create()
				tips:initWithFile(cc.rect(56, 43, 1, 1), "activity/snowman/box_sd_dialog.png")
				tips:size(190,87)
					:anchorPoint(0.3, 0)
					:xy(330, 340)
					:addTo(panel, 100, "snowTip")
				cc.Label:createWithTTF(str, "font/youmi1.ttf", 28)
					:color(cc.c4b(255, 255, 255, 255))
					:xy(90, 48)
					:addTo(panel:get("snowTip"), 2, "tipText")
				local label = panel:get("snowTip"):getChildByName("tipText")
				label:text(gLanguageCsv.snowClothEntranceTip)
			end
			panel:get("snow"):setTouchEnabled(false)
			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(200, 0, 0))
				panel:setBackGroundColorOpacity(100)
			end
			bind.click(self, panel, {method = functools.partial(self.onClickSnowman, self)})
			--衣服帽子
			local targets = yyData.targets
			if targets then
				for i = 1,itertools.size(targets) do
					local cfg = csv.yunying.huodongcloth_part[targets[tostring(i)]]
					local panel1 = self.bgPanel:get("snowman"):get("decoration"..targets[tostring(i)])
					local xPos = cfg.lookPos.x
					local yPos = cfg.lookPos.y
					if not pane1l then
						panel1 = ccui.Layout:create()
							:xy(pos)
							:size(size)
							:addTo(self.bgPanel:get("snowman"), cfg.zOrder, "decoration"..targets[tostring(i)])
						if cfg.showType == "pic" then
							ccui.ImageView:create(cfg.res)
								:xy(xPos,yPos)
								:addTo(panel1, 1, "decoration")
								:scale(0.75)
						else
							widget.addAnimationByKey(panel1, cfg.res, "decoration", "night_loop", 120)
								:scale(0.75)
								:xy(xPos, yPos)
						end
					end
				end
			end
			--装饰
			for k,v in orderCsvPairs(csv.yunying.huodongcloth_level) do
				for id,val in orderCsvPairs(csv.yunying.huodongcloth_part) do
					if snowLevel >= v.level and val.huodongID == huodongID and val.belongPart == v.unlockPart and v.unlockPart > 100 then
						local panel1 = self.bgPanel:get("snowman"):get("decoration"..id)
						local xPos = val.lookPos.x
						local yPos = val.lookPos.y
						if not pane1l then
							panel1 = ccui.Layout:create()
								:xy(pos)
								:size(size)
								:addTo(self.bgPanel:get("snowman"), val.zOrder, "decoration"..id)
							if val.showType == "pic" then
								ccui.ImageView:create(val.res)
									:xy(xPos,yPos)
									:addTo(panel1, 1, "decoration")
									:scale(1.6)
							else
								widget.addAnimationByKey(panel1, val.res, "decoration", "night_loop", 120)
									:scale(1.6)
									:xy(xPos, yPos)
							end
						end
					end
				end
			end
		end
	end)
end

function CityView:onClickSnowman()
	local snowmanId = self.snowmanId:read()
	if snowmanId then
		gGameApp:requestServer("/game/yy/cloth/main", function(tb)
			gGameUI:stackUI("city.activity.snowman", nil,nil,snowmanId)
		end, snowmanId)
	end
end

-- 解冻小精灵设置
function CityView:onFreezeSprite(data)
	local csvId = data.id
	local res = data.res
	local panel = self.citySpriteDatas[csvId].target
	local size = panel:size()
	local function recover(panel, effect, spriteUnfreezeData)
		local state = spriteUnfreezeData.state
		local clickCount = spriteUnfreezeData.clickCount
		-- 解冻定时恢复
		panel:stopActionByTag(UNFREEZE_ACTION_TAG)
		if state > 1 then
			local action = performWithDelay(panel, function()
				panel:stopActionByTag(UNFREEZE_ACTION_TAG)
				state = 1
				clickCount = 0
				spriteUnfreezeData.state = state
				spriteUnfreezeData.clickCount = clickCount
				effect:play("effect_loop")
				local freezeRecoverBg = widget.addAnimationByKey(panel, res, "freezeRecoverBg", "BK_huifu_hou", 0)
					:scale(2)
					:xy(size.width / 2, 0)
				local freezeRecoverFg = widget.addAnimationByKey(panel, res, "freezeRecoverFg", "BK_huifu_qian", 2)
					:scale(2)
					:xy(size.width / 2, 0)
				freezeRecoverFg:setSpriteEventHandler()
				freezeRecoverFg:setSpriteEventHandler(function()
					freezeRecoverFg:setSpriteEventHandler()
					performWithDelay(panel, function()
						freezeRecoverBg:removeFromParent()
						freezeRecoverFg:removeFromParent()
						effect:play("JS_bingdong" .. state .. "_loop")
					end, 0)
				end, sp.EventType.ANIMATION_COMPLETE)
			end, UNFREEZE_TIME)
			action:setTag(UNFREEZE_ACTION_TAG)
		end
	end

	local spriteUnfreezeData = self.spriteUnfreezeData[csvId]
	local state = spriteUnfreezeData.state
	if UNFREEZE_CLICKS[state] then
		local effect = panel:get("effect")
		effect:play("JS_bingdong" .. state .. "_loop")
		recover(panel, effect, spriteUnfreezeData)
	end
	bind.click(self, panel, {method = function()
		if not self.citySpriteDatas[csvId] then
			return
		end
		local panel = self.citySpriteDatas[csvId].target
		local effect = panel:get("effect")
		local size = panel:size()
		local spriteUnfreezeData = self.spriteUnfreezeData[csvId]
		local state = spriteUnfreezeData.state
		local clickCount = spriteUnfreezeData.clickCount
		if UNFREEZE_CLICKS[state] then
			local freezeEffect = panel:get("freezeEffect")
			if not freezeEffect then
				freezeEffect = widget.addAnimation(panel, "zhuchangjing/bingbao.skel", "bingbao", 10)
					:alignCenter(size)
			end
			local freezeRecoverFg = panel:get("freezeRecoverFg")
			if freezeRecoverFg then
				freezeRecoverFg:stopAllActions()
				freezeRecoverFg:removeFromParent()
				panel:get("freezeRecoverBg"):removeFromParent()
				effect:play("JS_bingdong" .. state .. "_loop")
			end
			freezeEffect:play("bingbao")
			clickCount = clickCount + 1
			spriteUnfreezeData.clickCount = clickCount
			if clickCount >= UNFREEZE_CLICKS[state] then
				state = state + 1
				spriteUnfreezeData.state = state
				if not UNFREEZE_CLICKS[state] then
					state = 0
					spriteUnfreezeData.state = state
					effect:play("effect_loop")
					local yydata = self.spriteUnfreezeYYData:read()
					local yyId = yydata.yyId
					self:onUnfreezeAward(yyId, csvId)
				else
					effect:play("JS_bingdong" .. state .. "_loop")
				end
			end

			recover(panel, effect, spriteUnfreezeData)
		end
	end})
end

-- 解冻小精灵领取
function CityView:onUnfreezeAward(yyID, csvId)
	if not yyID or not csvId then
		return
	end
	gGameApp:requestServer("/game/yy/award/get", function (tb)
		gGameUI:showGainDisplay(tb)
	end, yyID, csvId)
end

-- 小助手
function CityView:dailyAssistantTip()
	if not dataEasy.isShow("dailyAssistant") then
		return
	end
	local dailyAssistantPanel = self.bgPanel:getChildByName("dailyAssistantPanel")
	if dailyAssistantPanel == nil then
		dailyAssistantPanel = ccui.Layout:create()
		dailyAssistantPanel:setTouchEnabled(true)
		dailyAssistantPanel:addTo(self.bgPanel, 20, "dailyAssistantPanel")
		dailyAssistantPanel:xy(2100, 700)
		dailyAssistantPanel:anchorPoint(0.5, 0)

		local scaleAll = 1.4
		local obj = widget.addAnimationByKey(dailyAssistantPanel, "luotuomutujian/luotuomutujian.skel", 'luotuomutujian', "effect_loop", 1)
		obj:anchorPoint(cc.p(0.5, 0.5))
		obj:scale(scaleAll)
		local box = obj:box()
		box.width = box.width * scaleAll
		box.height = box.height * scaleAll
		obj:xy(box.width/2, -50)
		dailyAssistantPanel:size(box.width, box.height)

		if DEBUG_SPRITE_AREA then
			dailyAssistantPanel:setBackGroundColorType(1)
			dailyAssistantPanel:setBackGroundColor(cc.c3b(200, 0, 0))
			dailyAssistantPanel:setBackGroundColorOpacity(100)
		end
		bind.click(self, dailyAssistantPanel, {method = function()
			jumpEasy.jumpTo("dailyAssistant")
		end})
		local redHint = {
			class = "red_hint",
			props = {
				specialTag = "dailyAssistant",
				onNode = function(node)
					node:xy(box.width - 10, box.height - 10)
					node:scale(0.8)
				end,
			}
		}
		bind.extend(self, dailyAssistantPanel, redHint)

		local tipDatas = {}
		for i=1, math.huge do
			local tip = gLanguageCsv["dailyAssistantShowTips"..i]
			if tip == nil then
				break
			end
			table.insert(tipDatas, tip)
		end
		local offPos = {x = 250, y = 0}
		local function showTip()
			local redHint = dailyAssistantPanel:getChildByName("_redHint_")
			if not redHint or (not redHint:visible()) then
				return
			end
			local idx = math.random(1,#tipDatas)
			-- 添加对话气泡
			local txt = rich.createByStr("#C0x5b545b#" .. tipDatas[idx], 40)
				:anchorPoint(0.5, 0)
				:xy(box.width / 2 + offPos.x, box.height + 40 + offPos.y)
				:addTo(dailyAssistantPanel, 3, "talkContent")
				:formatText()
			local size = txt:size()
			local bg = ccui.Scale9Sprite:create()
			bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
			bg:size(size.width + 60, size.height + 60)
				:anchorPoint(0.5, 0)
				:xy(box.width / 2 + offPos.x, box.height + offPos.y)
				:scaleX(-1)
				:addTo(dailyAssistantPanel, 2, "talkBg")
			-- dailyAssistantPanel:setTouchEnabled(false)
			performWithDelay(dailyAssistantPanel, function()
				dailyAssistantPanel:removeChildByName("talkContent")
				dailyAssistantPanel:removeChildByName("talkBg")
				-- parent:setTouchEnabled(true)
			end, 2)
		end
		local animate = cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function ()
			showTip()
		end))
		local action = cc.RepeatForever:create(animate)
		dailyAssistantPanel:runAction(action)
	end
	dailyAssistantPanel:visible(dataEasy.isShow("dailyAssistant"))
	self.dailyAssistantPanel = dailyAssistantPanel
end

-- 钓鱼大赛
function CityView:fishingGameTip()
	self.fishPanel = ccui.Layout:create()
	self.fishPanel:setTouchEnabled(true)
	self.fishPanel:addTo(self.bgPanel, 10)
	self.fishPanel:xy(1570, 610)

	self.fishPanel:removeAllChildren()
	local obj = widget.addAnimationByKey(self.fishPanel, "fishing/diaoyudasairukou.skel", 'diaoyudasai', "effect_loop", 1)
	obj:anchorPoint(cc.p(0.5,0.5))
	obj:scale(0.8)

	local box = obj:box()
	self.fishPanel:size(box.width, box.height)
	obj:xy(box.width / 2, 0)

	if DEBUG_SPRITE_AREA then
		self.fishPanel:setBackGroundColorType(1)
		self.fishPanel:setBackGroundColor(cc.c3b(200, 0, 0))
		self.fishPanel:setBackGroundColorOpacity(100)
	end
	bind.click(self, self.fishPanel, {method = functools.partial(self.fishingClick)})

	self:setFishingGameTimer()
end

function CityView:fishingClick()
	if self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		self.fishPanel:hide()
		return
	end
	local function onFishingView()
		gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
			gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, game.FISHING_GAME, tb.view, self:createHandler("onOpenFishingMain"))
		end)
	end
	if self.fishingSelectScene:read() == game.FISHING_GAME then
		onFishingView()

	elseif self.fishingIsAuto:read() then
		gGameUI:stackUI("city.adventure.fishing.auto", nil, {blackLayer = true, clickClose = false}, game.FISHING_GAME, self:createHandler("onOpenView"))

	else
		gGameApp:requestServer("/game/fishing/prepare", onFishingView, "scene", game.FISHING_GAME)
	end
end

function CityView:onOpenView()
	if self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		self.fishPanel:hide()
		return
	end
	gGameApp:requestServer("/game/fishing/prepare",function (tb)
		gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
			gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, game.FISHING_GAME, tb.view, self:createHandler("onOpenFishingMain"))
		end)
	end, "scene", game.FISHING_GAME)
end

function CityView:onOpenFishingMain()
	gGameUI:stackUI("city.adventure.fishing.sence_select", nil, {full = true})
end

function CityView:onClickSprite(data)
	local info = self.citySpriteDatas[data.csvId]

	local showOver = {false}
	local callback = function()
		showOver[1] = true
	end
	if not info.isBaibian and not info.isMiniQ then
		if self.spriteGiftTimes:read() < 3 and not info.isGetGift then
			callback = function(tb)
				info.target:setTouchEnabled(true)
				if data.cfg.action then
					self:showRoleSpeak(data.csvId, 1)
					local effect = info.target:getChildByName("effect")
					if effect then
						effect:play("effect")
						effect:setSpriteEventHandler(function(event, eventArgs)
							effect:play("effect_loop")
						end, sp.EventType.ANIMATION_COMPLETE)
					end
				end
				showOver[1] = true
				self.citySpriteDatas[data.csvId].isGetGift = true
			end

		elseif data.cfg.action then
			local effect = info.target:getChildByName("effect")
			if effect then
				effect:play("effect")
				self:showRoleSpeak(data.csvId, 1)
				effect:setSpriteEventHandler(function(event, eventArgs)
					effect:play("effect_loop")
				end, sp.EventType.ANIMATION_COMPLETE)
			end
			return
		end

	elseif info.isBaibian and not info.isGet then
		callback = function(tb)
			local effect = info.target:getChildByName("effect")
			if effect then
				effect:hide()
				local allNames = {"effect_jingya", "effect_shengqi", "effect_kaixin"}
				local effectName = allNames[math.random(1, 3)]
				local baibianEft = widget.addAnimationByKey(info.target, "zhuchangjing/zjm_bbg.skel", "changeEft", effectName, 1)
					:xy(effect:xy())

				baibianEft:setSpriteEventHandler(function(event, eventArgs)
					info.target:setTouchEnabled(true)
					self.citySpriteDatas[data.csvId].isGet = true
					showOver[1] = true
				end, sp.EventType.ANIMATION_COMPLETE)
			end
		end

	elseif info.isMiniQ then
		callback = function(tb)
			local effect = info.target:getChildByName("effect")
			if effect then
				effect:play("effect")
				effect:setSpriteEventHandler(function(event, eventArgs)
					performWithDelay(self, function()
						info.target:removeFromParent()
						self.citySpriteDatas[data.csvId] = nil
						showOver[1] = true
					end, 1/60)
				end, sp.EventType.ANIMATION_COMPLETE)
			end
		end
	end
	info.target:setTouchEnabled(false)
	gGameApp:requestServerCustom("/game/role/city/sprite/gift")
		:params(data.csvId)
		:onResponse(function()
			if tolua.isnull(info.target) then
				showOver[1] = true
			else
				callback()
			end
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay(tb)
		end)
end

-- 万圣节相关活动参数设置
function CityView:initHalloween()
	-- 万圣节游荡精灵活动显示
	self.halloweenActivity = idler.new(false)
	-- 万圣节每日奖励领取
	self.halloweenDailyAward = idler.new(false)
	--万圣节精灵是否已经点完所有游荡精灵，nil表示无该活动
	self.halloweenAllSpriteClicked = idler.new()

	self:onHalloween()
end

--小鬼的个数 游荡精灵
function CityView:setHalloweenMoveSprites()
	self.fixHouse = true
	self.fixCar = true
	self.halloweenAllSpriteClicked:set(true)
	local yyhuodongs = self.yyhuodongs:read()
	local stamps = yyhuodongs[self.halloweenId] and yyhuodongs[self.halloweenId].stamps or {}
	local moveSprites = 0 -- 游荡精灵
	-- cfg.type 1 表示捣蛋，2表示游荡
	for k, v in pairs(stamps) do
		if k ~= 0 then
			local cfg = csv.yunying.halloween_sprites[k]
			if cfg.type == 1 then
				if cfg.buildNum == 1 then
					if v ~= 0 then
						self.fixHouse = false
						self.halloweenAllSpriteClicked:set(false)
					end
				end
				if cfg.buildNum == 2 then
					if v ~= 0 then
						self.fixCar = false
						self.halloweenAllSpriteClicked:set(false)
					end
				end
			else
				if v == 0 then
					moveSprites = moveSprites + 1
				else
					self.halloweenAllSpriteClicked:set(false)
				end
			end
		end
	end
	for k, v in pairs(stamps) do
		if k ~= 0 then
			if v == 1 then
				local cfg = csv.yunying.halloween_sprites[k]
				local randomNum = math.random(csvSize(cfg.pos))
				local x = cfg.pos[randomNum][1]
				local y = cfg.pos[randomNum][2]
				if cfg.type == 1 then
					self:onAllSaintsDaySpine(x, y, k)

				elseif cfg.type == 2 then
					if self.fixHouse and self.fixCar then
						self:onClickhalloweenSpineMove(x, y, k)
					end
				end
			end
		end
	end

	local panel = self.bgPanel:get("halloweenCar")
	local effect = panel:get("halloweenCar")
	if moveSprites == 1 then
		effect:play("night_deng1_bianhua")
		effect:addPlay("night_po_hou1_loop")
	end
	if moveSprites == 2 then
		-- 最终奖励是否领取
		if stamps[0] == 1 then
			effect:play("night_deng2_bianhua")
			effect:addPlay("night_hao_loop")
		else
			effect:play("night_loop")
		end
	end
end

function CityView:onHalloween()
	-- --游荡精灵是不是已经创建过
	self.halloweenTab = {}
	idlereasy.any({self.yyOpen}, function (_, yyOpen)
		self.halloweenActivity:set(false)
		for _,id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]
			local clientType = cfg.clientParam.type
			if clientType == "halloween" and cfg.type == YY_TYPE.halloween then
				self.halloweenId = id
				self.halloweenActivity:set(true)
				break
			end
		end
	end)

	idlereasy.any({self.isNight, self.halloweenActivity, self.yyhuodongs}, function (_, isNight, halloweenActivity, yyhuodongs)
		for _, v in pairs(self.halloweenTab) do
			v:removeSelf()
		end
		self.halloweenTab = {}
		if self.bgPanel:get("halloweenFang") then
			self.bgPanel:get("halloweenFang"):removeSelf()
		end
		if self.bgPanel:get("halloweenShan") then
			self.bgPanel:get("halloweenShan"):removeSelf()
		end
		if self.bgPanel:get("halloweenBreakCar") then
			self.bgPanel:get("halloweenBreakCar"):removeSelf()
		end
		if self.bgPanel:get("halloweenCar") then
			self.bgPanel:get("halloweenCar"):removeSelf()
		end
		local steryShop = self.bgPanel:get("steryShop")
		if steryShop then
			steryShop:show()
		end
		local chezi = self.bgPanel:get("chezi")
		if chezi then
			chezi:show()
		end

		if halloweenActivity then
			self:addHalloweenCar()
			if isNight then
				self:setHalloweenMoveSprites()

				widget.addAnimationByKey(self.bgPanel, HALLOWEEN_BREAK_SHAN_NAME, "halloweenShan", "effect_loop", 100)
					:alignCenter(self.bgPanel:getInnerContainerSize())
					:scale(HALLOWEEN_BREAK_SCALE)

				if not self.fixHouse then
					widget.addAnimationByKey(self.bgPanel, HALLOWEEN_BREAK_FANG_NAME, "halloweenFang", "effect_loop", 9)
						:alignCenter(self.bgPanel:getInnerContainerSize())
						:scale(HALLOWEEN_BREAK_SCALE)
				end

				if not self.fixCar then
					local steryShop = self.bgPanel:get("steryShop")
					if steryShop then
						steryShop:hide()
					end
					local chezi = self.bgPanel:get("chezi")
					if chezi then
						chezi:hide()
					end
					self:addBreakCar()
				end

				self:fixCarAndHouse()
			end
		end
	end)
end

-- 万圣节游荡精灵破损车
function CityView:addBreakCar()
	local breakCar = widget.addAnimationByKey(self.bgPanel, CHEZI_EFFECT_NAME, "halloweenBreakCar", "night_loop", 100)
		:alignCenter(self.bgPanel:getInnerContainerSize())
		:scale(2)
		:setCascadeOpacityEnabled(true)
		:opacity(0)
	widget.addAnimationByKey(breakCar, HALLOWEEN_BREAK_CHE_NAME, "effect", "effect_loop", 120)
		:scale(HALLOWEEN_BREAK_SCALE/2)
		:setCascadeOpacityEnabled(true)
		:opacity(255)
	transition.fadeIn(breakCar, {time = 1})
end

-- 万圣节南瓜车
function CityView:addHalloweenCar()
	local panel = self.bgPanel:get("halloweenCar")
	if not panel then
		panel = ccui.Layout:create()
			:xy(HALLOWEEN_CAR_POS)
			:size(850, 800)
			:addTo(self.bgPanel, 200, "halloweenCar")
		panel:setTouchEnabled(true)

		local name = self.isNight:read() and "night_po_loop" or "day_loop"
		widget.addAnimationByKey(panel, "wanshengjie/wsj_nanguache.skel", "halloweenCar", name, 120)
			:scale(2)
			:xy(500, 200)
		if DEBUG_SPRITE_AREA then
			panel:setBackGroundColorType(1)
			panel:setBackGroundColor(cc.c3b(200, 0, 0))
			panel:setBackGroundColorOpacity(100)
		end
		bind.click(self, panel, {method = functools.partial(self.onClickHalloweenCar, self)})
	else
		panel:xy(HALLOWEEN_CAR_POS)
	end
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end