-- @date:   2019-06-10
-- @desc:   公会副本排行榜界面

local UnionGateRankView = class("UnionGateRankView", Dialog)

UnionGateRankView.RESOURCE_FILENAME = "union_gate_rank.json"
UnionGateRankView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["empty"] = "empty",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"iconRank",
						"textRank1",
						"textRank2",
						"logo",
						"textName",
						"level",
						"gate"
					)
					childs.logo:texture(v.unionLogo)
					childs.textName:text(v.unionName)
					childs.level:text(v.unionLevel)
					childs.gate:text(string.format(gLanguageCsv.howManyLevels, v.gateNum))
					uiEasy.setRankIcon(k, childs.iconRank, childs.textRank1, childs.textRank2)
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
	["rottomPanel"] = "rottomPanel",
}

function UnionGateRankView:onCreate(rankDatas)
	self:initModel()
	self.empty:hide()
	local tmpData = {}
	for k,v in pairs(rankDatas) do
		table.insert(tmpData, {
			gateNum = v[1],
			damage = v[2],
			time = v[3],
			unionName = v[4],
			unionLogo = csv.union.union_logo[v[5]].icon,
			unionLevel = v[6],
			dbid = k
		})
	end
	table.sort(tmpData, function(a, b)
		if a.gateNum ~= b.gateNum then
			return a.gateNum > b.gateNum
		end
		if a.damage ~= b.damage then
			return a.damage > b.damage
		end
		return a.time < b.time
	end)
	self.rankDatas = tmpData
	local unionId = self.unionId:read()
	self.rottomPanel:get("unionName"):text(self.unionName)
	for k,v in pairs(tmpData) do
		if unionId == v.dbid then
			self.rottomPanel:get("rank"):text(k)
			self.rottomPanel:get("unionName"):text(v.unionName)
			self.rottomPanel:get("gate"):text(string.format(gLanguageCsv.howManyLevels, v.gateNum))
		end
	end

	Dialog.onCreate(self)
end

function UnionGateRankView:initModel()
	local unionInfo = gGameModel.union
	self.unionId = unionInfo:getIdler("id")
	self.unionName = unionInfo:read("name")
end

function UnionGateRankView:onAfterBuild()
	self.empty:visible(itertools.isempty(self.rankDatas))
end

return UnionGateRankView