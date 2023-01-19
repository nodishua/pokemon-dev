--
-- @desc 以太布阵下边操作
--
local EmbattleCardList = require "app.views.city.card.embattle.embattle_card_list"

local SummerChallengeEmbattleCardList = class("EmbattleCardList", EmbattleCardList)
SummerChallengeEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
SummerChallengeEmbattleCardList.RESOURCE_BINDING = {
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
				padding = 4,
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
	["btnPanel"] = "btnPanel",
}

function SummerChallengeEmbattleCardList:initItem(list, node, k, v)
	local size = node:size()
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unit_id,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			grayState = (v.battle == 1) and 1 or 0,
			levelProps = {
				data = v.level,
			},
			lock = v.lock >= 0,
			onNode = function(panel)
				local size = panel:size()
				panel:xy(-4, -4)
				local lockPanel = panel:get("lock")
				lockPanel:scale(1)
				lockPanel:xy(size.width - 30, size.height - 30)
			end,
		}
	})
	local textNote = node:get("textNote")
	textNote:visible(v.battle == 1)
	uiEasy.addTextEffect1(textNote)

	node:onTouch(functools.partial(list.clickCell, v))
end

function SummerChallengeEmbattleCardList:initFilterBtn()
	self.filterCondition = idlertable.new()
	--true是降序，false升序
	self.tabOrder = idler.new(true)
	self.seletSortKey = idler.new(1)
end

function SummerChallengeEmbattleCardList:initAllCards()
end

-- 按下
function SummerChallengeEmbattleCardList:onCardItemTouch(list, v, event)
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


return SummerChallengeEmbattleCardList