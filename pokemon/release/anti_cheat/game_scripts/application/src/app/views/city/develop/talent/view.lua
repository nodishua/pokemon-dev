-- @Date:   2019-01-28
-- @Desc: 天赋界面
local ViewBase = cc.load("mvc").ViewBase
local TalentView = class("TalentView", ViewBase)
local redHintHelper = require "app.easy.bind.helper.red_hint"

local SHOW_TYPE = {
	"HAVE_ROOT",
	"HAVE_ROOT",
	"NOT_ROOT",
	"NOT_ROOT",
}

local TITLE_BG = {
	{bg = "city/develop/talent/logo_red.png", glow = cc.c4b(222,57,70,123)},
	{bg = "city/develop/talent/logo_purple.png", glow = cc.c4b(130,61,226,123)},
	{bg = "city/develop/talent/logo_green.png", glow = cc.c4b(25,171,164,123)},
}

local COLUMN_NUM = 3
local function commonItemShow(list, childs, v, isRoot)
	itertools.invoke({childs.btn:get("lock"), childs.btn:get("mask")}, "visible", v.isLock)
	local level = v.level or 0
	local cfg = csv.talent[v.id]
	childs.level:text(level.."/"..cfg.levelUp)
	childs.btn:get("icon"):texture(cfg.icon)
	if not isRoot then
		cache.setShader(childs.center, false, v.isLock == true and "hsl_gray" or "normal")
		childs.btn:setTouchEnabled(true)
		bind.touch(list, childs.btn, {methods = {ended = functools.partial(list.itemClick, v)}})
	end
end

TalentView.RESOURCE_FILENAME = "talent.json"
TalentView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.selected then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):setTextColor(ui.COLORS.NORMAL.WHITE)
					else
						selected:hide()
						panel = normal:show()
						panel:get("subTxt"):text(v.show.subName)
						panel:get("subTxt"):setTextColor(ui.COLORS.NORMAL.GRAY)
						-- cache.setShader(panel:get("subTxt"), false, v.isLock == true and "hsl_gray" or "normal")
						panel:get("txt"):setTextColor(ui.COLORS.NORMAL.RED)
					end
					panel:get("lock"):visible(v.isLock == true)
					panel:get("txt"):text(v.show.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rightPanel.name"] = "nodeName",
	["rightPanel.begin"] = "begin",
	["rightPanel.slider"] = "slider",
	["rightPanel.subList1"] = "subList1",
	["item1"] = "item1",
	["rightPanel.list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showdata1"),
				columnSize = COLUMN_NUM,
				item = bindHelper.self("subList1"),
				cell = bindHelper.self("item1"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("center", "level", "btn")
					childs.center:visible(list:getIdx(k).col ~= 1)
					commonItemShow(list, childs, v)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel.subList2"] = "subList2",
	["item2"] = "item2",
	["rightPanel.list2"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showdata2"),
				columnSize = COLUMN_NUM,
				xMargin = -240,
				item = bindHelper.self("subList2"),
				cell = bindHelper.self("item2"),
				sliderBg = bindHelper.self("slider"),
				asyncPreload = 12,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget("center", "level", "btn", "title1", "title2")
					childs.center:visible(list:getIdx(k).col ~= 1)
					if v.tab == 3 then
						childs.title1:hide()
						childs.title2:visible(list:getIdx(k).col == 1)
						childs.title2:get("titleBg"):texture(ui.SKILL_ICON[list:getIdx(k).row])
						childs.title2:get("title"):texture(ui.SKILL_TEXT_ICON[list:getIdx(k).row])
					elseif v.tab == 4 then
						childs.title1:visible(list:getIdx(k).col == 1)
						childs.title2:hide()
						local t = TITLE_BG[list:getIdx(k).row % 3 == 0 and 3 or list:getIdx(k).row % 3]
						childs.title1:get("titleBg"):texture(t.bg)
						childs.title1:get("title"):text(csv.talent[v.id].name)
						text.addEffect(childs.title1:get("title"), {glow = {color = t.glow}})
					end
					commonItemShow(list, childs, v)
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						list.sliderShow = true
						list.sliderBg:hide()
					end
					list:setScrollBarEnabled(false)
				end,
				onAfterBuild = function(list)
					if list.sliderShow then
						list.sliderBg:show()
						list.sliderShow = false
					end
					local listX, listY = list:xy()
					local listSize = list:size()
					local x, y = list.sliderBg:xy()
					local size = list.sliderBg:size()
					list:setScrollBarEnabled(true)
					list:setScrollBarColor(cc.c3b(241, 59, 84))
					list:setScrollBarOpacity(255)
					list:setScrollBarAutoHideEnabled(false)
					list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
					list:setScrollBarWidth(size.width)
					list:refreshView()
				end,
				backupCached = false,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightPanel.num"] = "talentPointNum",
	["rightPanel.cost"] = "cost1",
	["rightPanel.btnReset.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color=ui.COLORS.GLOW.WHITE}},
		}
	},
	["rightPanel.btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onReset(true)
			end)}
		},
	},
	["rightPanel.btnOneReset"] = {
		varname = "btnOneReset",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onReset()
			end)}
		},
	},
	["rightPanel.btnQuestion"] = {
		varname = "btnQuestion",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	}
}

