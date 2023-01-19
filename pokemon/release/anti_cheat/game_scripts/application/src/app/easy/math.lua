--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 计算数值相关全局函数
--

local mathEasy = {}
globals.mathEasy = mathEasy

-- @desc 精确到小数点后n位
-- @param isRound 是否四舍五入
function mathEasy.getPreciseDecimal(number, n, isRound)
	local num = number
	local power = math.pow(10.0, n or 0)
	-- 乘法造成的精度误差导致值变小，加一定偏差值
	num = num * power + 1e-8
	local integer = math.floor(num)
	local off = isRound and math.floor(num - integer + 0.5) or 0
	local val = (integer + off) / power
	return val
end

-- @desc 将数字转换为短的带后缀的带小数的数字
function mathEasy.getShortNumber(number, n)
	if type(number) ~= "number" then
		return number
	end
	local str = number
	if not matchLanguage({"cn", "tw"}) then
		if number >= 1e9 then
			str = mathEasy.getPreciseDecimal(number/1e9, n) .. "Bn"

		elseif number >= 1e6 then
			str = mathEasy.getPreciseDecimal(number/1e6, n) .. "M"

		elseif number >= 1e4 then
			str = mathEasy.getPreciseDecimal(number/1e3, n) .. "K"
		end
	else
		if number >= 1e8 then
			str = mathEasy.getPreciseDecimal(number/1e8, n) .. gLanguageCsv.hundredMillion

		elseif number >= 1e5 then
			str = mathEasy.getPreciseDecimal(number/1e4, n) .. gLanguageCsv.tenThousand
		end
	end
	return str
end

-- @desc 一维数组转二维数组
function mathEasy.getRowCol(index, lineNum)
	local row  = math.floor((index - 1) / lineNum) + 1
	local col = (index - 1) % lineNum + 1
	return row, col
end

-- @desc 二维数组转一维数组
function mathEasy.getIndex(row, col, lineNum)
	return col + (row - 1) * lineNum
end

-- @desc 不等分进度显示到区间段中
-- progress: {10, 90}, data: {50, 100}
-- targetVal->result: 25->5% 50->10% 75->50% 101->100%
function mathEasy.showProgress(progress, data, targetVal)
	local idx = 0
	local min, max = 0, 0
	for _, val in ipairs(data) do
		idx = idx + 1
		min = max
		max = val
		if val > targetVal then
			break
		end
	end
	if targetVal > data[idx] then
		return 100
	end
	local rate = (targetVal - min) / (max - min)
	local base = progress[idx-1] or 0
	local percent = base + rate * (progress[idx] - base)
	return math.min(percent, 100)
end
