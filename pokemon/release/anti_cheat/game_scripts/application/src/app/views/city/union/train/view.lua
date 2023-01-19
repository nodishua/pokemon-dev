-- @date:   2019-06-10
-- @desc:   公会训练中心

local REQUEST_TYPE = {
	--解锁
	["open"] = "/game/union/training/open",
	--加速
	["speedup"] = "/game/union/training/speedup",
	--获取列表
	["list"] = "/game/union/training/list",
	--查看其它列表
	["see"] = "/game/union/training/see"
}
local UNLOCK_STATE = {
	--更换
	CHANGE = 1,
	--放入
	UPTIN = 2,
	--可解锁
	CAN_UNLOCK = 3,
	--不可解锁
	NOT_UNLOCK = 4
}
--获取每小时多少经验
local function getExpH(unionLevel, roleLv)
	--union_level.trainingExp * role_level.unionTrainingFix * 60
	local trainingExp = csv.union.union_level[unionLevel].trainingExp
	local unionTrainingFix = csv.base_attribute.role_level[roleLv].unionTrainingFix
	return math.floor(trainingExp * unionTrainingFix * 60)
end

local function getAnimation(parent)
	local animation = parent:get("animation")
	if not animation then
		local size = parent:getContentSize()
		animation = widget.addAnimationByKey(parent, "koudai_gonghuixunlian/gonghuixunlian.skel", "animation", "fangguang", 555)
			:xy(size.width/2, 0)
	else
		animation:play("fangguang")
	end
end

local function setPanelChange(list, panelChange, v)
	if v then
		local unitId= dataEasy.getUnitId(v.card_id, v.skin_id)
		bind.extend(list, panelChange:get("icon"), {
			class = "card_icon",
			props = {
				unitId = unitId,
				advance = v.advance,
				rarity = v.rarity,
				star = v.star,
				levelProps = {
					data = v.level,
				},
				onNode = function(panel)
					panel:xy(-5, -7)
				end,
			}
		})
		panelChange:get("name"):text(v.name)
		local sumExp = csv.base_attribute.card_level[v.level]["levelExp"..csv.cards[v.card_id].levelExpID]
		local expTxt = v.level >= v.roleLv and gLanguageCsv.experienceFull or v.level_exp.."/"..sumExp
		local color = v.level >= v.roleLv and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.DEFAULT
		local expH = v.level < v.roleLv and v.expH or 0
		panelChange:get("level1"):text("+"..expH)
		adapt.oneLinePos(panelChange:get("level1"), panelChange:get("level2"))
		text.addEffect(panelChange:get("exp"), {color = color})
		panelChange:get("exp"):text(expTxt)
		panelChange:get("bar"):setPercent(v.level >= v.roleLv and 100 or v.level_exp/sumExp*100)

	end
end

local function setPanelMask(panelMask, v)
	if v.conditoinTxt then
		local txt1 = panelMask:get("txt1")
		local txt2 = panelMask:get("txt2")
		local txt3 = panelMask:get("txt3")
		txt1:text(v.conditoinTxt)
		txt2:text(v.conditoinLevel)
		adapt.oneLinePos(txt2, txt1, cc.p(8, 0), "right")
		adapt.oneLinePos(txt2, txt3, cc.p(8, 0))
	end
end

local function setTextColor(childs, state)
	local color = state and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.DEFAULT
	text.addEffect(childs.name, {color = color})
	text.addEffect(childs.num, {color = color})
	text.addEffect(childs.numNote, {color = color})
	text.addEffect(childs.levelNote, {color = color})
	text.addEffect(childs.level, {color = color})
end

local function setPanelUnlock(panelUnlock, cost)
	local txt = string.format(gLanguageCsv.aConditionsUnlock, cost)
	panelUnlock:get("txt2"):text(txt)
end

local UnionTrainView = class("UnionTrainView", Dialog)

