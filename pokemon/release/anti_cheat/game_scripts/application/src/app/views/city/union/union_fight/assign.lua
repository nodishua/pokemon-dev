-- @date:   2020年2月28日15:56:35
-- @desc:   公会战界面布置界面

local UnionAssignView = class("UnionAssignView", Dialog)

local SELSCALE = 1.2
local OFF = 12
local ACTIONTIME = 0.2
local SCHEDULETIME = 5 * 60
local MAXDATALENGTH = 50
local LINELENGTH = 7
local DIFFY = 10
local MOVETYPE = {
	insert = 1,
	change = 2,
}

local JOB = {
	CHAIRMAN = 1,
	VICE_CHAIRMAN = 2,
	MEMBER = 3
}

local INSERTTYPE = {
	-- 拖动的item再插入位子前面
	before = 1,
	-- 拖动的item再插入位子后面
	ended = 2,
}

local SORTTYPE = {
	RANDOM = 1,
	UP = 2,
	DOWN = 3,
}

local SORT_TITLE = {
	gLanguageCsv.randomText,
	gLanguageCsv.fightPointUp,
	gLanguageCsv.fightPointDown,
}

--判断职位
local function JudgmentJob(id, jobList)
	if jobList["chairman"] == id then
		return JOB.CHAIRMAN
	end
	if jobList["viceChairmans"][id] then
		return JOB.VICE_CHAIRMAN
	end
	return JOB.MEMBER
end

local function getEndPosition(datas)
	for i=#datas, 1, -1 do
		if not datas[i].isNull then
			return i
		end
	end

	return 0
end

local function downHero(list, node, k, v)
	list.baseDatas()[k] = {isNull = true}
	local children = node:multiget("head", "info", "flag")
	itertools.invoke(children, "hide")
	node:get("imgBg"):texture("city/union/union_fight/part2/bg_bz2.png")
	local normalPanel = node:get("normal")
	normalPanel:get("textIdx"):text(k)
	text.addEffect(normalPanel:get("textIdx"), {outline = {color = cc.c4b(48, 31, 3, 255)}})
	normalPanel:show()
	adapt.oneLinePos(node:get("info.textFightNote"), node:get("info.textFightPoint"))
end

local function upHero(list, node, k, v)
	local children = node:multiget("head", "info")
	itertools.invoke(children, "show")

	local bgPath = "city/union/union_fight/part2/bg_bz1.png"
	if v.isSel then
		bgPath = "city/union/union_fight/part2/bg_xz.png"
	end
	node:get("imgBg"):texture(bgPath)

	children.info:get("textLv"):text(v.data.level)
	children.info:get("textName"):text(v.data.name)
	children.info:get("textFightPoint"):text(v.data.total_fp)
	adapt.oneLineCenterPos(cc.p(node:size().width / 2, 20), {children.info:get("textFightNote"), children.info:get("textFightPoint")})
	adapt.oneLineCenterPos(cc.p(node:size().width / 2, 105), {children.info:get("textLvNote"), children.info:get("textLv")})
	text.addEffect(node:get("flag.textMe"), {outline = {color = cc.c4b(59, 51, 59, 255)}})
	text.addEffect(children.info:get("textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
	text.addEffect(children.info:get("textLvNote"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
	text.addEffect(children.info:get("textFightPoint"), {outline = {color = cc.c4b(248, 241, 204, 255)}})
	node:get("flag"):visible(v.roleId == list.roleId())
	node:get("normal.textIdx"):text(k)
	text.addEffect(node:get("normal.textIdx"), {outline = {color = cc.c4b(48, 31, 3, 255)}})
	node:get("normal"):hide()
	children.head:scale(1)
	bind.extend(list, children.head, {
		class = "role_logo",
		props = {
			logoId = v.data.logo,
			frameId = v.data.frame,
			level = false,
			vip = false,
			onNode = function(panel)
				panel:y(130)
			end,
		},
	})
	-- node:get("head"):onTouch(functools.partial(list.moveCell, node, k, v))
	node:onTouch(functools.partial(list.moveCell, node, k, v))
	-- bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k)}})
	adapt.oneLinePos(node:get("info.textFightNote"), node:get("info.textFightPoint"))
end

