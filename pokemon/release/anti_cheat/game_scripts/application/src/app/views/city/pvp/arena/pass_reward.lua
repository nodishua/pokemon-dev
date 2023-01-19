local ArenaPassRewardView = class("ArenaPassRewardView", Dialog)

ArenaPassRewardView.RESOURCE_FILENAME = "arena_pass_reward.json"
ArenaPassRewardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnOK"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnOK.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["role1"] = {
		varname = "role1",
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				level = false,
				vip = false,
				onNode = function(node)
					node:y(node:y() + 30)
				end,
			},

		},
	},
	["role2"] = {
		varname = "role2",
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("enemyRoleLogo"),
				frameId = bindHelper.self("enemyFrameId"),
				level = false,
				vip = false,
				onNode = function(node)
					node:y(node:y() + 30)
				end,
			},
		},
	},
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "reward")
					childs.title:text(string.format(gLanguageCsv.battleTimes, k))
					local key, num = next(v)
					bind.extend(list, childs.reward, {
						class = "icon_key",
						props = {
							data = {
								key = key,
								num = num,
							},
						},
					})
				end,
			},
		},
	},
}

function ArenaPassRewardView:onCreate(enemyData, awardData)
	self.logoId = gGameModel.role:getIdler("logo")
	self.frameId = gGameModel.role:getIdler("frame")
	self.datas = awardData
	self.enemyRoleLogo = enemyData.logo
	self.enemyFrameId = enemyData.frame
	local level = gGameModel.role:read("level")
	local roleName = gGameModel.role:read("name")
	self:setRoleInfo(self.role1, roleName, level)
	self:setRoleInfo(self.role2, enemyData.name, enemyData.level)
	Dialog.onCreate(self)
end

function ArenaPassRewardView:setRoleInfo(node, name, level)
	node:get("level"):text("Lv" .. level)
	node:get("name"):text(name)
	text.addEffect(node:get("level"), {outline={color=ui.COLORS.OUTLINE.WHITE, size = 3}})
	text.addEffect(node:get("name"), {outline={color=ui.COLORS.OUTLINE.WHITE, size = 3}})
end

return ArenaPassRewardView