UnionTrainView.RESOURCE_FILENAME = "union_train.json"
UnionTrainView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftItem"] = "leftItem",
	["leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				unionCanUnlockIdx = bindHelper.self("unionCanUnlockIdx"),
				showTab = bindHelper.self("showTab"),
				hasFriend = bindHelper.self("hasFriend"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					panel:get("txt"):text(v.name)
					adapt.setAutoText(panel:get("txt"), nil, 300)
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-8)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})

					bind.extend(list, node, {
						class = "red_hint",
						props = {
							state = list.showTab:read() ~= k,
							specialTag = v.redHint,
							listenData = {
								unionCanUnlockIdx = list.unionCanUnlockIdx,
								hasFriend = list.hasFriend,
							},
							onNode = function (node)
								node:xy(60, 345)
							end
						}
					})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["myMaskPanel"] = "myMaskPanel",
	["myItem"] = "myItem",
	["mySubList"] = "mySubList",
	["myList"] = {
		varname = "myList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("trainDatas"),
				columnSize = 2,
				item = bindHelper.self("mySubList"),
				dataOrderCmpGen = bindHelper.self("onSortTrain", true),
				cell = bindHelper.self("myItem"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget(
						"panelChange",
						"panelPutIn",
						"panelUnlock",
						"mask"
					)
					setPanelChange(list, childs.panelChange, v.cardData)
					setPanelMask(childs.mask, v)
					setPanelUnlock(childs.panelUnlock, v.cost)
					childs.panelChange:visible(v.unlocked == UNLOCK_STATE.CHANGE)
					childs.panelPutIn:visible(v.unlocked == UNLOCK_STATE.UPTIN)
					childs.panelUnlock:visible(v.unlocked == UNLOCK_STATE.CAN_UNLOCK)
					childs.mask:visible(v.unlocked == UNLOCK_STATE.NOT_UNLOCK)
					local btnChange = childs.panelChange:get("btnChange")
					text.addEffect(btnChange:get("title"), {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					local btnPutIn = childs.panelPutIn:get("btnPutIn")
					text.addEffect(btnPutIn:get("title"), {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					bind.touch(list, btnChange, {methods = {ended = functools.partial(list.changeClick, list:getIdx(k), v)}})
					bind.touch(list, btnPutIn, {methods = {ended = functools.partial(list.changeClick, list:getIdx(k), v)}})
					bind.touch(list, childs.panelUnlock:get("btnUnlock"), {methods = {ended = functools.partial(list.unlockClick, list:getIdx(k), v)}})
				end,
				asyncPreload = 16,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				changeClick = bindHelper.self("onChangeClickClick"),
				unlockClick = bindHelper.self("onUnlockClickClick"),
				afterBuild = bindHelper.self("onMyAfterBuild"),
			},
		},
	},
	["otherPanel"] = "otherPanel",
	["otherItem"] = "otherItem",
	["otherPanel.otherList"] = {
		varname = "otherList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("otherDatas"),
				item = bindHelper.self("otherItem"),
				asyncPreload = 4,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					setPanelChange(list, node, v)
					node:get("level1"):hide()
					node:get("level2"):hide()
					local canClick = v.level < v.roleLv and v.speedup < 6
					if v.selectOtherId == k then
						getAnimation(node:get("icon"))
					end
					uiEasy.setBtnShader(btn, btn:get("title"), canClick and 1 or 2)
					bind.touch(list, btn, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onBtnSpeedUp"),
			},
		},
	},
	["otherPanel.roleMaskPanel"] = "roleMaskPanel",
	["roleItem"] = "roleItem",
	["otherPanel.roleList"] = {
		varname = "roleList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("roleDatas"),
				item = bindHelper.self("roleItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"bg",
						"logo",
						"name",
						"num",
						"numNote",
						"levelNote",
						"level"
					)
					childs.bg:visible(v.select == true)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.memberData.logo,
							frameId = v.memberData.frame,
							level = false,
							vip = false,
							onNode = function(node)
								node:scale(0.9)
							end,
						}
					})
					setTextColor(childs, v.select == true)
					childs.name:text(v.memberData.name)
					childs.num:text(v.num)
					adapt.oneLinePos(childs.num, childs.numNote)
					childs.level:text(v.memberData.level)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
				asyncPreload = 4,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onRoleItemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["otherPanel.empty"] = "empty",
	["otherPanel.speedUpPanel"] = "speedUpPanel",
	["otherPanel.speedUpPanel.btnSpeedUp"] = {
		varname = "btnSpeedUp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSpeedUp")}
		},
	},
	["otherPanel.speedUpPanel.num1"] = "speedUpNum1",
	["otherPanel.speedUpPanel.num2"] = "speedUpNum2",
}

