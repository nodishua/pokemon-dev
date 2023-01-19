-- @date 2020-10-11
-- @desc 限时碎片转换选择界面

local ActivityQualityExchangeFragmentSelectView = class("ActivityQualityExchangeFragmentSelectView", Dialog)

ActivityQualityExchangeFragmentSelectView.RESOURCE_FILENAME = "activity_quality_exchange_helditem_select.json"
ActivityQualityExchangeFragmentSelectView.RESOURCE_BINDING = {
	['title'] = "title",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	['list'] = {
		varname = "list",
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 6,
				data = bindHelper.self('datas'),
				item = bindHelper.self('innerList'),
				cell = bindHelper.self('item'),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.num ~= b.num then
						return a.num > b.num
					end
					return a.key < b.key
				end,
				onCell = function(list, node, k, v)
					local name, effect = uiEasy.setIconName(v.key, v.num)
					node:get("name"):hide()
					node:removeChildByName("richName")
					local richName = beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
						:xy(node:get("name"):xy())
						:addTo(node, 10, "richName")
					text.addEffect(richName, effect)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(panel)
								if list.hasItemCb() then
									panel:setTouchEnabled(false)
								end
							end,
						},
					})
					if list.hasItemCb() then
						bind.touch(list, node:get("icon"), {methods = {ended = functools.partial(list.itemClick, k, v)}})
					end
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick'),
				hasItemCb = bindHelper.self('hasItemCb'),
			}
		}
	},
	["tipPanel"] = "tipPanel",
}

-- 显示限定品质的携带道具
function ActivityQualityExchangeFragmentSelectView:onCreate(params)
	self.params = params
	if self.params.title then
		self.title:get("textNote1"):text(self.params.title[1])
		self.title:get("textNote2"):text(self.params.title[2])
		adapt.oneLinePos(self.title:get("textNote1"), self.title:get("textNote2"))
	end
	self.datas = {}
	for k, v in ipairs(self.params.data) do
		if dataEasy.isFragmentCard(v.key) then
			table.insert(self.datas, v)
		end
	end
	self.hasItemCb = self.params.cb ~= nil

	self.tipPanel:visible(itertools.size(self.datas) == 0)
	if params.tip then
		self.tipPanel:get("textTip"):text(params.tip)
	end

	Dialog.onCreate(self)
end

function ActivityQualityExchangeFragmentSelectView:onItemClick(list, k, v)
	if self.params.cb then
		self.params.cb(v.key)
	end
	self:onClose()
end

return ActivityQualityExchangeFragmentSelectView