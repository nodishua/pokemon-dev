local BraveChallengeRankView = class('BraveChallengeRankView', Dialog)

BraveChallengeRankView.RESOURCE_FILENAME = 'activity_brave_challenge_rank.json'
BraveChallengeRankView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},

	["content.rank.item"] = "rankItem",   --  排行列表
	["content.rank.list"] = {
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
					local childs = node:multiget("rank", "txtRank", "head", "name", "Lv", "Lv1",
					  "fastRound", "ordMedal", "ordMedalNum", "rareMedal", "rareMedalNum", "imgLineup")
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
					node:get("area"):text(getServerArea(v.game_key))
					local role = v.role == 0 and 4 or v.role
					childs.name:text(v.name)
					childs.Lv1:text(v.level)
					adapt.oneLinePos(childs.Lv, childs.Lv1, cc.p(2, 0), "left")
					childs.fastRound:text(v.brave_challenge_rank_info.round)
					childs.ordMedalNum:text(v.brave_challenge_rank_info.badge_num)
					adapt.oneLinePos(childs.ordMedal, childs.ordMedalNum, cc.p(2, 0), "left")
					childs.rareMedalNum:text(v.brave_challenge_rank_info.rare_badge_num)
					adapt.oneLinePos(childs.rareMedal, childs.rareMedalNum, cc.p(2, 0), "left")
					bind.touch(list, childs.imgLineup, {methods = {ended = functools.partial(list.clickCell, node, v)}})
				end,
				asyncPreload = 10,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
		{
			event = "touch",
			methods = {ended = bindHelper.self("btnrightClose")}
		},
	},
	["content"] = "content",
	["content.rank.down.rank"] = "myRank",
	["content.rank.down.name"] = "myName",
	["content.rank.down.fastRound"] = "myFastRound",

}

function BraveChallengeRankView:onCreate(data)
	self.data = data
	self:resetShowPanel()
	self.contentColumnSize = 10
	self.rankList:setScrollBarEnabled(false)
	self.rankData = idlers.newWithMap(self.data.ranking or {})


	local rank = gGameModel.brave_challenge:read("rank")
	-- 排名
	if data.rank and data.rank ~= 0 then
		self.myRank:text(data.rank)
	else
		self.myRank:text(gLanguageCsv.noRank)
	end

	self.myName:text(gGameModel.role:read("name"))

	-- 最短回合
	if rank.round and rank.round ~= 0 then
		self.myFastRound:text(rank.round)
	else
		self.myFastRound:text("--")
	end

	Dialog.onCreate(self)
end

function BraveChallengeRankView:resetShowPanel()
	self.content:get("noRank"):visible(itertools.size(self.data.ranking) == 0)
	self.content:get("rank"):visible(itertools.size(self.data.ranking) ~= 0)
end

function BraveChallengeRankView:onItemClick(list, node, v)
	if gGameUI.itemDetailView then
		gGameUI.itemDetailView:onClose()
	end
	local name = "city.activity.brave_challenge.rank_detail"
	local canvasDir = "vertical"
	local childsName = {"baseNode"}

	local view = tip.create(name, nil, {relativeNode = node, canvasDir = canvasDir, childsName = childsName, dir = "right"}, v)
	view:onNodeEvent("exit", functools.partial(gGameUI.unModal, gGameUI, view))
	gGameUI:doModal(view)
	gGameUI.itemDetailView = view
end

return BraveChallengeRankView