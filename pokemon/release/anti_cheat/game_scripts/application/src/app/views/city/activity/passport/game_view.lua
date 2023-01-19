-- @desc: 	activity-玩法通行证

local ruleTable = {
	[2] = {117001, 117050},
	[3] = {118001, 118050},
	[4] = {119001, 119050}
}

local ViewBase = cc.load("mvc").ViewBase
local ActivityGamePassportView = class("ActivityGamePassportView", ViewBase)

ActivityGamePassportView.RESOURCE_FILENAME = "activity_game_passport.json"
ActivityGamePassportView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["rewardPanel"] = "rewardPanel",
	["rewardPanel.bg"] = "rewardPanelBg",
	["rewardPanel.txtNode"] = {
		varname = "rewardTimeTxtNode",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(2, 94, 110, 255),  size = 4}}
		}
	},
	["rewardPanel.endTime"] = {
		varname = "rewardEndTime",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(2, 94, 110, 255),  size = 4}}
		}
	},
	["rewardPanel.name"] = {
		varname = "rewardName",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(3, 96, 112, 255),  size = 6}}
		}
	},
	["rewardPanel.lvName"] = {
		varname = "rewardLvName",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(2, 94, 110, 255),  size = 4}}
		}
	},
	["rewardPanel.lv"] = {
		varname = "rewardLv",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
		}
	},
	["rewardPanel.textNode2"] = "txtNode2",
	["rewardPanel.exp"] = "rewardExp",
	["rewardPanel.expBar"] = "rewardExpBar",
	["rewardPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRule")}
		}
	},
	["rewardPanel.target"] = "target",
	["rewardPanel.target.normalPanel"] = "targetNormalPanel",
	["rewardPanel.target.highPanel1"] = "targetHighPanel1",
	["rewardPanel.target.highPanel2"] = "targetHighPanel2",
	["rewardPanel.target.noClick"] = "targetNoClick",  -- 禁止点击层，当rewardScroll滑动时，禁止点击
	["rewardPanel.btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBuy")}
		}
	},
	["rewardPanel.btnBuyExp"] = {
		varname = "btnBuyExp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBuyExp")}
		}
	},
	["rewardPanel.btnOneKeyGet"] = {
		varname = "btnOneKeyGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnOneKeyGet")}
		}
	},
	["rewardItem"] = "rewardItem",
	["rewardPanel.scroll"] = "rewardScroll",
	["rewardPanel.highMask"] = "highMask",
	["rewardPanel.highLock"] = "highLock",
	["rewardPanel.txtHigh"] = "rewardTxtHigh",
	["rewardPanel.nameText"] = "nameText",
	["rewardPanel.nameText1"] = "nameText1",
	["rewardPanel.txtNormal"] = {
		varname = "rewardTxtNormal",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 255, 255, 255),  size = 3}}
		}
	},
	["rewardPanel.txtHigh"] = {
		varname = "rewardTxtHigh",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 255, 255, 255),  size = 3}}
		}
	},
	["rewardPanel.iconNormal"] = "iconNormal",
	["rewardPanel.iconHigh"] = "iconHigh",
}

