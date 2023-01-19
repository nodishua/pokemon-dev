
local Gate = require "app.views.city.test.gate.gate"
local ChaosGate = class("ChaosGate",Gate)

function ChaosGate:getFightRoleData()
	local roleOut = {}
	local unitLimitIndex = 4023
	local sceneNum = #self.scene
	local i = 12
	local _prefab
	local resources = self.parent.resources
	while i ~= 0 do
		local range = unitLimitIndex + sceneNum*1000
		local unitId = math.random(range)
		if i <= sceneNum or (unitId > unitLimitIndex and sceneNum > 0) then
			roleOut[i] = self.scene[sceneNum]:getRoleData()
			sceneNum = sceneNum - 1
		elseif csv.unit[unitId] then
			local isNeedDel = false
			if not resources[unitId] then
				self.parent:addRes(unitId)
				isNeedDel = true
			end
			_prefab = resources[unitId]
			roleOut[i] = _prefab:getRoleData()
			if isNeedDel then self.parent:delRes(_prefab) end
		else
			i = i + 1
		end
		i = i - 1
	end

	return {roleOut}
end

return ChaosGate