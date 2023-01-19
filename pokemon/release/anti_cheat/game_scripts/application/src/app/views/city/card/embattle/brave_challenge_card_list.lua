--
-- @desc 以太布阵下边操作
--
local EmbattleCardList = require "app.views.city.card.embattle.embattle_card_list"

local BraveChallengeEmbattleCardList = class("EmbattleCardList", EmbattleCardList)
BraveChallengeEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
BraveChallengeEmbattleCardList.RESOURCE_BINDING = {
	["textNotRole"] = "emptyTxt",
	["item"] = "item",
	["list"] = "list",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("item"),
				emptyTxt = bindHelper.self("emptyTxt"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)
					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
				asyncPreload = 12,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch"),
				initItem = bindHelper.self("initItem"),
			},
		},
	},
	["btnPanel"]  = "btnPanel",
}

function BraveChallengeEmbattleCardList:initItem(list, node, k, v)
	local size = node:size()
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unit_id,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			isNew = v.isNew,
			grayState = (v.battle == 1) and 1 or 0,
			levelProps = {
				data = v.level,
			},
			onNode = function(panel)
				panel:xy(-4, -4)
			end,
		}
	})
	local textNote = node:get("textNote")
	textNote:visible(v.battle == 1)
	uiEasy.addTextEffect1(textNote)
	local hpBar = node:get("hpBar"):show()
	local mpBar = node:get("mpBar"):show()
	hpBar:get("bar"):setPercent(v.states[1] * 100)
	mpBar:get("bar"):setPercent(v.states[2] * 100)

	-- 还存活的卡牌才可以点击
	if v.states[1] > 0 then
		node:onTouch(functools.partial(list.clickCell, v))
	else
		node:get("deadMask"):show()
	end
end

function BraveChallengeEmbattleCardList:onSortCards(list)
	self.seletSortKey:set(3)
	local func = EmbattleCardList.onSortCards(self, list) -- 原始函数
	return function (a, b)
		local statesA = a.states
		local statesB = b.states
		if statesA[1] <= 0 then return false end
		if statesB[1] <= 0 then return true end

		return func(a,b)
	end
end
function BraveChallengeEmbattleCardList:initFilterBtn()
	-- 筛选UI按钮
	self.filterCondition = idlertable.new()
	--true是降序，false升序
	self.tabOrder = idler.new(true)
	self.seletSortKey = idler.new(1)
	idlereasy.any({self.filterCondition, self.seletSortKey, self.tabOrder}, function()
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", false)
	end)
end

function BraveChallengeEmbattleCardList:initAllCards()
end

-- 按下
function BraveChallengeEmbattleCardList:onCardItemTouch(list, v, event)
	if event.name == "began" then
		self.moved = false
		self.touchBeganPos = event
		self.deleteMovingItem()
	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)
		if not self.moved and not self.isMovePanelExist() and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			-- 斜率不够或对象数量不足列表长度，判定为选中对象
			if deltaY > deltaX * 0.7 then
				local data = self.allCardDatas:atproxy(v.csvID)
				self.createMovePanel(data)
			end
			self.moved = true
		end
		self.cardList:setTouchEnabled(not self.isMovePanelExist())
		self.moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		if self.isMovePanelExist() == false and self.moved == false then --没有创建movePanel 说明是点击操作
			self.onCardClick(v, true)
			return
		end
		self.moveEndMovePanel(v)
	end
end


return BraveChallengeEmbattleCardList