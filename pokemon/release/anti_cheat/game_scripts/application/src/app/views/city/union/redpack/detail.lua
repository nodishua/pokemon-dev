-- @date:   2019-06-10
-- @desc:   公会红包详细信息界面

local UnionRedPackDetailView = class("UnionRedPackDetailView", Dialog)

UnionRedPackDetailView.RESOURCE_FILENAME = "union_redpack_info.json"
UnionRedPackDetailView.RESOURCE_BINDING = {
	["imgBG"] = "imgBG",
	["imgInnerBg"] = "imgInnerBg",
	["title.textTitle1"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("sendName"),
			},
			{
				event = "visible",
				idler = bindHelper.self("showName"),
			},
		},
	},
	["title.textTitle2"] = {
		varname = "textTitle2",
		binds = {
			event = "text",
			idler = bindHelper.self("desc"),
		},
	},
	["tetxTip"] = {
		varname = "tetxTip",
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip")
		},
	},
	["info"] = "infoPanel",
	["info.tetxNum1"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("getNum"),
		},
	},
	["info.tetxNum2"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("allNUm"),
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("packDatas"),
				item = bindHelper.self("item"),
				topRoleName = bindHelper.self("topRoleName"),
				info = bindHelper.self("info"),
				onItem = function(list, node, k, v)
					node:get("textName"):text(v.name)
					node:get("textNum"):text(v.val)
					node:get("imgFlag"):visible(v.name == list.topRoleName)
					local path = dataEasy.getIconResByKey(list.info.key)
					node:get("imgIcon"):texture(path)
					adapt.oneLinePos(node:get("imgIcon"), node:get("textNum"), cc.p(5, 0), "right")
				end,
			},
		},
	},
}

function UnionRedPackDetailView:onCreate(info, membersInfo)
	local showType = info.showType or 1
	if showType == 2 then
		self.imgBG:texture("city/union/redpack/img_hb2_h@.png")
		self.imgInnerBg:texture("city/union/redpack/box_d2.png")
	end
	self.info = info
	self.sendName = idler.new(string.format(gLanguageCsv.redpackSender, info.role_name))
	self.desc = idler.new(info.text)
	self.showTip = idler.new(info.used_count == info.total_count)
	local showName = false
	if string.len(info.role_name or "") > 0  then
		showName = true
	end
	local posy = 80
	if showName then
		posy = 26
	end
	self.textTitle2:y(posy)
	self.showName = idler.new(showName)
	self.getNum = idler.new(string.format("%d/%d", info.used_count, info.total_count))
	self.allNUm = idler.new(string.format("%d/%d", info.used_val, info.total_val))
	self.infoPanel:get("tetxNum1"):text(self.getNum:read())
	self.infoPanel:get("tetxNum2"):text(self.allNUm:read())
	adapt.oneLinePos(self.infoPanel:get("tetxNote1"),{self.infoPanel:get("tetxNum1"),self.infoPanel:get("tetxNote2"),self.infoPanel:get("tetxNum2"),})
	self.packDatas = idlers.newWithMap(membersInfo)
	self.topRoleName = info.top_role_name
	if not self.topRoleName then
		local max = 0
		for _, v in ipairs(info.members) do
			if membersInfo[v] then
				if membersInfo[v].val > max then
					max = membersInfo[v].val
					self.topRoleName = membersInfo[v].name
				end
			end
		end
	end

	idlereasy.when(self.showTip, function(_, showTip)
		local posy = 800
		if showTip then
			posy = 766
		end
		self.infoPanel:y(posy)
	end)

	Dialog.onCreate(self)
end

return UnionRedPackDetailView