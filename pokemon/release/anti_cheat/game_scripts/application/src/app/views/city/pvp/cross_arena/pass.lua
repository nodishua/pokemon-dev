-- @date: 2020-6-23
-- @desc: 跨服竞技场碾压

local ViewBase = cc.load("mvc").ViewBase
local CrossArenaPass = class("CrossArenaPass", Dialog)
CrossArenaPass.RESOURCE_FILENAME = "cross_arena_pass.json"
CrossArenaPass.RESOURCE_BINDING = {
	["title"] = "titleLabel",
	["role1"] = "head1",
	["role2"] = "head2",
	["textName1"] = "textName1",
	["textName2"] = "textName2",
	["textLv1"] = {
		varname = "textLv1",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
			},
		},
	},
	["textLv2"] = {
		varname = "textLv2",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
			},
		},
	},

	["textNote1"] = {
		varname = "textNote1",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
			},
		},
	},
	["textNote2"] = {
		varname = "textNote2",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
			},
		},
	},

	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnOk.title"] = {
		varname = "btnText",
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}},
			},
		},
	},
}

function CrossArenaPass:onCreate(role1, role2)
	bind.extend(self, self.head1, {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = role1.logo,
			frameId = role1.frame,
			level = false,
			vip = false,
		}
	})
	bind.extend(self, self.head2, {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = role2.logo,
			frameId = role2.frame,
			level = false,
			vip = false,
		}
	})
	self.textLv1:text(role1.level)
	self.textLv2:text(role2.level)
	self.textName1:text(role1.name)
	self.textName2:text(role2.name)

	adapt.oneLineCenterPos(cc.p(self.textName1:x(), -52 + 720), {self.textNote1, self.textLv1}, cc.p(5,0))
	adapt.oneLineCenterPos(cc.p(self.textName2:x(), -52 + 720), {self.textNote2, self.textLv2}, cc.p(5,0))

	Dialog.onCreate(self)
end

function CrossArenaPass:onClose(  )
	Dialog.onClose(self)
end

return CrossArenaPass