-- @date:   2021-06-09
-- @desc:   沙滩刨冰 -- 排行榜
local BeachIceRankView = class("BeachIceRankView",Dialog)


BeachIceRankView.RESOURCE_FILENAME = "beach_ice_rank.json"
BeachIceRankView.RESOURCE_BINDING = {
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
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, index, v)
					local childs = node:multiget("rank", "head", "name", "Lv", "Lv1", "score", "txtRank", "score", "area", "vip")
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
					childs.name:text(v.name)
					if v.vip > 0 then
						childs.vip:texture("common/icon/vip/icon_vip" .. v.vip .. ".png"):show()
						adapt.oneLinePos(childs.name, childs.vip, cc.p(10, 0))
					else
						childs.vip:hide()
					end
					childs.Lv1:text(v.level)
					childs.score:text(v.rank_data[1])
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(20,0))
				end,
				asyncPreload = 10,
			},
		},
	},
	["right"] = "right",
	["right.rank.down.rank"] = "myRank",
	["right.rank.down.name"] = "myName",
	["right.rank.down.area"] = "myArea",
	["right.rank.down.high"] = "myHigh",
}

function BeachIceRankView:onCreate(params, activityID)
	self.yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yydata = self.yyhuodongs[activityID] or {}
	local info = yydata.info or {}
	self.rankData = idlers.newWithMap(params.ranking or {})
	if itertools.size(params.ranking) ~= 0 then
		self.right:get("rank"):show()
		self.right:get("noRank"):hide()
		if params.rank and params.rank ~= 0 then
			self.myRank:text(params.rank)
			self.myHigh:text(info.score or 0)
		else
			self.myRank:text("--")
			self.myHigh:text("--")
		end
		self.myName:text(gGameModel.role:read("name"))
		self.myArea:text(getServerArea(userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})))
	else
		self.right:get("rank"):hide()
		self.right:get("noRank"):show()
	end

	Dialog.onCreate(self)

end

return BeachIceRankView