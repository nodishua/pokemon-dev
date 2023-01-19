-- @date 2019-12-30
-- @desc 资源找回

local ORDER = {
	roleExp = 1,
	gold = 2,
	expItems = 3,
	advanceItems = 4,
	equipItems = 5,
	energyItems = 6,
}

local RES_STR = {
	gold = gLanguageCsv.gold, 				--金币
	roleExp = gLanguageCsv.experience,  			--  经验
	advanceItems = gLanguageCsv.advanceMaterial,  		--  突破材料
	expItems = gLanguageCsv.experienceMaterial,  			--  经验材料
	equipItems = gLanguageCsv.accessoriesDrawing,  		--  饰品图纸
	energyItems = gLanguageCsv.energyItems,  		--  能量核心
}

local RES_NAME = {
	gold = "icon_jb.png", 				--金币
	roleExp = "icon_wjjy.png",  		--  经验
	advanceItems = "icon_jjcl.png",  	--  突破材料
	expItems = "icon_jlyl.png",  		--  经验材料
	equipItems = "icon_sptz.png",  		--  饰品图纸
	energyItems = "icon_nlhx.png",  	--  能量核心
}

local RETRIEVE_STATE = {
	NOT = 0,	-- 没有找回过
	FREE = 1,	--免费找回过
	ALL = 2,	--全部找回了
}

local LANGUAGE_NAME = {
	[0] = gLanguageCsv.canRetrieve,
	[1] = gLanguageCsv.canAlsoRetrieve,
	[2] = gLanguageCsv.haveRetrieved,
}

--# 找回标识
--Free = 'free'  # 免费找回
--RMB = 'rmb'  # 钻石找回

local ActivityResourceRetrieve = class("ActivityResourceRetrieve", cc.load("mvc").ViewBase)
ActivityResourceRetrieve.RESOURCE_FILENAME = "activity_resource_retrieve.json"
ActivityResourceRetrieve.RESOURCE_BINDING = {
	["item"] = "item",
	["item.textCount1"] = {
		binds = {
			event = "effect",
			data = {outline={color = cc.c4b(178, 119, 0, 255), size = 4}}
		}
	},
	["item.textCount2"] = {
		binds = {
			event = "effect",
			data = {outline={color = cc.c4b(178, 119, 0, 255), size = 4}}
		}
	},

	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				asyncPreload = 4,
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					return a.order < b.order
				end,
			},
			handlers = {
				initItem = bindHelper.self("initItem"),
			},
		},
	},
}

function ActivityResourceRetrieve:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	self:initData()
end

-- 初始化model
function ActivityResourceRetrieve:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yyOpen = gGameModel.role:read("yy_open")
	self.itemsData = idlertable.new({}) 	--存放资源回收活动
	self.roleLv = gGameModel.role:getIdler("level")
	self.rmb = gGameModel.role:getIdler("rmb")
end

--初始化数据
function ActivityResourceRetrieve:initData()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local clientParam = yyCfg.clientParam --客户端参数
	local huodongID = yyCfg.huodongID -- 活动版本
	idlereasy.any({self.yyhuodongs, self.rmb},function(_, yyhuodongs, rmb)
		local retrieve = yyhuodongs[self.activityId] or {}
		if retrieve.lastday ~= tonumber(time.getTodayStrInClock()) then
			return
		end
		local lvl =  retrieve.info.level
		local retrieveDatas = {}
		for k, v in csvPairs(csv.yunying.retrieve) do
			if v.huodongID == huodongID and lvl == v.level then
				retrieveDatas = v
			end
		end

		local itemsData = {}
		local cost = {}
		local days = retrieve.info.days > clientParam.limit and clientParam.limit or retrieve.info.days
		local coefficient = clientParam.dayUpd[days] -- 系数
		for k, v in csvMapPairs(retrieveDatas) do
			if k ~= "cost" and k ~= "level"  and k ~= "huodongID" then
				local data = {key = k, item = {}, retrieveState = RETRIEVE_STATE.NOT, percent = 100}
				local award = {}
				for item, count in csvMapPairs(v) do
					table.insert( award, {item = item, count = count * coefficient} )
				end
				if #award ~= 0 then
					data.order = ORDER[k] or 100
					if retrieve.retrieve_award ~= nil then

						if type(retrieve.retrieve_award[k]) =="table" and retrieve.retrieve_award[k].rmb == 1 then
							--全部找回了
							data.retrieveState = RETRIEVE_STATE.ALL
							data.percent = 0
						elseif type(retrieve.retrieve_award[k]) =="table" and retrieve.retrieve_award[k].free == 1 then
							--部分找回
							data.retrieveState = RETRIEVE_STATE.FREE
							data.percent = 100 - clientParam.freeProportion
						else
							-- 未找回过
							data.retrieveState = RETRIEVE_STATE.NOT
							data.percent = 100
						end
					end
					data.item = award
					itemsData[k] = data
				end
			elseif k == "cost" then
				cost = v
			end
		end
		for k, v in csvMapPairs(cost) do
			local costRmb = clientParam.rmbUpd[days] * v
			if itemsData[k] then
				itemsData[k].cost = math.ceil(costRmb)
				itemsData[k].canBuy = itemsData[k].cost <= rmb
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.itemsData:set(itemsData)
	end)
	--升级动画
	self.roleLv:addListener(function(curval, oldval)
		print("curval == oldval",curval, oldval)
		if curval == oldval then
			return
		end
		gGameUI:stackUI("common.upgrade_notice", nil, nil, oldval)
	end, true)
