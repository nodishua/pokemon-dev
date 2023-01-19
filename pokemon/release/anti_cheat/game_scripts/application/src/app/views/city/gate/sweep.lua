local function setTitle(titleNode1, titleNode2, title1, title2)
	if title1 then
		titleNode1:text(title1)
	end
	if title2 then
		titleNode2:text(title2)
	end
	adapt.oneLinePos(titleNode1, titleNode2)
end

local function getTargetItemNum(datas, key)
	local count = 0
	if not key then
		return count
	end
	for _,data in ipairs(datas) do
		if data[key] then
			count = count + data[key]
		else
			for i,v in pairs(data.items or {}) do
				if i == key then
					count = count + v
				end
			end
		end
	end

	return count
end

local ViewBase = cc.load("mvc").ViewBase
local GateSweepView = class("GateSweepView", Dialog)

GateSweepView.RESOURCE_FILENAME = "gate_sweep.json"
GateSweepView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpeedClick")}
		}
	},
	["title.textNote1"] = "titleNode1",
	["title.textNote2"] = "titleNode2",
	["btnSure"] = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["sureBtn.title"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["againBtn.title"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["btnAgain"] = {
		varname = "againBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainClick")}
		}
	},
	["panelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpeedClick")}
		}
	},
	["sweepInfo"] = {
		varname = "sweepInfo",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowTargetInfo"),
		},
	},
	["sweepInfo.textNoteNum1"] = "textNoteNum1",
	["sweepInfo.textNoteNum2"] = "textNoteNum2",
	["list"] = "list",
	["item"] = "item",
	["item.textTip"] = "textTip",
	["successItem"] = "successItem",
	["itemTitle"] = "itemTitle",
	["innerList"] = "innerList",
	["item1"] = "item1",
	["imgBG"] = "imgBG",
	["bottomItem"] = "bottomItem",
	["bottomList"] = {
		varname = "bottomList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("bottomDatas"),
				item = bindHelper.self("bottomItem"),
				item1 = bindHelper.self("item1"),
				startGateId = bindHelper.self("startGateId"),
				isDouble = bindHelper.self("isDouble"),
				innerList = bindHelper.self("innerList"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("textTitle", "innerList")
					if v.effect then
						childs.textTitle:hide()
						childs.innerList:hide()
						local size = node:size()
						local effect = CSprite.new("level/saodangchenggong.skel")		-- 文字部分特效
						effect:addTo(node, 100)
						effect:setAnchorPoint(cc.p(0.5, 0.5))
						effect:xy(size.width / 2, size.height / 2)
						effect:visible(true)
						-- 播放结算特效
						effect:play("saodangchenggong")
						effect:addPlay("saodangchenggong_loop")
						effect:retain()
					else
						local str = ""
						if v.isTotal then
							str = gLanguageCsv.totalGot
						else
							str = csv.endless_tower_scene[list.startGateId + k - 1].sceneName
						end
						childs.textTitle:text(str)

						local listData = v.items
						if v.gold and not listData.gold then
							listData.gold = v.gold
						end

						-- 排序:金币、高级努力币、普通努力币、道具id
						local newListData = {}
						for key,value in pairs(listData) do
							local data = {key = key, value = value}
							if key == "gold" then
								data.sort = 1
							elseif key == 452 then
								data.sort = 2
							elseif key == 451 then
								data.sort = 3
							elseif type(key) ~= "number" then
								data.sort = 4
							else
								data.sort = key + 4
							end
							table.insert(newListData, data)
						end
						table.sort(newListData, function (a, b)
							return a.sort < b.sort
						end)
						local itemSubList
						local j = 0
						local line = 6
						local verticalNum = math.ceil(itertools.size(listData)/6)
						local listHeight = list.innerList:height() * verticalNum + childs.innerList:getItemsMargin() * (verticalNum - 1)
						node:height(node:height() + listHeight - list.innerList:height())
						childs.innerList:height(listHeight)
						childs.textTitle:y(childs.textTitle:y() + listHeight - list.innerList:height())

						for kk,vv in pairs(newListData) do
							j = j + 1
							local row, col = mathEasy.getRowCol(j, line)
							if j%line == 1 then
								itemSubList = list.innerList:clone():tag(row):show()
								childs.innerList:pushBackCustomItem(itemSubList)
							end
							local itemItem = list.item1:clone():show()
							local binds = {
								class = "icon_key",
								props = {
									data = {
										key = vv.key,
										num = vv.value,
									},
									isDouble = list.isDouble,
								},
							}
							bind.extend(list, itemItem, binds)
							itemSubList:pushBackCustomItem(itemItem)
						end
					end

				end,
				preloadBottom = true,
				asyncPreload = 6,
			},
		},
	},
}

