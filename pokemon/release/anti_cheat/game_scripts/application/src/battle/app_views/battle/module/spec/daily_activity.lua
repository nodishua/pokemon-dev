-- @desc 日常活动副本的显示界面
local _format = string.format
-- boss血条: 轮换的颜色 {}  每条血的基数,
-- 按顺序: 红 紫 黄 绿 蓝
local BAR_RES = {	-- battle\boss
	[1] = "city/adventure/goldbaby/bar_hxt1.png",
	[2] = "city/adventure/goldbaby/bar_zxt.png",
	[3] = "city/adventure/goldbaby/bar_hxt.png",
	[4] = "city/adventure/goldbaby/bar_lxt1.png",
	[5] = "city/adventure/goldbaby/bar_lxt.png",
}
local ORDER_N = {
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[4] = 4,
	[5] = 5,
	[6] = 1,
}

local BattleDailyActivityView = class("BattleDailyActivityView", battleModule.CBase)

BattleDailyActivityView.RESOURCE_FILENAME = "battle_daily_activity.json"
BattleDailyActivityView.RESOURCE_BINDING = {
	["item1"] = "item1",
	["item2"] = "item2",
	["statsPanel"] = "statsPanel",
	["bossLifePanel"] = "bossLifePanel",
	["statsPanel.count"] = {
		binds = {
			event = "effect",
			data = {outline = {color=ui.COLORS.NORMAL.WHITE}},
		}
	},
	["item1.count"] = {
		binds = {
			event = "effect",
			data = {outline = {color=ui.COLORS.NORMAL.WHITE}},
		}
	},
	["item2.count"] = {
		binds = {
			event = "effect",
			data = {outline = {color=ui.COLORS.NORMAL.WHITE}},
		}
	},
}

-- call by battleModule.CBase.new
function BattleDailyActivityView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)
	bindUI(self, self.root, self.RESOURCE_BINDING)
	-- TODO: ?与BattleView其它module层级问题?
	self.root:addTo(parent, 99):show()

	self:init()
end

function BattleDailyActivityView:init()
	self.item1:hide()
	self.item2:hide()
	self.statsPanel:hide()
	self.bossLifePanel:hide()
	self.sceneID = self.parent.sceneID
	if self.parent.gateType == game.GATE_TYPE.dailyGold
		or self.parent.gateType == game.GATE_TYPE.unionFuben
		or self.parent.gateType == game.GATE_TYPE.crossMineBoss then	-- 打boss
		self.bossLifePanel:show()
		self.barResOrderN = 1		-- 记录当前血条的图片颜色顺序
	elseif self.parent.gateType == game.GATE_TYPE.dailyExp then	-- 打地鼠
		self.statsPanel:show()
	end

	self.dropSpritesTb = {{}, {}}	-- 掉落图标s
	self.countTb = {0, 0}			-- 掉落量
	self.lostHpPerTb = self.lostHpPerTb or {}	-- 记录损失的血量, 要连续的一段段显示

	-- 左侧的道具收集量显示
	local dropCfg = csv.huodong_drop[self.sceneID]
	if dropCfg then
		self.dropCfg = dropCfg
		-- 先显示百分比掉落的: 默认经验本金钱本就只有一种道具,多种道具的话,配置成礼包吧
		for key, _ in csvMapPairs(dropCfg.perDrop or {}) do
			local res = dataEasy.getIconResByKey(key)
			if res then
				self.item1Res = res
				self.item1:get("icon"):texture(res)
				self.item1:show()
				break
			end
		end
		-- 宝箱: 放节点掉落中的非百分比掉落里面的道具
		if not itertools.isempty(dropCfg.node) then
			self.item2:show()
		end
	end

	self.convStr = idler.new("")
end

-- 击杀数
function BattleDailyActivityView:onKillCount(countArgs)
	local curCount = countArgs.curCount or 0
	local totalCount = countArgs.totalCount or 1
	local count = self.statsPanel:get("count")
	local str = string.format(gLanguageCsv.totalKill, curCount, totalCount)
	count:text(str)
end

function BattleDailyActivityView:onNewBattleRound(args)
	-- 回合数设置
	local csvConfig = csv.scene_conf[self.parent.sceneID]
	local curRound = math.max(math.min(args.curRound, csvConfig.roundLimit), 0)
	self.bossLifePanel:get("round.round"):setString(_format(gLanguageCsv.theRound, curRound,csvConfig.roundLimit))
