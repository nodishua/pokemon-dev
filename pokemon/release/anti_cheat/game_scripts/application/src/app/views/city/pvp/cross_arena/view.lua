-- @date 2020-5-21
-- @desc 跨服竞技场主界面

local ViewBase = cc.load("mvc").ViewBase
local CrossArenaView = class("CrossArenaView", ViewBase)

CrossArenaView.RESOURCE_FILENAME = "cross_arena.json"
CrossArenaView.RESOURCE_BINDING = {
	["bgPanel"] = "bgPanel",
	["noServerPanel"] = "noServerPanel",
	["serverPanel"] = "serverPanel",
	["serverPanel.textNote"] = {
		varname = "serverTextNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["serverPanel.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(252, 251, 223, 255)}},
		},
	},

	["serverPanel.item.textServer"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	["serverPanel.item"] = "serverItem",
	["serverPanel.subList"] = "serverSubList",
	["serverPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("serverSubList"),
				cell = bindHelper.self("serverItem"),
				title = bindHelper.self("title"),
				columnSize = 4,
				onCell = function(list, node, k, v)
					node:get("textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(v, nil, true)))
				end,
				onAfterBuild = function(list)
					for _, child in pairs(list:getChildren()) do
						child:setItemAlignCenter()
					end
				end
			},
		},
	},
	-- 底部按钮
	["downPanel.rankReward"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRankRewardClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"crossArenaPointAward",
						"crossArenaRankAward",
					},
				}
			},
		}
	},
	["downPanel.rankReward.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.rule"] = {
		varname = "rulePanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["downPanel.rule.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.defend"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDefendArrayClick")}
		},
	},
	["downPanel.defend.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.rank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")}
		},
	},
	["downPanel.rank.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.record"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecordClick")}
		},
	},
	["downPanel.record.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.shop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShopClick")}
		},
	},
	["downPanel.shop.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
}

function CrossArenaView:onCreate(data)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.crossArena, subTitle = "WORLD ARENA"})
	self.data = data
	self:initModel()
	self.subView = {}
	self.subViewFunc = {
		selectEnemy = function(...)
			return gGameUI:createView("city.pvp.cross_arena.select_enemy", self):init(...)
		end,
		over = function(...)
			return gGameUI:createView("city.pvp.cross_arena.over", self):init(...)
		end,
	}
	idlereasy.when(self.round, function(_, round)
		local showFirstBg = false
		local viewName = nil
		if round == "start" then
			self.noServerPanel:hide()
			self.serverPanel:hide()
			viewName = "selectEnemy"

			self:removeChildByName("paomingbg")
			self:removeChildByName("kufujinjichang1")
			self:removeChildByName("kufujinjichang2")
			widget.addAnimationByKey(self.bgPanel, "crossarena/kfjjc_bj.skel", "kfjjc_bj", "effect_loop", 1)
					:alignCenter(self.bgPanel:size())
					:scale(2)
		elseif round == "closed" then
			local state = self:getCloseState()
			if state == "showResult" then
				self.noServerPanel:hide()
				self.serverPanel:hide()
				viewName = "over"
				self:removeChildByName("kfjjc_bj")
				self:removeChildByName("kufujinjichang1")
				self:removeChildByName("kufujinjichang2")
				widget.addAnimationByKey(self.bgPanel, "crossarena/paomingbj.skel", "paomingbj", "effect_loop", 1)
					:alignCenter(self.bgPanel:size())
					:scale(2)
			elseif state == "showService" then
				self.noServerPanel:hide()
				self.serverPanel:show()
				self:initServerPanel()
				self:removeChildByName("kfjjc_bj")
				self:removeChildByName("paomingbj")
				self:removeChildByName("kufujinjichang2")
				widget.addAnimationByKey(self.bgPanel, "crossarena/kufujinjichang.skel", "kufujinjichang1", "effect_loop", 1)
					:alignCenter(self.bgPanel:size())
					:scale(2)
			else
				self.noServerPanel:show()
				self.serverPanel:hide()
				self:removeChildByName("kfjjc_bj")
				self:removeChildByName("paomingbj")
				self:removeChildByName("kufujinjichang1")
				widget.addAnimationByKey(self.bgPanel, "crossarena/kufujinjichang.skel", "kufujinjichang2", "effect_loop2", 1)
					:alignCenter(self.bgPanel:size())
					:scale(2)
			end
		end
		self:showSubView(viewName)
	end)
end

function CrossArenaView:getCloseState()
	local id = dataEasy.getCrossServiceData("crossarena")
	if id then
		local cfg = csv.cross.service[id]
		self.date = cfg.date
		local startTime = time.getNumTimestamp(cfg.date, 5) - 2 * 24 * 3600 -- 下一场比赛开始前两天
		local endTime = time.getNumTimestamp(cfg.date, 10)
		-- 到点服务器状态还没变的，继续显示匹配服 14 天开赛中
		if time.getTime() >= startTime and time.getTime() < endTime + 13 * 24 * 3600 then
			self.servers:update(getMergeServers(cfg.servers))
			self:countToStart(endTime - time.getTime())
			game.crossArenaCsvId = id
			return "showService"
		end
	end
	if itertools.size(self.lastRanks:read()) > 0 then
		return "showResult"
	end
