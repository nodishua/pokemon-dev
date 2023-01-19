local TrainAttrAdd = class("TrainAttrAdd", Dialog)

TrainAttrAdd.RESOURCE_FILENAME = "trainer_attr.json"
TrainAttrAdd.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("icon", "name")
					local attr = game.ATTRDEF_TABLE[v.id]
					childs.icon:texture(ui.ATTR_LOGO[attr])
					childs.name:text(getLanguageAttr(v.id).." +"..dataEasy.getAttrValueString(v.id, v.num))
				end,
				asyncPreload = 6,
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["name"] = "nodeName",
	["pos"] = "pos"
}

function TrainAttrAdd:onCreate(params)
	self.data = params()
	local t = {}
	for i,v in csvPairs(self.data.cfg.attrs) do
		table.insert(t, {id = i, num = v})
	end
	self.attrDatas = idlertable.new(t)
	self.nodeName:text(self.data.cfg.name)
	-- 特效文件分两个1-6为第一个，7-12为第二个
	local skelName = self.data.level < 7 and "1_6" or "7_12"
	widget.addAnimation(self.pos, "kapai/kapai"..skelName..".skel", tostring(self.data.level).."_loop", 2)
		:alignCenter(self.pos:size())
		:scale(0.7)
	Dialog.onCreate(self)
end

return TrainAttrAdd
