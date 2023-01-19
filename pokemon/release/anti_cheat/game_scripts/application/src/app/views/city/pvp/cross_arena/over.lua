-- @date 2020-5-25
-- @desc 跨服竞技场赛后展示界面
local ROLE_INFO = {
	[1] = {pos = cc.p(1055, 530), scale = 1.15},
	[2] = {pos = cc.p(496, 446), scale = 1.10},
	[3] = {pos = cc.p(1636, 446), scale = 1.10},
	[4] = {pos = cc.p(54, 306 ), scale = 1.0},
	[5] = {pos = cc.p(2136, 306), scale = 1.0},
	[6] = {pos = cc.p(1055, -90), scale = 1.10},
	[7] = {pos = cc.p(670, -40), scale = 1.0},
	[8] = {pos = cc.p(1460 , -40), scale = 1.0},
	[9] = {pos = cc.p(286, 32), scale = 0.95},
	[10] = {pos = cc.p(1872, 32), scale = 0.95},
 }

local ViewBase = cc.load("mvc").ViewBase
local OverView = class("OverView", ViewBase)

OverView.RESOURCE_FILENAME = "cross_arena_over.json"
OverView.RESOURCE_BINDING = {
	["centerPanel"] = "centerPanel",
	["textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}},
		},
	},
	["rolePanel1"] = "rolePanel1",
	["rolePanel1.textName"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 2}},
		},
	},
	["rolePanel1.textZl"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 2}},
		},
	},
	["rolePanel1.textServer"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(79, 72, 79, 255), size = 2}},
		},
	},

	["rolePanel2"] = "rolePanel2",
	["rolePanel2.textZl"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 2}},
		},
	},
	["rolePanel2.textStage"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 3}},
		},
	},
	["rolePanel2.textServer"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 2}},
		},
	},
}


function OverView:onCreate()
	self:initSpine()
	self:initModel()
	self.subView = {}
	self:initRole()
end

--初始化spine动画
function OverView:initSpine(  )
	--todo 动特资源
end

function OverView:initModel()
	self.round = gGameModel.cross_arena:getIdler("round")
	self.lastRanks = gGameModel.cross_arena:getIdler("lastRanks")
end

function OverView:initRole()
	local lastRanks = self.lastRanks:read()
	for i = 1, 3 do
		local role = lastRanks[i]
		if role == nil then
			break
		end
		local panel = self.rolePanel1:clone()
			:addTo(self.centerPanel)
			:xy(ROLE_INFO[i].pos)
			:name("role_"..i)
		panel:get("textName"):text(role.name)
		adapt.oneLinePos(panel:get("textName"), panel:get("stagePanel"), cc.p(20, 0))
		panel:get("textZl"):text(role.fighting_point)
		panel:get("textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(role.game_key, true)))
		adapt.oneLinePos(panel:get("imgZl"), {panel:get("textZl"), panel:get("textServer")}, {cc.p(10, 0),cc.p(10, 0)})
		bind.extend(self, panel:get("stagePanel"), {
			class = "stage_icon",
			props = {
				rank = role.rank,
				showStageBg = false,
				showStage = false,
				onNode = function(node)
					node:scale(0.7)
						:y(50)
				end,
			},
		})
		if role.figure ~= "" then
			local size = panel:size()
			local y = (i == 1) and 20 or 50
			local figureCfg = gRoleFigureCsv[role.figure]
			widget.addAnimationByKey(panel, figureCfg.resSpine, "figure", "standby_loop1", 1)
				:xy(size.width / 2, y)
				:scale(ROLE_INFO[i].scale)
		end
		panel:get("imgRank"):texture("city/pvp/cross_arena/rank_".. i ..".png")
		bind.touch(self, panel, {methods = {ended = function()
			gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
				local view = gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, dispatchNodes = self.centerPanel}, tb.view)
				tip.adaptView(view, self, {relativeNode = panel, canvasDir = "horizontal", childsName = {"baseNode"}})
			end, role.record_db_id, role.game_key, role.rank)
		end}})
	end

	for i = 4, 10 do
		local role = lastRanks[i]
		if role == nil then
			break
		end
		local panel = self.rolePanel2:clone()
			:addTo(self.centerPanel)
			:xy(ROLE_INFO[i].pos)
			:name("role_"..i)
		panel:get("textName"):text(role.name)
		panel:get("textZl"):text(role.fighting_point)
		panel:get("textStage"):text(dataEasy.getCrossArenaStageByRank(role.rank).stageName)
		panel:get("textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(role.game_key, true)))
		adapt.oneLinePos(panel:get("imgZl"), panel:get("textZl"), cc.p(10, 0))
		adapt.oneLinePos(panel:get("textStage"), panel:get("textServer"), cc.p(10, 0))
		panel:get("atlasLabelRank"):text(i)

		if role.figure ~= "" then
			local size = panel:size()
			local figureCfg = gRoleFigureCsv[role.figure]
			widget.addAnimationByKey(panel, figureCfg.resSpine, "figure", "standby_loop1", 1)
				:xy(size.width / 2, 50)
				:scale(ROLE_INFO[i].scale)
		end
		bind.touch(self, panel, {methods = {ended = function()
			gGameApp:requestServer("/game/cross/arena/role/info", function(tb)
				local view = gGameUI:stackUI("city.pvp.cross_arena.personal_info", nil, {clickClose = true, dispatchNodes = self.centerPanel}, tb.view)
				tip.adaptView(view, self, {relativeNode = panel, canvasDir = "horizontal", childsName = {"baseNode"}})
			end, role.record_db_id, role.game_key, role.rank)
		end}})
	end
end


return OverView