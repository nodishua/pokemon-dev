local ViewBase = cc.load('mvc').ViewBase
local GemFilterView = class('GemFilterView', ViewBase)
GemFilterView.RESOURCE_FILENAME = 'gem_filter.json'

GemFilterView.RESOURCE_BINDING = {
	['subList'] = 'subList',
	['item'] = 'item',
	['window.list'] = {
		varname = 'list',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				data = bindHelper.self('showData'),
				columnSize = 4,
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				onCell = function(list, node, k, v)
					node:get('icon'):texture(v.icon)
					if v.selected then
						ccui.ImageView:create("common/box/box_selected.png")
						:alignCenter(node:size())
						:addTo(node, -1)
						:scale(0.6)
						:y(94)
					end
					node:get('name'):text(gLanguageCsv['gemSuit'..v.typeIdx])
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	['closePanel'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('closeWithoutSelect')}
		}
	},
	['window'] = 'window',
	['window.btnAll'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickAll')}
		}
	}
}

function GemFilterView:closeWithoutSelect()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

function GemFilterView:clickAll()
	self:addCallbackOnExit(functools.partial(self.cb, 0))
	ViewBase.onClose(self)
end

function GemFilterView:onItemClick(list, node, k, v)
	self:addCallbackOnExit(functools.partial(self.cb, v.typeIdx))
	ViewBase.onClose(self)
end

function GemFilterView:onCreate(pos, aligns, cb, curTypeIdx)
	aligns = aligns or {}
	local size = self.window:size()
	local dxs = {
		left = size.width / 2,
		right = - size.width / 2
	}
	local dys = {
		top = - size.height / 2,
		bottom = size.height / 2
	}
	local dx, dy = 0, 0
	for _, align in pairs(aligns) do
		if dxs[align] then
			dx = dxs[align]
		end
		if dys[align] then
			dy = dys[align]
		end
	end
	self.window:xy(pos.x + dx, pos.y + dy)

	self.showData = idlers.new()
	local data = {}
	for i = 1, 9 do
		table.insert(data, {icon = ui.GEM_SUIT_ICON[i], typeIdx = i, selected = i == curTypeIdx})
	end
	self.cb = cb
	self.list:setClippingEnabled(false)
	self.showData:update(data)
end

return GemFilterView