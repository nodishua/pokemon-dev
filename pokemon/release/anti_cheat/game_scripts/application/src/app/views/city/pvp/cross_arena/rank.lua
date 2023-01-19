-- @desc: 	跨服竞技场-排行榜
-- @date:   2020-05-07

local CrossArenaRankView = class("CrossArenaRankView", Dialog)

--获得横批的位置和段位
local function showTitle(rank)
	local csvId = gGameModel.cross_arena:read("csvID")
	local cfg = csv.cross.service[csvId]
	local version = cfg and cfg.version or nil
	local title = {}
	local stageData = dataEasy.getCrossArenaStageByRank(1)
	for k, v in orderCsvPairs(csv.cross.arena.stage) do
		if v.version == version then
			title[v.stageID] = {rank = v.range[1], stage = v.stageName}
		end
	end
	table.insert(title, {rank = 4, stage = stageData.stageName})
	for k, v in ipairs(title) do
		if rank ~= 1 then
			if rank == v.rank then
				return v.stage
			end
		end
	end
	return 0
end

CrossArenaRankView.RESOURCE_FILENAME = "cross_arena_rank.json"
CrossArenaRankView.RESOURCE_BINDING = {
	["topPanel"] = "topPanel",
	["topBgPanel"] = "topBgPanel",
	["topBgPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["topPanel.panel1"] = {
		binds = {
			varname = "panel1",
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:topClick(1)
			end)}
		},
	},
	["topPanel.panel1.imgIcon1"] = "imgIcon1",
	["topPanel.stageIcon1"] = {
		binds ={
			event = "extend",
			class = "stage_icon",
			props = {
				rank = 1,
				showStageBg = false,
				showStage = false,
				onNodeClick = nil,
				onNode = function(node)
					node:xy(80, 40)
						:z(6)
						:scale(1)
				end,
			}
		}
	},
	["topPanel.stageIcon2"] = {
		binds ={
			event = "extend",
			class = "stage_icon",
			props = {
				rank = 2,
				showStageBg = false,
				showStage = false,
				onNodeClick = nil,
				onNode = function(node)
					node:xy(80, 40)
						:z(6)
						:scale(1)
				end,
			}
		}
	},
	["topPanel.stageIcon3"] = {
		binds ={
			event = "extend",
			class = "stage_icon",
			props = {
				rank = 3,
				showStageBg = false,
				showStage = false,
				onNodeClick = nil,
				onNode = function(node)
					node:xy(80, 40)
						:z(6)
						:scale(1)
				end,
			}
		}
	},
	["topPanel.panel2"] = {
		binds = {
			varname = "panel2",
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:topClick(2)
			end)}
		},
	},
	["topPanel.panel3"] = {
		binds = {
			varname = "panel3",
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:topClick(3)
			end)}
		},
	},
	["topPanel.panel2.imgIcon2"] = "imgIcon2",
	["topPanel.panel3.imgIcon3"] = "imgIcon3",
	["topPanel.downbg"] = "downbg",
	["topPanel.downbg.top1"] = "top1",
	["topPanel.downbg.top2"] = "top2",
	["topPanel.downbg.top3"] = "top3",
	["rankPanel"] = "rankPanel",
	["rankPanel.rankItem"] = "rankItem",
	["rankPanel.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData"),
				item = bindHelper.self("rankItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "down")
					bind.extend(list, childs.down:get("trainerIcon"), {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							level = false,
							vip = false,
							frameId = v.frame,
							onNode = function(node)
								node:xy(30, 85)
									:z(6)
									:scale(0.8)
							end,
						}
					})
					bind.extend(list, childs.down:get("rankIcon"), {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.rank,
							showStageBg = false,
							showStage = false,
							onNodeClick = nil,
							onNode = function(node)
								node:xy(100, 60)
									:z(6)
									:scale(1)
							end,
						}
					})
					childs.title:hide()
					childs.down:get("imgVip"):hide()

					childs.down:get("txtName"):text(v.name)
					childs.down:get("txtLv"):text(v.level)
					childs.down:get("txtServer"):text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
					childs.down:get("txtRecord"):text(v.fighting_point)
					adapt.oneLineCenterPos(cc.p(925, 125), {childs.down:get("txtNode"), childs.down:get("txtLv"), childs.down:get("txtServer")}, cc.p(5, 0))
					local stageInfo = dataEasy.getCrossArenaStageByRank(v.rank)
					childs.down:get("txtRank"):text(stageInfo.rank)

					local stageName = showTitle(v.rank)
					if stageName ~= 0 then
						childs.title:show()
						childs.title:get("txtRank"):text(stageName)
						node:height(271)
					else
						node:height(200)
					end
					node:setTouchEnabled(true)
					bind.touch(list, childs.down, {methods = {ended = functools.partial(list.clickCell, node, v)}})
				end,
				scrollState = bindHelper.self("scrollState"),
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["noRankPanel"] = "noRankPanel",
	["myRankPanel"] = "myRankPanel",
	["myRankPanel.txtScore"] = "myScore",
	["myRankPanel.txtState"] = "myState",
	["myRankPanel.txtName"] = "myName",
	["myRankPanel.txtRank"] = "myRank"
}

