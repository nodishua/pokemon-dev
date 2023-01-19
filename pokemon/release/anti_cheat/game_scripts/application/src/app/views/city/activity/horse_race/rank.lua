-- @date:   2019-02-28
-- @desc:   竞技场-排行榜

local ICON_BG = {
	"common/icon/logo_yellow.png",
	"common/icon/logo_blue.png",
	"common/icon/logo_green.png",
	"common/icon/logo_gray.png",
}

local HorseRaceRankView = class("HorseRaceRankView", Dialog)
HorseRaceRankView.RESOURCE_FILENAME = "horse_race_rank.json"
HorseRaceRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["noRank"] = "noRank",
	["down"] = "downPanel",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 12,
				padding = 20,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local name = node:get("baseNode.textName"):text(v.name)
					local level = node:get("baseNode.textLv"):text(v.level)
					uiEasy.setRankIcon(k, node:get("baseNode.imgIcon"), node:get("baseNode.textRank1"), node:get("baseNode.textRank2"))
					node:get("baseNode.textFightPoint"):text(v.rank_data[1])
					node:get("baseNode.textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
					adapt.oneLinePos(name, {node:get("baseNode.textLvNote"),level}, cc.p(10, 0), "left")
					bind.extend(list, node:get("baseNode.head"), {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
						}
					})
					node:get("baseNode.textFightPoint"):text(v.fighting_point)
				end,
			},
		},
	},
}

function HorseRaceRankView:onCreate(activityId, rankDatas)
	self:initModel()
	self.rankDatas = idlers.new()
	self.rankDatas:update(rankDatas.ranking)
	local point = self.yyhuodongs[activityId].horse_race.point
	if rankDatas.my_rank and rankDatas.my_rank ~= 0 then
		self.downPanel:get("textRank"):text(rankDatas.my_rank)
	else
		self.downPanel:get("textRank"):text(gLanguageCsv.noRank)
	end
	if itertools.size(rankDatas.ranking) <= 0 then
		self.noRank:setVisible(true)
		self.downPanel:setVisible(false)
	else
		self.noRank:setVisible(false)
		self.downPanel:setVisible(true)
	end
	self.downPanel:get("textName"):text(self.name)
	self.downPanel:get("textFightPoint"):text(point or 0)

	Dialog.onCreate(self)
end

function HorseRaceRankView:initModel()
	self.yyhuodongs = gGameModel.role:read("yyhuodongs")
	self.name = gGameModel.role:read("name")

	-- self.record = gGameModel.arena:getIdler("record")
end


return HorseRaceRankView