function ActivityGamePassportView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	self:initData()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.type = yyCfg.paramMap.type
	self.rewardLvName:text(gLanguageCsv["gamePassportNowText"..self.type])
	self.dailyBuyTimes = yyCfg.paramMap.dailyBuyTimes
	self.endDate = yyCfg.endDate
	self.target:visible(yyCfg.clientParam.showLastUnlock)
	self.bg:texture(yyCfg.clientParam.res)
	self.rewardPanelBg:texture(yyCfg.clientParam.banner)
	self.iconNormal:texture(yyCfg.clientParam.icon..".png")
	self.iconHigh:texture(yyCfg.clientParam.icon.."1"..".png")

	-- 顶部UI
	self.topView = gGameUI.topuiManager:createView(self.exchangeShop == 1 and "passport" or "default", self, {onClose = self:createHandler("onClose")})
		:init({title = yyCfg.name, subTitle = yyCfg.clientParam.topText})

	-- passport数据监听
	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.yyhuodongs, self.clientBuyTimes}, function(_, yyhuodongs)
		local passport = yyhuodongs[self.activityId]
		local nextExpTotal = 0 -- 升至下一等级需要的经验总量（用于显示上的计算）
		local nexRewardData = {} -- 下一级奖励
		self.currentPassportLv = passport.info.level
		self.isMaxLv = self.max == passport.info.level  -- 是否达到最大等级
		self.buyHigh = passport.info.elite_buy > 0 -- 是否购买高级通行证
		self.curRewardIdx = nil
		local maxReceivedIdx = 1 -- 最大已领的下标
		for k, v in ipairs(self.awardCfg) do
			local cfg = v.cfg -- 表原始数据，只读，不可修改
			local custom = v.custom -- 新增的自定义数据，可以修改
			if cfg.level <= passport.info.level then
				nextExpTotal = nextExpTotal + cfg.needExp
			end
			if cfg.level == passport.info.level + 1 then
				nexRewardData = v
			end
			-- 奖励状态发生变化
			local state = passport.stamps[custom.csvId]
			if state and custom.normalAwardState ~= state then
				custom.normalAwardState = state
				if not self.isReset then  -- 第一次进入界面不修改
					self:modifyItem(k)
				end
			end

			local state = passport.stamps1[custom.csvId]
			if state and custom.eliteAwardState ~= state then
				custom.eliteAwardState = state
				if not self.isReset then  -- 第一次进入界面不修改
					self:modifyItem(k)
				end
			end

			-- 当前可领取最大奖励
			if not self.curRewardIdx then
				if not self.buyHigh then
					if custom.normalAwardState == 1 then
						self.curRewardIdx = k

					elseif custom.normalAwardState == 0 then
						maxReceivedIdx = k
					end
				else
					if custom.normalAwardState == 1 or custom.eliteAwardState == 1 then
						self.curRewardIdx = k

					elseif custom.normalAwardState == 0 and custom.eliteAwardState == 0 then
						maxReceivedIdx = k
					end
				end
			end
		end
		self.curRewardIdx = self.curRewardIdx or maxReceivedIdx

		self.rewardLv:text(mathEasy.getShortNumber(passport.info.exp, 2))
		adapt.oneLinePos(self.rewardLvName, self.rewardLv, cc.p(15, 0))
		self.rewardName:text(yyCfg.name)
		self.rewardExp:text((passport.info.exp - nextExpTotal + self.awardCfg[passport.info.level].cfg.needExp).."/"..self.awardCfg[passport.info.level].cfg.needExp)
		if passport.info.level == self.max then
			self.rewardExp:text(gLanguageCsv.levelMax)
		end
		self.rewardExpBar:setPercent((passport.info.exp - nextExpTotal + self.awardCfg[passport.info.level].cfg.needExp)/self.awardCfg[passport.info.level].cfg.needExp*100)
		self.btnBuy:visible(not self.buyHigh)
		self.highMask:visible(not self.buyHigh)
		self.highLock:visible(not self.buyHigh)
		for k, v in csvMapPairs(csv.yunying.playpassport_recharge) do
			if v.huodongID == yyCfg.huodongID then
				local buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, 0)
				if buyTimes > 0 then
					self.btnBuy:hide()
				end
			end
		end
		local namePointX = self.rewardName:x()
		local nameSizeX = self.rewardName:size().width
		self.nameText:x(namePointX+nameSizeX+50)
		self.nameText1:x(namePointX+nameSizeX+50)
	end)

	-- --时间
	-- self:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")[self.activityId]
	local timeTab = time.getDate(mathEasy.getPreciseDecimal(yyEndtime+1, 0, true))
	-- local timeTab = time.getDate(yyEndtime+2)
	self.rewardEndTime:text(string.format(gLanguageCsv.recordPassportShowDay, timeTab.year, timeTab.month, timeTab.day, timeTab.hour))

	local richText = rich.createWithWidth(gLanguageCsv["gamePassportTitle"..self.type], 70, nil, 1250)
		:addTo(self.nameText, 10)
		:anchorPoint(cc.p(0, 0.5))
		-- :xy(0, 38)
		:formatText()

	local richText = rich.createWithWidth(gLanguageCsv["gamePassportNextTitle"..self.type], 70, nil, 1250)
		:addTo(self.nameText1, 10)
		:anchorPoint(cc.p(0, 0.5))
		-- :xy(0, 38)
		:formatText()

	-- 第一次进入跳转至最大可领取奖励
	if self.isReset then
		self:resetScroll()
	end