local function onInitTeam(list, node, k, v)
	node:get("textFightPoint"):text(v.troops_fp)
	node:get("flag.textIdx"):text(k)
	text.addEffect(node:get("flag.textIdx"), {outline = {color = cc.c4b(59, 51, 59, 255), size = 4}})
	text.addEffect(node:get("flag.textNote"), {outline = {color = cc.c4b(59, 51, 59, 255), size = 4}})

	text.addEffect(node:get("textFightPoint"), {outline = {color = ui.COLORS.NORMAL.WHITE, size = 4}})
	text.addEffect(node:get("textFightNote"), {outline = {color =ui.COLORS.NORMAL.WHITE, size = 4}})
	local isFail = true
	local datas = {{}, {}}
	for i = 1, 3 do
		for j = 1, 2 do
			local cardInfo = v.cards[(j-1)*3 + i]
			if cardInfo then
				table.insert(datas[j], cardInfo)
				if isFail and cardInfo[3] ~= 0 then
					isFail = false
				end
			else
				table.insert(datas[j], {})
			end
		end
	end
	local function setCards(nodeList, data)
		bind.extend(list, nodeList, {
			class = "listview",
			props = {
				data = data,
				item = list.roleItem(),
				onItem = function(innerList, cell, kk ,vv)
					if itertools.isempty(vv) then
						nodetools.invoke(cell, {"head", "bar", "imgDie", "imgBarBg"}, "hide")
						nodetools.invoke(cell, {"emptyPanel"}, "show")
					else
						nodetools.invoke(cell, {"head", "bar", "imgBarBg"}, "show")
						nodetools.invoke(cell, {"imgDie", "emptyPanel"}, "hide")
						local cardInfo = csv.cards[vv[1]]
						local isDie = vv[3] <= 0
						local rarity = csv.unit[cardInfo.unitID].rarity
						local unitId = dataEasy.getUnitId(vv[1], vv[2])
						bind.extend(innerList, cell, {
							class = "card_icon",
							props = {
								unitId = unitId,
								rarity = rarity,
								grayState = isDie and 1 or 0,
								levelProps = {
									data = vv[4],
								},
								star = vv[5],
								advance = vv[6],
								onNode = function(panel)
									panel:scale(0.7)
									panel:xy(0, 15)
								end,
							}
						})
						cell:visible(true)
						cell:get("imgDie"):visible(isDie)
						bind.extend(innerList, cell:get("bar"), {
							event = "extend",
							class = "loadingbar",
							props = {
								data = math.max(0, vv[3]),
								maskImg = "city/union/union_fight/part2/jdt_2.png"
							},
						})
					end
				end,
			},
		})
		nodeList:setRenderHint(0)
	end
	setCards(node:get("list1"), datas[1])
	setCards(node:get("list2"), datas[2])

	node:get("fail"):visible(isFail)
	adapt.setAutoText(node:get("textNote1"), nil, 70)
	adapt.setAutoText(node:get("textNote2"), nil, 70)
end

UnionAssignView.RESOURCE_FILENAME = "union_fight_assign.json"
UnionAssignView.RESOURCE_BINDING = {
	["topView"] = "topView",
	["btnSort"] = {
		varname = "btnSort",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isMember"),
				method = function(val)
					return not val
				end,
			},
			{
				event = "extend",
				class = "sort_menus",
				props = {
					data = bindHelper.self("sortTabData"),
					defaultTitle = bindHelper.self("btnTitle"),
					expandUp = true,
					btnClick = bindHelper.self("onSortMenusBtnClick", true),
					-- showSelected = bindHelper.self("sortType"),
					showSortList = bindHelper.self("btnState"),
					btnType = 4,
					btnWidth = 380,
					locked = bindHelper.self("locked"),
					showLock = false,
					onNode = function(node)
						node:xy(-1125, -480):z(20)
					end,
				},
			},
		}
	},
	["timeInfo.textTimeNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}}
		},
	},
	["timeInfo.textTip"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isMember"),
			method = function(val)
				return not val
			end,
		},
	},
	["timeInfo.textTime"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("time"),
				method = function(val)
					local t = time.getCutDown(val)

					return t.str
				end,
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.WHITE}}
			}
		},
	},
	["item1"] = "item1",
	["item2"] = "item2",
	["item"] = "item",
	["innerList"] = "innerList",
	["leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 7,
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					node:name("item" .. t.k)
					if v.isNull then
						downHero(list, node, t.k, v)
					else
						upHero(list, node, t.k, v)
					end
				end,
				asyncPreload = 28,
			},
			handlers = {
				moveCell = bindHelper.self("initHeroSprite"),
				baseDatas = bindHelper.self("baseDatas"),
				roleId = bindHelper.self("roleId"),
				clickCell = bindHelper.self("onClickCell"),
			},
		},
	},
	["rightList"] = {
		varname = "rightList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("teamDatas"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					onInitTeam(list, node, k, v)
				end,
			},
			handlers = {
				roleItem = bindHelper.self("item2"),
			},
		},
	},
	["btnBack"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["btnSave"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onSave")},
			},
			{
				event = "visible",
				idler = bindHelper.self("isMember"),
				method = function(val)
					return not val
				end,
			},
		},
	},
}

