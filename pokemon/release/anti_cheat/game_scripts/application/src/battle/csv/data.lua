--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- 配表数据获取
--

-- 固定值或百分比
function battleCsv.getFixedOrPercent(s)
	local fixed, percent = 0, 0
	if s then
		local perPos = string.find(s, "%%")
		if perPos then
			local num = tonumber(string.sub(s, 1, perPos-1))
			percent = num/100.0		-- 百分比值
		else
			fixed = s
		end
	end
	return fixed, percent
end

-- 是否存在buff组
function battleCsv.hasBuffGroup(groupTab,group)
    if groupTab then 
        for k,v in ipairs(groupTab) do
            if v[group] then 
                return true,k
            end
        end
    end
    return false,nil
end

