-- @date:   2019-05-21
-- @desc:   无尽塔-战斗录像

local EndlessTowerBattleVideo = class("EndlessTowerBattleVideo", Dialog)
EndlessTowerBattleVideo.RESOURCE_FILENAME = "endless_tower_battle_video.json"
EndlessTowerBattleVideo.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
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
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"logo",
						"roleName",
						"vip",
						"battle",
						"rounds",
						"btn"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
							onNode = function(node)
								node:scale(0.9)
							end,
						}
					})
					childs.roleName:text(v.name)
					childs.vip:texture(ui.VIP_ICON[v.vip]):visible(v.vip > 0)
					childs.battle:text(v.fighting_point)
					childs.rounds:text(v.round)
					if v.vip > 0 then
						childs.vip:texture(ui.VIP_ICON[v.vip])
						adapt.oneLinePos(childs.roleName, childs.vip, cc.p(15, 0))
					end

					bind.touch(list, childs.btn, {methods = {ended = functools.partial(list.playBtn, k, v)}})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				playBtn = bindHelper.self("onPlayClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["icon"] = "icon",
}

function EndlessTowerBattleVideo:onCreate(combatDatas)
	self.combatDatas = combatDatas

	Dialog.onCreate(self)
end


function EndlessTowerBattleVideo:onPlayClick(list, k, v)
	local reqBattleRecord
	reqBattleRecord = function(battle,data,isFirst)
		battleEntrance.battleRecord(data, battle.result, {noShowEndRewards = true})
			:preCheck(nil, function()
				if isFirst then
					-- 战报修正 第一次失败强行修正
					for attr, _ in pairs(game.ATTRDEF_ENUM_TABLE) do
						for _, attrData in pairs(data.roleOut) do
							if attrData[attr] then
								attrData[attr] = attrData[attr] * gCommonConfigCsv.preCheckFailAttrFix
							end
						end
					end
					data.endlessAttrFix = true
					reqBattleRecord(battle,data)
				else
					gGameUI:showTip(gLanguageCsv.crossCraftPlayNotExisted)
				end
			end)
			:show()
	end

	gGameApp:requestServer("/game/endless/play/detail",function (tb)
		local battle = gGameModel:getEndlessPlayRecord(v.play_id)
		local data = battle:getData()
		reqBattleRecord(battle,data,true)
	end,v.play_id)
end

function EndlessTowerBattleVideo:onAfterBuild()
	self.icon:visible(self.list:getChildrenCount() == 0)
end

return EndlessTowerBattleVideo
