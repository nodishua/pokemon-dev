-- 万圣节消息数据

local halloweenMessages = {}
local instance = nil

function halloweenMessages:getInstance()
    if not instance then
        instance = self:ctor()
    end

    return instance
end

function halloweenMessages:ctor()
	self.data = {}

    return self
end

function halloweenMessages:clear()
	self.data = {}
end

function halloweenMessages.set(battleMessages)
	halloweenMessages.data = battleMessages or {}
end

function halloweenMessages.get()
	return halloweenMessages.data or {}
end

function halloweenMessages.getSpritesPos(x, y, index)
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local range = csvHalloween.range
	local lenX, lenY = csvHalloween.randDistance[1], csvHalloween.randDistance[2]
	local lenX = math.random(lenX)
	local lenY = math.random(lenY)

	local randomNum = math.random(4)
	if randomNum == 1 then
		if x + lenX >= range[2][1] or y + lenY >= range[2][2] or x + lenX <= range[1][1] or y + lenY <= range[1][2] then
			return halloweenMessages.getSpritesPos(x, y, index)
		else
			return x + lenX, y + lenY, randomNum
		end
	elseif randomNum == 2 then
		if x + lenX >= range[2][1] or y - lenY >= range[2][2] or x + lenX <= range[1][1] or y - lenY <= range[1][2] then
			return halloweenMessages.getSpritesPos(x, y, index)
		else
			return x + lenX, y - lenY, randomNum
		end
	elseif randomNum == 3 then
		if x - lenX >= range[2][1] or y - lenY >= range[2][2] or x - lenX <= range[1][1] or y - lenY <= range[1][2] then
			return halloweenMessages.getSpritesPos(x, y, index)
		else
			return x - lenX, y - lenY, randomNum
		end
	elseif randomNum == 4 then
		if x - lenX >= range[2][1] or y + lenY >= range[2][2] or x - lenX <= range[1][1] or y + lenY <= range[1][2] then
			return halloweenMessages.getSpritesPos(x, y, index)
		else
			return x - lenX, y + lenY, randomNum
		end
	end
end

function halloweenMessages.getHalloweenMessages(halloweenData, x, y, index, clickNum)
	if halloweenData[index] then
		halloweenData[index].num = halloweenData[index].num + 1
		halloweenData[index].x = x
		halloweenData[index].y = y
	else
		halloweenData[index] = {}
		halloweenData[index].num = 1
		halloweenData[index].x = x
		halloweenData[index].y = y
		halloweenData[index].clickNum = clickNum
	end
	return halloweenData
end


return halloweenMessages