function UnionAssignView:onCreate(params)
	self.locked = idler.new(1)
	self.btnState = idler.new(false)
	self.btnTitle = idler.new(gLanguageCsv.unionFightSortTitle)
	self.isMember = idler.new(true)
	self.sortType = idler.new()
	self.sortTabData = idlertable.new(SORT_TITLE)
	self:initModel()
	self.curSelIdx = idler.new()
	self.time = idler.new(0)
	self.itemActionCache = {}
	self.itemBoxCache = {}
	self.teamDatas = idlers.newWithMap({})
	-- 用于比较队伍是否发生变化
	self.baseDatas = {}
	self.showDatas = idlers.newWithMap({})
	local roles = params.roles
	local rolesInfo = params.rolesInfo
	idlereasy.when(self.sortType, function(_, sortType)
		local count = 0
		local tab = {}
		for i,roleId in ipairs(roles) do
			local result = self:isAllCardDie(rolesInfo[roleId].troops)
			if not result then
				table.insert(tab, {isNull = false, data = rolesInfo[roleId], roleId = roleId, isSel = false})
				count = count + 1
			end
		end
		local lineNum = math.ceil(count / LINELENGTH) + 1
		lineNum = math.max(4, lineNum)
		for i=1,lineNum * LINELENGTH - count do
			table.insert(tab, {isNull = true, isSel = false})
		end
		if not self.modelDatas then
			-- 模板数据用来对比是否有改动队伍
			self.modelDatas = clone(tab)
		end
		if sortType then
			if sortType == 1 then
				local len = #params.roles
				for i=1,math.floor(len / 2) do
					local r1 = math.random(1, len)
					local r2 = math.random(1, len)
					tab[r1], tab[r2] = tab[r2], tab[r1]
				end
			else
				table.sort(tab, function(a, b)
					if sortType == 3 then
						if a.data and b.data then
							return a.data.total_fp > b.data.total_fp
						elseif a.data or b.data then
							return a.data ~= nil
						end

						return false
					elseif sortType == 2 then
						if a.data and b.data then
							return a.data.total_fp < b.data.total_fp
						elseif a.data or b.data then
							return a.data ~= nil
						end

						return false
					end
				end)
			end
		end

		if not self.selectId then
			self.selectId = tab[1].roleId
		end

		local curSelIdx
		for i,v in ipairs(tab) do
			if self.selectId and v.roleId == self.selectId then
				curSelIdx = i
				break
			end
		end
		tab[curSelIdx].isSel = true

		self.baseDatas = tab
		self.showDatas:update(tab)
		self.curSelIdx:set(curSelIdx)
		self.teamDatas:update(tab[curSelIdx].data.troops)
	end)

	self.curSelIdx:addListener(function(val, old)
		if self.showDatas:atproxy(val) and not self.showDatas:atproxy(val).isNull then
			if old and self.showDatas:atproxy(old) then
				self.showDatas:atproxy(old).isSel = false
			end
			if val and self.showDatas:atproxy(val) then
				self.showDatas:atproxy(val).isSel = true
				self.teamDatas:update(self.baseDatas[val].data.troops)
				self.selectId = self.baseDatas[val].roleId
			end
		end
	end)

	local curTime = time.getTime()
	local delta = self.nextBattleTime - curTime
	self.time:set(delta)
	self:enableSchedule():schedule(function()
		delta = delta - 1
		if delta < 0 then
			Dialog.onClose(self)
			return false
		end
		self.time:set(delta)
	end, 1, nil)

	Dialog.onCreate(self, {clickClose = false})
end

function UnionAssignView:isAllCardDie(datas)
	for _,data in ipairs(datas) do
		for _,card in pairs(data.cards) do
			if card[3] > 0 then
				return false
			end
		end
	end

	return true
end

