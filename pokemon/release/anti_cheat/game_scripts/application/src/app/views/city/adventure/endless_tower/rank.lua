-- @date:   2019-05-23
-- @desc:   无尽塔-排行榜

local EndlessTowerRank = class("EndlessTowerRank", Dialog)
EndlessTowerRank.RESOURCE_FILENAME = "endless_tower_rank.json"
EndlessTowerRank.RESOURCE_BINDING = {
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
				asyncPreload = 6,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				endlessRank = bindHelper.self("endlessRank"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local endlessRank = list.endlessRank:read()
					local childs = node:multiget(
						"rankImg",
						"logo",
						"textRank1",
						"textRank2",
						"roleName",
						"vip",
						"battle",
						"level",
						"gate"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							frameId = v.role.frame,
							level = false,
							vip = false
						}
					})
					uiEasy.setRankIcon(k, childs.rankImg, childs.textRank1, childs.textRank2)
					childs.roleName:text(v.role.name)
					childs.vip:texture(ui.VIP_ICON[v.role.vip_level]):visible(v.role.vip_level>0)
					childs.battle:text(v.fighting_point)
					childs.level:text(v.role.level)
					if v.endless ~= 0 then
						local gateTxt = csv.endless_tower_scene[v.endless].sceneName
						childs.gate:text(gateTxt)
					end
					adapt.oneLinePos(childs.roleName, childs.vip, cc.p(15, 0))

					childs.logo:setTouchEnabled(endlessRank ~= k)
					childs.logo:onClick(functools.partial(list.clickCell, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["rottomPanel"] = "rottomPanel",
	["textPoint"] = "textPoint",
	["textLv"] = "textLv",
}

function EndlessTowerRank:onCreate(rankDatas)
	self:initModel()
	self.rankDatas = rankDatas

	self.textPoint:hide()
	self.textLv:hide()

	local rankTxt = self.endlessRank:read() == 0 and gLanguageCsv.notOnTheList or self.endlessRank:read()
	self.rottomPanel:get("rank"):text(rankTxt)

	self.rottomPanel:get("roleName"):text(self.roleName:read())
	self.rottomPanel:get("battle"):text(self.fightingPoint:read())
	local gateTxt = self.maxGateId:read() == 0 and gLanguageCsv.notCleared or csv.endless_tower_scene[self.maxGateId:read()].sceneName
	self.rottomPanel:get("gate"):text(gateTxt)

	Dialog.onCreate(self)
end

function EndlessTowerRank:initModel()
	self.endlessRank = gGameModel.role:getIdler("endless_rank")
	self.roleName = gGameModel.role:getIdler("name")
	self.fightingPoint = gGameModel.role:getIdler("top6_fighting_point")
	--已挑战的最大关卡id
	self.maxGateId = gGameModel.role:getIdler("endless_tower_max_gate")
end

function EndlessTowerRank:onItemClick(list, k, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = v.role}, {speical = "rank", target = list.item:get("bg")})
end

return EndlessTowerRank
