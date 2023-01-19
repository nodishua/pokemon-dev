--
-- 光环buff技能
-- skillType 2
-- 按战斗回合更新
-- skillArgs 配置 <是否一次性;是否固定值> => 默认: <FALSE;TRUE>
-- 参数注释:
--    是否一次性: 针对单个单位值只计算一次 后固定 <TRUE OR FALSE>
--    是否固定值: 针对单位的加成值是固定值 不是比例 即不会添加到attr.aura <TRUE OR FALSE>

local BuffSkillModel = class("BuffSkillModel", battleSkill.SkillModel)
battleSkill.BuffSkillModel = BuffSkillModel

function BuffSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)
	local skillArgs = self.cfg.skillArgs or {}
	self.cantShowText = false
	self.buffValues = {}
	self.effectOnce = battleEasy.ifElse(skillArgs[1] ~= nil,skillArgs[1],false)
	self.isFixValue = battleEasy.ifElse(skillArgs[2] ~= nil,skillArgs[2],true)
end

function BuffSkillModel:canSpell()
	return not self.owner:isDeath()
end

function BuffSkillModel:onTrigger(typ, target, args)
	if self.skillType ~= battle.SkillType.PassiveAura or typ ~= 'Aura' then
		return
	end

	if self.owner:isLeaveField() then return end

	-- judgePassiveSkill
	if self:canSpell() then
		self:spellTo(target, args)
		-- 飘字只显示一次
		self.cantShowText = true
	end
end

function BuffSkillModel:isAttackSkill()
	return false
end

function BuffSkillModel:_spellTo(target, args)
	log.battle.passiveSkill.spellTo("spellTo", self.owner.id, self.id, 'target', (target or {})['id'])

	battleSkill.SkillModel._spellTo(self, target)
end

function BuffSkillModel:addProcessBuffBefore(id, holder, caster, buffCfg)
	local buff = holder:getBuff(id)
	-- 需要提前清除加成值，不然后续的计算拿的是有光环加成的最终值
	if buff then buff:alterAuraBuffValue(0) end
end

function BuffSkillModel:addProcessBuff(id,holder,caster,buffCfg,args)
	-- 处理value
	if self.effectOnce then
		args.value = self.buffValues[holder.id] or args.value
	end

	args.isAuraType = true
	args.cantShowText = self.cantShowText
	args.isFixValue = self.isFixValue

	local buff, canTakeEffect = addBuffToHero(id, holder, caster, args)
	local _buff = buff or holder:getBuff(id)
	if canTakeEffect then
		if self.effectOnce and not self.buffValues[holder.id] then
			self.buffValues[holder.id] = args.value
		end

		if _buff then
			-- 不是第一次添加
			_buff:addCaster(self.owner)
			self.owner.auraBuffs:insert(_buff.id, _buff)
		end
	end

	if _buff and not assertInWindows(_buff.alterAuraBuffValue, "not aura buff skill:%d, buff:%d", self.id, _buff.cfgId) then
		_buff:alterAuraBuffValue(args.value)
	end

	return buff
end

function BuffSkillModel:onSpellView(skillBB)
	local view = self.owner.view

	battleEasy.queueNotifyFor(view, 'skillBefore', self.disposeDatasOnSkillStart, self.skillType)

	battleEasy.queueNotifyFor(view, 'objSkillEnd', self.disposeDatasOnSkillEnd, self.skillType)

	battleEasy.queueNotifyFor(view,'afterComeBack',self.disposeDatasAfterComeBack)

	battleEasy.queueNotifyFor(view, 'objSkillOver')
end

function BuffSkillModel:toHumanString()
	return string.format("BuffSkillModel: %s", self.id)
end