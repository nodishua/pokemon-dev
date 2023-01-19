

local ViewBase = cc.load("mvc").ViewBase
local UnionApplyView = class("UnionApplyView", Dialog)

local JOB_TXT = {
	gLanguageCsv.chairman,
	gLanguageCsv.viceChairman,
	gLanguageCsv.member
}
local JOB = {
	CHAIRMAN = 1,
	VICE_CHAIRMAN = 2,
	MEMBER = 3
}

--判断职位
local function JudgmentJob(id, jobList)
	if jobList["chairman"] == id then
		return JOB.CHAIRMAN
	end
	if jobList["viceChairmans"][id] then
		return JOB.VICE_CHAIRMAN
	end
	return JOB.MEMBER
end

UnionApplyView.RESOURCE_FILENAME = "union_apply.json"
UnionApplyView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("applyDate"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortMembers", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("icon"), {
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

					node:get("name"):text(v.name)
					node:get("level"):text(v.level)
					node:get("wbm"):visible(not v.isHas)
					node:get("ybm"):visible(v.isHas)
					node:get("member"):text(JOB_TXT[v.job])

					local bgOpacity = k % 2 == 0 and 153 or 77
					node:get("bg"):setOpacity(bgOpacity)
					if not v.roleId then
						node:get("bg"):onClick(functools.partial(list.clickCell, k, v))
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("ItemclickBtn"),
			},
		}
	},
}

function UnionApplyView:onCreate()
	self:initModel()
	self.item:hide()
	self.applyDate = idlers.new({})

	local jobList = {}
	jobList["chairman"] = self.chairmanId
	local tmpViceChairmans = {}
	for k,v in ipairs(self.viceChairmans) do
		tmpViceChairmans[v] = true
	end
	jobList["viceChairmans"] = tmpViceChairmans

	local unionId = {}
	local roleId = false
	for _, v in csvMapPairs(self.members) do
		local isHas = false
		for _, id in ipairs(self.signRoles) do
			if v.id == id then
				isHas = true
			end
		end
		roleId = false
		if self.id == v.id then
			roleId = true
		end
		local job = JudgmentJob(v.id, jobList)
		table.insert(unionId, {logo = v.logo, id = v.id, vip = v.vip, level = v.level,
			frame = v.frame, contrib = v.contrib, name = v.name, isHas = isHas, job = job, roleId = roleId})
	end
	self.applyDate:update(unionId)

	Dialog.onCreate(self, {clickClose = true})
end

function UnionApplyView:initModel()
	local unionInfo = gGameModel.union_fight:read("union_info")
	self.signRoles = unionInfo.sign_roles
	self.members = gGameModel.union:read("members")
	--会长ID 长度12
	self.chairmanId = gGameModel.union:read("chairman_db_id")
	--副会长ID 长度12
	self.viceChairmans = gGameModel.union:read("vice_chairmans")
	self.id = gGameModel.role:read('id')
end

function UnionApplyView:ItemclickBtn(list, k, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, {clickClose = true, dispatchNodes = list:parent()}, pos, {role = v}, {speical = "rank", target = list.item:get("bg"), disableTouch = true})
end

--会员排序
function UnionApplyView:onSortMembers(list)
	return function(a, b)
		if a.job ~= b.job then
			return a.job < b.job
		end
		return a.contrib < b.contrib
	end
end

return UnionApplyView