function TalentView:onCreate()
	self:initModel()
	self:initCsvTable()
	idlereasy.when(self.talentPoint, function (_, point)
		self.talentPointNum:text(point)
		adapt.oneLinePos(self.talentPointNum, self.btnQuestion, cc.p(10, 0), "left")
	end)
	self.ids = {}
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")}):init(
		{title = gLanguageCsv.talent, subTitle = "TALENT"})
	local leftDatas = {}
	local t = {
		{name = gLanguageCsv.talentBasis, subName = "Basis"},
		{name = gLanguageCsv.talentAdvance, subName = "Advance"},
		{name = gLanguageCsv.talentElement, subName = "Element"},
		{name = gLanguageCsv.talentChallenge, subName = "Challenge"},
	}
	for i,v in orderCsvPairs(csv.talent_tree) do
		if matchLanguage(v.languages) and self.level >= v.showLevel then
			table.insert(leftDatas, {id = i, cfg = v, show = t[i]})
		end
	end
	self.leftDatas = idlers.newWithMap(leftDatas)

	self.showTab = idler.new(1)
	self.showdata1 = idlers.newWithMap({})
	self.showdata2 = idlers.newWithMap({})

	self.showTab:addListener(function(val, oldval, idler)
		self.nodeName:removeAllChildren()
		self.leftDatas:atproxy(oldval).selected = false
		self.leftDatas:atproxy(val).selected = true
		self.nodeName:text(self.leftDatas:atproxy(val).show.name)

		local richWidth = 2560
		if matchLanguage({"kr", "en"}) then
			richWidth = 1550
		end
		--改成富文本
		local desc = rich.createWithWidth(string.format("#C0xFF5B545B#%s", self.leftDatas:atproxy(val).cfg.des), 40, nil, richWidth, nil, cc.p(0, 0.5))
		:addTo(self.nodeName, 3, "richtext")
		:xy(self.nodeName:size().width + 1310,48)
		if matchLanguage({"en"}) then
			desc:y(desc:y() - 18)
			desc:x(self.nodeName:size().width + richWidth/2 + 20)
		elseif matchLanguage({"kr"}) then
			desc:x(self.nodeName:size().width + richWidth/2 + 20)
		end

		itertools.invoke({self.list1, self.begin}, "visible", val < 3)
		itertools.invoke({self.list2, self.slider}, "visible", val >= 3)
		if val >= 3 then
			self.list2:jumpToTop()
		end
		dataEasy.tryCallFunc(self.list2, "setItemAction", {isAction = true})
		self:refreshShowData()
	end)

	idlereasy.when(self.talentTree, function()
		dataEasy.tryCallFunc(self.list2, "updatePreloadCenterIndex")
		self:refreshShowData()
	end)
	self.btnOneReset:visible(dataEasy.isShow(gUnlockCsv.singleTalentReset))
	uiEasy.updateUnlockRes(gUnlockCsv.singleTalentReset, self.btnOneReset, {pos = cc.p(360, 102)})
