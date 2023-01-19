--
-- 作用在战斗物体上的skill
--

local battleSkill = {}
globals.battleSkill = battleSkill

require "battle.models.skill.skill"
require "battle.models.skill.passive_skill"
require "battle.models.skill.immediate_skill"
require "battle.models.skill.summon_skill"
require "battle.models.skill.combine_skill"

require "battle.models.skill.helper"

-- 技能类型;0:常规技能1:增加属性2:光环buff类3:被动技能条件触发

local map = {
	[battle.SkillType.NormalSkill] = battleSkill.SkillModel,
	[battle.SkillType.PassiveAura] = battleSkill.BuffSkillModel,
	[battle.SkillType.PassiveSkill] = battleSkill.PassiveSkillModel,
	[battle.SkillType.PassiveSummon] = battleSkill.SummonSkillModel,
	[battle.SkillType.PassiveCombine] = battleSkill.CombineSkillModel
}

-- source: 记录技能的来源, buff中部分特殊效果会创建新的技能出来,这时候需要记录 source, 以备其它地方使用
function globals.newSkillModel(scene, owner, skillID, level, source)
	local cfg = csv.skill[skillID]
	local cls = map[cfg.skillType]
	if cls == nil then
		error(string.format("skill type %d not existed", cfg.skillType))
	end
	return cls.new(scene, owner, cfg, level, source)
end