end

-- 活动掉落的显示：每次技能结束时显示
function BattleDailyActivityView:onDropShow(dropArgs)
	if not dropArgs then return end
	if not self.dropCfg then return end
	local dropCfg = self.dropCfg

	local nPer = dropArgs.nPer
	local nNode = dropArgs.nNode
	local tostrModel = dropArgs.tostrModel
	local objView = self.parent:onViewProxyCall('getSceneObjs')[tostrModel]
	if not objView then return end

	local dPosx, dPosy = objView:xy()
	local lx = dPosx - 250
	local rx = dPosx + 100		-- 有可能会掉到屏幕外面去吧。。
	local py = 180*1.5
	local dropTb = {}
	if nPer >= 1 then
		for key, num in csvMapPairs(dropCfg.perDrop or {}) do
			dropTb[key] = dropTb[key] or 0
			dropTb[key] = dropTb[key] + num * nPer
		end
	end
	self.nodeDropN = self.nodeDropN or 0
	if dropCfg.node then
		for i, v in ipairs(dropCfg.node) do
			if (self.nodeDropN < i) and (nNode >= v) then
				self.nodeDropN = i
				local nodeDrop = dropCfg.nodeDrop[i]
				for key, num in csvMapPairs(nodeDrop or {}) do
					dropTb[key] = dropTb[key] or 0
					dropTb[key] = dropTb[key] + num
				end
			end
		end
	end

	if next(dropTb) then
		for key, num in pairs(dropTb) do
			local res = dataEasy.getIconResByKey(key)
			local itemN = (self.item1Res == res) and 1 or 2
			self.countTb[itemN] = self.countTb[itemN] + num
			if res then
				local n = num
				if num > 100 then
					n = cc.clampf(math.ceil(num/(dropCfg.perIcon or 1)), 1, 99)
				end
				for i=1, n do
					local spr = newCSprite(res)
					spr:xy(dPosx, dPosy+display.fightLower):anchorPoint(0,0)
					self.root:add(spr)
					table.insert(self.dropSpritesTb[itemN], spr)
					local rx1 = math.random(lx, rx)
					local rx2 = (rx1 > dPosx) and math.random(dPosx, rx1) or math.random(rx1, dPosx)
					spr:runAction(cc.Sequence:create(
						cc.JumpTo:create(0.4, cc.p(rx1, py), 0, 1),
						cc.JumpTo:create(0.4, cc.p(rx2, py), 50, 1)
					))
				end
			end
		end
	end
end

-- 掉落汇总的动画: 回合结束时收集起来
function BattleDailyActivityView:onRoundEndDropCollection()
	local px1, py1 = self.item1:xy()
	local px2, py2 = self.item2:xy()

	local deltat = 0.03
	for itemN, sprs in ipairs(self.dropSpritesTb) do
		local px, py = px1, py1
		if itemN ~= 1 then
			px, py = px2, py2
		end
		local dt = 0
		for _, spr in ipairs(sprs) do
			transition.executeSequence(spr)
				:delay(dt)
				:moveTo(0.5, px, py)
				:func(function()
					removeCSprite(spr)
				end)
				:done()
			dt = dt + deltat
		end
	end

	local function doCountAction(node, idx)
		local widget = node:get("count")
		local n = math.max(1, table.length(self.dropSpritesTb[idx]))
		local dtCount = self.countTb[idx]/n
		local curCount = tonumber(widget:getString())
		local endCount = curCount + self.countTb[idx]
		node:stopAllActionsByTag(idx)

		local action
		action = schedule(node, function()
			curCount = math.floor(curCount + dtCount)
			widget:text(math.max(curCount, endCount))
			if curCount >= endCount then
				widget:text(endCount)
				node:stopAction(action)
			end
		end, deltat)
		action:setTag(idx)
	end
	doCountAction(self.item1, 1)
	doCountAction(self.item2, 2)


	self.dropSpritesTb = {{}, {}}
	self.countTb = {0, 0}
end

