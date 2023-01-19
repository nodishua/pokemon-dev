
local IDCount = 0
local Prefab = class("prefab")


function Prefab:ctor(node)
    IDCount = IDCount + 1

    self.id = IDCount
    self.node = node
    self.unit = {}
    self.roleData = {}
    self.selectShowChild = {"select","add","del"}
    self.roleId = 0
end

function Prefab:init(roleId,extraData)
    self.unit = csv.unit[roleId]
    self.card = csv.cards[self.unit.cardID]
    self.roleId = roleId
    self.roleData.roleId = roleId

    if self.node then
        self.node:setName("prefab_" .. IDCount)

        if self.unit.icon then
            self.node:get("icon"):texture(self.unit.iconSimple)
        end
    end

    if extraData then
        for attrName,val in pairs(extraData) do
            self.roleData[attrName] = val
        end
    end

    if self.roleData then
        if self.roleData.skills and next(self.roleData.skills) then
            for k, v in pairs(self.roleData.skills) do
                self.roleData.skills[k] = self.roleData.skills[k] or self.roleData.level
            end
        end

        -- 考虑有些精灵有皮肤, card表对应读取的技能不对, 通过unit表填充默认技能
        local exSkillID = 0
        if not self.roleData.skills then self.roleData.skills = {} end
        for _, skillID in pairs(self.unit.skillList) do  -- 主动技能
            self.roleData.skills[skillID] = self.roleData.skills[skillID] or self.roleData.level
            exSkillID = math.floor(skillID / 10)
        end
        for _, skillID in pairs(self.unit.passiveSkillList) do  -- 被动技能
            self.roleData.skills[skillID] = self.roleData.skills[skillID] or self.roleData.level
        end
        exSkillID = 10 * exSkillID + 6
        self.roleData.skills[exSkillID] = self.roleData.skills[exSkillID] or self.roleData.level
    end

    -- 如果是双形态
    if self.unit.twinFlag then
        local otherCardId
        for id,v in orderCsvPairs(csv.cards) do
            if v.cardMarkID == self.card.cardMarkID and id ~= self.unit.cardID then
                otherCardId = id
            end
        end
        if otherCardId and not self.roleData.role2Data then
            -- 复制一份属性
            local data = clone(extraData)
            data.roleId = csv.cards[otherCardId].unitID
            data.skills = {}
            local skillList = csv.cards[otherCardId].skillList
            for k = 1, 4 do
                local skillID = skillList[k]
                data.skills[skillID] = data.skills[skillID] or data.level
            end
            self.roleData.role2Data = data
        end
    end
end

function Prefab:clean()
    self.node:removeFromParent()
end

function Prefab:getRoleData()
    return csvClone(self.roleData)
end

return Prefab