end

function ActivityGamePassportView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityGamePassportView:initData()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	-- 根据活动id获取当前活动id对应表内容
	self.awardCfg = {}  -- 奖励表
	local expNum = 0
	for k,v in orderCsvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID then
			-- expNum = v.needExp + expNum
			table.insert(self.awardCfg, {cfg = v, custom = {csvId = k}, expNum = expNum}) -- cfg为表原始数据，custom为添加的自定义数据
			expNum = v.needExp + expNum
		end
	end
	self.recharge = csv.yunying.playpassport_recharge  -- 充值表
	self.max = #self.awardCfg -- 奖励表最大长度
	self.currentPassportLv = self.yyhuodongs:read()[self.activityId].info.level     			-- 通行证当前等级
	-- self.buyHigh = itertools.size(self.yyhuodongs:read()[self.activityId].buy) > 0			-- 是否购买进阶通行证
	self.buyHigh = self.yyhuodongs:read()[self.activityId].info.elite_buy > 0
	self.isReset = true  -- 第一次进入通行证界面，重置reset界面信息
	local huodongID = yyCfg.paramMap.taskHuodongID
	self.startHideLevel = yyCfg.paramMap.startHideLevel	or 0	--隐藏奖励等级
	if not self.clock then
		self.clock = 1	--小于特定等级的锁是否存在
	end
	self.items = gGameModel.role:getIdler("items")
	self.btnBuyExp:hide()
	local dt = (gGameModel.role:read("yy_endtime")[self.activityId] or 0) - time.getTime()
	if yyCfg.paramMap.buyUnlock or (yyCfg.clientParam.buyExpShowDay and yyCfg.clientParam.buyExpShowDay > 0 and dt <= yyCfg.clientParam.buyExpShowDay * 24 * 3600) then
		self.btnBuyExp:show()
	end
end

function ActivityGamePassportView:onBtnRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityGamePassportView:onBtnBuy()
	self.rewardScroll:stopAutoScroll()
	gGameUI:stackUI("city.activity.passport.game_buy", nil, nil, self.activityId, self:createHandler("onBtnBuyCb"))
end

function ActivityGamePassportView:onBtnBuyCb()
	self.clientBuyTimes:notify()
end

function ActivityGamePassportView:onBtnBuyExp()
	self.rewardScroll:stopAutoScroll()
	if self.isMaxLv then
		gGameUI:showTip(gLanguageCsv.gamePassportShowTip)
		return
	end
	if self.yyhuodongs:read()[self.activityId].info.buy_times == self.dailyBuyTimes then
		gGameUI:showTip(gLanguageCsv.gamePassportShowTipFull)
		return
	end
	gGameUI:stackUI("city.activity.passport.game_buy_exp", nil, nil, self.activityId)
end

function ActivityGamePassportView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(ruleTable[self.type][1], ruleTable[self.type][2]),
	}
	return context
end

function ActivityGamePassportView:onBtnGetClick(v)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, v.custom.csvId)
end

function ActivityGamePassportView:onBtnOneKeyGet()
	local isHaveRewardGet = false
	local passport = self.yyhuodongs:read()[self.activityId]
	for _, state in pairs(passport.stamps) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	for _, state in pairs(passport.stamps1) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	if not isHaveRewardGet then
		gGameUI:showTip(gLanguageCsv.noRewardGet)
		return
	end
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb)
		self:resetScroll()
	end, self.activityId)
