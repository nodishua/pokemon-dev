-- @date:   2019-06-10
-- @desc:   公会副本进度界面

local function getTexture(bool)
	if bool then
		return "city/union/gate/box_jdt.png"
	end
	return "city/union/gate/box_jdd.png"
end
local function setColorTxt(txtNode, bool)
	if bool then
		text.addEffect(txtNode, {color = ui.COLORS.NORMAL.LIGHT_GREEN})
	else
		text.addEffect(txtNode, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
	end
end
local JOB_TXT = {
	gLanguageCsv.chairman,
	gLanguageCsv.viceChairman,
	gLanguageCsv.member
}
local function getJob(myId, chairmanId, viceChairmans)
	if myId == chairmanId then
		return 1
	end
	for k,v in ipairs(viceChairmans) do
		if myId == v then
			return 2
		end
	end
	return 3
end
local UnionGateProgressView = class("UnionGateProgressView", Dialog)

UnionGateProgressView.RESOURCE_FILENAME = "union_gate_progress.json"
UnionGateProgressView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["maskPanel"] = "maskPanel",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("members"),
				item = bindHelper.self("item"),
				chairmanId = bindHelper.self("chairmanId"),
				viceChairmans = bindHelper.self("viceChairmans"),
				dataOrderCmpGen = bindHelper.self("onSortRank", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local chairmanId = list.chairmanId:read()
					local viceChairmans = list.viceChairmans:read()
					local childs = node:multiget(
						"logo",
						"roleName",
						"level",
						"job",
						"progressTxt",
						"progress1",
						"progress2",
						"progress3"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false
						}
					})
					childs.roleName:text(v.name)
					childs.level:text(v.level)
					childs.job:text(JOB_TXT[getJob(v.id, chairmanId, viceChairmans)])
					childs.progressTxt:text(v.fuben_times.."/3")
					setColorTxt(childs.progressTxt, v.fuben_times >= 3)
					childs.progress1:texture(getTexture(v.fuben_times >= 1))
					childs.progress2:texture(getTexture(v.fuben_times >= 2))
					childs.progress3:texture(getTexture(v.fuben_times >= 3))
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
}

function UnionGateProgressView:onCreate()
	self:initModel()
	Dialog.onCreate(self)
end

function UnionGateProgressView:initModel()
	local unionInfo = gGameModel.union
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	--会长ID 长度12
	self.chairmanId = unionInfo:getIdler("chairman_db_id")
	--副会长ID 长度12
	self.viceChairmans = unionInfo:getIdler("vice_chairmans")
end

function UnionGateProgressView:onSortRank(list)
	return function(a, b)
		return a.fuben_times > b.fuben_times
	end
end
function UnionGateProgressView:onAfterBuild()
	uiEasy.setBottomMask(self.list, self.maskPanel)
end

return UnionGateProgressView