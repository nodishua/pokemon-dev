-- @desc: 	craft-查看对手参赛阵容

local ViewBase = cc.load("mvc").ViewBase
local CraftEnemyEmbattleView = class("CraftEnemyEmbattleView", Dialog)
local MINLV = csv.unlock[gUnlockCsv.craft].startLevel
local FINALPANEL = {         -- 四强赛、半决赛、冠军赛
	[11] = "finalFourPanel",
	[12] = "semifinalsPanel",
	[13] = "championPanel",
}
local ROUND = {           -- 每回合round字段，和服务器对应
	[1] = "pre1",
	[2] = "pre2",
	[3] = "pre3",
	[4] = "pre4",
	[5] = "pre5",
	[6] = "pre6",
	[7] = "pre7",
	[8] = "pre8",
	[9] = "pre9",
	[10] = "pre10",
	[11] = "final1",
	[12] = "final2",
	[13] = "final3",
}
local MAXPREROUNDNUM = 10  -- 小组赛最大回合数

CraftEnemyEmbattleView.RESOURCE_FILENAME = "craft_battle_enemy.json"
CraftEnemyEmbattleView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rolePanel.trainerIcon"] = {
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
	["rolePanel.txtLv"] = "roleLv",
	["rolePanel.txtName"] = "roleName",
	["rolePanel.txtRecord"] = "roleRecord",
	["rolePanel.txtState"] = "roleState",

	["prePanel"] = "prePanel",
	["prePanel.pre1"] = "pre1",
	["prePanel.pre2"] = "pre2",
	["prePanel.pre3"] = "pre3",
	["prePanel.pre4"] = "pre4",
	["prePanel.pre5"] = "pre5",
	["prePanel.pre6"] = "pre6",
	["prePanel.pre7"] = "pre7",
	["prePanel.pre8"] = "pre8",
	["prePanel.pre9"] = "pre9",
	["prePanel.pre10"] = "pre10",

	["finalPanel"] = "finalPanel",
	["finalPanel.final1"] = "final1",
	["finalPanel.final2"] = "final2",
	["finalPanel.final3"] = "final3",
	["finalPanel.final4"] = "final4",
	["finalPanel.final5"] = "final5",
	["finalPanel.final6"] = "final6",
	["finalPanel.final7"] = "final7",
	["finalPanel.final8"] = "final8",
	["finalPanel.final9"] = "final9",
	["finalPanel.final10"] = "final10",

	["finalPanel.finalFourPanel"] = "finalFourPanel",
	["finalPanel.semifinalsPanel"] = "semifinalsPanel",
	["finalPanel.championPanel"] = "championPanel",

	["imgStar"] = "imgStar",
}

-- if history[x] then 有多处重复
local function historyStatus(history, txtBgPath, txtNode, isFighting, final3Path, historys)
	if history then
		if history.result == "win" then
			if historys then
				txtBgPath, txtNode, final3Path = historyStatus(historys, txtBgPath, txtNode, isFighting, final3Path)
			else
				txtBgPath = "city/pvp/craft/box_bs.png"
				txtNode = isFighting and gLanguageCsv.stateFighting or gLanguageCsv.beisai
			end
		elseif history.result == "fail" then
			if final3Path and not historys then
				final3Path = "city/pvp/craft/myteam/txt_jjs.png"
				txtBgPath = "city/pvp/craft/box_lb.png"
				txtNode = isFighting and gLanguageCsv.stateFighting or gLanguageCsv.beisai
			else
				txtBgPath = "city/pvp/craft/box_lb.png"
				txtNode = gLanguageCsv.yitaotai
			end
		end
	else
		txtBgPath = "city/pvp/craft/box_lb.png"
		txtNode = gLanguageCsv.weikaisai
	end
	return txtBgPath, txtNode, final3Path
end