function UnionAssignView:initModel()
	self.nextBattleTime = gGameModel.union_fight:read("next_round_battle_time")
	self.roleId = gGameModel.role:read("id")
	local unionInfo = gGameModel.union
	--会长ID 长度12
	self.chairmanId = unionInfo:getIdler("chairman_db_id")
	--副会长ID 长度12
	self.viceChairmans = unionInfo:getIdler("vice_chairmans")
	idlereasy.any({self.chairmanId, self.viceChairmans}, function(_, chairmanId, viceChairmans)
		local jobList = {}
		jobList["chairman"] = chairmanId
		local tmpViceChairmans = {}
		for k,v in ipairs(viceChairmans) do
			tmpViceChairmans[v] = true
		end
		jobList["viceChairmans"] = tmpViceChairmans
		local isMember = JudgmentJob(self.roleId, jobList) == JOB.MEMBER
		self.isMember:set(isMember)
	end)

end

function UnionAssignView:getPercent()
	local container = self.leftList:getInnerContainer()
	local innerSize = container:size()
	local listSize = self.leftList:size()
	local x, y = container:xy()
	return 100 - math.abs(y) / (innerSize.height - listSize.height) * 100
end

function UnionAssignView:onClickCell(list, k)
	if k == self.curSelIdx:read() or self.baseDatas[k].isNull then
		return
	end
	self.curSelIdx:set(k)
end

function UnionAssignView:deleteMovingItem()
	if self.movePanel then
		self.movePanel:removeSelf()
		self.movePanel = nil
		return true
	end
end

