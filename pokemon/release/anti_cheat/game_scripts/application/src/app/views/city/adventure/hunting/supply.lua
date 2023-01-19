-- @date:   2021-05-10
-- @desc:   狩猎地带 --- supply

local SUPPLY_CONTENT = {
	[1] = gLanguageCsv.huntingCureTips,
    [2] = gLanguageCsv.huntingCureTips,
	[3] = gLanguageCsv.huntingReviveTips,
}

local QUALITY_TYPE = {
    [1] = {res = "city/adventure/hunting/box_green.png", color = cc.c4b(68, 185, 117, 255),},
    [2] = {res = "city/adventure/hunting/box_yellow.png", color = cc.c4b(202, 153, 35, 255),},
    [3] = {res = "city/adventure/hunting/box_blue.png", color = cc.c4b(65, 142, 177, 255),},
    [4] = {res = "city/adventure/hunting/box_orange.png", color = cc.c4b(227, 118, 84, 255),},
    [5] = {res = "city/adventure/hunting/box_pink.png", color = cc.c4b(217, 85, 118, 255),},
    [6] = {res = "city/adventure/hunting/box_purple.png", color = cc.c4b(165, 82, 193, 255),},
    [7] = {res = "city/adventure/hunting/box_red.png", color = cc.c4b(227, 98, 91, 255),},
}
local SUPPLY_TYPE = {
    single = 1,
    all = 2,
    resurrect = 3
}
local ViewBase = cc.load("mvc").ViewBase
local HuntingSupplyView = class("HuntingSupplyView",ViewBase)

HuntingSupplyView.RESOURCE_FILENAME = "hunting_supply.json"

HuntingSupplyView.RESOURCE_BINDING = {
    ["title"] = {
        binds = {
            event = "effect",
            data = {outline = {color = cc.c4b(192, 91, 69, 255),  size = 4}}
        }
    },
    ["item"] = "item",
    ["list"] = {
        varname = "list",
        binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 10,
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
                    local childs = node:multiget("bg", "name","icon","select","text")
                    childs.select:visible(v.isSel)
                    childs.name:text(v.name)
                    --名字颜色
                    text.addEffect(childs.name, {color = QUALITY_TYPE[v.quality].color})
                    childs.bg:texture(QUALITY_TYPE[v.quality].res)
                    childs.icon:texture(v.icon)
                    childs.text:removeChildByName("richText")
                    local richText = rich.createByStr("#C0x5B545B#" .. v.desc, 40, nil)
                        :xy(childs.text:width() / 2, childs.text:y() / 2 )
                        :anchorPoint(0.5, 0.5)
                        :addTo(childs.text, 100, "richText")
                        :formatText()
                    childs.text:text("")
                    bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
			},
            handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
    },
    ["btnSure"] = {
        varname = "eventSure",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSure")}
		},
	},
}


function HuntingSupplyView:onCreate(params, cb)
    self.params = params
    self.cb = cb
    self:initModel()
    self.selectNum:addListener(function(val, oldval)
		if self.eventDatas:atproxy(oldval) then
			self.eventDatas:atproxy(oldval).isSel = false
		end
		if self.eventDatas:atproxy(val) then
			self.eventDatas:atproxy(val).isSel = true
		end
	end)
end

function HuntingSupplyView:onClose()
	self:addCallbackOnExit(self.cb, true)
	ViewBase.onClose(self)
	return self
end

function HuntingSupplyView:initModel()
    self.selectNum = idler.new(1)
    self.eventDatas = idlers.newWithMap({})
    local datas = {}
    for k,v in orderCsvPairs(csv.cross.hunting.supply) do
        if v.group == self.params.group then
            table.insert(datas, {
                id = k,
                name = v.name,
                type = v.type,
                icon = v.icon,
                desc = v.desc,
                quality = v.quality,
                isSel = false,
        })
        end
    end
    self.eventDatas:update(datas)
end

function HuntingSupplyView:onItemClick(list, k, v)
    self.selectNum:set(k)
end

function HuntingSupplyView:onSure()
    local cfg = csv.cross.hunting.supply[self.selectNum:read()]
    local cardStates = gGameModel.hunting:read("hunting_route")[self.params.route].card_states or {}
    local canResurrect = false
    local canSingle = false
    for _,val  in pairs(cardStates) do
        if val[1] < 1 and val[1] > 0 then
            canSingle = true
        elseif val[1] == 0 then
            canResurrect = true
        end
    end
    -- end
    local callbacks = function()
        gGameApp:requestServer("/game/hunting/supply", function(tb)
            self:onClose()
        end, self.params.route, self.params.node, self.eventDatas:atproxy(self.selectNum:read()).id)
    end
    local params = {
        size = {width = 850, height = 460},
        cb = callbacks,
        isRich = false,
        btnType = 2,
        content = SUPPLY_CONTENT[cfg.type],
        dialogParams = {clickClose = false},
    }

    if cfg.type == SUPPLY_TYPE.single then
        if canSingle then
            gGameUI:stackUI("city.adventure.hunting.supply_detail", nil, nil, {route = self.params.route, node = self.params.node,  cb = self:createHandler("onClose") , type = SUPPLY_TYPE.single, csvId = self.eventDatas:atproxy(self.selectNum:read()).id})
        else
            gGameUI:showDialog(params)
        end
    elseif cfg.type == SUPPLY_TYPE.all then
            if canSingle then
                gGameApp:requestServer("/game/hunting/supply", function(tb)
                    self:onClose()
                end, self.params.route, self.params.node, self.eventDatas:atproxy(self.selectNum:read()).id)
            else
                gGameUI:showDialog(params)
            end
    elseif cfg.type == SUPPLY_TYPE.resurrect then
        if canResurrect then
            gGameUI:stackUI("city.adventure.hunting.supply_detail", nil, nil, {route = self.params.route, node = self.params.node,  cb = self:createHandler("onClose") , type = SUPPLY_TYPE.resurrect, csvId = self.eventDatas:atproxy(self.selectNum:read()).id})
        else
            gGameUI:showDialog(params)
        end
    end
end

return HuntingSupplyView