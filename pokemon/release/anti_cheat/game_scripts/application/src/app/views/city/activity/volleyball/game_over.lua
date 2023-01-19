local RES = {
	[0] = {
		result = "effect_shibai_loop",
		bg2 = "activity/volleyball/bg_sb.png",
		bg = "city/pvp/reward/bg_pvp_lose.png",
		animation = "standby_loop"
	},
	[1] = {
		result = "effect_chenggong_loop",
		bg2 = "city/pvp/reward/bg_role.png",
		bg = "city/pvp/reward/bg_pvp_win.png",
		animation = "win_loop"
	},
}

--沙滩排球游戏结束
local ViewBase = cc.load("mvc").ViewBase
local VolleyballGameOver = class("VolleyballGameOver", ViewBase)

VolleyballGameOver.RESOURCE_FILENAME = "volleyball_end.json"
VolleyballGameOver.RESOURCE_BINDING = {

	["btnBack"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackClick")},
		},
	},
	["btnAgain"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainClick")},
		},
	},
	["score"] = {
		varname = "score",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(0, 0, 0, 30), size = 8}, color = ui.COLORS.WHITE}
		}
	},
	["img"] = "img",
	["result"] = "result",
	["bg2"] = "bg2",
	["bg"] = "bg",
	["btnBack.back"] = {
		varname = "back",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(82, 76, 85, 255), size = 4}}
		}
	},
	["btnAgain.again"] = {
		varname = "again",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(82, 76, 85, 255), size = 4}}
		}
	},

}

function VolleyballGameOver:onCreate(parent, data)
	-- 0输 1赢
	self.parent = parent
	local info = RES[data.result]

	widget.addAnimationByKey(self.result, "volleyball_result/tiaozhan.skel", "resultEffect", info.result, 5)
		:alignCenter(self.result:size())
		:scale(1)

	self.bg2:texture(info.bg2)
	self.bg:texture(info.bg)
	widget.addAnimationByKey(self.img, csv.unit[data.unitId].unitRes, nil, info.animation, 5)
		:alignCenter(self.img:size())
		:scale(4)
	self.score:text(string.format("%d : %d", data.score[1], data.score[2]))
end


function VolleyballGameOver:onPanelClick()
	self.parent:onClose()
end

function VolleyballGameOver:onBackClick()
	self.parent:onClose()
end

function VolleyballGameOver:onAgainClick()
	self.parent:resetGame()
	ViewBase.onClose(self)
end

return VolleyballGameOver