end

function TalentView:getPageLockState(talentTree, treeID)
	local isLock = false
	-- 第一页判断当前页
	if talentTree[treeID] == nil and treeID == 1 then
		isLock = true
	elseif treeID > 1 and self.leftDatas:atproxy(treeID - 1).isLock then
		isLock = true
	else
		if treeID > 1 then
			local cfg = csv.talent_tree[treeID]
			if self.level < cfg.roleLevel or talentTree[treeID - 1] == nil or (talentTree[treeID - 1].cost < cfg.preTalentpoint) then
				isLock = true
			end
		end
	end
	return isLock
end

function TalentView:refreshShowData()
	-- 滑动条底通用设置不显示
	self.list2.sliderShow = false
	local talentTree = self.talentTree:read()
	local treeId = self.showTab:read()
	local t = self.usedTable[treeId]
	-- 前置页天赋点满足条件判断
	for i, v in orderCsvPairs(csv.talent_tree) do
		if matchLanguage(v.languages) and self.level >= v.showLevel then
			-- 当前页不为空，则判断前一页是否满足条件，第一页只判断当前页
			self.leftDatas:atproxy(i).isLock = self:getPageLockState(talentTree, i)
		end
	end

	local currState = talentTree[treeId] and talentTree[treeId].talent or {}
	local isLock = self:getPageLockState(talentTree, treeId)
	for i, v in ipairs(t.tree) do
		v.isLock = currState[v.id] == nil or isLock
		v.level = currState[v.id]
		v.tab = treeId
	end

	if t.root then
		local lineState = {}
		local maxLine = math.floor(#t.tree / COLUMN_NUM)
		for i=1,maxLine do
			lineState[i] = currState[t.tree[1 + (i-1)*COLUMN_NUM].id] ~= nil
		end
		self.list1:setItemsMargin(#lineState == 2 and 334 or 34)
		local level = currState[t.root.id]
		self:initRootNode(t.root.id, level, lineState)
	end

	local idlersData = t.root and self.showdata1 or self.showdata2
	idlersData:update(clone(t.tree))

	isLock = self.leftDatas:atproxy(treeId).isLock
	local costText
	if isLock then
		local cfg = csv.talent_tree[treeId]
		local level = cfg.roleLevel
		if treeId ~= 1 then
			local name = csv.talent_tree[treeId - 1].name
			costText = string.format(gLanguageCsv.talentTreeUnlockCondition, name, cfg.preTalentpoint, cfg.roleLevel)
		else
			costText = string.format(gLanguageCsv.teamReachTargetLevel, cfg.roleLevel)
		end
	else
		costText = string.format(gLanguageCsv.currTreeCostTalentPoint, talentTree[treeId] and talentTree[treeId].cost or 0)
	end
	self.cost1:setTextColor(isLock and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT)
	self.cost1:text(costText)
	if matchLanguage({"en"}) then
		adapt.setTextAdaptWithSize(self.cost1, {size = cc.size(1700, 120), vertical = "bottom"})
	end
end

function TalentView:initRootNode(id, level, lineState)
	local childs = self.begin:multiget("up", "down", "level", "btn", "center")
	cache.setShader(childs.up, false, lineState[1] and "normal" or "hsl_gray")
	local downState = #lineState == 2 and lineState[2] or lineState[3]
	childs.center:show()
	if #lineState == 2 then
		childs.center:size(134, 20)
		childs.center:x(368)
	else
		childs.center:size(252, 20)
		childs.center:x(486)
	end
	cache.setShader(childs.center, false, (downState or lineState[1]) and "normal" or "hsl_gray")
	cache.setShader(childs.down, false, downState and "normal" or "hsl_gray")
	local isLock = level == nil
	local t = {
		isLock = isLock,
		level = level or 0,
		id = id
	}
	childs.btn:setTouchEnabled(true)
	commonItemShow(self, childs, t, true)
	bind.touch(self.begin, childs.btn, {methods = {ended = function()
		gGameUI:stackUI("city.develop.talent.detail", nil, {clickClose = true},
			self:createHandler("sendParams", self.showTab:read(), id, isLock))
	end}})
end

function TalentView:sendParams(treeId, id, isLock)
	return treeId, id, isLock, self.talentTree, self.ids
end

function TalentView:initCsvTable(treeId)
	self.talentTreeTable = {}
	for i,v in orderCsvPairs(csv.talent) do
		if not self.talentTreeTable[v.treeID] then
			self.talentTreeTable[v.treeID] = {}
		end
		self.talentTreeTable[v.treeID][i] = {cfg = v, next = {}}
	end

	local rootNode = {}

	for treeId, treeData in ipairs(self.talentTreeTable) do
		rootNode[treeId] = {}
		for k, v in pairs(treeData) do
			if v.cfg.preTalentID then
				self.talentTreeTable[treeId][v.cfg.preTalentID].next = self.talentTreeTable[treeId][v.cfg.preTalentID].next or {}
				table.insert(self.talentTreeTable[treeId][v.cfg.preTalentID].next, k)
			else
				table.insert(rootNode[treeId], {cfg = v, id = k, next = v.next})
			end
		end
	end
	self.usedTable = {}
	--分为两种情况，第一种有共同的根节点。第二种没有共同的根节点
	for treeId, rootData in ipairs(rootNode) do
		local roots = {}
		local needTable = {}
		for index, root in ipairs(rootData) do
			table.sort(root.next)
			for i, id in ipairs(root.next) do
				needTable[i] = {}
				if SHOW_TYPE[treeId] == "NOT_ROOT" then
					table.insert(needTable[i], {id = root.id})
				end
				local data = self.talentTreeTable[treeId][id]
				table.insert(needTable[i], {id = id})
				local nextId = data.next and data.next[1]
				while nextId and type(nextId) == "number" do
					table.insert(needTable[i],{id = nextId})
					data = self.talentTreeTable[treeId][nextId]
					nextId = data.next and data.next[1]
				end
			end
			if SHOW_TYPE[treeId] == "NOT_ROOT" then
				roots[index] = clone(needTable[1])
			else
				roots = clone(needTable)
			end
		end
		if SHOW_TYPE[treeId] == "HAVE_ROOT" then
			self.usedTable[treeId] = {root = {id = rootData[1].id}, tree = arraytools.merge(roots)}
		else
			table.sort(roots, function (a, b)
				return a[1].id < b[1].id
			end)
			self.usedTable[treeId] = {tree = arraytools.merge(roots)}
		end
	end
end

function TalentView:initModel()
	self.talentTree = gGameModel.role:getIdler("talent_trees")
	self.talentPoint = gGameModel.role:getIdler("talent_point")
	self.level = gGameModel.role:read("level")
end

function TalentView:onTabClick(list, index)
	self.showTab:set(index)
end

function TalentView:onItemClick(list, v)
	gGameUI:stackUI("city.develop.talent.detail", nil, {clickClose = true},
		self:createHandler("sendParams", self.showTab:read(), v.id, v.isLock))
end

function TalentView:onReset(all)
	local params = {}
	if not all then
		if not dataEasy.isUnlock(gUnlockCsv.singleTalentReset) then
			gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.singleTalentReset))
			return
		end
		params = {treeID = self.showTab:read()}
	end
	gGameUI:stackUI("city.develop.talent.reset", nil, {clickClose = true}, params)
end

function TalentView:onClose()
	local sendT = {}
	for id, v in pairs(self.ids) do
		table.insert(sendT, id)
	end
	if #sendT > 0 then
		gGameApp:requestServer("/game/talent/levelup_end",function (tb)
			ViewBase.onClose(self)
		end, sendT)
	else
		ViewBase.onClose(self)
	end
end

-- 显示规则文本
function TalentView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function TalentView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.talentPoint)
		end),
		c.noteText(56001, 56004),
	}
	return context
end

return TalentView