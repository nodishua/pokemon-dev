--
-- 光环Buff
--

local AuraBuffModel = class("AuraBuffModel", BuffModel)
globals.AuraBuffModel = AuraBuffModel

function AuraBuffModel:ctor(cfgId, holder, caster, args)
	BuffModel.ctor(self,cfgId, holder, caster, args)

	self.auraRef = 1
	self.isAuraType = true -- 光环类buff

	self.casters = {[caster.id] = true}
end

function AuraBuffModel:refreshAuraRef(ret)
	self.auraRef = self.auraRef + (ret and ret or 1)
	if self.auraRef <= 0 then self:alterAuraBuffValue(0) end
end

function AuraBuffModel:addCaster(caster)
	self.casters[caster.id] = true
end

function AuraBuffModel:over(params)
	if self.auraRef > 1 then
		self:refreshAuraRef(-1)
		return
	end
	BuffModel.over(self,params)

	for id,_ in pairs(self.casters) do
		local obj = self.scene:getObject(id)
		if obj then
			obj.auraBuffs:erase(self.id)
		end
	end
end

function AuraBuffModel:alterAuraBuffValue(value)
	if not self.isNumberType then return end
	if type(value) == "string" then
		value = self:cfg2Value(value)
	end
	-- self:doEffect(self.csvCfg.easyEffectFunc, value - self:getValue(), false)
	self:setValue(value)
	self:refreshLerpValue(false)
end

local function argsArray(args)
	if type(args[1]) ~= 'table' then
		return {args}
	end
	return args
end

function AuraBuffModel:getBuffEffectFunc(effectName)
	-- 影响属性 且当前值不为固定值
	if effectName == "addAttr" and not self.args.isFixValue then
		return function (buff, args, isOver)
			local _args = {}
			for _, t in ipairs(argsArray(args)) do
				local attrName = t.attr
				local value = t.val
				if attrName == "speed" then
					if not isOver then
						buff.holder.attrs:addAuraAttr(attrName, value)
						-- buff.holder:objAddBuffAttr(attrName, value)		-- 这个增加了对能力弱化属性的判断
						buff.triggerAddAttrTb[attrName] = buff.triggerAddAttrTb[attrName] and (buff.triggerAddAttrTb[attrName] + value) or value
					else
						buff.holder.attrs:addAuraAttr(attrName, -(buff.triggerAddAttrTb[attrName] or 0))	-- over时的计算,不需要考虑能力弱化的影响
						buff.triggerAddAttrTb[attrName] = nil
					end
				else
					table.insert(_args,{attr = attrName,val = value})
				end
			end
			-- 目前只处理速度
			if table.length(_args) > 0 then
				local f = BuffModel.getBuffEffectFunc(self,"addAttr")
				f(buff, _args, isOver)
			end
			return true
		end
	end
	return BuffModel.getBuffEffectFunc(self,effectName)
end

function AuraBuffModel:toHumanString()
	return string.format("AuraBuffModel: %s(%s)", self.id, self.cfgId)
end