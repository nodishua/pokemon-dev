-- @date:   2019-03-07
-- @desc:   排行界面

local DailyActivityRankView = class("DailyActivityRankView", Dialog)
DailyActivityRankView.RESOURCE_FILENAME = "daily_activity_rank.json"
DailyActivityRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["down.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("myName"),
		}
	},
	["down.textRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("myRank"),
		}
	},
	["down.textPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("myScore"),
		}
	},
	["empty"] = "empty",
	["empty.txt2"] = "txtEmpty",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"imgIcon",
						"textRank",
						"head",
						"textName",
						"textPoint",
						"textLv"
					)
					childs.textName:text(v.name)
					childs.textLv:text(v.level)
					if k < 4 then
						childs.imgIcon:texture(ui.RANK_ICON[k])
						childs.textRank:hide()
					else
						childs.imgIcon:hide()
						childs.textRank:text(k)
					end

					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
							onNode = function(panel)
								panel:scale(0.9)
							end,
						},
					})
					childs.textPoint:text(v.score)
					node:setTouchEnabled(false)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
}

function DailyActivityRankView:onCreate(rankDatas)
	self:initModel()
	if matchLanguage({"en", "kr"}) then
        adapt.setTextAdaptWithSize(self.txtEmpty, {size = cc.size(450,200), vertical = "center", horizontal = "center", margin = -8})
    	self.txtEmpty:xy(self.txtEmpty:x() - 10, self.txtEmpty:y() - 15)
    end
	self.empty:hide()
	self.rankDatas = rankDatas.rank
	if rankDatas.myrank == 0 then
		rankDatas.myrank = gLanguageCsv.noRank
	end
	self.myRank = idler.new(rankDatas.myrank)
	if  rankDatas.score ~= 0 then
		self.myScore = idler.new(rankDatas.score)
	end

	Dialog.onCreate(self)
end

function DailyActivityRankView:initModel()
	self.myName = gGameModel.role:getIdler("name")
end

function DailyActivityRankView:onAfterBuild()
	self.empty:visible(itertools.isempty(self.rankDatas))
end

return DailyActivityRankView