end
function ActivityGamePassportView:checkRefresh(i)
	if self.awardCfg[i].cfg.specialAward == 1 then
		if i ~= self.rigthRewardIndex then --判断奖励是否有变更，若有变更，刷新，无变更，不刷新
			self.rigthRewardIndex = i
			self:refreshTarget()
		end
		return true
	end
	return false
end

-- @desc 建立滚动层，装在奖励item
function ActivityGamePassportView:buildScroll()
	-- [[ 主要思路：创建固定数量item，加载对应信息，当左右滑动时，将队伍item移动至队首，并更新信息，支持多列同时移动]]
	self.rewardScroll:setScrollBarEnabled(false) -- 隐藏滚动条
	local itemWidth = self.rewardItem:width() -- item 宽度
	local size = self.rewardScroll:size()	-- rewardScroll显示区域大小
	local container = self.rewardScroll:getInnerContainer() -- rewardScroll实际滚动区域
	local innerWidth = 0
	local innerHeight = 0

	--	低于一定等级的时候只展示等级之内的奖励
	if self.currentPassportLv < self.startHideLevel then
		innerWidth, innerHeight = itemWidth * self.startHideLevel, size.height -- rewardScroll实际滚动区域宽高
	else
		innerWidth, innerHeight = itemWidth*self.max, size.height
	end
	container:size(innerWidth, innerHeight)
	self.itemCreateNum = math.ceil(size.width/itemWidth)  -- 创建item总数，+5是为了提供一个缓冲区域，确保显示区域内，一定有item显示
	self.itemCreateNum = (self.itemCreateNum + 5) >= self.max and self.itemCreateNum or (self.itemCreateNum + 5)
	self.itemCreateNum = self.itemCreateNum > self.max and self.itemCreateNum or self.max

	local col = self.itemCreateNum
	local itemLength = itemWidth * col -- 创建所有item的总宽度，用于item位置移动

	-- 这段代码主要逻辑是为了当前奖励至最大奖励的长度不足itemCreateNum时，向前补足长度，保证item创建总数为itemCreateNum个
	-- 这里只是读取左右item编号，与创建时须保持一致
	local min = self.curRewardIdx  -- 最左item id
	local max = self.curRewardIdx-1+self.itemCreateNum -- 理论最右item id
	if max > self.max then  -- 理论最右item id超过最大id后，最右item id等于最大id， 最左item id向前补足长度，保证item总数长度为itemCreateNum
		min = min - (max - self.max)
		max = self.max
	end

	local leftIdx = min%col == 0 and col or min%col -- 初始化最左侧item创建编号，计算逻辑即编号规则，编号与id是固定对应上的，用于位置计算
	local rightIdx = leftIdx - 1 == 0 and col or leftIdx - 1  --  初始化最右侧item创建编号
	local dir, idx  -- 方向，当前item编号
	self.percent = -1
	local function onMove()
		local percent = self.rewardScroll:getScrolledPercentHorizontal()
		if self.percent > percent then
			dir = "right"-- 手指滑动方向
			idx = rightIdx
			self.percent = percent
		elseif self.percent < percent then
			dir = "left"
			idx = leftIdx
			self.percent = percent
		end

		local lx = math.abs(container:x())  -- container位置绝对值，转换成item坐标，即为显示区域最左边item在rewardScroll中的坐标
		local rx = lx + size.width          -- container位置绝对值+显示区域宽度，转换成item坐标，即为显示区域最右边item在rewardScroll中的坐标
		local item = self.rewardScroll:getChildByName("reward" .. idx)

		local right = math.ceil(rx/itemWidth) -- 右侧奖励id，通过位置计算，计算规则依赖：从1级开始，逐级提升(不支持缺级，不从1开始)
		if self.currentPassportLv >= self.startHideLevel then
			for i = right, self.max do     	-- 读取实际需要显示
				if self:checkRefresh(i) then
					break
				end
			end
		else
			for i = right, self.startHideLevel do     	-- 读取实际需要显示
				if self:checkRefresh(i) then
					break
				end
			end
		end
		--  刷新左右编号
		local function calculatelIdx(dir, num)
			local dt = num
			if dir ~= "left" then
				dt = col - num
			end
			leftIdx = (dt + leftIdx - 1) % col + 1
			rightIdx = (dt + rightIdx - 1) % col + 1
		end
		local function calculateRewardItem(num)
			for i=1,num do
				local itemIdx = dir == "left" and (idx + i - 1) % col or (idx - i + 1) % col
				itemIdx = itemIdx == 0 and col or itemIdx
				local cItem = self.rewardScroll:getChildByName("reward"..itemIdx)
				if cItem then
					if dir == "left" then
						cItem:x(cItem:x() + itemLength)
					else
						cItem:x(cItem:x() - itemLength)
					end
					self:modifyItem(cItem:x()/itemWidth+1)
				end
			end
		end

		if item then
			local x = item:x()
			if dir == "left" and lx > x + itemWidth then  -- lx > x + itemWidth 表示最左侧item已滑出显示区域，需要移动至右侧队尾
				local rightItem = self.rewardScroll:getChildByName("reward"..(rightIdx == 0 and col or rightIdx))  -- 临界值判断  -- 最大奖励item
				local rightLess = (innerWidth - rightItem:x())/itemWidth - 1  -- 右侧剩余可移动位置，最大奖励已加载后，左侧item不应再向右侧移动
				local num = math.min(math.ceil((lx - (x + itemWidth)) / itemWidth), rightLess) -- 需要移动的item数量
				calculatelIdx(dir, num)
				calculateRewardItem(num)
				idx = leftIdx
			elseif dir == "right" and rx < x then  -- rx < x 表示最右侧item已向右滑出显示区域，需要移动至左侧队尾
				local leftItem = self.rewardScroll:getChildByName("reward"..(leftIdx == 0 and col or leftIdx))  -- 临界值判断  -- 最小奖励item
				local leftLess = leftItem:x()/itemWidth  -- 左侧剩余可移动i位置，最小奖励已加载后，右侧item不应再向左侧移动
				local num = math.min(math.ceil(((x - itemWidth) - rx) / itemWidth), leftLess)
				calculatelIdx(dir, num)
				calculateRewardItem(num)
				idx = rightIdx
			end
			local itemSize = itemWidth * self.startHideLevel
			if self.currentPassportLv < self.startHideLevel then
				if dir == "left" and rx >= itemSize - 1 then	--减一是因为滑到底部之后不算滑动
					gGameUI:showTip(string.format(gLanguageCsv.upPasswordLevelToGet, self.startHideLevel))
				end
			end
		end
	end
	onMove()

	self.rewardScroll:onEvent(function(event)
		if event.name == "CONTAINER_MOVED" then
			onMove()
		elseif event.name == "SCROLLING_BEGAN" then
			self:refreshNoClick(true) -- 滑动开始，显示禁止点击层
		elseif event.name == "AUTOSCROLL_ENDED" then
			self:refreshNoClick(false) -- 自动滑动结束，隐藏禁止点击层
		elseif event.name == "SCROLLING_ENDED" then
			-- 这里不能隐藏禁止点击层，因为这之后，还有惯性自动滑动
		end
	end)