-- @param data.cards 布阵详情，小组赛时，1-10分别为第一到第十场布阵，淘汰赛时，1-3为四强布阵，4-6为半决赛布阵，7-9为冠军赛布阵，10为替补布阵
-- @param data.card_attrs 所有卡牌详细数据集合
-- @param data.history 玩家战绩集合，没有发生的比赛不会记入history
-- @param state 1 小组赛 2 淘汰赛
-- @param isFighting 是否处于比赛中，用于区别比赛中/备战中
function CraftEnemyEmbattleView:onCreate(data, state, isFighting)
	self.logoId = data.role_logo
	self.frameId = data.role_frame
	self.roleLv:text(math.max(MINLV, tonumber(data.role_level)))
	self.roleName:text(data.role_name)
	if not data.online then
		self.roleState:text(gLanguageCsv.symbolBracketLeft .. gLanguageCsv.offLine .. gLanguageCsv.symbolBracketRight)
		text.addEffect(self.roleState, {color = ui.COLORS.QUALITY[1]})
	end
	adapt.oneLinePos(self.roleName, self.roleState)

	local winCount = 0		-- 计算玩家胜负场
	local loseCount = 0
	for k,v in pairs(data.history) do
		if v.result == "win" then
			winCount = winCount + 1
		elseif v.result == "fail" then
			loseCount = loseCount + 1
		end
	end
	self.roleRecord:text(string.format(gLanguageCsv.winAndLoseNum, winCount, loseCount))

	-- 淘汰赛相关 begin
	if state == 2 then
		local history = {}  	-- 历史比赛数据
		for k,v in pairs(data.history) do
			for i=MAXPREROUNDNUM+1,#ROUND do
				if v.round == ROUND[i] then
					history[i] = v
				end
			end
		end

		local final3Path = "city/pvp/craft/myteam/txt_gjs.png"  -- 冠军赛/季军赛图片切换显示
		local txtBgPath = "city/pvp/craft/box_lb.png" -- 标识背景图
		local txtNode = gLanguageCsv.weikaisai -- 标识文本
		local checkConditions = {
			["final1"] = function() -- 第一轮没有数据, 比赛尚未开始，处于备战中/比赛中（小组赛被淘汰，暂无查看淘汰赛阵容入口，暂不考虑）
				txtBgPath = "city/pvp/craft/box_bs.png"
				txtNode = isFighting and gLanguageCsv.stateFighting or gLanguageCsv.beisai
			end,
			["final2"] = function() -- 第二轮没有数据：1、第一轮没有数据，未开赛 2、第一轮结果为fail，已淘汰 3、第一轮结果为win，备战中/进行中
				txtBgPath, txtNode, final3Path = historyStatus(history[11], txtBgPath, txtNode, isFighting)
			end,
			["final3"] = function()
				-- 第三轮没有数据：1、第一轮没有数据，未开赛 2、第一轮结果为win，第二轮没有数据，未开赛 3、第一轮结果为win，第二轮结果为win，冠军赛备战中/进行中
				-- 4、第一轮结果为win，第二轮结果为fail，季军赛备战中/进行中 5、第一轮结果为fail，已淘汰
				txtBgPath, txtNode, final3Path = historyStatus(history[11] ,txtBgPath ,txtNode ,isFighting ,final3Path ,history[12])
			end
		}

		for i=MAXPREROUNDNUM+1,#ROUND do
			local children = self[FINALPANEL[i]]:multiget("txtBg", "txtNode", "bg")
			if history[i] then
				txtBgPath = history[i].result  == "win" and "city/pvp/craft/box_jj.png" or "city/pvp/craft/box_lb.png"
				txtNode = history[i].result  == "win" and (history[i].round == "final3" and gLanguageCsv.huosheng or gLanguageCsv.jinji)
					or gLanguageCsv.xibai
				if history[12] and  history[12].result == "fail" then -- 玩家上场结果为fail, 这场还有数据，玩家参加的一定是季军赛
					if i == 12 then
						txtNode = gLanguageCsv.xibai
					elseif i == 13 then
						final3Path = "city/pvp/craft/myteam/txt_jjs.png"
					end
				end
			else
				checkConditions[ROUND[i]]()
			end
			if ROUND[i] == "final3" then
				children.bg:texture(final3Path)
			end
			children.txtBg:texture(txtBgPath)
			children.txtNode:text(txtNode)
		end
	end
	-- 淘汰赛相关 end

	self.prePanel:visible(state == 1)
	self.finalPanel:visible(state == 2)

	-- 组装参赛阵容卡牌数据 begin
	local cards = {}
	local history_num = 0
	-- pairs(data.history) 多次重复，考虑合并
	local function insertHistory2Table(cards, states)
		if states == 1 then
			for k,v in pairs(data.history) do
				if k < MAXPREROUNDNUM + 1 then
					table.insert(cards, v.cards[1][1])
					history_num = history_num + 1
				end
			end
		else
			for k,v in pairs(data.history) do
				if k > MAXPREROUNDNUM then
					for i,q in ipairs(v.cards) do
						table.insert(cards, q[1])
						history_num = history_num + 1  -- 第二个调用并未使用，考虑到后续未使用history 不用去掉
					end
				end
			end
		end
	end

	if state == 1 then
		insertHistory2Table(cards, 1)

		if history_num < MAXPREROUNDNUM then    -- 没有发生的战斗histor中没有对应数据，需要去cards里补全
			for i=history_num+1,MAXPREROUNDNUM do
				table.insert(cards, data.cards[i])
			end
		end
	elseif state == 2 then
		insertHistory2Table(cards, 2)

		if history_num == MAXPREROUNDNUM - 1 then  -- 非战斗中，最后一张替补卡牌数据需要通过对比小组赛历史数据筛选出来，而不用data.cards里的最后一张，服务器要求，这里统一处理成三场比赛均有历史数据之后，最后一张替补卡牌通过比对小组赛历史数据筛选出来
			local groupCards = {}  -- 小组赛历史卡牌数据
			insertHistory2Table(groupCards, 1)

			local finalCards = {} 	-- 淘汰赛历史卡牌数据9张
			insertHistory2Table(finalCards,2)

			local subCards = {}  -- 替补卡牌，理论上只存在一张
			for _,groupCard in ipairs(groupCards) do
				local isSub = true  -- 是否为替补卡牌
				for _,finalCard in ipairs(finalCards) do
					if finalCard == groupCard then
						isSub = false
						break
					end
				end
				if isSub then
					table.insert(subCards, groupCard)
				end
			end

			table.insert(cards, subCards[1])
		elseif history_num < MAXPREROUNDNUM - 1 then  -- history_num 小于 MAXPREROUNDNUM - 1，表示history里面淘汰赛数据不足9个，淘汰赛尚未结束，直接读取cards里数据
			for i=history_num+1,MAXPREROUNDNUM do
				table.insert(cards, data.cards[i])
			end
		end
	end

	-- 组装参赛阵容卡牌数据 begin

	-- 参赛卡牌展示相关(小组赛/淘汰赛共用) begin
	for i=1,MAXPREROUNDNUM do
		for k,v in pairs(data.card_attrs) do
			if v.id == cards[i] then
				local node = state == 1 and self["pre" .. i] or self["final" .. i]
				local children = node:multiget("head", "textLv", "textNote", "textFightPoint", "imgAttr1", "imgAttr2", "imgFlag")
				local cfg = csv.cards[v.card_id]
				local unitCfg = csv.unit[cfg.unitID]
				local rarity = unitCfg.rarity
				local unitId = dataEasy.getUnitId(v.card_id,v.skin_id)
				bind.extend(self, children.head, {
					class = "card_icon",
					props = {
						unitId =unitId,
						rarity = rarity,
						advance = v.advance,
					}
				})

				children.textLv:text("Lv" .. v.level)
				children.textFightPoint:text(v.fighting_point)

				if state == 1 then 	-- 小组赛左上角显示胜负小角标
					local history = false  -- 通过round字段对比一下数据，确保数据准确性
					for k,v in pairs(data.history) do
						if v.round == ROUND[i] then
							history = v
						end
					end
					if history then
						children.imgFlag:texture(history.result  == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png")
					else
						children.imgFlag:hide()
					end
				end

				local nature1 = unitCfg.natureType
				children.imgAttr1:texture(ui.ATTR_ICON[nature1])
				local nature2 = csv.unit[cfg.unitID].natureType2
				if nature2 then
					children.imgAttr2:texture(ui.ATTR_ICON[nature2])
					local y = children.imgAttr1:y()   -- 保存原来高度用于调整
					if state == 1 then
						adapt.oneLineCenterPos(cc.p(node:width()/2, children.textLv:y()), {children.textLv, children.imgAttr1, children.imgAttr2}, cc.p(5,0))
					else
						adapt.oneLinePos(children.textLv, {children.imgAttr1, children.imgAttr2}, {cc.p(15,0), cc.p(5,0)})
					end
					children.imgAttr1:y(y)
					children.imgAttr2:y(y)
				else
					children.imgAttr2:hide()
					local y = children.imgAttr1:y()   -- 保存原来高度用于调整
					if state == 1 then
						adapt.oneLineCenterPos(cc.p(node:width()/2, children.textLv:y()), {children.textLv, children.imgAttr1}, cc.p(15, 0))
					else
						adapt.oneLinePos(children.textLv, children.imgAttr1, cc.p(15,0), "left")
					end
					children.imgAttr1:y(y)
				end

				local starNum = v.star
				for j=1,starNum do
					if j < 7 then
						local relNum = math.min(starNum, 6)
						local posX = state == 1 and (160 - 18 * (relNum + 1 - 2 * j)) or (240 + (j-1)*40)
						local posY = state == 1 and 85 or 115
						local star = self.imgStar:clone()
							:xy(posX, posY)
							:show()
							:addTo(node, 10, "star" .. j)
					else
						local idx = j % 6 == 0 and 6 or j % 6
						local star = node:getChildByName("star" .. idx)
						if star then
							star:texture("common/icon/icon_star_z.png")
						end
					end
				end

				if state == 1 then  -- 小组赛和淘汰赛布局不一致，对齐方式也不同
					adapt.oneLineCenterPos(cc.p(node:width()/2, children.textNote:y()), {children.textNote, children.textFightPoint}, cc.p(10, 0))
				else
					adapt.oneLinePos(children.textNote, children.textFightPoint, cc.p(10,0))
				end
				break
			end
		end
	end
	-- 参赛卡牌展示相关 end

	Dialog.onCreate(self)
end

return CraftEnemyEmbattleView