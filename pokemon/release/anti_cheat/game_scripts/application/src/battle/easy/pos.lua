--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 位置计算相关

-- 获得单位的原始行列值
function battleEasy.getRowAndColumn(idOrObj)
	local seat = idOrObj
	if type(idOrObj) ~= 'number' then
		seat = idOrObj.seat
	end
	local rowNum = 2-(math.floor((seat+2)/3))%2   -- 行数
	local columnNum = (seat-1)%3+1     -- 列数
	return rowNum, columnNum
end

--               {1,2,3,4,5,6,7,8,9,10,11,12,13,14}
local mirrorTb = {7,8,9,10,11,12,1,2,3,4,5,6,14,13}
function battleEasy.mirrorSeat(seat)
	return mirrorTb[seat]
end

local leftIds = {1,2,3,4,5,6,13}
function battleEasy.getForce(seat)
	return (seat == 13 or seat <= 6) and 1 or 2
	-- return itertools.include(leftIds,seat) and 1 or 2
end