end

-- 创建奖励item
function ActivityGamePassportView:buildItem()
	local min = self.curRewardIdx  -- 最左item id
	local max = self.curRewardIdx-1+self.itemCreateNum -- 理论最右item id
	if max > self.max then  -- 理论最右item id超过最大id后，最右item id等于最大id， 最左item id向前补足长度，保证长度为itemCreateNum
		min = min - (max - self.max)
		max = self.max
	end

	for i = min,max do  -- 最大创建item不超过self.max,创建长度保证为itemCreateNum个
		self:addItem(i)
	end
end

-- 添加item
function ActivityGamePassportView:addItem(id)
	local rewardInfo = self.awardCfg[id]
	local item = self.rewardItem:clone()
	local idx = id%self.itemCreateNum == 0  and self.itemCreateNum or id%self.itemCreateNum
	local itemWidth = self.rewardItem:width() -- item 宽度
	local x = (id - 1) * itemWidth
	item:xy(x, 0)
	self:refreshRewardItem(item, id)
	self.rewardScroll:addChild(item, idx, "reward"..idx)
	item:show()
	return item
end

-- 修改item
function ActivityGamePassportView:modifyItem(id)
	for i=1,self.itemCreateNum do
		local item =  self.rewardScroll:getChildByName("reward"..i)
		local x = item:x()
		local modifyItemX = (id-1)*self.rewardItem:width()
		if x == modifyItemX then  -- 位置相同表示是信息完全相同的item，需要修改信息；一个item可能改变为不同等级信息，等级不相同，不能修改
			self:refreshRewardItem(item, id)
		end
	end