-- 初始化boss的血条
function BattleDailyActivityView:onInitBossLife(infoArgs)
	local name = infoArgs.name
	local headIconRes = infoArgs.headIconRes	-- 头像
	self.bossLifeTotalCount = infoArgs.leftBars or 1		-- 保存血条数量
	-- 总血条血量比例 如： 60条血为 60*100=6000, 简单处理，这里只在初始化时保存,后续并未同步
	self.bossLastLifeBarsPer = infoArgs.barsLife

	if name then
		self.bossLifePanel:get("name"):text(name)
	end
	if headIconRes then
		self.bossLifePanel:get("headIcon"):texture(headIconRes)
	end

	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")

	if self.bossLifeTotalCount == 1 then
		bar1:loadTexture(BAR_RES[self.barResOrderN])
		bar2:hide()
	else
		-- 初始化2个血条底色
		bar1:loadTexture(BAR_RES[ORDER_N[self.barResOrderN]])
		bar2:texture(BAR_RES[ORDER_N[self.barResOrderN + 1]])
	end
	-- self.bossLifePanel:get("count"):text(self.bossLifeTotalCount)
	self.convStr:set('x' .. tostring(self.bossLifeTotalCount))
	bind.extend(self.parent, self.bossLifePanel:get("lifeCount"), {
		class = "text_atlas",
		props = {
			data = self.convStr,
			pathName = "boss",
			isEqualDist = false,
			align = "left",
		}
	})
	local lostHp = self.bossLifeTotalCount * 100 - self.bossLastLifeBarsPer
	self:onBossLostHp({lostHpPer = lostHp})
end

-- boss扣血数据存储
function BattleDailyActivityView:onBossLostHp(hpArgs)
	if hpArgs.lostHpPer > 0 then
		table.insert(self.lostHpPerTb, hpArgs.lostHpPer)
	end

	self.root:stopAllActionsByTag(100)
	local t = 0
	local action
	action = schedule(self.root, function()
		t = t + 0.02
		if next(self.lostHpPerTb) then
			self:showBossHPBarAni()
		end
		-- 固定5秒左右的时间 删除吧
		if t > 5 or not self.isHPBarChanging then
			self.root:stopAction(action)
		end
	end, 0.02)
	action:setTag(100)

end


function BattleDailyActivityView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

-- 血条扣血动画
function BattleDailyActivityView:showBossHPBarAni()
	if self.isHPBarChanging then return end
	self.isHPBarChanging = true
	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")

	local lostPer = self.lostHpPerTb[1]
	local curBarLeftPer = self.bossLastLifeBarsPer % 100	-- 这个值在初始时获取后保存起来
	if curBarLeftPer == 0 then
		curBarLeftPer = 100
	end

	local lost2Per
	self.lostHpPerTb[1] = lostPer - curBarLeftPer
	if self.lostHpPerTb[1] <= 0 then
		table.remove(self.lostHpPerTb, 1)	-- 当前的去掉
		lost2Per = curBarLeftPer - lostPer
		self.bossLastLifeBarsPer = self.bossLastLifeBarsPer - lostPer
	else
		lost2Per = 0
		self.bossLastLifeBarsPer = self.bossLastLifeBarsPer - curBarLeftPer
	end
	-- 动画显示
	local showTime = 0.1
	local function change2NextBar()	 -- 下一个血条设置
		if self.bossLifeTotalCount == 1 then
			self.bossLifeTotalCount = 0
			self.convStr:set("x"..self.bossLifeTotalCount)
			return
		end
		self.barResOrderN = ORDER_N[self.barResOrderN + 1]
		bar1:loadTexture(BAR_RES[self.barResOrderN])
		bar1:setPercent(100)
		bar2:texture(BAR_RES[ORDER_N[self.barResOrderN + 1]])
		self.bossLifeTotalCount = self.bossLifeTotalCount - 1
		self.convStr:set("x"..self.bossLifeTotalCount)
		if self.bossLifeTotalCount <= 1 then
			bar2:hide()
		end
	end
	local sequence = transition.executeSequence(bar1)
		:progressTo(showTime, lost2Per)
	-- 如果当前血条清空了, 就换成下一条, 血条数字减少,
	if lost2Per == 0 then
		sequence:func(change2NextBar)
	end
	sequence:func(function()
		self.isHPBarChanging = false
	end)
	sequence:done()
end

function BattleDailyActivityView:onClose()
	ViewBase.onClose(self)
end

return BattleDailyActivityView