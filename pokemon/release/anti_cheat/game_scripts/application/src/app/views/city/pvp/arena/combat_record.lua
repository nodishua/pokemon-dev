-- @date:   2019-02-26
-- @desc:   竞技场-战斗记录

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.short_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local ArenaCombatRecordView = class("ArenaCombatRecordView", Dialog)
ArenaCombatRecordView.RESOURCE_FILENAME = "arena_combat_record.json"
ArenaCombatRecordView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("combatDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"head",
						"textName",
						"textFightPoint",
						"btnReplay",
						"btnShare",
						"imgFlag",
						"textTime",
						"textNum",
						"imgDownOrUp",
						"textLv"
					)
					childs.btnShare:visible(dataEasy.isUnlock(gUnlockCsv.battleShare))
					childs.textLv:text(v.enemyLevel)
					childs.textName:text(v.enemyName)
					childs.textFightPoint:text(v.enemyFight)
					childs.imgFlag:texture(v.result == "win" and "city/pvp/arena/txt_win.png" or "city/pvp/arena/txt_lose.png")

					childs.textTime:text(getStrTime(v.time))
					adapt.setTextScaleWithWidth(childs.textName, nil, 280)
					adapt.setTextScaleWithWidth(childs.textTime, nil, 500)
					if matchLanguage({"en"}) then
						childs.textTime:x(childs.textTime:x() + 80)
					end
					if v.result == "fail" then
						text.addEffect(childs.textNum, {color=cc.c4b(185, 35, 49, 255)})
					end
					childs.textNum:text(math.abs(v.move))
					childs.imgDownOrUp:texture(v.result == "win" and "common/icon/logo_arrow_green.png" or "common/icon/logo_arrow_red.png")
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.enemyLogo,
							frameId = v.enemyFrame,
							level = false,
							vip = false,
						}
					})
					text.addEffect(childs.btnReplay:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					text.addEffect(childs.btnShare:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
					bind.touch(list, childs.btnShare, {methods = {ended = functools.partial(list.shareBtn, k, v)}})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
				shareBtn = bindHelper.self("onShareClick"),
			},
		},
	},
	["emptyPanel"] = "emptyPanel",
}

function ArenaCombatRecordView:onCreate()
	self:initModel()
	self.emptyPanel:hide()
	self.combatDatas = self.record:read().history

	Dialog.onCreate(self)
end

function ArenaCombatRecordView:initModel()
	self.record = gGameModel.arena:getIdler("record")
end

function ArenaCombatRecordView:onPlaybackClick(list, k, v)
	local interface = "/game/pw/playrecord/get"
	gGameModel:playRecordBattle(v.playRecordID, nil, interface, 0, nil)
end

function ArenaCombatRecordView:onShareClick(list, k, v)
	uiEasy.shareBattleToChat(v.playRecordID, v.enemyName)
end

function ArenaCombatRecordView:onAfterBuild()
	self.emptyPanel:visible(self.list:getChildrenCount() == 0)
end

function ArenaCombatRecordView:onSortCards(list)
	return function(a, b)
		return a.time > b.time
	end
end

return ArenaCombatRecordView