end

function ActivityGamePassportView:refreshRewardItem(item, id)
	local rewardInfo = self.awardCfg[id]
	local isSpecial = rewardInfo.cfg.specialAward == 1
	local childs = item:multiget("lv", "normalPanel", "highPanel1", "highPanel2", "topMask", "bottomMask", "btnGet", "noClick", "lv1")
	childs.lv:text(string.format(gLanguageCsv["gamePassportItemText"..self.type], rewardInfo.expNum))
	childs.lv1:text("Lv."..rewardInfo.cfg.level)
	text.addEffect(childs.lv, {outline={color=cc.c4b(23, 98, 128, 255), size = 3}})
	text.addEffect(childs.lv1, {outline={color=cc.c4b(255, 254, 238, 255), size = 3}})

	-- 普通奖励
	local normal = {}
	for k,v in csvMapPairs(rewardInfo.cfg.normalAward) do
		normal.key = k
		normal.num = v
		normal.state = rewardInfo.custom.normalAwardState
	end
	self:onBindIcon(self.rewardScroll, childs.normalPanel, normal, isSpecial)
	local high = {}
	for k,v in csvMapPairs(rewardInfo.cfg.eliteAward) do
		table.insert(high, {key = k, num = v, state = rewardInfo.custom.eliteAwardState})
	end
	-- 进阶奖励1
	self:onBindIcon(self.rewardScroll, childs.highPanel1, high[1], isSpecial)
	-- 进阶奖励2
	if high[2] then
		self:onBindIcon(self.rewardScroll, childs.highPanel2, high[2], isSpecial)
		childs.highPanel2:show()
	else
		childs.highPanel2:hide()
	end

	childs.btnGet:visible(rewardInfo.custom.normalAwardState == 1 or rewardInfo.custom.eliteAwardState == 1)  --判断是否有奖励可领取，分为普通奖励和进阶奖励，1可领取，0已领取
	childs.lv:visible(not (rewardInfo.custom.normalAwardState == 1 or rewardInfo.custom.eliteAwardState == 1))
	childs.lv1:visible(not (rewardInfo.custom.normalAwardState == 1 or rewardInfo.custom.eliteAwardState == 1))
	bind.touch(self, childs.btnGet, {methods = {ended = function(view, node, event)
		self:onBtnGetClick(rewardInfo)
	end}})
	childs.topMask:visible(self.currentPassportLv < rewardInfo.cfg.level)
	childs.bottomMask:visible(self.currentPassportLv < rewardInfo.cfg.level or not self.buyHigh)

	bind.click(self, childs.noClick, {method = function()
		self:onRewardNoClick()
	end})
end

function ActivityGamePassportView:onRewardNoClick()
	self:refreshNoClick(false)
end