function UnionTrainView:onCreate()

	self.unionCanUnlockIdx = userDefault.getForeverLocalKey("unionCanUnlockIdx", 0)

	self:initModel()
	--tab
	self.leftDatas = {
		{name = gLanguageCsv.myTrainingCenter, redHint = "unionTrainPosition"},
		{name = gLanguageCsv.accelerateForComrades, redHint = "unionTrainSpeedUp"}}
	self.leftDatas = idlers.newWithMap(self.leftDatas)
	self.showTab = idler.new(1)
	self.showOtherTrain = idler.new(false)
	self.showTab:addListener(function(val, oldval, idler)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		self.myList:visible(val == 1)
		self.myMaskPanel:visible(val == 1)
		self.showOtherTrain:set(val == 2)
	end)

	--我的训练列表数据
	self.trainDatas = idlers.new()
	idlereasy.any({self.slots, self.opened}, function(_, slots, opened)
		local roleLv = self.roleLv:read()
		local vipLevel = self.vipLevel:read()
		local unionLevel = self.unionLevel:read()
		local tmpData = {}
		local maxCanUnLockIdx = 0
		for k,v in csvPairs(csv.union.training) do
			local unlocked
			local cardData
			local conditoinTxt
			local conditoinLevel
			--已开启有精灵 更换
			local card
			if slots[k] then
				card = gGameModel.cards:find(slots[k].id)
			end
			if opened[k] and card then
				unlocked = UNLOCK_STATE.CHANGE
				slots[k].rarity = csv.cards[slots[k].card_id].rarity
				slots[k].expH = getExpH(unionLevel, roleLv)
				slots[k].roleLv = roleLv
				slots[k].nextExp = card:read("next_level_exp")
				slots[k].skin_id = card:read("skin_id")
				cardData = slots[k]
			--已开启没精灵 放入
			elseif opened[k] and not card then
				unlocked = UNLOCK_STATE.UPTIN
			--没开启 等级和vip满足 可开启
			elseif (not opened[k]) and (roleLv >= v.openLevel) and (vipLevel >= v.openVIP) then
				unlocked = UNLOCK_STATE.CAN_UNLOCK
				if k > maxCanUnLockIdx then
					maxCanUnLockIdx = k
				end
			--不可开启
			else
				local txtTyp = roleLv >= v.openLevel and "VIP " or gLanguageCsv.level
				conditoinLevel = roleLv >= v.openLevel and v.openVIP or v.openLevel
				conditoinTxt = string.format(gLanguageCsv.reachedConditoinUnlock, txtTyp)
				unlocked = UNLOCK_STATE.NOT_UNLOCK
			end
			table.insert(tmpData,{
				id = k,
				unlocked = unlocked,
				cardData = cardData,
				conditoinTxt = conditoinTxt,
				conditoinLevel = conditoinLevel,
				cost = v.costRMB
			})
		end
		dataEasy.tryCallFunc(self.myList, "updatePreloadCenterIndex")
		self.trainDatas:update(tmpData)
		userDefault.setForeverLocalKey("unionCanUnlockIdx", maxCanUnLockIdx)
	end)


	-- self.otherDatas = idlers.new({})
	self.otherDatas = idlers.newWithMap({})
	self.roleDatas = idlers.new({})
	self.selectRole = idler.new(1)
	--选择成员
	self.selectRole:addListener(function(val, oldval, idler)
		local oldRole = self.roleDatas:atproxy(oldval)
		local newRole = self.roleDatas:atproxy(val)
		if oldRole then
			oldRole.select = false
		end
		if newRole then
			newRole.select = true
		end
	end)
	self.selectOtherId = idler.new(0)
	idlereasy.when(self.selectRole,function(_, selectRole)
		local roleData = self.roleDatas:atproxy(selectRole)
		self.selectOtherId:set(0)
		if roleData then
			self:onRequest("see", {roleData.id}, function(tb)
				dataEasy.tryCallFunc(self.otherList, "updatePreloadCenterIndex")
				self.otherDatas:update(self:setRoleDatas(tb.view, roleData.id))
			end)
		end
	end)
	idlereasy.when(self.unionTrainingSpeedup,function(_, unionTrainingSpeedup)
		self.speedUpNum1:text(math.max(6 - unionTrainingSpeedup or 0, 0))
		adapt.oneLinePos(self.speedUpNum1, self.speedUpNum2)
		uiEasy.setBtnShader(self.btnSpeedUp, self.btnSpeedUp:get("title"), unionTrainingSpeedup < 6 and 1 or 2)
		for i,_ in pairs(csv.union.training) do
			if self.otherDatas:atproxy(i) then
				dataEasy.tryCallFunc(self.otherList, "updatePreloadCenterIndex")
				self.otherDatas:atproxy(i).speedup = unionTrainingSpeedup
				self.otherDatas:atproxy(i).selectOtherId = self.selectOtherId:read()
			end
		end
	end)
	self.hasFriend = false
	--别人训练列表数据
	idlereasy.when(self.showOtherTrain,function(_, showOtherTrain)
		if showOtherTrain then
			local roleId = self.roleId:read()
			local members = self.members:read()
			gGameApp:requestServer("/game/union/training/list",function (tb)
				local roleDatas = {}
				local count = 0
				for i,v in ipairs(tb.view) do
					if roleId ~= v[1] and v[2] > 0 then
						table.insert(roleDatas, {
							id = v[1],
							num = v[2],
							memberData = members[v[1]]
						})
						count = count + 1
					end
				end
				self.roleDatas:update(roleDatas)
				self.selectRole:set(self.selectRole:read(), true)
				self.otherPanel:visible(true)
				self.hasFriend = count > 0
			end)
		else
			self.otherPanel:visible(false)
		end
	end)
	Dialog.onCreate(self)
