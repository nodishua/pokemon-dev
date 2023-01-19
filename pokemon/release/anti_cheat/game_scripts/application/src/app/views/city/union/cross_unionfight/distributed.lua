
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"
local ViewBase = cc.load("mvc").ViewBase
local UnionFightDistributeView = class("UnionFightDistributeView", ViewBase)


UnionFightDistributeView.RESOURCE_FILENAME = "cross_union_fight_distributed.json"
UnionFightDistributeView.RESOURCE_BINDING = {
	["right"] = {
		varname = "right",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["item2"] = "item2",
	["item3"] = "item3",
	["list"] = "list",
	--["right"] = "right",
	["right.title.name"] = "rightName",
	["right.slider"] = "slider",
	["right.list"] = "rightList",
	["right.team"] = "rightTeam",
	["right.team.team1.title.name"] = {
		varname = "team1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(216, 132, 62), size = 3}},
		},
	},
	["right.team.team3.title.name"] = {
		varname = "team3",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(216, 132, 62), size = 3}},
		},
	},
	["right.bgs"] = "bgs",
	["right.team.fail.txt"] = {
		varname = "failTxt",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(70, 79, 100), size = 7}, color = cc.c3b(211, 234, 251)},
		},
	},
}

function UnionFightDistributeView:onCreate(param)
	-- {{{card1,card2...},{card1,card2...}}, {{card1,card2...},{card1,card2...}}, {{card1,card2...},{card1,card2...}}}
	self.topuiView = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.ministryHouseBattle, subTitle = "Building war"})
	self.cash = {}
	self.beforeNode = nil
	self:initModel()
	self.list:setScrollBarEnabled(false)
	self.rightList:setScrollBarEnabled(false)
	self.item:get("list"):setScrollBarEnabled(false)
	self.listData = idler.new(true)
	self.localUnionData, self.unionId, self.allInfoData, self.type = param()
	self.infoData = {}
	self.selectIndex = 10
	for i = 1, 3 do
		self.infoData[i] = self.allInfoData[i] or {}
		if not itertools.isempty(self.infoData[i]) and i < self.selectIndex then
			self.selectIndex = i
		end
	end

	local showItemList = function(itemTab)
		-- 6 个一组
		local item = itemTab.item
		item:get("list"):show()
		item:get("bg"):show()
		item:get("item"):get("icon"):rotate(0)
		item:get("item"):y(125/2 + item:get("list"):height())
		item:height(125 + item:get("list"):height())
		self.list:refreshView()
		self.list:forceDoLayout()
		-- self:pushBackChild(item, itemTab)

	end
	local closeItemList = function(itemTab)
		-- 6 个一组
		local item = itemTab.item
		item:get("list"):hide()
		item:height(125)
		item:get("bg"):hide()
		item:get("item"):get("icon"):rotate(90)
		item:get("item"):y(125/2)
		self.list:refreshView()
		self.list:forceDoLayout()
	end

	self.itemTabs = {}
	self.itemK = false
	self.selectPlayer = 1
	self.beforeSelectIndex = 0
	self.beforeSelectPlayer = 0
	self.beforeData = {}
	-- 默认取第一行的第一个
	idlereasy.any({self.listData}, function (_, listData)
		-- self.list:removeAllChildren()
		local num = 0
		local distributed = {gLanguageCsv.crossUnionFightEmbattle1, gLanguageCsv.crossUnionFightEmbattle2, gLanguageCsv.crossUnionFightEmbattle3}
		--local data = {{{1},{2},{3},{4},{55},{66},{77}},{{5},{6},{7},{8}},{{9},{10},{11},{12}}}
		for k, v in pairs(self.infoData) do
			local battlefield = self.item:clone():show()
			battlefield:get("item"):get("name"):text(string.format(gLanguageCsv.crossUnionFightDistributed,distributed[k],#v))
			if not self.itemTabs[k] then

				table.insert(self.itemTabs, {item = battlefield, list = k, opened = true, value = v})
			else
				self.itemTabs[k].item = battlefield
			end
			self.list:pushBackCustomItem(battlefield)
			self:pushBackChild(self.itemTabs[k].item, self.itemTabs[k])
			if self.itemTabs[k].opened then
				showItemList(self.itemTabs[k])
			end


			battlefield:get("item"):onClick(function()
				-- 原来是关掉的现在打开，已打开的，现在关掉
				if self.itemTabs[k].opened then
					closeItemList(self.itemTabs[k])
					self.itemTabs[k].opened = false
				else
					showItemList(self.itemTabs[k])
					self.itemTabs[k].opened = true
				end
				--  选择起点
				-- self.list:jumpToPercentVertical(0)
				-- self.listData:set(true, true)
			end)
		end
	end)

	self.item:hide()
	self.item2:hide()
end

function UnionFightDistributeView:initModel()
	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.userInfo = gGameModel.cross_union_fight:read("roles")
	self.unions = gGameModel.cross_union_fight:read("unions")
end

-- 加载子页签
function UnionFightDistributeView:pushBackChild(node, datas)
	-- {player = {},}
	local data = datas.value
	local index = 0
	local dataList = {}
	local t ={}
	for i, v in pairs(data) do
		table.insert(t,self.userInfo[v])
		index = index + 1
		if index%6 == 0  then
			table.insert(dataList, t)
			t = {}
		end
	end
	if #t > 0 then
		table.insert(dataList, t)
	end
	--node:height(330 * #dataList + 100)
	local item = node:get("item")
	local width = self.item2:size().width
	local height = 340 * #dataList
	node:height(height + 122)
	node:get("list"):size(width,height)
	node:get("list"):anchorPoint(cc.p(0, 1))
	node:get("list"):y(height)
	item:y(height + 122/2)
	local bgSize = node:get("bg"):size()
	if #dataList ~= 0 then
		node:get("bg"):size(bgSize.width, height + 140)
		node:get("bg"):y(height + 105)
	end

	local number = 1
	for i, v in ipairs(dataList) do
		local item2 = self.item2:clone():show()
		for key, val in pairs(v) do
			local item3 = self.item3:clone():show()
			text.addEffect(item3:get("numberLevel"), {color=ui.COLORS.NORMAL.WHITE, outline={color=ui.COLORS.NORMAL.DEFAULT, size=4}})
			text.addEffect(item3:get("txtLv"), {color=ui.COLORS.NORMAL.WHITE, outline={color=ui.COLORS.NORMAL.DEFAULT, size=3}})
			item3:get("name"):text(val.role_name)
			item3:get("numberLevel"):text(val.role_level)
			item3:get("number"):text(val.fighting_point)
			adapt.oneLineCenterPos(cc.p(145, 40), {item3:get("zhan"),item3:get("number")}, cc.p(6, 0))
			bind.extend(self, item3:get("icon"), {
				event = "extend",
				class = "role_logo",
				props = {
					logoId = val.role_logo,
					frameId = val.role_frame,
					level = false,
					vip = false,
					onNode = function(node)
						node:xy(104, 95):scale(0.9)
					end,
				}
			})
			-- 是不是我自己
			if val.role_db_id == gGameModel.role:read("id") then
				item3:get("my"):show()
			else
				item3:get("my"):hide()
			end
			-- 是否已经淘汰了
			local playCards = self.localUnionData:read()[val.role_db_id] or {}
			local playHp = itertools.isempty(playCards.troop_card_state) and 1 or self:isPlayOut(playCards.troop_card_state, datas.list,playCards.troop) --CrossUnionFightTools.WhetherLive(playCards.troop_card_state)
			if playHp <= 0 then
				item3:get("out"):show()
			else
				item3:get("out"):hide()
			end
			item3:get("selected"):hide()
			if self.selectIndex == datas.list and self.selectPlayer == number then
				self.beforeNode = item3
				--  该玩家为选择状态
				item3:get("selected"):show()
				-- 防止重复请求
				if not self.cash[val.record_id] then
					gGameApp:requestServer("/game/cross/union/fight/role/info", function(tb)
						self.cash[val.record_id] = tb.view
						self:rightUpdata(tb.view)
					end, val.record_id)
				else
					self:rightUpdata(self.cash[val.record_id])
				end
				self.beforeSelectIndex = self.selectIndex
				self.beforeSelectPlayer = self.selectPlayer
			end
			item2:pushBackCustomItem(item3)
			item3:get("btn"):onClick(function()
				self.selectIndex = datas.list
				self.selectPlayer = 6 * (i-1) + key
				--self.listData:set(true, true)
				self.beforeNode:get("selected"):hide()
				item3:get("selected"):show()
				self.beforeNode = item3
				if not self.cash[val.record_id] then
					gGameApp:requestServer("/game/cross/union/fight/role/info", function(tb)
						self.cash[val.record_id] = tb.view
						self:rightUpdata(tb.view)
					end,val.record_id)
				else
					self:rightUpdata(self.cash[val.record_id])
				end
			end)
			number = number + 1
		end
		item2:setScrollBarEnabled(false)
		node:get("list"):pushBackCustomItem(item2)
	end
end

--刷新右边内容
function UnionFightDistributeView:rightUpdata(data)
	local dataAttrs = {"card_attrs", "top_card_attrs"}
	self.rightList:removeAllChildren()
	if self.selectIndex == 1 then
		self.bgs:show()
		self.bgs:get("bg1"):hide()
		self.bgs:get("bg3"):hide()
	else
		self.bgs:hide()
	end
	local battle = self.selectIndex > 1 and  {{},{},{}} or {{},{}}
	local type =  CrossUnionFightTools.getNowMatch(self.status:read())
	for i, v in pairs(battle) do
		local team = self.rightTeam:clone():show()
		if self.selectIndex > 2 then
			team:get("team1"):hide()
			team:get("team3"):show()
			local team3 = team:get("team3")
			local child = team3:multiget("fight", "fightNum", "title")
			child.title:get("name"):text(string.format(gLanguageCsv.crossMinePVPArmy, i))
			local cardInfo = data[dataAttrs[self.type]]
			local cardPlace = data.cards[type] and data.cards[type][self.selectIndex] or {}
			local fightPoint = 0
			local teamAllDead = true
			local tmp = self.localUnionData:read()[data.role_db_id] or {}
			for ii = 1, 3 do
				local key = ii + (i-1) * 3
				local val = cardPlace[key]
				local card = cardInfo[val]
				if card then
					fightPoint = fightPoint + card.fighting_point
					local unitId = dataEasy.getUnitId(card.card_id, card.skin_id)
					local unitCsv = csv.unit[unitId]
					bind.extend(self, team3:get("icon0" .. ii), {
						class = "card_icon",
						props = {
							unitId = unitId,
							advance = card.advance,
							rarity = unitCsv.rarity,
							star = card.star,
							levelProps = {
								data = card.level,
							},
							onNode = function(node)
								node:scale(0.7)
							end,
						}
					})
					team3:get("icon0" .. ii):get("hp"):show()
					local hpNode = team3:get("icon0" .. ii):get("hp"):get("hp")
					hpNode:setCapInsets(cc.rect(9, 6, 1, 1)) -- 克隆时九宫格信息丢失
					local hp = 1 * 100
					if tmp and tmp.troop_card_state and tmp.troop_card_state[val] then
						hp = (tmp.troop_card_state[val][1] or 1) * 100
					end
					if tmp and tmp.troop and tmp.troop > i then
						-- 给的数据为N队，则N-1队全死了
						hp = 0
						--teamAllDead = true
					end
					if hp <= 0 then
						team3:get("icon0" .. ii):get("end"):show()
					else
						teamAllDead = false
						team3:get("icon0" .. ii):get("end"):hide()
					end
					hpNode:setPercent(hp)
				end
			end

			-- troop 没给或者 troop + 1队都是活着的
			--if itertools.isempty(tmp) or (tmp.troop and tmp.troop < i) then
			--	teamAllDead = false
			--end
			if teamAllDead and self:isInBattle() then
				team:get("fail"):show()
				team:get("fail"):get("mask"..i):show()
			else
				team:get("fail"):hide()
			end
			child.fightNum:text(fightPoint)
			adapt.oneLinePos(child.fightNum,child.fight, cc.p(10, 0), "right")
		else
			team:get("team1"):show()
			team:get("team3"):hide()
			local team1 = team:get("team1")
			local child = team1:multiget("fight", "fightNum", "title")
			child.title:get("name"):text(string.format(gLanguageCsv.crossMinePVPArmy, i))
			local cardInfo = data[dataAttrs[self.type]]
			local cardPlace = data.cards[type] and data.cards[type][self.selectIndex] or {}
			local fightPoint = 0
			local teamAllDead = true
			local tmp = self.localUnionData:read()[data.role_db_id] or {}
			for ii = 1, 6 do
				local key = ii + (i-1) * 6
				local val = cardPlace[key]  -- card 的 db_id
				local card = cardInfo[val]
				if card then
					fightPoint = fightPoint + card.fighting_point
					local unitId = dataEasy.getUnitId(card.card_id, card.skin_id)
					local unitCsv = csv.unit[unitId]
					bind.extend(self, team1:get("icon0" .. ii), {
						class = "card_icon",
						props = {
							unitId = unitId,
							advance = card.advance,
							rarity = unitCsv.rarity,
							star = card.star,
							levelProps = {
								data = card.level,
							},
							onNode = function(node)
								node:scale(0.7)
							end,
						}
					})
					team1:get("icon0" .. ii):get("hp"):show()
					local hpNode = team1:get("icon0" .. ii):get("hp"):get("hp")
					hpNode:setCapInsets(cc.rect(9, 6, 1, 1)) -- 克隆时九宫格信息丢失
					local hp = 1 * 100
					if tmp and tmp.troop_card_state and tmp.troop_card_state[val] then
						hp = (tmp.troop_card_state[val][1] or 1) * 100
					end
					if tmp and tmp.troop and tmp.troop > i then
						-- 给的数据为N队，则N-1队全死了
						hp = 0
						--teamAllDead = true
					end
					if hp <= 0 then
						team1:get("icon0" .. ii):get("end"):show()
					else
						teamAllDead = false
						team1:get("icon0" .. ii):get("end"):hide()
					end
					hpNode:setPercent(hp)
				end
			end
			-- troop 没给或者 troop + 1队都是活着的
			--print(1231324141,tmp.troop)
			--print_r(tmp)
			--if itertools.isempty(tmp) or (tmp.troop and tmp.troop < i) then
			--	teamAllDead = false
			--end
			if teamAllDead and self:isInBattle() then
				team:get("fail"):show()
				team:get("fail"):get("mask"..i):show()
			else
				team:get("fail"):hide()
			end
			child.fightNum:text(fightPoint)
			adapt.oneLinePos(child.fightNum,child.fight, cc.p(10, 0), "right")
		end
		self.rightList:pushBackCustomItem(team)
	end
end

-- 获得玩家相关信息并返回
function UnionFightDistributeView:isPlayOut(cards, index, troop)
	-- 根据卡牌数量和血量判断c 0 死亡， 1 活着
	if (index == 1 and troop < 2) or (index ~= 1 and troop < 3) then
		return 1
	end
	for i, v in pairs(cards) do
		if v[1] and v[1] > 0 then
			return 1
		end
	end
	return 0
end

function UnionFightDistributeView:isInBattle()
	local status = self.status:read()
	if status == "start" or status == "prePrepare" or status == "preStart" or status == "topPrepare" or status == "topStart" then
		return false
	end
	return true
end


return UnionFightDistributeView

