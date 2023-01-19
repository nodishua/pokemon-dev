-- @date: 2020-12-29
-- @desc:服务器排行榜

local ServerRankView = class("ServerRankView", cc.load("mvc").ViewBase)

local RANKCOLOR = {
	[1] = {
		color = cc.c3b(255, 214, 50),
		outline = cc.c3b(225, 140, 18),
	},
	[2] = {
		color = cc.c3b(78, 197, 253),
		outline = cc.c3b(97, 143, 179),
	},
	[3] = {
		color = cc.c3b(255, 176, 137),
		outline = cc.c3b(214, 135, 103),
	}
}

ServerRankView.RESOURCE_FILENAME = "cross_mine_server_rank.json"
ServerRankView.RESOURCE_BINDING = {
	["panel"] ={
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["rankPanel"] = "rankPanel",
	["rankPanel.item"] = "item",
	["rankPanel.listview"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankDates"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true, actionTime = 0.1},
				onItem = function(list, node, k, v)
					node:get("no"):text(k)
					if k < 4 then
						text.deleteAllEffect(node:get("no"))
						text.addEffect(node:get("no"), {color = RANKCOLOR[k].color, outline = {color = RANKCOLOR[k].outline}})
					end
					node:get("zone"):text(string.format("%s %s", getServerArea(v.servKey, nil, true), getServerName(v.servKey, true)))
					node:get("score"):text(v.score)
					node:get("bonus"):text(v.bonus)
					node:get("selfBg"):visible(isCurServerContainMerge(v.servKey))
				end
			},
		},
	},
}

function ServerRankView:onCreate()
	self:initModel()

	idlereasy.when(self.serverPoints, function(_, serverPoints)
		local datas = {}
		local AllScore = 0
		for k, val in pairs(serverPoints) do
			table.insert(datas, {servKey = k, score = val, bonus = 0})
			AllScore = AllScore + val
		end
		table.sort(datas, function (a, b)
			return a.score > b.score
		end)

		if #datas > 8 then
			printWarn("ServerRankView:onCreate #servers > 8")
		end
		local extraAward = csv.cross.mine.base[1].extraAward[#datas]
		for k, val in pairs(datas) do
			local name = string.format("serverAward%d", k)
			local baseAward = csv.cross.mine.base[1][name]
			local dynamicAward = math.floor(extraAward*val.score/AllScore)
			val.bonus = baseAward + dynamicAward
		end
		self.rankDates:update(datas)
	end)
end

function ServerRankView:initModel()
	self.serverPoints = gGameModel.cross_mine:getIdler("serverPoints")
	self.rankDates = idlers.new()
end

return ServerRankView