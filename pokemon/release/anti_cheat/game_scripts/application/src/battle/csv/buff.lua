--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
-- BuffModel导出Csv公式用
--

local CsvBuff = battleCsv.newCsvCls("CsvBuff")
battleCsv.CsvBuff = CsvBuff

-- 获取当前buff的驱散状态
-- @return 获取当前buff的驱散状态 默认false
function CsvBuff:getDispleState()
	return self.model:getEventByKey(battle.ExRecordEvent.dispelSuccess) or false
end

-- 获取当前buff的值
-- @return self.model.value
function CsvBuff:getValue()
	return self.model.value
end

-- 获取当前buff的group
-- @return self.model.group
function CsvBuff:getGroup()
	return self.model.csvCfg.group
end

-- 获取当前buff的cfgId
-- @return self.model.cfgId
function CsvBuff:getCfgId()
	return self.model.cfgId
end

-- 获取当前buff的直接触发效果
-- @return self.model.csvCfg.easyEffectFunc
function CsvBuff:getEasyEffectFunc()
	return self.model.csvCfg.easyEffectFunc
end

-- 获取当前buff的记录数据
-- @param key string 存储值的key
-- @return ExRecordEvent[key](不存在则返回0)
function CsvBuff:getRecordDataTab(key)
	return self.model:getEventByKey(battle.ExRecordEvent[key]) or 0
end

-- 获取当前buff的值的某个index的子值
-- @return self.model.value[i]
function CsvBuff:getValueIdx(i)
	return self.model.value[i]
end

-- 获取当前buff配表中的生命周期
-- @return 返回当前buff配表中的生命周期
function CsvBuff:getLifeRound()
	return self.model.args.lifeRound
end

-- 获取当前buff的lifeRound
-- @return 返回buf当前的生命周期
function CsvBuff:getFinalLifeRound()
	return self.model:getLifeRound()
end

-- 获取当前buff的overlayCount
-- @return 返回buf当前的叠加层数
function CsvBuff:getOverLayCount()
	return self.model:getOverLayCount()
end

--获取当前复制buff的状态
--@return 默认false
function CsvBuff:getCopyBuffState()
	return self.model:getEventByKey(battle.ExRecordEvent.copyState) or false
end

--获取当前转移buff的状态
--@return 默认false
function CsvBuff:getTransferBuffState()
	return self.model:getEventByKey(battle.ExRecordEvent.transferState) or false
end