
local function itemShow(list, node, k, v)
	bind.extend(list, node.iconBg, {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = v.logo,
			frameId = v.frame,
			level = false,
			vip = false,
			onNode = function(node)
				node:scale(0.8)
			end,
		}
	})
end

--春节红包领取详情
local ViewBase = cc.load("mvc").ViewBase
local RedPacketInfoView = class("RedPacketInfoView", Dialog)

RedPacketInfoView.RESOURCE_FILENAME = "activity_get_particulars.json"
RedPacketInfoView.RESOURCE_BINDING = {
	["close"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["item.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DULL_YELLOW, size = 2}}
		}
	},
	["item.rmb"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DULL_YELLOW, size = 2}}
		}
	},
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"bg",
						"name",
						"society",
						"gh",
						"luck",
						"rmb",
						"icon",
						"iconBg",
						"name1"
					)
					itemShow(list, childs, k, v)
					childs.name:text(v.name)
					if v.game_key then
						childs.name1:text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
					else
						childs.name1:hide()
					end
					adapt.oneLinePos(childs.name,childs.name1,cc.p(6,0))
					if v.union and string.len(v.union) == 0 then
						v.union = gLanguageCsv.nonunion
					end
					childs.gh:text(v.union)
					childs.luck:visible(v.lickId == v.id)
					childs.rmb:text(v.val)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onBtnClick")
			},
		},
	},
	["name"] = "name",
	["name1"] = "name1",
	["benediction"] = "benediction",
	["anima"] = "anima",
	["oneself"] = "oneself",
}

function RedPacketInfoView:onCreate(param, cb)
	if not param then return end
	self.cb = cb
	self.tabDatas = idlers.newWithMap({})
	local paramtab = {}
	paramtab = clone(param.members)
	self.tabDatas:update(paramtab)

	--自己信息
	self.name:text(param.role_name)
	if param.game_key then
		self.name1:text(string.format(gLanguageCsv.brackets, getServerArea(param.game_key, true)))
	else
		self.name1:hide()
	end
	adapt.oneLinePos(self.name,self.name1,cc.p(6,0))
	self.benediction:text(param.message)
	local oneselfTab = {}
	oneselfTab.logo = param.role_logo
	oneselfTab.frame = param.role_frame
	local childs = self.oneself:multiget("iconBg")
	itemShow(self, childs, nil, oneselfTab)

	Dialog.onCreate(self)
end

function RedPacketInfoView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end
return RedPacketInfoView