-- 绑定icon_key通用方法
function ActivityGamePassportView:onBindIcon(parent, node, data, isEffect)
	bind.extend(self, node, {
		class = "icon_key",
		props = {
			data = data,
			onNode = function (panel)
				panel:scale(0.9)
				local img = node:get("img")
				if img then
					img:visible(data.state == 0)
				else
					img = ccui.ImageView:create("common/icon/radio_selected.png")
					:addTo(node, 1000, "img")
					:xy(140, 140)
					:visible(data.state == 0)
				end
			end
		},
	})

	local sprite = node:getChildByName("wupinshanguang")
	if sprite then
		sprite:removeFromParent()
	end
	if isEffect then
		widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "wupinshanguang", "effect_loop", 999)
			:xy(node:size().width/2, node:size().height/2)
			:scale(0.5)
	end
end

-- 跳转至当前最大可领取奖励位置
function ActivityGamePassportView:jumpScroll()
	local max = self.itemCreateNum
	local idx = self.curRewardIdx%max == 0 and max or self.curRewardIdx%max
	local item = self.rewardScroll:getChildByName("reward"..idx)
	if not item then
		return
	end
	local x = item:x()
	local size = self.rewardScroll:getInnerContainer():size()
	local scrollWidth = self.rewardScroll:size().width
	local percent = cc.clampf(x / (size.width - scrollWidth) * 100, 0, 100)
	self.rewardScroll:scrollToPercentHorizontal(percent, 0.01, false)
	self.percent = percent  -- 当前滚动层百分比，用于判断滚动方向
end

function ActivityGamePassportView:resetScroll()
	self.rewardScroll:removeAllChildren()
	self:buildScroll()
	self:buildItem()
	self:refreshNoClick(false)
	self:jumpScroll()
	self.isReset = false
end

-- @desc 右侧展示奖励刷新
function ActivityGamePassportView:refreshTarget()
	local targetRewardInfo = self.awardCfg[self.rigthRewardIndex]
	self.target:getChildByName("lv"):text(string.format(gLanguageCsv["gamePassportItemText"..self.type], targetRewardInfo.expNum))
	self.target:getChildByName("lv1"):text("Lv."..targetRewardInfo.cfg.level)
	text.addEffect(self.target:getChildByName("lv"), {outline={color=cc.c4b(195, 80, 4, 255), size = 3}})
	text.addEffect(self.target:getChildByName("lv1"), {outline={color=cc.c4b(255, 254, 238, 255), size = 3}})
	if matchLanguage({"kr"}) then
		adapt.setTextAdaptWithSize(self.target:getChildByName("lv"), {size = cc.size(228,100)})
	end
	-- 普通奖励
	local normal = {}
	for k,v in csvMapPairs(targetRewardInfo.cfg.normalAward) do
		normal.key = k
		normal.num = v
		normal.state = targetRewardInfo.custom.normalAwardState
	end

	-- 进阶奖励
	local high = {}
	for k,v in csvMapPairs(targetRewardInfo.cfg.eliteAward) do
		table.insert(high, {key = k, num = v, state = targetRewardInfo.custom.eliteAwardState})
	end

	-- 普通奖励
	self:onBindIcon(self.rewardScroll, self.targetNormalPanel, normal, true)
	-- 进阶奖励1
	self:onBindIcon(self.rewardScroll, self.targetHighPanel1, high[1], true)
	-- 进阶奖励2
	if high[2] then
		self:onBindIcon(self.rewardScroll, self.targetHighPanel2, high[2], true)
		self.targetHighPanel2:show()
	else
		self.targetHighPanel2:hide()
	end
end

-- @desc 禁止点击方法，用于滑动中禁止icon点击
function ActivityGamePassportView:refreshNoClick(state)
	for i=1,self.itemCreateNum do
		local noClickPanel = self.rewardScroll:getChildByName("reward"..i):getChildByName("noClick")
		noClickPanel:visible(state)
	end
	self.targetNoClick:visible(state)
end

--更新时间
function ActivityGamePassportView:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local countdown = yyEndtime[self.activityId] - time.getTime()
	bind.extend(self, self.rewardEndTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			endFunc = function()
				self.rewardEndTime:text(gLanguageCsv.activityOver)
			end,
		}
	})
end

return ActivityGamePassportView