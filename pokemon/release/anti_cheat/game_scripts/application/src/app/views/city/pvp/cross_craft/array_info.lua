-- @date 2020-3-15
-- @desc 跨服石英大会查看阵容详情

local CrossCraftView = require("app.views.city.pvp.cross_craft.view")
local CrossCraftArrayInfoView = class("CrossCraftArrayInfoView", Dialog)

local NEED_CARDS = 12

local function initItem(parent, item, data)
	local childs = item:multiget("head", "level", "txt", "fightPoint", "attr1", "attr2")
	childs.level:text("Lv" .. data.level)
	childs.fightPoint:text(data.fighting_point)
	adapt.oneLinePos(childs.txt, childs.fightPoint, cc.p(5, 0))
	childs.attr1:texture(ui.ATTR_ICON[data.attr1])
	childs.attr2:visible(data.attr2 and true or false)
	if data.attr2 then
		childs.attr2:texture(ui.ATTR_ICON[data.attr2])
	end
	bind.extend(parent, childs.head, {
		class = "card_icon",
		props = {
			unitId = data.unit_id,
			rarity = data.rarity,
			advance = data.advance,
			onNode = function(panel)
				panel:xy(-4, -4)
			end,
		},
	})
end

CrossCraftArrayInfoView.RESOURCE_FILENAME = "cross_craft_array_info.json"
CrossCraftArrayInfoView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rolePanel.icon"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				level = false,
				vip = false,
				onNode = function(node)
					node:xy(104, 95)
						:z(6)
						:scale(0.9)
				end,
			}
		}
	},
	["rolePanel.level"] = "roleLevel",
	["rolePanel.name"] = "roleName",
	["rolePanel.server"] = "roleServer",
	["rolePanel.txt"] = "roleTxt",
	["rolePanel.record"] = "roleRecord",
	["rolePanel.state"] = "roleState",
	["prePanel"] = "prePanel",
	["prePanel.group"] = "preGroup",
	["finalPanel"] = "finalPanel",
	["finalPanel.group"] = "finalGroup",
	["finalPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("finalData"),
				item = bindHelper.self("finalGroup"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "bg", "state", "list", "item")
					if v.result == "inBattle" then
						childs.bg:texture("city/pvp/craft/box_bs.png")
						childs.state:text(gLanguageCsv.zhandou)

					elseif v.result == "inPrepare" then
						childs.bg:texture("city/pvp/craft/box_bs.png")
						childs.state:text(gLanguageCsv.beisai)

					elseif v.result == "win" then
						childs.bg:texture("city/pvp/craft/box_jj.png")
						if k == 1 and v.isFinal then
							childs.state:text(gLanguageCsv.huosheng)
						else
							childs.state:text(gLanguageCsv.jinji)
						end

					elseif v.result == "fail" then
						childs.bg:texture("city/pvp/craft/box_lb.png")
						childs.state:text(gLanguageCsv.xibai)

					elseif v.result == "isOut" then
						childs.bg:texture("city/pvp/craft/box_lb.png")
						childs.state:text(gLanguageCsv.yitaotai)
					else
						childs.bg:texture("city/pvp/craft/box_lb.png")
						childs.state:text(gLanguageCsv.weikaisai)
					end
					childs.title:texture(v.res)
					bind.extend(list, childs.list, {
						class = "listview",
						props = {
							data = v.data,
							item = childs.item,
							onItem = function(list, node, k, v)
								initItem(list, node, v)
								uiEasy.getStarPanel(v.star, {align = "left", interval = -5})
									:scale(0.35)
									:xy(230, 120)
									:addTo(node, 2)
							end,
						}
					})
				end,
			},
		},
	},
	["finalPanel.backup.item"] = "finalBackupItem",
	["finalPanel.backup.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("finalBackupData"),
				item = bindHelper.self("finalBackupItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("head", "txt", "fightPoint")
					childs.fightPoint:text(v.fighting_point)
					adapt.oneLineCenterPos(cc.p(140, 30), {childs.txt, childs.fightPoint}, cc.p(5, 0))
					bind.extend(list, childs.head, {
						class = "card_icon",
						props = {
							unitId = v.unit_id,
							rarity = v.rarity,
							advance = v.advance,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:xy(-4, -4)
							end,
						},
					})
				end,
			},
		},
	},
}