end

function CrossArenaView:countToStart(endTime)
	local round = self.round:read()
	if round ~= "closed" then
		return
	end
	if endTime < 0 then
		endTime = 10
	end
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/arena/battle/main", functools.handler(self, "countToStart", 10))
	end, endTime)
end

function CrossArenaView:initServerPanel()
	local startDate = time.getNumTimestamp(self.date)
	local t1 = time.getDate(startDate)
	local strStartTime = string.formatex(gLanguageCsv.timeMonthDay, {month = t1.month, day = t1.day}) .. "10:00"

	local endTime = time.getNumTimestamp(self.date) + 13 * 24 * 60 * 60
	local t2 = time.getDate(endTime)
	local strEndTime = string.formatex(gLanguageCsv.timeMonthDay, {month = t2.month, day = t2.day}) .. "22:00"

	self.textTime:text(strStartTime .."--" .. strEndTime)
	adapt.oneLineCenterPos(cc.p(750, 750), {self.serverTextNote, self.textTime}, cc.p(40, 0))
end

function CrossArenaView:initModel()
	self.round = gGameModel.cross_arena:getIdler("round")
	self.lastRanks = gGameModel.cross_arena:getIdler("lastRanks")
	self.servers = idlers.newWithMap({})
	game.crossArenaCsvId = gGameModel.cross_arena:read("csvID")
end

function CrossArenaView:showSubView(viewName, ...)
	if self.subView.name ~= viewName then
		if self.subView.view then
			self.subView.view:onClose()
		end
		if viewName == nil then
			self.subView = {}
		else
			self.subView = {
				name = viewName,
				view = self.subViewFunc[viewName](...)
			}
		end
	end
end


--段位奖励
function CrossArenaView:onRankRewardClick()
	if self.round:read() == "closed" and not self:getCloseState() then
		gGameUI:showTip(gLanguageCsv.crossCraftFirstPrepare)
	else
		gGameUI:stackUI("city.pvp.cross_arena.point_reward")
	end
end

--规则
function CrossArenaView:onRuleClick()
	if not self.rulePanel:get("ruleItem") then
		ccui.Layout:create():hide():addTo(self.rulePanel, 1, "ruleItem")
	end
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CrossArenaView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(144),
		c.noteText(86001, 86010),
		c.noteText(145),
		c.noteText(87001, 87010),
		c.noteText(146),
		c.noteText(88001, 88010),
	}
	if self.round:read() == "start" then
		-- {"game.dev.1", "game.dev.4", "game.dev.5"}
		local servers = gGameModel.cross_arena:read("servers")
		if servers then
			local t = arraytools.map(getMergeServers(servers), function(k, v)
				return string.format(gLanguageCsv.brackets, getServerArea(v, nil, true))
			end)
			table.insert(context, 2, "#C0x5B545B#" .. gLanguageCsv.currentServers .. table.concat(t, ","))
		end
		local role = gGameModel.cross_arena:read("role")
		if role.top_rank then
			local ruleItem = self.rulePanel:get("ruleItem")
			local width = view.list:width()
			local data = dataEasy.getCrossArenaStageByRank(role.top_rank)
			local str = data.stageName .. " " .. data.rank
			table.insert(context, 2, c.clone(ruleItem, function(item)
				local highestItem, height = beauty.textScroll({
					size = cc.size(width, 0),
					strs = string.format(gLanguageCsv.crossArenaRankHighest .. str),
					isRich = true,
					align = "center",
				})
				highestItem:height(height)
				item:size(width, height):add(highestItem)
			end))
		end
	end
	return context
end

-- 防守阵容
function CrossArenaView:onDefendArrayClick()
	if self.round:read() == "start" then
		gGameUI:stackUI("city.pvp.cross_arena.embattle", nil, {full = true}, {type = "defence"})
	else
		gGameUI:showTip(gLanguageCsv.crossArenaNotStart)
	end
end


-- 排行榜
function CrossArenaView:onRankClick()
	if self.round:read() == "start" or self:getCloseState() == "showResult" then
		gGameApp:requestServer("/game/cross/arena/rank", function (tb)
			gGameUI:stackUI("city.pvp.cross_arena.rank", nil, nil, tb.view)
		end, 0, 10)
	else
		gGameUI:showTip(gLanguageCsv.crossArenaNoRank)
	end
end

-- 回放
function CrossArenaView:onRecordClick()
	gGameUI:stackUI("city.pvp.cross_arena.combat_record")
end

-- 商店
function CrossArenaView:onShopClick()
	-- if not gGameUI:goBackInStackUI("city.shop") then
	-- 	gGameApp:requestServer("/game/fixshop/get", function(tb)
	-- 		gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CROSS_ARENA_SHOP)
	-- 	end)
	-- end
	gGameUI:showTip(gLanguageCsv.comingSoon)
end

return CrossArenaView