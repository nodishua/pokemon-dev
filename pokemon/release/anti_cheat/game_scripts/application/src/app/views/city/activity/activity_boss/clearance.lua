--节日Boos-通关玩家

local ViewBase = cc.load("mvc").ViewBase
local ActivityBossDetail = class("ActivityBossDetail", Dialog)

ActivityBossDetail.RESOURCE_FILENAME = "activity_boss_clearance.json"
ActivityBossDetail.RESOURCE_BINDING = {
    ["emptyPanel"] = "emptyPanel",
    ["centerPanel"] = "centerPanel",
    ["centerPanel.item"] = "item",
    ["centerPanel.list"] = {
        varname = "list",
        binds = { 
            event = "extend",
			class = "listview",
			props = {
				-- asyncPreload = 6,
				-- padding = 10,
				data = bindHelper.self("roleDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                    local childs = node:multiget(
						"icon",
						"name",
						"lvNum",
						"area",
						"fighting"
                    )
                    bind.extend(list, childs.icon, {
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
                    childs.name:text(v.name)
                    childs.lvNum:text(v.level)
					childs.area:text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key)))
					childs.area:x(childs.area:x() - 35)
                    childs.fighting:text(v.fight_point)
				end,
			}
        },
    },
    ["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},

}

function ActivityBossDetail:onCreate(datas)
	self.item:hide()
	self.roleDatas = datas
    self.emptyPanel:visible(#datas==0)
    self.centerPanel:visible(#datas > 0)
    Dialog.onCreate(self)

end


return ActivityBossDetail