local function getMyData()
	return {
		role_logo = gGameModel.role:read("logo"),
		role_frame = gGameModel.role:read("frame"),
		role_level = gGameModel.role:read("level"),
		role_name = gGameModel.role:read("name"),
		game_key = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true}),
		online = true,
		history = gGameModel.cross_craft:read("history"),
		card_attrs = gGameModel.cross_craft:read("card_attrs"),
		cards = gGameModel.cross_craft:read("cards"),
	}
end

-- data nil 为获取自己的信息
function CrossCraftArrayInfoView:onCreate(data, round)
	data = data or getMyData()
	self.data = data
	self.logoId = data.role_logo
	self.frameId = data.role_frame
	self.roleLevel:text("Lv" .. data.role_level)
	self.roleName:text(data.role_name)
	self.roleServer:text(getServerArea(data.game_key, true))
	if not data.online then
		self.roleState:text(gLanguageCsv.symbolBracketLeft .. gLanguageCsv.offLine .. gLanguageCsv.symbolBracketRight)
		text.addEffect(self.roleState, {color = ui.COLORS.QUALITY[1]})
	end
	adapt.oneLinePos(self.roleLevel, self.roleName, cc.p(15, 0))
	adapt.oneLinePos(self.roleName, self.roleState, cc.p(5, 0))

	self.round = gGameModel.cross_craft:read("round")

	self.showResult = false
	-- 若相同轮用最新状态，不相同用指定round显示
	if round then
		if (string.find(round, "^pre1") and not string.find(self.round, "^pre1"))
			or (string.find(round, "^pre2") and not string.find(self.round, "^pre2"))
			or (string.find(round, "^pre3") and not string.find(self.round, "^pre3"))
			or (string.find(round, "^top") and not string.find(self.round, "^top"))
			or (string.find(round, "^final") and not string.find(self.round, "^final")) then
			self.showResult = true
			self.round = round
		end
	end
	if self.round == "closed" or self.round == "signup" or round == "final" then
		-- 未开赛时使用上一期的结果
		self.showResult = true
		self.round = "final3"

	elseif self.round == "halftime" then
		-- 中场显示第2轮结果
		self.showResult = true
		self.round = "pre24"

	elseif round == "top" then
		self.showResult = true
		self.round = "top16"
	end

	local lockPos = string.find(self.round, "_lock$")
	local round = self.round
	if lockPos then
		round = string.sub(self.round, 1, lockPos - 1)
	end

	-- 计算玩家胜负场
	local winCount = 0
	local loseCount = 0
	for k,v in pairs(data.history) do
		-- 当前比赛进行中时，如果有结果了也忽略
		if self.showResult or data.round ~= round then
			if v.result == "win" then
				winCount = winCount + 1

			elseif v.result == "fail" then
				loseCount = loseCount + 1
			end
		end
	end
	self.roleRecord:text(string.format(gLanguageCsv.winAndLoseNum, winCount, loseCount))


	self.cardAttrs = {}
	for _, v in pairs(data.card_attrs) do
		self.cardAttrs[v.id] = v
	end
	self.finalData = {}
	self.finalBackupData = {}
	self.isShowFinal = false
	if self.round == "closed" or string.find(self.round, "^top") or string.find(self.round, "^final") then
		self.isShowFinal = true
		self:showFinalPanel()
	else
		self:showPrePanel()
	end

	Dialog.onCreate(self)
end


