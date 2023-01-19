-- @date:   2021-06-13
-- @desc:   沙滩刨冰 -- 核对结果

local PIC_TYPE = {
	[1] = "activity/beach_ice/logo_wm.png",
	[2] = "activity/beach_ice/logo_lh.png",
	[3] = "activity/beach_ice/logo_xc.png",
	[4] = "activity/beach_ice/logo_xc.png",
	[5] = "activity/beach_ice/logo_xc.png",
}

local TITLE_TYPE = {
    [1] = gLanguageCsv.perfectService,
    [2] = gLanguageCsv.goodService,
    [3] = gLanguageCsv.defectiveService,
    [4] = gLanguageCsv.defectiveService,
    [5] = gLanguageCsv.defectiveService,
}

local ViewBase = cc.load("mvc").ViewBase
local BeachIceCheckView = class("BeachIceCheckView",ViewBase)

BeachIceCheckView.RESOURCE_FILENAME = "beach_ice_check.json"
BeachIceCheckView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["title"] = "title",
	["score"] = "score",
	["item"] = "item",
	["demandList"] = {
        varname = "demandList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("demand"),
                item = bindHelper.self("item"),
                onItem = function(list, node, k, v)
                    local cfg = csv.yunying.shaved_ice_items
                    node:get("icon"):texture(cfg[v].icon1)
                end,
                onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
            },
        },
    },
	["mineList"] = {
        varname = "mineList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("mineChoose"),
                item = bindHelper.self("item"),
                onItem = function(list, node, k, v)
                    local cfg = csv.yunying.shaved_ice_items
                    node:get("icon"):texture(cfg[v].icon1)
                end,
                onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
            },
        },
    },
	["cardIcon"] = "cardIcon",
	["resImg"] = "resImg",
}

function BeachIceCheckView:onCreate(param)
    self.cb = param.cb
    self.cardIcon:texture(csv.unit[param.unitID].iconSimple)
    self.cardIcon:scale(2)
    self.mineChoose = idlers.newWithMap(param.mineChoose)
    self.demand = idlers.newWithMap(param.demand)
    self.resImg:texture(PIC_TYPE[param.type])
    self.title:text(TITLE_TYPE[param.type])
    self.score:text(string.format(gLanguageCsv.bonusPoints, param.score))
    adapt.oneLinePos(self.cardIcon, self.title, cc.p(10, 0))
    performWithDelay(self, function()
        self:onClose()
    end, 2)
end

function BeachIceCheckView:onClose()
    if self.cb then
        self:addCallbackOnExit(self.cb)
    end
    ViewBase.onClose(self)
    self = nil
end

return BeachIceCheckView