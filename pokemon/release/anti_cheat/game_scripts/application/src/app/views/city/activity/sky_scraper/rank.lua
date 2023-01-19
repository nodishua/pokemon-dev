local SkyScraperRank = class('SnowBallRank', Dialog)


SkyScraperRank.RESOURCE_FILENAME = 'sky_scraper_rank.json'
SkyScraperRank.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},

	["right.rank.item"] = "rankItem",
	["right.rank.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankData"),
				item = bindHelper.self("rankItem"),
				huodongId = bindHelper.self("huodongId"),
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, index, v)
					local childs = node:multiget("rank", "head", "name", "Lv", "Lv1", "score", "count", "txtRank", "floor", "imgSprite","area")
					-- 头像
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							level = false,
							vip = false,
							frameId = v.frame,
							onNode = function(node)
								node:xy(104, 95)
									:z(6)
									:scale(0.9)
							end,
						}
					})
					childs.area:text(getServerArea(v.game_key))
					-- 名次
					childs.rank:get("txt"):visible(index > 3)
					childs.rank:visible(index <= 10)
					childs.txtRank:visible(index > 10)
					if index == 1 then
						childs.rank:texture("city/rank/icon_jp.png")
					elseif index == 2 then
						childs.rank:texture("city/rank/icon_yp.png")
					elseif index == 3 then
						childs.rank:texture("city/rank/icon_tp.png")
					elseif index >= 4 and index <= 10 then
						childs.rank:texture("common/icon/icon_four.png")
						childs.rank:get("txt"):text(index)
					elseif index > 10 then
						childs.txtRank:text(index)
					end
					local maxLevel = 1
					local maxLevelRes
					for k, val in orderCsvPairs(csv.yunying.skyscraper_medals) do
						if val.huodongID == list.huodongId then
							maxLevel = val.medalLevel > maxLevel and val.medalLevel or maxLevel
							maxLevelRes = val.medalLevel == maxLevel and val.rankRes or maxLevelRes
						end
					end
					for k, val in orderCsvPairs(csv.yunying.skyscraper_medals) do
						if val.medalLevel == v.medallvl + 1 and val.huodongID == list.huodongId then
							childs.imgSprite:texture(val.rankRes)
							break
						end
					end
					if v.medallvl == maxLevel then
						childs.imgSprite:texture(maxLevelRes)
					end

					childs.name:text(v.name)
					childs.Lv1:text(v.level)
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(2, 0), "left")
					childs.score:text(v.high_score)
					childs.floor:text(string.format(gLanguageCsv.randomTowerSomeFloor, v.high_floor))
					adapt.oneLinePos(childs.name, {childs.Lv, childs.Lv1}, {cc.p(20,0), cc.p(0,0)})
				end,
				asyncPreload = 10,
			},
		},
	},
	["right"] = "right",
	["right.rank.txtRank"] = "txtRank",
	["right.rank.down.rank"] = "myRank",
	["right.rank.down.name"] = "myName",
	["right.rank.down.score"] = "myScore",
	["right.rank.down.floor"] = "myFloor",
	["right.rank.down.spriteName"] = "mySpriteName",
}



function SkyScraperRank:onCreate(activityId, data)
	self.data = data
	self:resetShowPanel()
	self.rightColumnSize = 10
	self.rankList:setScrollBarEnabled(false)
	self.rankData = idlers.newWithMap(self.data.top_scorers or {})
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	local yyCfg = csv.yunying.yyhuodong[activityId]
	self.huodongId = yyCfg.huodongID
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		self.yydata = yydata
		-- 我的排行
		local myData = yydata.info or {}
		if myData.rank and myData.rank ~= -1 then
			self.myRank:text(myData.rank)
		else
			self.myRank:text("--")
		end
		self.myName:text(gGameModel.role:read("name"))
		self.myScore:text(myData.high_points == 0 and "--" or myData.high_points)
		self.myFloor:text(myData.high_floors == 0 and "--" or string.format(gLanguageCsv.randomTowerSomeFloor, myData.high_floors))
		end)
 	Dialog.onCreate(self)
end

function SkyScraperRank:resetShowPanel()
	self.right:get("noRank"):visible(self.data.top_scorers[1] == nil)
	self.right:get("rank"):visible(self.data.top_scorers[1] ~= nil )
end

return SkyScraperRank