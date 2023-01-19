-- @date:   2019-10-12
-- @desc:   随机塔-积分奖励

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("textNote"))
		text.addEffect(btn:get("textNote"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local RandomTowerPointRewardView = class("RandomTowerPointRewardView", Dialog)

RandomTowerPointRewardView.RESOURCE_FILENAME = "random_tower_point_reward.json"
RandomTowerPointRewardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["down.btnGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onGetBtn(-1)
			end)}
		},
	},
	["down.btnGet.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["item"] = "item",
	["item1"] = "item1",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("pointDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("textScore", "btnGet", "icon", "list", "imgReceived")
					childs.textScore:text(v.point)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 1})
					end
					--0已领取，1可领取, nil不能领取(由于排序nil赋值为0.5)
					childs.imgReceived:visible(v.canReceive == 0)
					childs.btnGet:visible(v.canReceive ~= 0)
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					setBtnState(childs.btnGet, v.canReceive == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onitemClick"),
			},
		},
	},
	["down.textScore"] = "textScore",
	["down.textNote"] = "textNote",
	["down.list"] = "downList",
}

function RandomTowerPointRewardView:onCreate()
	self:initModel()
	self.pointDatas = idlers.new()
	local isHas, getAward = true, false
	-- 上次没有领取的奖励索引
	local getTable = {}
	local isGetAward = {}
	-- 一键领取：版本变动后且有可领取奖励时显示(此一键领取和以往不同，版本改动后可领切仅一次)
	self.saveGetAward = userDefault.getForeverLocalKey("saveGetAward", {})
	isGetAward = userDefault.getForeverLocalKey("isGetAward", {})
	idlereasy.any({self.resultPointAward, self.pointAwardVersion}, function(_, resultPointAward, pointAwardVersion)
		local pointDatas = {}
		local totalGetAward = {}
		getTable = {}
		local saveGetAwardSign = false
		for k,v in csvPairs(csv.random_tower.point_award) do
			if v.version == pointAwardVersion then
				--（1表示可领 0表示已领）
				if resultPointAward[k] == 1 then
					getAward = true
					getTable[k] = true
				end
				if resultPointAward[k] == 0 then
					for k,v in csvMapPairs(v.award) do
						if not totalGetAward[k] then
							totalGetAward[k] = 0
						end
						totalGetAward[k] = totalGetAward[k] + v
					end
					isHas = false
				end
				pointDatas[k] = {
					id = k,
					award = v.award,
					point = v.needPoint,
					canReceive = resultPointAward[k] or 0.5
				}
				if self.saveGetAward and self.saveGetAward[k] then
					saveGetAwardSign = true
					if not getTable[k] then getTable[k] = false end
				end
			end
		end
		if saveGetAwardSign then
			self.saveGetAward = getTable
		end
		local getAwardBtn = false
		if (getAward and isHas) or saveGetAwardSign then
			getAwardBtn = true
		end
		if not getAward then
			self.saveGetAward = {}
			getAwardBtn = false
		end
		self.getBtn:visible(getAwardBtn)
		--累计获得奖励
		uiEasy.createItemsToList(self, self.downList, totalGetAward, {scale = 0.8})
		self.pointDatas:update(pointDatas)
	end)


	local awardState = userDefault.getForeverLocalKey("awardState", {})
	-- 当前版号(如果版号不一致会弹框提示)
	if (awardState and awardState.isOpen) or (isGetAward and isGetAward.isOpen) then
		if getAward and isHas then
			-- 版本变动后会有弹框提示，如果在有可领取奖励时且没有领取任何奖励的时候每次进来会一直弹框提示（就是为了提示玩家领取奖励）
			gGameUI:showDialog({title = gLanguageCsv.tips, content = gLanguageCsv.etherIntegral, btnType = 2, cb = function ()
			end})
			userDefault.setForeverLocalKey("isGetAward", {isOpen = true})
		else
			-- 如果版本变动后第一次进来没有可领取那么这个版本就不会在有弹框(此弹框的意义就是版本变动时提醒玩家领取奖励)
			userDefault.setForeverLocalKey("isGetAward", {})
		end
		self.saveGetAward = getTable
	end
	if awardState and awardState.isOpen then
		userDefault.setForeverLocalKey("awardState", {})
	end

	local totalPoint = self.dayPoint:read() + self.history_point:read() * 0.08
	self.textScore:text(math.floor(totalPoint))
	adapt.oneLinePos(self.textScore, self.textNote, cc.p(20, 0), "left")
	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")

	Dialog.onCreate(self)
end

function RandomTowerPointRewardView:initModel()
	self.resultPointAward = gGameModel.random_tower:getIdler("point_award")
	--当日积分
	self.dayPoint = gGameModel.random_tower:getIdler("day_point")
	--历史总积分
	self.history_point = gGameModel.random_tower:getIdler("history_point")
	-- 当前版本
	self.pointAwardVersion = gGameModel.random_tower:getIdler("point_award_version")
end

function RandomTowerPointRewardView:onitemClick(list, k, v)
	self:onGetBtn(v.id)
end

function RandomTowerPointRewardView:onGetBtn(csvId)
	local showOver = {false}
	gGameApp:requestServerCustom("/game/random_tower/point/award")
		:params(csvId)
		:onErrClose(function(err)
			if err.err ~= "randomTowerPointAwardVersionChange" then return false end
			gGameApp:requestServerCustom("/game/random_tower/prepare", function(tb)
				if tb.view.updata then
					gGameUI:showDialog({title = gLanguageCsv.tips, content = gLanguageCsv.randomTowerPointAwardVersionChange, btnType = 2, cb = function ()
					end})
				end
			end)
		end)
		:onResponse(function (tb)
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function(tb)
			gGameUI:showGainDisplay(tb)
			userDefault.setForeverLocalKey("isGetAward", {})
		end)

	if csvId == -1 then
		self.saveGetAward = {}
	else
		self.saveGetAward[csvId] = false
	end
end

function RandomTowerPointRewardView:onClose()
	userDefault.setForeverLocalKey("saveGetAward", self.saveGetAward)
	Dialog.onClose(self)
end

function RandomTowerPointRewardView:onSortCards(list)
	return function(a, b)
		if a.canReceive ~= b.canReceive then
			return a.canReceive > b.canReceive
		end
		return a.id < b.id
	end
end

return RandomTowerPointRewardView
