local SnowBallRank = class('SnowBallRank', Dialog)


SnowBallRank.RESOURCE_FILENAME = 'snow_ball_rank.json'
SnowBallRank.RESOURCE_BINDING = {
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
					local childs = node:multiget("rank", "head", "name", "Lv", "Lv1", "score", "count", "txtRank", "time", "imgSprite")
					-- 头像
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							level = false,
							vip = false,
							frameId = v.role.frame,
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
					local role = v.snowball.role == 0 and 4 or v.snowball.role
					local cardID = csv.yunying.snowball_element[role].attr.cardId
					local unitInfo = csv.unit[csv.cards[cardID].unitID]
					childs.imgSprite:texture(unitInfo.iconSimple)

					childs.name:text(v.role.name)
					childs.Lv1:text(v.role.level)
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(2, 0), "left")
					childs.score:text(v.snowball.point)
					local min = math.floor((v.snowball.time % 3600 ) / 60)
					local sec = math.floor(v.snowball.time % 60)
					local str = string.format("%02d:%02d", min, sec)
					childs.time:text(str)
				end,
				asyncPreload = 10,
			},
		},
	},
	["right"] = "right",
	["right.rank.txtCount"] = "txtCount",
	["right.rank.down.rank"] = "myRank",
	["right.rank.down.name"] = "myName",
	["right.rank.down.score"] = "myScore",
	["right.rank.down.time"] = "myTime",
	["right.rank.down.spriteName"] = "mySpriteName",

}



function SnowBallRank:onCreate(data, myData)
	self.data = data
	self:resetShowPanel()
	self.rightColumnSize = 10
	self.rankList:setScrollBarEnabled(false)
	self.rankData = idlers.newWithMap(self.data.rank or {})
	-- 我的排行
	if myData.rank and myData.rank ~= 0 then
		self.myRank:text(myData.rank)
	else
		self.myRank:text("--")
	end
	self.myName:text(gGameModel.role:read("name"))
	self.myScore:text(myData.top_point == 0 and "--" or myData.top_point)

	if myData.top_time and myData.top_time == 0 then
		self.myTime:text("--:--")
	else
		local min = math.floor((myData.top_time % 3600 ) / 60)
		local sec = math.floor(myData.top_time % 60)
		local str = string.format("%02d:%02d", min, sec)
		self.myTime:text(str)
	end

	if myData.top_role and myData.top_role ~= 0  then
		local cardID = csv.yunying.snowball_element[myData.top_role].attr.cardId
		local unitInfo = csv.unit[csv.cards[cardID].unitID]
		self.mySpriteName:text(unitInfo.name)
	else
		self.mySpriteName:text("")
	end
	Dialog.onCreate(self)
end

function SnowBallRank:resetShowPanel()
	self.right:get("noRank"):visible(self.data.rank[1] == nil)
	self.right:get("rank"):visible(self.data.rank[1] ~= nil )
end

return SnowBallRank