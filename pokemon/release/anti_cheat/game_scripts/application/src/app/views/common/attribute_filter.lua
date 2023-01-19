--属性过滤（特攻，特防，生命，物攻，物防，速度）

local AttributeFilterView = class("AttributeFilterView", cc.load("mvc").ViewBase)

AttributeFilterView.RESOURCE_FILENAME = "common_influence_attr.json"
AttributeFilterView.RESOURCE_BINDING = {
	["sm"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(1)
			end)}
		},
	},
	["speed"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(13)
			end)}
		},
	},
	["wg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(7)
			end)}
		},
	},
	["wf"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(9)
			end)}
		},
	},
	["tg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(8)
			end)}
		},
	},
	["tf"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(10)
			end)}
		},
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnClose")}
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnClose")}
		},
	},
}

--selectDatas:选中数据, panelState是否关闭页面
function AttributeFilterView:onCreate(params)
	self.isShow = params.panelState
	self.selectDatas = params.selectDatas
end

function AttributeFilterView:atrributeBtn(id)
	self.selectDatas:set(id)
	self.isShow:set(false)
end
function AttributeFilterView:btnClose()
	self.isShow:set(false)
end

return AttributeFilterView