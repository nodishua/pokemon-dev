-- @date 2020-7-19
-- @desc 钓鱼（通用方法）

local fishingTools = {}

function fishingTools.getExp(fishLevel, fishCounter, targetCounter)
	-- 计算等级
	local cfg = csv.fishing.level[fishLevel]

	local lowCounter = 0
	local middleCounter = 0
	local highCounter = 0
	local fishCounter1 = 0
	local fishCounter2 = 0
	local fishCounter3 = 0

	if fishCounter ~= nil then
		if fishCounter[1] ~= nil then
			lowCounter = fishCounter[1] < cfg.lowNum and fishCounter[1] or cfg.lowNum
			fishCounter1 = fishCounter[1]
		end
		if fishCounter[2] ~= nil then
			middleCounter = fishCounter[2] < cfg.middleNum and fishCounter[2] or cfg.middleNum
			fishCounter2 = fishCounter[2]
		end
		if fishCounter[3] ~= nil then
			highCounter = fishCounter[3] < cfg.highNum and fishCounter[3] or cfg.highNum
			fishCounter3 = fishCounter[3]
		end
	end

	local sum = fishCounter1 + fishCounter2 + fishCounter3
	if sum > cfg.totalNum then
		sum = cfg.totalNum
	end

	local all = cfg.totalNum == 0 and 0 or sum
	-- 分母
	local nextExp = cfg.lowNum + cfg.middleNum + cfg.highNum + cfg.totalNum + (cfg.targetNum[1] or 0)
	-- 分子
	local nowExp = lowCounter + middleCounter + highCounter + targetCounter + all
	-- 总经验
	local sumExp = nowExp
	for i=1,fishLevel do
		local cfg = csv.fishing.level[i]
		sumExp = sumExp + cfg.lowNum + cfg.middleNum + cfg.highNum + cfg.totalNum + (cfg.targetNum[1] or 0)
	end
	return nowExp, nextExp, sumExp
end

return fishingTools