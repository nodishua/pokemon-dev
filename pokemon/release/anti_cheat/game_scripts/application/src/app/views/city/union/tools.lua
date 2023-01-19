
local unionTools = {}

function unionTools.canEnterBuilding(name, todayCanUse, notShowTip)
	local flag = true
	local unionLv = gGameModel.union:read("level")
	if not name or not gUnionFeatureCsv[name] or gUnionFeatureCsv[name] > unionLv then
		flag = false
		return flag
	end
	if not todayCanUse and dataEasy.notUseUnionBuild() then
		flag = false
		if not notShowTip then
			gGameUI:showTip(gLanguageCsv.cannotUseBuilding)
		end
		return flag
	end

	return flag
end

function unionTools.currentOpenFuben()
	local t = time.getTimeTable()
	if t.wday == 1 then
		return "weekError"
	end

	local t1 = t.hour * 100 + t.min
	if t1 < 930 or t1 > 2330 then
		return "timeError"
	end

	return "open"
end
return unionTools