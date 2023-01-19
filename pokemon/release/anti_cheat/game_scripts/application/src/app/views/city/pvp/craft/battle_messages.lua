local BattleMessages = {}
local instance = nil

function BattleMessages:getInstance()
    if not instance then
        instance = self:ctor()
    end

    return instance
end

function BattleMessages:ctor()
    self:initModel()
    idlereasy.when(self.battleMessages, function(_, battleMessages)
        if itertools.size(battleMessages) > 0 then
            local msg = {}
            for i = #battleMessages, 1, -1 do
                local data = battleMessages[i]
                -- 有连胜
                if data[6] > 2 then
                    local t = {}
                    t[1] = "streak"
                    t[2] = data[4] == "win" and data[2] or data[3]
                    t[3] = data[6]
                    table.insert(msg, t)
                end

                table.insert(msg, data)
                self.data = msg
            end
        end
    end)

    idlereasy.when(self.round, function(_, round)   -- 进入准备阶段后，清除缓存的战报信息
        if round == "prepare" then
            self.data = {}
        end
    end)
    return self
end

function BattleMessages:initModel()
    local craftData = gGameModel.craft
    self.battleMessages = craftData:getIdler("battle_messages")
    self.round = craftData:getIdler("round")
end

function BattleMessages.set(battleMessages)
	BattleMessages.data = battleMessages or {}
end

function BattleMessages.get()
	return BattleMessages.data or {}
end

return BattleMessages