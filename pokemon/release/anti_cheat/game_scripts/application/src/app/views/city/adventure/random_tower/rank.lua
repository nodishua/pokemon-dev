-- @date:   2019-10-12
-- @desc:   随机塔-排行榜

local ICON_BG = {
	"common/icon/logo_yellow.png",
	"common/icon/logo_blue.png",
	"common/icon/logo_green.png",
	"common/icon/logo_gray.png",
}
local function setFloor(room, textProgressNote, textProgress)
	--层数 房间位置 最大房间数
	local floor = 0
	local roomIdx = 0
	local floorMax = 0
	if room then
		floor = csv.random_tower.tower[room].floor
		roomIdx = csv.random_tower.tower[room].roomIdx
		floorMax = gRandomTowerFloorMax[floor]
	end
	textProgressNote:text(string.format(gLanguageCsv.randomTowerSomeFloor, floor))
	textProgress:text(roomIdx .. "/" .. floorMax)
	adapt.oneLinePos(textProgressNote, textProgress, cc.p(5, 0))
end

local RandomTowerRankView = class("RandomTowerRankView", Dialog)
RandomTowerRankView.RESOURCE_FILENAME = "random_tower_rank.json"
RandomTowerRankView.RESOURCE_BINDING = {
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
			idler = bindHelper.self("roleName"),
		}
	},
	["down.textRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("dayRank"),
			method = function(rank)
				return rank > 0 and rank or gLanguageCsv.noRank
			end
		}
	},
	["down.textPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("dayPoint"),
		}
	},
	["down.textProgress"] = "textProgress",
	["down.textProgressNote"] = "textProgressNote",
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
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"imgIcon",
						"textRank1",
						"textRank2",
						"head",
						"textName",
						"imgVip",
						"textLv",
						"textPoint",
						"textProgress",
						"textProgressNote"
					)
					childs.textName:text(v.role.name)
					childs.imgVip:texture(ui.VIP_ICON[v.role.vip_level]):visible(v.role.vip_level > 0)
					adapt.oneLinePos(childs.textName, childs.imgVip, cc.p(5, 0))
					setFloor(v.random_tower.room, childs.textProgressNote, childs.textProgress)
					childs.textLv:text(v.role.level)
					uiEasy.setRankIcon(k, childs.imgIcon, childs.textRank1, childs.textRank2)

					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							frameId = v.role.frame,
							level = false,
							vip = false,
						}
					})
					childs.textPoint:text(v.random_tower.day_point)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function RandomTowerRankView:onCreate(rankDatas)
	self:initModel()
	self.rankDatas = rankDatas.rank
	setFloor(self.room:read(), self.textProgressNote, self.textProgress)
	Dialog.onCreate(self)
end

function RandomTowerRankView:initModel()
	self.dayRank = gGameModel.random_tower:getIdler("day_rank")
	self.dayPoint = gGameModel.random_tower:getIdler("day_point")
	self.room = gGameModel.random_tower:getIdler("room")
	self.roleName = gGameModel.role:getIdler("name")
end

return RandomTowerRankView
