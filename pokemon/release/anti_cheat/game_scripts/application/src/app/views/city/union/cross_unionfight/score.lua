-- @date:   2021-09-08
-- @desc:   1.公会战积分排名界面
local ScoreView = class("ScoreView", Dialog)

ScoreView.RESOURCE_FILENAME = "cross_union_fight_score.json"
ScoreView.RESOURCE_BINDING = {
    ["noRank"] = "noRank",
    ["item"] = "item",
    ["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("rankIcon", "unionIcon", "unionName", "point", "bg", "bg1", "rankNum", "includeImg")
					childs.unionName:text(v.union_name)
                    childs.point:text(v.point)
                    if k <= 3 then
						childs.rankIcon:texture(ui.RANK_ICON[k])
					elseif k<= 10 then
						childs.rankIcon:texture(ui.RANK_ICON[4])
						childs.rankNum:text(k)
					else
						childs.rankIcon:hide()
						childs.rankNum:text(k)
						text.addEffect(childs.rankNum, {color = ui.COLORS.NORMAL.DEFAULT})
					end
					childs.bg:visible(v.color == nil)
					childs.bg1:visible(v.color ~= nil)
					childs.includeImg:visible(v.include ~= nil)
                    childs.unionIcon:texture(csv.union.union_logo[v.union_logo].icon)
				end,
			},
		},
	},
}

function ScoreView:onCreate(parmas)
    Dialog.onCreate(self)
	self.item:hide()
	self.data = {}
    self.showData = idlers.newWithMap({})
	local union_db_id = parmas.union_db_ids or {}
	local userUnionId = gGameModel.role:read("union_db_id")
	local colorIdx
	local includeIdx = {}
	for i, v in ipairs(parmas.rank) do
		table.insert(self.data, v)
	end
	if not itertools.isempty(self.data) then
		for i, v in ipairs(self.data) do
			if userUnionId == v.union_db_id then
				colorIdx = i
			end
			for ni, nv in pairs(union_db_id) do
				if nv == v.union_db_id then
					includeIdx[i] = 1
				end
			end
		end
		self.showData:update(self.data)
		if colorIdx then
			self.showData:atproxy(colorIdx).color = 1
		end
		for k, v in pairs(includeIdx) do
			self.showData:atproxy(k).include = 1
		end
	end
	if itertools.isempty(parmas.rank) then
		self.noRank:show()
	end
end

return ScoreView