end

function ActivityResourceRetrieve:initItem(list, node, k, itemData)
	local freeProportion = csv.yunying.yyhuodong[self.activityId].clientParam.freeProportion
	local textType = node:get("textType")
	local btnFree = node:get("btnFree")
	local btnBuy = node:get("btnBuy")
	local imgFound = node:get("imgFound")
	local imgAllFound = node:get("imgAllFound")

	local textCount = node:get("textCount") --花费
	local perCent = 0
	if itemData.retrieveState == RETRIEVE_STATE.NOT then
		-- 没有找回
		imgFound:hide()
		imgAllFound:hide()
		btnFree:show()
		btnBuy:show()

		node:get("textState"):text(LANGUAGE_NAME[0])
	elseif itemData.retrieveState == RETRIEVE_STATE.FREE then
		-- 部分找回
		imgFound:show()
		imgAllFound:hide()
		btnFree:hide()
		btnBuy:show()
		node:get("textState"):text(LANGUAGE_NAME[1])
	elseif itemData.retrieveState == RETRIEVE_STATE.ALL then
		-- 全部找回
		imgFound:hide()
		imgAllFound:show()
		btnBuy:hide()
		btnFree:hide()
		node:get("textState"):text(LANGUAGE_NAME[2])
	else
		printWarn("retrieveState error %s ", itemData.retrieveState)
	end
	if matchLanguage({"en"}) then
		node:get("img3"):width(node:get("textState"):width() + 40)
	end

	--奖励
	local textCount1 = node:get("textCount1")
	local textCount2 = node:get("textCount2")
	local imgIcon1 = node:get("imgIcon1")
	local imgIcon2 = node:get("imgIcon2")
	local awardItem = itemData.item
	local amendment = math.floor -- 数据修正函数

	local function amendment(x, percent)
		--免费领取向下取整
		--钻石领取向上取整
		if percent == 100 then
			return math.floor(x)
		elseif percent ~= 0 then
			return math.floor(x - math.floor(x * freeProportion/100))
		elseif  percent == 0 then
			-- 全部领取完了 显示已经领取的
			return math.floor(x)
		end
	end

	imgIcon1:texture(dataEasy.getIconResByKey(awardItem[1].item))
	textCount1:text(amendment(awardItem[1].count, itemData.percent))
	if awardItem[2] ~= nil then
		textCount1:x(488/2-75)
		imgIcon1:x(textCount1:x() - textCount1:size().width/2 - 10)
		textCount2:text(amendment(awardItem[2].count, itemData.percent))
			:show()
		textCount2:x(488/2 + 150)
		imgIcon2:x(textCount2:x() - textCount2:size().width/2 - 10)
		imgIcon2:texture(dataEasy.getIconResByKey(awardItem[2].item))
	else
		textCount1:x(488/2 + 20)
		imgIcon1:x(textCount1:x() - textCount1:size().width/2 - 10)
		textCount2:hide()
		imgIcon2:hide()
	end

	--按钮
	node:get("imgAwardIcon"):texture("activity/resource_find/".. RES_NAME[itemData.key])
	node:get("textType"):text(RES_STR[itemData.key])
	btnBuy:get("price"):text(itemData.cost)
	if itemData.canBuy == false then
		btnBuy:get("price"):setTextColor(ui.COLORS.NORMAL.ALERT_YELLOW)
	else
		btnBuy:get("price"):setTextColor(ui.COLORS.WHITE)
	end
	node:get("textRemainPercent"):text(itemData.percent.."%")
	bind.touch(self, btnFree, {methods = {ended =  functools.partial(self.sendGetAward, self, itemData.key,"free",0)}})
	bind.touch(self, btnBuy, {methods = {ended =  functools.partial(self.sendGetAward, self, itemData.key, "rmb",itemData.cost)}})
end
-- 发送领取
function ActivityResourceRetrieve:sendGetAward(sType,tab,price)
	if price > 0 and price > gGameModel.role:read("rmb") then
		uiEasy.showDialog("rmb")
		return
	end
	local function cb()
		gGameApp:requestServer("/game/yy/retrieve/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityId, sType, tab)
	end
	if price > 0 then
		dataEasy.sureUsingDiamonds(cb, price)
	else
		cb()
	end
end


return ActivityResourceRetrieve