function CrossCraftArrayInfoView:showPrePanel()
	self.prePanel:show()
	self.finalPanel:hide()
	local list = self.preGroup:get("list")
	list:setScrollBarEnabled(false)
	if string.find(self.round, "^pre%d") then
		local idx = string.sub(self.round, 4, 4)
		self.prePanel:get("round"):texture("city/pvp/cross_craft/txt/txt_d" .. idx .. "l.png")
	end

	for i = 1, 4 do
		local history = CrossCraftView.getRoundHistory(i, self.round, self.data.history)
		local result = self:getArrayRoundResult(i, self.round, self.data.history)
		local group = self.preGroup:clone()
		group:get("result"):hide()
		if result == "win" then
			group:get("result"):texture("city/pvp/craft/icon_win.png"):show()

		elseif result == "fail" then
			group:get("result"):texture("city/pvp/craft/icon_lose.png"):show()
		end
		local res = CrossCraftView.getArrayRoundRes(i, self.round, self.data.history)
		group:get("title"):texture(res)
		group:xy(self.prePanel:get("bg" .. i):xy())
			:z(5)
			:show()
		self.prePanel:addChild(group)

		for j = 1, 3 do
			local idx = j + (i - 1) * 3
			local dbid = history and history.cards[j][1] or self.data.cards[idx]
			local attrs = self.cardAttrs[dbid]
			local item = self.preGroup:get("item"):clone():show()
			local cardCfg = csv.cards[attrs.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			local unit_id = dataEasy.getUnitId(attrs.card_id, attrs.skin_id)
			local data = {
				id = attrs.id,
				card_id = attrs.card_id,
				unit_id = unit_id,
				fighting_point = attrs.fighting_point,
				level = attrs.level,
				star = attrs.star,
				advance = attrs.advance,
				rarity = unitCfg.rarity,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
			}
			initItem(self, item, data)
			local childs = item:multiget("txt", "fightPoint")
			adapt.oneLineCenterPos(cc.p(140, 40), {childs.txt, childs.fightPoint}, cc.p(5, 0))
			uiEasy.getStarPanel(data.star, {align = "center", interval = -5})
				:scale(0.35)
				:xy(item:width()/2, 90)
				:addTo(item, 2)
			group:get("list"):pushBackCustomItem(item)
		end
	end
end

function CrossCraftArrayInfoView:showFinalPanel()
	self.prePanel:hide()
	self.finalPanel:show()
	local list = self.preGroup:get("list")
	list:setScrollBarEnabled(false)
	for i = 1, 3 do
		local history = CrossCraftView.getRoundHistory(4 - i, self.round, self.data.history)
		local result = self:getArrayRoundResult(4 - i, self.round, self.data.history)
		local res = CrossCraftView.getArrayRoundRes(4 - i, self.round, self.data.history)
		local data = {}
		for j = 1, 3 do
			local idx = j + (3 - i) * 3
			local dbid = history and history.cards[j][1] or self.data.cards[idx]
			local attrs = self.cardAttrs[dbid]
			local item = self.preGroup:get("item"):clone()
			local cardCfg = csv.cards[attrs.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			local unit_id = dataEasy.getUnitId(attrs.card_id, attrs.skin_id)
			data[j] = {
				id = attrs.id,
				card_id = attrs.card_id,
				unit_id = unit_id,
				fighting_point = attrs.fighting_point,
				level = attrs.level,
				star = attrs.star,
				advance = attrs.advance,
				rarity = unitCfg.rarity,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
			}
		end
		self.finalData[i] = {
			result = result,
			res = res,
			data = data,
			isFinal = not string.find(self.round, "^top"),
		}
	end
	for i = 1, 3 do
		local attrs = self.cardAttrs[self.data.cards[9+i]]
		local item = self.preGroup:get("item"):clone()
		local cardCfg = csv.cards[attrs.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local unit_id = dataEasy.getUnitId(attrs.card_id, attrs.skin_id)

		self.finalBackupData[i] = {
			id = attrs.id,
			unit_id = unit_id,
			card_id = attrs.card_id,
			fighting_point = attrs.fighting_point,
			level = attrs.level,
			star = attrs.star,
			advance = attrs.advance,
			rarity = unitCfg.rarity,
			attr1 = unitCfg.natureType,
			attr2 = unitCfg.natureType2,
		}
	end
end

-- 设置第idx场的结果状态
function CrossCraftArrayInfoView:getArrayRoundResult(idx, round, history)
	if self.showResult then
		local data = CrossCraftView.getRoundHistory(idx, round, history)
		if data then
			return data.result
		end
		return "isOut"
	end
	if self.isShowFinal then
		-- top final 会显示淘汰
		for i = 1, idx-1 do
			local data = CrossCraftView.getRoundHistory(i, round, history)
			if data and data.result == "fail" and data.round ~= "final2" then
				return "isOut"
			end
		end
	end
	return CrossCraftView.getArrayRoundResult(idx, round, history)
end

return CrossCraftArrayInfoView