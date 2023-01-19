-- @date:   2020-02-28
-- @desc:   获赠记录

local UnionFragDonateRecordView = class("UnionFragDonateRecordView", Dialog)

UnionFragDonateRecordView.RESOURCE_FILENAME = "union_frag_donate_record.json"
UnionFragDonateRecordView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionFragDonateHistorys"),
				item = bindHelper.self("item"),
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"logo",
						"textName",
						"level",
						"donateTime",
						"fragPanel",
						"donateNote"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
							onNode = function(node)
								node:scale(0.9)
							end,
						}
					})
					childs.textName:text(v.name or "")
					local t = time.getDate(v.time)
					childs.donateTime:text(string.format(gLanguageCsv.fragDonateTime, t.month, t.day, t.hour, t.min))
					adapt.oneLinePos(childs.donateTime, childs.donateNote, cc.p(5, 0), "left")

					childs.level:text(v.level)
					bind.extend(list, childs.fragPanel, {
						event = "extend",
						class = "icon_key",
						props = {
							data = {
								key = v.frag,
								num = 1
							},
							onNode = function(node)
								node:scale(1)
							end,
						}
					})
				end,
				preloadCenter = bindHelper.self("lastIdx"),
			},
		},
	},
}

function UnionFragDonateRecordView:onCreate()
	self:initModel()
	Dialog.onCreate(self)
	self.lastIdx = idler.new(1)
	idlereasy.any({self.unionFragDonateHistorys}, function(_, unionFragDonateHistorysp)
		self.lastIdx:set(#unionFragDonateHistorysp)
	end)
end

function UnionFragDonateRecordView:initModel()
	self.unionFragDonateHistorys = gGameModel.role:getIdler("union_frag_donate_historys")
end

return UnionFragDonateRecordView