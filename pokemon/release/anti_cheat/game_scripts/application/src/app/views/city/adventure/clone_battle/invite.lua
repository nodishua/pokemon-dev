-- @date:   2019-10-16
-- @desc:   克隆战(元素挑战)好友邀请页面

local SHOW_REUNION = {
	UNSHOW = 0,
	SHOW_REUNION = 1,
	SHOW_SENIRO = 2,
}

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleInviteView = class("CloneBattleInviteView", Dialog)

CloneBattleInviteView.RESOURCE_FILENAME = "clone_battle_friend_invite.json"
CloneBattleInviteView.RESOURCE_BINDING = {
	["item"] = "item",
	["empty"] = "empty",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("roles"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local children = node:multiget("icon", "name", "text1", "text2", "lv", "lvNumber", "btn", "reunionPanel")
					bind.extend(list, children.icon, {
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
						},
					})
					children.name:text(v.name)
					children.text2:text(v.battle_fighting_point)
					children.lvNumber:text(v.level)
					adapt.oneLinePos(children.name, {children.lv, children.lvNumber}, cc.p(15,0), "left")
					adapt.oneLinePos(children.text1, children.text2, cc.p(15,0), "left")
					children.btn:tag(k)
					bind.click(list, children.btn, {method = functools.partial(list.clickCell, children.btn, k, v)})
					text.addEffect(children.btn:get("text"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					children.reunionPanel:visible(v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW or false)
					if v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW then
						children.reunionPanel:get("label"):text(gLanguageCsv['reunionType'..v.reunionType])
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
}

function CloneBattleInviteView:getReunionType(roleID)
	local reunionStatue = SHOW_REUNION.UNSHOW
	if self.reunion and self.reunion.role_type == 1 and self.reunion.info and self.reunion.info.end_time - time.getTime() > 0
		and self.reunionBindRoleId and self.reunionBindRoleId == roleID then
		reunionStatue = SHOW_REUNION.SHOW_SENIRO
	elseif self.reunion and self.reunion.role_type == 2 and self.reunion.info and self.reunion.info.end_time - time.getTime() > 0
		and self.reunion.info.role_id == roleID then
		reunionStatue = SHOW_REUNION.SHOW_REUNION
	end
	return reunionStatue
end

function CloneBattleInviteView:onCreate(data, func)
	self.reunion = gGameModel.role:read("reunion")
	self.reunionBindRoleId = gGameModel.reunion_record:read("bind_role_db_id")
	self.roles = idlers.newWithMap({})
	local dataRoles = data.roles or {}
	for idx, role in ipairs(dataRoles) do
		dataRoles[idx].reunionType = self:getReunionType(role.id)
	end
	self.roles:update(dataRoles)
	self.func = func

	if data.size == 0 then
		self.empty:show()
		self.list:hide()
	end

	Dialog.onCreate(self, {clickClose = true})
end

function CloneBattleInviteView:onItemClick(list, btn, k, v)
	self.func(v, self, btn)
end

return CloneBattleInviteView





