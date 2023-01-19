local GameObject = require "app.views.city.test.model.gameobject"

local Gate = require "app.views.city.test.gate.gate"
local SingleGate = class("SingleGate",Gate)

function SingleGate:init()
	for i=1,30 do
		self:addGameObject()
	end
end

function SingleGate:parseRecord(record)
	self:cleanGameObject()
	for k,roleData in pairs(record) do
		if k < 13 then
			local index = self:indexToSeat(k)
			self:initGameObjectByRoleId(index,k,roleData.roleId,roleData)
		end
	end
end

function SingleGate:parseScene(_scene)
	self:cleanGameObject()
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			if k < 13 then
				self:initGameObjectByRoleId(_obj.index,self:indexToSeat(k),_obj._prefab.roleId,_obj._prefab.data)
			end
		end
	end
end

-- 添加阵营单位
function SingleGate:addGameObject(_prefab,seat)
	if _prefab then
		for _,_gameObject in ipairs(self.scene) do
            if not _gameObject:getRoleData() then
                seat = seat or _gameObject.seat
                _gameObject:init(_gameObject.index,seat,_prefab)
                break
            end
		end
		return
	end
	local lerpPos,limit = cc.p(10,2),3
    local _gameObject = GameObject.new(self.gameObject:clone())

    local itemNode = _gameObject.node
    local startPos = cc.p(itemNode:size().width/2+lerpPos.x
        ,itemNode:size().height/2-lerpPos.y)

    self.parent:addItemToScrollView(self.gameObjects,itemNode,lerpPos,startPos,limit)
    itemNode:onTouch(functools.handler(self,self.dragSprite,_gameObject))
	itemNode:addClickEventListener(functools.handler(self.parent,self.parent.onlyShowSelect,self.gameObjects,_gameObject))
    itemNode:get("del"):addClickEventListener(functools.handler(self,self.delGameObject,_gameObject))

	table.insert(self.scene,_gameObject)
	seat = seat or self:indexToSeat(#self.scene)
    _gameObject:init(#self.scene,seat,_prefab)
end

-- 删除阵营单位
function SingleGate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end

    _gameObject:init(_gameObject.index,_gameObject.seat)
end

-- 清除布阵
function SingleGate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    for i=1,12 do
		self:addGameObject()
	end
end

-- 获取场上单位索引
function SingleGate:getGameObjectIndex(count)
	return count > 5 and (count + 3) or count
end

function SingleGate:getFightRoleData()
	local roleOut = {}
	local roleData = {{},{}}
	local _roleData
	for _, _gameObject in ipairs(self.scene) do
		_roleData = _gameObject:getRoleData()
		if _roleData then
			table.insert(roleData[_gameObject.force], _roleData)
		end
	end

	if not next(roleData[1]) or not next(roleData[2]) then
		return roleOut
	end

	for _, attacker in pairs(roleData[1]) do
		for _, target in pairs(roleData[2]) do
			roleOut[#roleOut + 1] = {[2] = attacker, [8] = target}
		end
	end

	return roleOut
end

return SingleGate