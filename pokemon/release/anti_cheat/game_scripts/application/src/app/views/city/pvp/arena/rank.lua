-- @date:   2019-02-28
-- @desc:   竞技场-排行榜

local ICON_BG = {
	"common/icon/logo_yellow.png",
	"common/icon/logo_blue.png",
	"common/icon/logo_green.png",
	"common/icon/logo_gray.png",
}

local ArenaRankView = class("ArenaRankView", Dialog)
ArenaRankView.RESOURCE_FILENAME = "arena_rank.json"
ArenaRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["down.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("record"),
			method = function(record)
				return record.role_name
			end
		}
	},
	["down.textRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("record"),
			method = function(record)
				return record.rank
			end
		}
	},
	["down.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("record"),
			method = function(record)
				return record.fighting_point
			end
		}
	},
	["down.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("record"),
			method = function(record)
				return record.role_level
			end
		}
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 12,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				record = bindHelper.self("record"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local record = list.record:read()
					node:get("baseNode.textName"):text(v.name)
					node:get("baseNode.textLv"):text(v.level)
					uiEasy.setRankIcon(k, node:get("baseNode.imgIcon"), node:get("baseNode.textRank1"), node:get("baseNode.textRank2"))

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
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function ArenaRankView:onCreate(rankDatas)
	self:initModel()
	self.rankDatas = rankDatas.rank

	Dialog.onCreate(self)
end

function ArenaRankView:initModel()
	self.record = gGameModel.arena:getIdler("record")
end

function ArenaRankView:onItemClick(list, k, v)
	local isSelf = v.role_db_id == self.record:read().role_db_id
	if isSelf then
		return
	end
	gGameApp:requestServer("/game/pw/role/info", function(tb)
		gGameUI:stackUI("city.pvp.arena.personal_info", nil, nil, tb.view)
	end, v.record_id)
end

return ArenaRankView