GateSweepView.RESOURCE_STYLES = {
	backGlass = true,
}

function GateSweepView:setEffect(pnode)
	local size = pnode:size()
	local effect = CSprite.new("level/saodangchenggong.skel")		-- 文字部分特效
	effect:addTo(pnode, 100)
	effect:setAnchorPoint(cc.p(0.5, 0.5))
	effect:xy(size.width / 2, size.height / 2)
	effect:visible(true)
	effect:hide()-- 初始状态先隐藏

	self.effect = effect
end

function GateSweepView:playEffect()
	local effect = self.effect
	if not effect then return end

	local isUnionSweep = self.from == "union"
	local play1 = isUnionSweep and "tiaozhanchenggong" or "saodangchenggong"
	local play2 = isUnionSweep and "tiaozhanchenggong_loop" or "saodangchenggong_loop"
	local isDailyAssistant = self.from == "dailyAssistant"
	play1 = isDailyAssistant and "saodangwancheng" or play1
	play2 = isDailyAssistant and "saodangwancheng_loop" or play2

	-- 播放结算特效
	effect:show()
	effect:play(play1)
	effect:addPlay(play2)
	effect:retain()
end

-- @param showType 1: 两个按钮 2: 只有确定按钮
-- @param hasExtra 是否有附加奖励
-- @param sweepData 数据
-- @param oldRoleLv 等级
-- @param startGateId 开始扫荡的开始关卡ID
-- @param targetNum 目标物品需要的数量
-- @param targetId 目标物品的 ID
function GateSweepView:onCreate(params)
	self:initModel()
	--第几战
	self.sweepTimes = 1
	self.prenumb1 = 0
	self.prenumb2 = 0
	setTitle(self.titleNode1, self.titleNode2, params.title1, params.title2)
	self.sweepData = params.sweepData
	local sweepData = params.sweepData
	local oldRoleLv = params.oldRoleLv
	local hasExtra = params.hasExtra
	local oldCapture = params.oldCapture
	local curMopUpNum = params.curMopUpNum or 0
	self.startGateId = params.startGateId or 100000
	self.cb = params.cb
	self.checkCb = params.checkCb
	self.from = params.from
	local showType = params.showType or 1
	self.isShowTargetInfo = idler.new(params.targetId ~= nil and params.targetNum ~= nil)
	self.isDouble = params.isDouble
	if self.from == "gate" or self.from =="gainWay" then
		self.gateId = params.gateId
	elseif self.from == "allGate" then
		self.gateId = params.sweepData[1].gateId
	end
	self.catchup = params.catchup


	if params.targetId and params.targetNum then
		local curSweepGet = getTargetItemNum(sweepData, params.targetId)
		self.textNoteNum1:text(curSweepGet)
		local hasNum = dataEasy.getNumByKey(params.targetId)
		bind.extend(self, self.sweepInfo:get("item"), {
			class = "icon_key",
			props = {
				data = {
					key = params.targetId,
					num = hasNum,
				},
				onNode = function(node)
					node:scale(0.9)
				end,
			},
		})
		if hasNum >= params.targetNum then
			local str = gLanguageCsv.material
			if dataEasy.isFragment(params.targetId) then
				str = gLanguageCsv.fragment
			end
			local sweepInfo = self.sweepInfo:get("textNote2")
			sweepInfo:text(string.format(gLanguageCsv.hasEnoughItemOrFrag, str))
			adapt.setTextAdaptWithSize(sweepInfo, {size = cc.size(300, 100), vertical = "center", horizontal = "left", margin = -4})
			self.sweepInfo:get("textNoteNum2"):visible(false)
			self.sweepInfo:get("textNoteGe2"):visible(false)
		else
			self.textNoteNum2:text(params.targetNum - hasNum)
		end
	end
	adapt.oneLinePos(self.sweepInfo:get("textNote1"), {self.textNoteNum1, self.sweepInfo:get("textNoteGe1")}, {cc.p(10, 0)}, "left")
	adapt.oneLinePos(self.sweepInfo:get("textNote2"), {self.textNoteNum2, self.sweepInfo:get("textNoteGe2")}, {cc.p(10, 0)}, "left")

	if showType == 2 then
		self.sureBtn:x(self.imgBG:x())
	end
	self.list:setScrollBarEnabled(false)
	self.innerList:setScrollBarEnabled(false)
	self.bottomList:setScrollBarEnabled(false)
	self.item:get("list"):setScrollBarEnabled(false)
	self.bottomItem:get("innerList"):setScrollBarEnabled(false)
	local newCapture = gGameModel.capture:read("limit_sprites")
	local i = 0
	local interval = 0
	self.interval = 0.1
	self.canClose = false
	self.btnClose:setTouchEnabled(false)
	self.againBtn:hide()
	self.sureBtn:hide()
	local sweepDataSize = itertools.size(sweepData)

	local function sweepDone ()
		self.againBtn:visible(showType == 1)
		self.sureBtn:show()
		if oldRoleLv < self.roleLv:read() then
			gGameUI:stackUI("common.upgrade_notice", nil, nil, oldRoleLv)
		end
		performWithDelay(self, function()
			self:playEffect()
			uiEasy.showMysteryShop()
			uiEasy.showActivityBoss()
			self.canClose = true
			self.btnClose:setTouchEnabled(true)
			if dataEasy.isUnlock(gUnlockCsv.limitCapture) then
				for i, capture in pairs(newCapture) do
					--符合条件的新精灵
					if csv.capture.sprite[capture.csv_id] then
						if capture.find_time + csv.capture.sprite[capture.csv_id].time - time.getTime() > 0 and capture.state == 1 then --1可捕捉状态 2不可捕捉
							--新的精灵
							if not itertools.equal(capture, oldCapture[i]) then
								gGameUI:stackUI("common.capture_tips")
								break
							end
						end
					end
				end
			end
		end, 0.5)
	end
	if self.from == "endlessTower" then
		sweepDone()
		local effect = {effect = true}
		table.insert(sweepData, effect)
		self.bottomDatas = idlertable.new(sweepData)
		self.list:hide()
	else
		self.bottomDatas = idlertable.new({})
		self.bottomList:hide()
		self:enableSchedule():schedule(function (dt)
			if i >= sweepDataSize then
				self.interval = 10
				interval = 10
				self.list:scrollToBottom(0.3, true)
				sweepDone()
				return false
			end
			interval = interval - dt
			if interval <= 0 and i < sweepDataSize then
				interval = self.interval
				i = i + 1
				local data = sweepData[i]
				local isDouble = self.isDouble
				if data.isExtra then
					-- isDouble = false -- 额外奖励固定不双倍
					local successItem = self.successItem:clone():show()
					self:setEffect(successItem)
					self.list:pushBackCustomItem(successItem)
					if hasExtra == nil then
						hasExtra = true
					end
				end
				-- isTotal 是否为总计获得，针对最后一项显示文本，params.isTotal及总计获得数据均由外部传入
				local isTotal = i == sweepDataSize and params.isTotal
				if data.textDatas then
					if data.dailyDatas and data.dailyDatas.hasTitle then
						local titleItem = self:cloneTitleItem(i, data.exp or 0, data.isExtra, isTotal, data.dailyDatas)
						self.list:pushBackCustomItem(titleItem)
						-- 还需要加一个空行，增加行间距
						self.list:pushBackCustomItem(self:cloneTextItem(" ", {fontSize = 1}))
					end
					local textItem = self:cloneTextItem(data.textDatas.content, data.textDatas.params or {})
					self.list:pushBackCustomItem(textItem)
				else
					if not data.noTitle then
						local titleItem = self:cloneTitleItem(i, data.exp or 0, data.isExtra, isTotal, data.dailyDatas)
						self.list:pushBackCustomItem(titleItem)
					end
					local listData = data.items
					if data.gold and not listData.gold then
						listData.gold = data.gold
					end

					local itemSubList
					local j = 0
					local line = 6

					-- listData排序:金币、高级努力币、普通努力币、道具id
					local newListData = {}
					for k,v in pairs(listData) do
						local data = {key = k, value = v}
						data.type = "items"
						if k == "fish" then
							for i, val in pairs(v) do
								data = {key = i, value = val}
								data.type = "fish"
								data.sort = 5
								table.insert(newListData, data)
							end
						elseif k == "cards" then
							for i, val in pairs(v) do
								data = {key = i, value = val}
								data.type = "cards"
								data.sort = 6
								table.insert(newListData, data)
							end
						elseif k == "carddbIDs" then
						else
							if k == "gold" then
								data.sort = 1
							elseif k == 452 then
								data.sort = 2
							elseif k == 451 then
								data.sort = 3
							elseif type(k) ~= "number" then
								data.sort = 4
							else
								data.sort = k + 4
							end
							table.insert(newListData, data)
						end
					end
					table.sort(newListData, function (a, b)
						return a.sort < b.sort
					end)

					local verticalNum = math.ceil(itertools.size(newListData)/6)
					local item = self:cloneItem(verticalNum,i,newListData)
					self.list:pushBackCustomItem(item)

					if self.catchup and self.catchup > 0 then
						isDouble = true
						if i > self.catchup then
							isDouble = false
						end
					end
					if i == sweepDataSize then
						isDouble = false
					end
					for k,v in pairs(newListData) do
						j = j + 1
						local row, col = mathEasy.getRowCol(j, line)
						if j%line == 1 then
							itemSubList = self.innerList:clone():tag(row):show()
							item:get("list"):pushBackCustomItem(itemSubList)
						end
						local itemItem = self.item1:clone():tag(col):show()
						local showDouble = isDouble
						if showDouble and v.key ~= "gold" then
							local cfg = csv.items[v.key]
							-- 额外奖励固定不双倍
							if cfg and cfg.isLimitDrop then
								showDouble = false
							end
						end
						if v.type == "cards" then
							local unitID = csv.cards[v.value.id].unitID
							local star = csv.cards[v.value.id].star
							local rarity = csv.unit[unitID].rarity
							bind.extend(self, itemItem, {
								class = "card_icon",
								props = {
									unitId = unitID,
									rarity = rarity,
									star = star,
									onNodeClick = function(node)
										self:onitemClick(node, v.value.id)
									end
								},
							})
						elseif v.type == "fish" then
							bind.extend(self, itemItem, {
								class = "fish_icon",
								props = {
									data = {
										key = v.key,
										num = v.value,
									},
									onNodeClick = true,
								},
							})
						else
							local binds = {
								class = "icon_key",
								props = {
									data = {
										key = v.key,
										num = v.value,
									},
									isDouble = showDouble,
								},
							}
							bind.extend(self, itemItem, binds)
						end
						itemSubList:pushBackCustomItem(itemItem)

					end
				end

				if hasExtra == false and i == sweepDataSize then
					local successItem = self.successItem:clone():show()
					self:setEffect(successItem)
					self.list:pushBackCustomItem(successItem)
				end
				if i == sweepDataSize and curMopUpNum > sweepDataSize then
					gGameUI:showTip(gLanguageCsv.sweepAdaptiveTip)
				end
				self.list:scrollToBottom(0.3, true)
			end
		end, 1/60, 0, "GateSweepView")
	end

	bind.click(self, self.imgBG, {method = function()
		self.interval = 0
	end})

	Dialog.onCreate(self)