function CrossArenaRankView:onCreate(data)
	self.topPanel:show()
	self.rankPanel:show()
	self.myRankPanel:show()
	self.noRankPanel:hide()
	self.title = {}
	local myInfo = data.rank.myinfo
	if myInfo ~= nil then
		local stageInfo = dataEasy.getCrossArenaStageByRank(myInfo.rank)
		self.myState:text(stageInfo.stageName)
		self.myScore:text(myInfo.fighting_point)
		self.myName:text(myInfo.name)
		self.myRank:text(stageInfo.rank)
	else
		self.myScore:hide()
		self.myState:hide()
		self.myRank:hide()
		self.myName:text(gLanguageCsv.crossArenaNoRank)
			:x(858)
	end

	self.data = data.rank.ranks or {}
	if itertools.isempty(self.data) then
		self.topPanel:hide()
		self.rankPanel:hide()
		self.noRankPanel:show()
	else
		--前三名数据
		local topData = {}
		for k, v in ipairs(self.data) do
			table.insert(topData, {cfg = v})
		end
		for i = 1, 3 do
			table.remove(self.data, 1)
		end
		self.showData = idlers.newWithMap(self.data)
		self.topData = topData

		--前三名显示
		local csvTab = gRoleFigureCsv
		for i = 1, 3 do
			local childs = nodetools.multiget(self["top"..i], "txt", "damage", "name", "vip", "attack")
			self["imgIcon"..i]:texture(csvTab[topData[i].cfg.figure].res)
				:xy(self["imgIcon"..i]:x() + csvTab[topData[i].cfg.figure].crossArenaPos.x, self["imgIcon"..i]:y() + csvTab[topData[i].cfg.figure].crossArenaPos.y)
			childs.txt:text(string.format(gLanguageCsv.brackets, getServerArea(topData[i].cfg.game_key, true)))
			childs.damage:text(topData[i].cfg.fighting_point)
			childs.name:text(topData[i].cfg.name)
			childs.vip:hide()

			text.addEffect(childs.txt, {outline={color = cc.c4b(254, 253, 236, 255), size=2}})
			text.addEffect(childs.name, {outline={color = cc.c4b(254, 253, 236, 255), size=2}})
			text.addEffect(childs.damage, {outline={color = cc.c4b(254, 253, 236, 255), size=2}})
			adapt.oneLineCenterPos(cc.p(250, 72), {childs.txt, childs.name, childs.vip}, cc.p(15, 0))
			adapt.oneLineCenterPos(cc.p(250, 30), {childs.attack, childs.damage}, cc.p(15, 0))
		end
	end
	self.scrollState = idler.new(true)
	self.isCanDown = #self.data == 7
	local container = self.rankList:getInnerContainer()
	self.rankList:onScroll(function(event)
		local y = container:getPositionY()
		if y == 0 and self.scrollState:read() and self.isCanDown then
			local offset = #self.data
			self.isCanDown = false
			gGameApp:requestServer("/game/cross/arena/rank", function (tb)
				if tolua.isnull(self) then
					return --界面关闭了 回调不执行
				end
				for i, v in ipairs(tb.view.rank.ranks) do
					table.insert(self.data, v)
				end
				self.isCanDown = #tb.view.rank.ranks == 10
				self.showData:update(self.data)
				self.rankList:jumpToItem(offset - 3, cc.p(0, 1), cc.p(0, 1))
			end, offset + 3, 10) --前三名数据要+3
		end
	end)
	Dialog.onCreate(self)
end

function CrossArenaRankView:topClick(k)
	gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
		gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, blackLayer = true}, tb.view)
	end, self.topData[k].cfg.record_db_id, self.topData[k].cfg.game_key, self.topData[k].cfg.rank)
end

function CrossArenaRankView:onItemClick(list, k, v)
	gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
		gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, blackLayer = true}, tb.view)
	end,v.record_db_id, v.game_key, v.rank)
end

return CrossArenaRankView