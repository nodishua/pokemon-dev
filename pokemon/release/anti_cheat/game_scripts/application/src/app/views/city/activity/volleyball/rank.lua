local VolleyballRankView = class('VolleyballRankView', Dialog)

VolleyballRankView.RESOURCE_FILENAME = 'volleyball_rank.json'
VolleyballRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},

	["right.rank.item"] = "rankItem",   --  排行列表
	["right.rank.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankData"),
				item = bindHelper.self("rankItem"),
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, index, v)
					local childs = node:multiget("rank", "head", "name", "Lv", "Lv1", "areaSer", "txtRank", "times")
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

					-- 名次
					childs.rank:get("txt"):visible(index > 3)
					childs.rank:visible(index <= 10)
					childs.txtRank:visible(index > 10)
					local res = {"city/rank/icon_jp.png", "city/rank/icon_yp.png", "city/rank/icon_tp.png", "common/icon/icon_four.png"}
					if index < 4 then
						childs.rank:texture(res[index])
					elseif index >= 4 and index <= 10 then
						childs.rank:texture(res[4])
						childs.rank:get("txt"):text(index)
					elseif index > 10 then
						childs.txtRank:text(index)
					end

					childs.name:text(v.name)
					childs.Lv1:text(v.level)
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(2, 0), "left")
					childs.areaSer:text(getServerArea(v.game_key))
					childs.times:text(v.rank_data[1])
				end,
				asyncPreload = 10,
			},
		},
	},
	["right"] = "right",
	["right.rank.txtCount"] = "txtCount",
	["right.rank.down.rank"] = "myRank",
	["right.rank.down.name"] = "myName",
	["right.rank.down.areaSer"] = "myAreaSer",
	["right.rank.down.times"] = "myTimes",
	["right.rank.down.spriteName"] = "mySpriteName",
}

function VolleyballRankView:onCreate(data, myData)
	self.data = data
	self.ranking = data.ranking or {}
	self.rightColumnSize = 10
	self.rankData = idlers.newWithMap(self.ranking)

	self.rankList:setScrollBarEnabled(false)
	self:resetShowPanel()
	self:showMyRank(myData)

	Dialog.onCreate(self)
end

function VolleyballRankView:resetShowPanel()
	self.right:get("noRank"):visible(self.ranking[1] == nil)
	self.right:get("rank"):visible(self.ranking[1] ~= nil )
end

function VolleyballRankView:showMyRank(myData)
	-- 我的排行
	local data = self.data
	local text = (data.rank and data.rank ~= 0) and data.rank or gLanguageCsv.noRank
	self.myRank:text(text)
	self.myName:text(gGameModel.role:read("name"))
	local serverKey =  userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	self.myAreaSer:text(getServerArea(serverKey)) -- 区服

	local time = myData > 0 and myData or "--"
	self.myTimes:text(time)
end

return VolleyballRankView