end

function UnionTrainView:initModel()
	local trainInfo = gGameModel.union_training
	self.slots = trainInfo:getIdler("slots")
	self.opened = trainInfo:getIdler("opened")
	local unionInfo = gGameModel.union
	self.unionLevel = unionInfo:getIdler("level")
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	self.roleLv = gGameModel.role:getIdler("level")
	self.roleId = gGameModel.role:getIdler("id")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	--加速次数
	local dailyRecord = gGameModel.daily_record
	self.unionTrainingSpeedup = dailyRecord:getIdler("union_training_speedup")
end

function UnionTrainView:setRoleDatas(view, roleId, selectOtherId)
	local unionLevel = self.unionLevel:read()
	local otherDatas = {}
	for i,cards in pairs(view.slots) do
		local roleLv = self.members:read()[roleId].level
		local expH = getExpH(unionLevel, roleLv)
		cards.expH = expH
		cards.roleId = roleId
		local cardInfo = csv.cards[cards.card_id]
		local unitInfo = csv.unit[cardInfo.unitID]
		cards.rarity =  unitInfo.rarity
		cards.roleLv = roleLv
		cards.selectOtherId = selectOtherId
		cards.speedup = self.unionTrainingSpeedup:read()
		cards.selectOtherId = self.selectOtherId:read()
		cards.nextExp = csv.base_attribute.card_level[cards.level]["levelExp"..cardInfo.levelExpID]
		if view.offline_exp and view.offline_exp[cards.id] then
			local level = cards.level
			local level_exp = cards.level_exp + view.offline_exp[cards.id]
			for i=level,roleLv do
				local needExp = csv.base_attribute.card_level[i]["levelExp"..cardInfo.levelExpID]
				if i >= roleLv or level_exp < needExp then
					cards.level_exp = level_exp
					cards.level = i
					break
				end
				level_exp = level_exp - needExp
			end
		end
	 	otherDatas[i] = cards
	end
	return otherDatas
end
--替换或放入精灵
function UnionTrainView:onChangeClickClick(list, t, v)
	local requestTyp = v.unlocked == 1 and "replace" or "start"
	gGameUI:stackUI("city.union.train.select_sprite", nil, nil, {idx = v.id, requestTyp = requestTyp})
end
--解锁
function UnionTrainView:onUnlockClickClick(list, t, v)
	local params = {
		cb = function()
			self:onRequest("open", {v.id})
		end,
		isRich = true,
		btnType = 2,
		content = string.format(gLanguageCsv.unlockTrain, v.cost),
		dialogParams = {clickClose = false},
	}
	gGameUI:showDialog(params)
end
--加速
function UnionTrainView:onBtnSpeedUp(list, k, v)
	local requestParams = {}
	local speedUpTimes = math.max(6 - self.unionTrainingSpeedup:read(), 1)
	if v then

		speedUpTimes = 1
		requestParams = {v.roleId, k}
	end
	self.selectOtherId:set(k)
	self:onRequest("speedup", requestParams, function(tb)
		self.selectRole:set(self.selectRole:read(), true)
		gGameUI:showTip(string.format(gLanguageCsv.acceleratingSuccessTips, speedUpTimes * gCommonConfigCsv.unionTrainingSpeedUpGold))
	end)
end
--查看别人训练
function UnionTrainView:onRoleItemClick(list, k, v)
	dataEasy.tryCallFunc(self.otherList, "setItemAction", {isAction = true})
	self.selectRole:set(k)
end
--切换页签
function UnionTrainView:onLeftItemClick(list, index)
	self.showTab:set(index)
end
--各种请求
function UnionTrainView:onRequest(typ, requestParams, cb)
	gGameApp:requestServer(REQUEST_TYPE[typ],function (tb)
		if cb then
			cb(tb)
		end
	end, unpack(requestParams or {}))
end

function UnionTrainView:onAfterBuild()
	local showEmpty = self.roleList:getChildrenCount() == 0 and self.showOtherTrain:read()
	self.empty:visible(showEmpty)
	self.speedUpPanel:visible(not showEmpty)
	self.roleMaskPanel:visible(not showEmpty)
	uiEasy.setBottomMask(self.roleList, self.roleMaskPanel)
end

function UnionTrainView:onMyAfterBuild()
	uiEasy.setBottomMask(self.myList, self.myMaskPanel)
end

function UnionTrainView:onSortTrain(list)
	return function(a, b)
		if a.unlocked ~= b.unlocked then
			return a.unlocked < b.unlocked
		end
		return a.id < b.id
	end
end

return UnionTrainView