-- 给界面上的精灵添加拖拽功能
function UnionAssignView:initHeroSprite(list, node, k, v, event)
	if event.name == "began" then
		self.topView:setTouchEnabled(true)
		self.touchBeganPos = event
		self.hasMovingItem = nil
		self.movingTime = 0
		self.isClick = false
		self:deleteMovingItem()
		list:enableSchedule()
		if not self.isMember:read() then
			list:schedule(function(delay)
				self.movingTime = self.movingTime + delay
				if self.movingTime >= 0.3 then
					self.isClick = true
					if self.leftList:getItemNodes(self.curSelIdx:read()) then
						self.leftList:getItemNodes(self.curSelIdx:read()):get("imgBg")
							:texture("city/union/union_fight/part2/bg_bz1.png")
					end
					-- 直接修改下背景 假装选中但是实际选中的数值没有改变
					local item = self.leftList:getItemNodes(k)
					item:get("imgBg"):texture("city/union/union_fight/part2/bg_xz.png")
					item:get("head"):scale(SELSCALE)
					return false
				end
			end, 0.1, nil, "itemSchedule" .. k)
		end

	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if self.hasMovingItem == nil and (self.isClick or deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			self.hasMovingItem = false
			list:unSchedule("itemSchedule" .. k)
			-- 会长，副会长才能操作
			if not self.isMember:read() and (self.isClick or deltaY < deltaX * 0.7 or (self:getPercent() < 0.1 and event.y < self.touchBeganPos.y) or (self:getPercent() > 99.9 and event.y > self.touchBeganPos.y)) then
				if self.leftList:getItemNodes(self.curSelIdx:read()) then
					self.leftList:getItemNodes(self.curSelIdx:read()):get("imgBg")
						:texture("city/union/union_fight/part2/bg_bz1.png")
				end
				-- 直接修改下背景 假装选中但是实际选中的数值没有改变
				local item = self.leftList:getItemNodes(k)
				item:get("imgBg"):texture("city/union/union_fight/part2/bg_xz.png")
				item:get("head"):scale(SELSCALE)

				self.hasMovingItem = true
				self.movePanel = event.target:get("head"):clone()
					:addTo(self.topView, 1000, "cloneRoleItem" .. k)
					:scale(SELSCALE)
				bind.extend(self, self.movePanel, {
					class = "role_logo",
					props = {
						logoId = self.baseDatas[k].data.logo,
						frameId = self.baseDatas[k].data.frame,
						level = false,
						vip = false,
					},
				})
				local item = self.leftList:getItemNodes(k)
				item:get("head"):hide()
				item:get("info"):hide()
				item:get("flag"):hide()
				item:get("normal"):show()
				item:get("normal.textIdx"):text(k)
			end
		end
		self.leftList:setTouchEnabled(not self.hasMovingItem)
		if self.movePanel then
			local pos = self.topView:convertToNodeSpace(event)
			self.movePanel:xy(pos)
			local pos1, pos2, _type = self:whichEmbattleTargetPos(event.target:get("head"), pos, k)
			self:playHeadAction(pos1, pos2, _type)
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		self.topView:setTouchEnabled(false)
		list:unSchedule("itemSchedule" .. k)

		-- 点击
		if self.hasMovingItem == nil then
			self.curSelIdx:set(k)
		end
		self.hasMovingItem = nil
		self.leftList:getItemNodes(k):get("head"):scale(1)

		-- 移动
		if self:deleteMovingItem() then
			self.leftList:getItemNodes(k):get("normal"):hide()
			self.leftList:getItemNodes(k):get("imgBg"):texture("city/union/union_fight/part2/bg_bz1.png")
			local endPos = self.topView:convertToNodeSpace(event)
			local pos1, pos2, _type = self:whichEmbattleTargetPos(event.target:get("head"), endPos, k)
			if pos1 then
				-- pos1 == pos2 交换
				if (pos1 == pos2 or (pos1 == k or pos2  == k)) then
					if pos1 ~= pos2 then
						pos1 = k
					end
					self:playChangeAction(pos1, k)
				else
					self:playInsertAction(pos1, pos2, k)
				end
			else
				-- 选中的自己移动后会到自己位子上就强制刷新一次 显示一下UI之前有hide操作
				local flag = self.curSelIdx:read() == k
				self.curSelIdx:set(k, flag)
			end
			self:playHeadAction()
		end
	end
end

function UnionAssignView:createNode(item, data)
	local cloneItem = self.item:get("head"):clone():addTo(self.topView, 1000)
	local pos = gGameUI:getConvertPos(item:get("head"), self.topView)
	cloneItem:xy(pos.x, pos.y + DIFFY)

	bind.extend(self, cloneItem, {
		class = "role_logo",
		props = {
			logoId = data.logo,
			frameId = data.frame,
			level = false,
			vip = false,
		},
	})
	cloneItem:show()

	return cloneItem
end

-- curPos : 当前需要被交换的位子
-- tarPos : 需要移动过去的目标位置（拖动的item的原先位置）
function UnionAssignView:playChangeAction(curPos, tarPos)
	if curPos == tarPos then
		local item = self.leftList:getItemNodes(tarPos)
		item:get("head"):show()
		item:get("info"):show()
		item:get("flag"):visible(self.baseDatas[curPos].roleId == self.roleId)
		item:get("normal"):hide()
		self.curSelIdx:set(curPos)
		return
	end

	local curItem = self.leftList:getItemNodes(curPos)
	local tarItem = self.leftList:getItemNodes(tarPos)
	if not curItem or not tarItem then
		return
	end
	-- 当前位子需要显示的item
	local curPosClone = self.item:clone():addTo(self.topView, 1000, "curPosClone")
	local pos = gGameUI:getConvertPos(curItem, self.topView)
	curPosClone:xy(pos.x, pos.y)
	local data1 = self.baseDatas[tarPos]
	bind.extend(self, curPosClone:get("head"), {
		class = "role_logo",
		props = {
			logoId = data1.data.logo,
			frameId = data1.data.frame,
			level = false,
			vip = false,
		},
	})
	curPosClone:get("head"):y(curPosClone:get("head"):y() + DIFFY)
	curPosClone:get("info.textName"):text(data1.data.name)
	curPosClone:get("info.textFightPoint"):text(data1.data.total_fp)
	curPosClone:get("normal"):hide()
	curPosClone:get("flag"):visible(data1.roleId == self.roleId)

	adapt.oneLineCenterPos(cc.p(curPosClone:size().width / 2, 20), {curPosClone:get("info.textFightNote"), curPosClone:get("info.textFightPoint")})
	adapt.oneLineCenterPos(cc.p(curPosClone:size().width / 2, 105), {curPosClone:get("info.textLvNote"), curPosClone:get("info.textLv")})
	text.addEffect(curPosClone:get("flag.textMe"), {outline = {color = cc.c4b(59, 51, 59, 255)}})
	text.addEffect(curPosClone:get("info.textLv"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
	text.addEffect(curPosClone:get("info.textLvNote"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})

	curPosClone:show()

	-- 移动的头像
	local data2 = self.baseDatas[curPos]
	local tarPosClone = self.item:get("head"):clone():addTo(self.topView, 1001, "tarPosClone")
	local pos = gGameUI:getConvertPos(curItem:get("head"), self.topView)
	tarPosClone:xy(pos.x, pos.y + DIFFY)

	bind.extend(self, tarPosClone, {
		class = "role_logo",
		props = {
			logoId = data2.data.logo,
			frameId = data2.data.frame,
			level = false,
			vip = false,
		},
	})
	tarPosClone:show()

	self.topView:setTouchEnabled(true)
	local tpos = gGameUI:getConvertPos(tarItem:get("head"), self.topView)
	transition.executeSequence(tarPosClone)
		:moveTo(ACTIONTIME, tpos.x, tpos.y + DIFFY)
		:func(function()
			performWithDelay(self, function()
				curPosClone:removeFromParent()
				curPosClone = nil
				tarPosClone:removeFromParent()
				tarPosClone = nil
				dataEasy.tryCallFunc(self.leftList, "updatePreloadCenterIndex")
				local idx, flag = curPos, false
				if idx == self.curSelIdx:read() then
					self.baseDatas[curPos].isSel = false
					flag = true
				end
				self.baseDatas[curPos], self.baseDatas[tarPos] = self.baseDatas[tarPos], self.baseDatas[curPos]
				self.showDatas:update(self.baseDatas)
				self.curSelIdx:set(idx, flag)
				self.topView:setTouchEnabled(false)
			end, 1/60)
		end)
		:done()
end

function UnionAssignView:playInsertAction(insertPos1, insertPos2, removeIdx)
	local beforeData = self.baseDatas[removeIdx]
	local actionNodes = {}
	local _insertType, curPosIdx
	-- 移动的item 再 插入位子前方 所有数据往前移动
	if insertPos1 > removeIdx then
		_insertType = INSERTTYPE.before
		curPosIdx = insertPos1
		for i=removeIdx + 1, insertPos1 do
			local item = self.leftList:getItemNodes(i)
			if item then
				itertools.invoke(item:multiget("head", "info", "flag", "normal"), "hide")
				local node = self:createNode(item, self.baseDatas[i].data)
				table.insert(actionNodes, {item = node, idx = i, isAction = i % LINELENGTH ~= 1})
			end
		end

	elseif removeIdx > insertPos2 then
		_insertType = INSERTTYPE.ended
		curPosIdx = insertPos2
		for i=removeIdx - 1, insertPos2, -1 do
			local item = self.leftList:getItemNodes(i)
			if item then
				itertools.invoke(item:multiget("head", "info", "flag", "normal"), "hide")
				local node = self:createNode(item, self.baseDatas[i].data)
				table.insert(actionNodes, {item = node, idx = i, isAction = i % LINELENGTH ~= 0})
			end
		end
	end

	if not _insertType then
		return
	end
	local curPosNode = self.leftList:getItemNodes(curPosIdx)
	local curPosClone = self:createNode(curPosNode, self.baseDatas[removeIdx].data)
	curPosClone:hide()

	self.topView:setTouchEnabled(true)
	transition.executeSequence(curPosClone)
		:delay(ACTIONTIME / 4)
		:func(function()
			curPosClone:show()
		end)
		:delay(ACTIONTIME / 4 * 3)
		:delay(0.05)
		:func(function()
			performWithDelay(self, function()
				curPosClone:removeFromParent()
			end, 1/60)
		end)
		:done()

	for _,v in ipairs(actionNodes) do
		local nextNodeIdx = _insertType == INSERTTYPE.before and v.idx - 1 or v.idx + 1
		local nextNode = self.leftList:getItemNodes(nextNodeIdx)
		if nextNode then
			local tpos = gGameUI:getConvertPos(nextNode:get("head"), self.topView)
			if v.isAction then
				transition.executeSequence(v.item)
					:moveTo(ACTIONTIME, tpos.x, tpos.y + DIFFY)
					:delay(0.05)
					:func(function()
						performWithDelay(self, function()
							v.item:removeFromParent()
						end, 1/60)
					end)
					:done()
			else
				transition.executeSequence(v.item)
					:delay(ACTIONTIME / 2)
					:func(function()
						v.item:xy(tpos.x, tpos.y + DIFFY)
					end)
					:delay(ACTIONTIME / 2)
					:delay(0.05)
					:func(function()
						performWithDelay(self, function()
							v.item:removeFromParent()
						end, 1/60)
					end)
					:done()
			end
		end
	end
	transition.executeSequence(self)
		:delay(ACTIONTIME + 0.05)
		:func(function()
			local curSelIdx, falg = insertPos1, false
			if _insertType == INSERTTYPE.before then
				-- 例如之前选中13号位 拖动9号到13/14之间就会有问题
				-- 做一下特殊处理
				if self.curSelIdx:read() == insertPos1 then
					falg = true
				end
				self.baseDatas[self.curSelIdx:read()].isSel = false
				for j=removeIdx + 1, insertPos1 do
					self.baseDatas[j - 1] = self.baseDatas[j]
				end
				self.baseDatas[insertPos1] = beforeData

			else
				curSelIdx = insertPos2
				-- 例如之前选中12号位 拖动15号到11/12之间就会有问题
				-- 做一下特殊处理
				if self.curSelIdx:read() == insertPos2 then
					falg = true
				end
				self.baseDatas[self.curSelIdx:read()].isSel = false
				for j=removeIdx - 1, insertPos2, -1 do
					self.baseDatas[j + 1]  = self.baseDatas[j]
				end
				self.baseDatas[insertPos2] = beforeData
			end
			dataEasy.tryCallFunc(self.leftList, "updatePreloadCenterIndex")
			self.showDatas:update(self.baseDatas)
			self.curSelIdx:set(curSelIdx, falg)
			self.topView:setTouchEnabled(false)
		end)
		:done()
end

function UnionAssignView:playHeadAction(pos1, pos2, _type)
	if not pos1 then
		for idx,_ in pairs(self.itemActionCache) do
			local item = self.leftList:getItemNodes(idx)
			if item then
				item:get("imgFlag"):hide()
			end
		end
		self.itemActionCache = {}
		return
	end
	-- 0 是个特例  插入最前面一个的时候就会有参数 0， 1
	if pos1 ~= 0 then
		local item1 = self.leftList:getItemNodes(pos1)
		local endPos = getEndPosition(self.baseDatas)
		item1:get("imgFlag"):visible(not (pos1 == endPos and _type == MOVETYPE.insert))
		self.itemActionCache[pos1] = 1
	end
	local item2 = self.leftList:getItemNodes(pos2)
	item2:get("imgFlag"):show()
	self.itemActionCache[pos2] = 1
	local t = {}
	for idx,_ in pairs(self.itemActionCache) do
		if idx ~= pos1 and idx ~= pos2 then
			local item = self.leftList:getItemNodes(idx)
			if item then
				-- item:get("head"):scale(1)
				item:get("imgFlag"):hide()
				table.insert(t, idx)
			end
		end
	end
	for i,v in ipairs(t) do
		self.itemActionCache[v] = nil
	end
end

-- 返回插入位子
function UnionAssignView:whichEmbattleTargetPos(target, p, moveIdx)
	local size = target:box()
	-- local width = size.width / SELSCALE
	-- local height = size.height / SELSCALE
	local width, height = 190, 190
	local leftUp = cc.p(p.x - width / 2 + OFF, p.y + height / 2 - OFF)
	local leftDown = cc.p(p.x - width / 2 + OFF, p.y - height / 2 + OFF)
	local rightUp = cc.p(p.x + width / 2 - OFF, p.y + height / 2 - OFF)
	local rightDown = cc.p(p.x + width / 2 - OFF, p.y - height / 2 + OFF)
	local points = {leftUp, rightUp, leftDown, rightDown}

	local len = #self.baseDatas
	-- targetIdx: 目标位子, pointIdx：点的位子
	local pointsInfo = {}
	local count = 0

	local container = self.leftList:getInnerContainer()
	local ch = container:size().height
	local lh = self.leftList:size().height

	local y = container:y()
	local off = ch - lh - math.abs(y)

	for k, point in ipairs(points) do
		for i=1,len do
			local box = self.itemBoxCache[i]
			local item = self.leftList:getItemNodes(i)
			if item then
				if not box then
					local headNode = item
					box = headNode:box()
					local pos = gGameUI:getConvertPos(headNode, self.topView)
					box.x = pos.x - box.width / 2
					-- 校正位子 抱着每个item的box都是 list初始时候的位子
					-- off是偏移量
					box.y = pos.y + DIFFY - box.height / 2 - off
					self.itemBoxCache[i] = box
				end
				local y = self.leftList:getInnerContainer():y()
				local tBox = {}
				tBox.y = box.y + ch - lh - math.abs(y)
				tBox.x = box.x
				tBox.width = box.width
				tBox.height = box.height
				if cc.rectContainsPoint(tBox, point) then
					table.insert(pointsInfo, {targetIdx = i, pointIdx = k})
					count = count + 1
				end
			end
		end
	end

	if count <= 1 then
		return
	end
	return self:getTargetMoveType(count, pointsInfo, p, moveIdx)
end

function UnionAssignView:getTargetMoveType(count, pointsInfo, p, moveIdx)
	local endPos = getEndPosition(self.baseDatas)
	if count == 2 then
		local info1, info2 = pointsInfo[1], pointsInfo[2]
		if info1.targetIdx == info2.targetIdx then
			if self.baseDatas[info1.targetIdx].isNull then
				return endPos, endPos + 1, MOVETYPE.insert
			end

			if info1.targetIdx % LINELENGTH == 1 and info1.pointIdx == 2 and info2.pointIdx == 4 then
				return info1.targetIdx - 1, info1.targetIdx, MOVETYPE.insert
			end
			return info1.targetIdx, info1.targetIdx, MOVETYPE.change

		-- 相邻两个点在相邻两个item上
		elseif info2.pointIdx - info1.pointIdx == 1 then
			if info1.targetIdx > endPos then
				return endPos, endPos + 1, MOVETYPE.insert
			end
			return info1.targetIdx, info2.targetIdx, MOVETYPE.insert
		end
	end

	if count == 4 then
		local info1, info2, info3, info4 = pointsInfo[1], pointsInfo[2], pointsInfo[3], pointsInfo[4]
		if info1.targetIdx == info2.targetIdx and info3.targetIdx == info4.targetIdx and info2.targetIdx == info3.targetIdx then
			-- 移动到最后面
			if info1.targetIdx ~= moveIdx and self.baseDatas[info1.targetIdx].isNull then
				return endPos, endPos + 1, MOVETYPE.insert
			else
				-- 交换位子
				return info1.targetIdx, info2.targetIdx, MOVETYPE.change
			end

		-- 相邻两个点在相邻两个item上
		elseif info1.targetIdx == info3.targetIdx and info2.targetIdx == info4.targetIdx and info2.targetIdx ~= info3.targetIdx then
			if info1.targetIdx > endPos then
				return endPos, endPos + 1, MOVETYPE.insert
			end
			return info1.targetIdx, info2.targetIdx, MOVETYPE.insert

		-- 位于上下相邻之间和位子四个相邻的之间
		else
			local p1, p2 = info1.targetIdx, info2.targetIdx
			local d1, d2 = 0, 0
			for i = 1, 2 do
				local val = self:getDistance(p, pointsInfo[i].targetIdx)
				d1 = d1 + val

				val = self:getDistance(p, pointsInfo[i + 2].targetIdx)
				d2 = d2 + val
			end
			if d2 < d1 then
				p1, p2 = info3.targetIdx, info4.targetIdx
			end
			if self.baseDatas[info3.targetIdx].isNull then
				return endPos, endPos + 1, MOVETYPE.insert
			end
			local _type = info1.targetIdx == info2.targetIdx and MOVETYPE.change or MOVETYPE.insert
			return p1, p2, _type
		end
	end
end

function UnionAssignView:getDistance(p, targetIdx)
	local item = self.leftList:getItemNodes(targetIdx)
	local pos = gGameUI:getConvertPos(item, self.topView)

	return math.sqrt(math.abs(pos.x - p.x)^2 + math.abs(pos.y + DIFFY - p.y)^2)
end

function UnionAssignView:onSortMenusBtnClick(node, layout, idx, val)
	local params = {
		cb = function()
			self.sortType:set(idx, true)
			self.btnState:set(false)
		end,
		cancelCb = function()
			self.btnState:set(false)
		end,
		btnType = 2,
		content = string.format(gLanguageCsv.sortTipText, self.sortTabData:read()[idx]),
		-- clearFast = true,
	}
	gGameUI:showDialog(params)
end

function UnionAssignView:isChange()
	local result = false
	for i,v in ipairs(self.modelDatas) do
		if self.baseDatas[i].roleId ~= v.roleId then
			result = true
			break
		end
	end
	return result
end

function UnionAssignView:onSave(isClose)
	if not self:isChange() then
		return
	end
	local roles = {}
	for i,v in ipairs(self.baseDatas) do
		if not v.data then
			break
		end
		table.insert(roles, v.roleId)
	end
	gGameApp:requestServer("/game/union/fight/top8/deploy", function (tb)
		self.modelDatas = clone(self.baseDatas)
		if isClose == true then
			Dialog.onClose(self)
			return
		end
		gGameUI:showTip(gLanguageCsv.positionSave)
	end, roles)
end

function UnionAssignView:onClose()
	if not self:isChange() then
		Dialog.onClose(self)
		return
	end

	gGameUI:showDialog({
		cb = function()
			self:onSave(true)
		end,
		cancelCb = function()
			Dialog.onClose(self)
		end,
		btnType = 2,
		content = gLanguageCsv.isSaveCurBattle,
		clearFast = true,
	})
end

return UnionAssignView