end

function GateSweepView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
	-- self.mysteryShopLastTime = gGameModel.mystery_shop:getIdler("last_active_time")
	-- self.mysteryTimes = gGameModel.daily_record:getIdler("mystery_active_times")
end

function GateSweepView:cloneItem(verticalNum,tag,itemDatas)
	local margin = 10
	local height = 200 * verticalNum + margin * (verticalNum - 1)
	local item = self.item:clone()
		:tag(tag)
		:size(1248, height)
		:xy(1000,1500)
		:show()
	local size = item:size()
	item:get("textTip"):visible(next(itemDatas) == nil)
	item:get("list"):size(1248, height):y(0)
	return item
end

function GateSweepView:cloneTextItem(textDatas, params)
	local width = params.width or self.list:width()
	width = math.min(width, self.list:width())
	local size = cc.size(width, 300)

	local defaultAlign = "center"
	local list, height = beauty.textScroll({
		size = size,
		fontSize = params.fontSize or 50,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = textDatas,
		verticalSpace = params.verticalSpace or 10,
		isRich = params.isRich,
		margin = 20,
		align = params.align or defaultAlign,
	})
	list:height(height+30)
	return list
end

-- dailyDatas,日常小助手相关数据
function GateSweepView:cloneTitleItem(index,exp,isExtra,isTotal,dailyDatas)
	local titleItem = self.itemTitle:clone():show()
	if isExtra == true then
		--世界额外奖励
		if self.gateId and dataEasy.getWorldLevelExpAdd(math.floor(self.gateId / 10000)) then
			titleItem:get("textTitle"):text(gLanguageCsv.sweepWorldLevelExtra):x(624)
		else
			titleItem:get("textTitle"):text(gLanguageCsv.addedBonus):x(624)
		end
	else
		local str = string.format(gLanguageCsv.battleTimes,index)
		if self.from == "allGate" then
			local gateId = self.sweepData[index].gateId
			local cfg = csv.scene_conf
			local map = csv.world_map
			--第N章节
			local numb1 = cfg[gateId].ownerId
			--第N关卡
			local numb2 = 0
			for key, val in ipairs(map[numb1].seq) do
				if gateId == val then
					numb2 = key
				end
			end
			if self.prenumb1 == numb1 and self.prenumb2 == numb2 then
				self.sweepTimes = self.sweepTimes + 1
			else
				self.sweepTimes = 1
			end
			self.prenumb1 = numb1
			self.prenumb2 = numb2
			str = string.format(gLanguageCsv.battleTimes, self.sweepTimes)
			titleItem:get("textGate"):text(string.format(gLanguageCsv.allBattleTimes, numb1-110, numb2))
			text.addEffect(titleItem:get("textGate"), {outline={color = cc.c4b(234, 67, 22, 255), size=4}})
			titleItem:get("textGate"):show()
		else
			titleItem:get("textGate"):hide()
		end
		if self.from == "endlessTower" and not isTotal then
			local info = csv.endless_tower_scene[self.startGateId + index - 1]
			str = info.sceneName
		end
		if isTotal then
			str = gLanguageCsv.totalGot
		end
		--世界额外经验加成
		if self.gateId and dataEasy.getWorldLevelExpAdd(math.floor(self.gateId / 10000)) then
			titleItem:get("textTitle"):text(str)
			local sceneCfg = csv.scene_conf[self.gateId]
			local addExp = sceneCfg.roleExp
			local worldExp = exp - addExp
			titleItem:get("textExpNum"):text("+"..addExp.."(+"..worldExp..")")
			-- adapt.oneLineCenterPos(cc.p(624, 30), {titleItem:get("textTitle"):text(str), titleItem:get("textExpNote"), titleItem:get("textExpNum")}, cc.p(40, 0))
		else
			titleItem:get("textTitle"):text(str)
			titleItem:get("textExpNum"):text("+"..exp)
			-- adapt.oneLineCenterPos(cc.p(624, 30), {titleItem:get("textTitle"):text(str), titleItem:get("textExpNote"), titleItem:get("textExpNum")}, cc.p(40, 0))
		end
		if self.from == "union" then
			titleItem:get("textExpNum"):text(exp)
			titleItem:get("textExpNote"):text(gLanguageCsv.percentageOfInjuries)
			adapt.oneLinePos(titleItem:get("textExpNote"), titleItem:get("textExpNum"), cc.p(20, 0), "left")
		end
		if self.from == "dailyAssistant" then
			local titleName = ""
			local expStr = ""
			local expNoteStr = string.format(gLanguageCsv.totalTodo, exp)
			if dailyDatas.hasTitle then
				titleName = dailyDatas.hasTitle
			else
				local feature = dailyDatas.feature
				local cfg = gDailyAssistantCsv[feature].cfg
				titleName = cfg.name

				if feature == "endlessTower" then
					-- 冒险之路
					expNoteStr = string.format(gLanguageCsv.totalReset, exp)
				elseif feature == "catch" then
					-- 钓鱼
					local win = dailyDatas.win or 0
					local fail = dailyDatas.fail or 0
					expNoteStr = string.format(gLanguageCsv.successAndFailTimes, win, fail)
				elseif feature == "unionFuben" then
					-- 公会副本
					expNoteStr = gLanguageCsv.percentageOfInjuries
					expStr = exp
				end
			end
			titleItem:get("textTitle"):text(titleName)
			titleItem:get("textExpNum"):text(expStr)
			titleItem:get("textExpNote"):text(expNoteStr)
			adapt.oneLinePos(titleItem:get("textTitle"), {titleItem:get("textExpNote"), titleItem:get("textExpNum")}, cc.p(20, 0), "left")
		end
	end
	titleItem:get("textExpNum"):visible(exp ~= 0)
	titleItem:get("textExpNote"):visible(exp ~= 0)
	return titleItem
end

function GateSweepView:onAgainClick()
	local checkCb = self.checkCb
	if checkCb and not checkCb() then
		return
	end
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

function GateSweepView:onSpeedClick()
	if self.canClose then
		self:onClose()
	else
		self.interval = 0
	end
end

-- 精灵详情
function GateSweepView:onitemClick(node, id)
	gGameUI:showItemDetail(node, {key = "card", num = id})
end

return GateSweepView
