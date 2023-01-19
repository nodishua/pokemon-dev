
local GameObject = require "app.views.city.test.model.gameobject"

local Gate = require "app.views.city.test.gate.gate"
local CraftGate = class("CraftGate",Gate)

function CraftGate:init()
	for i=1,6 do
		self:addGameObject()
	end
end

function CraftGate:parseScene(_scene)
	self:cleanGameObject()
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			self:initGameObjectByRoleId(_obj.index,_obj.index < 4 and _obj.index or _obj.index + 3,_obj._prefab.roleId,_obj._prefab.data)
		end
	end
end

-- 添加阵营单位
function CraftGate:addGameObject(_prefab,seat)
	if _prefab then
		for _,_gameObject in ipairs(self.scene) do
            if not _gameObject:getRoleData() then
                _gameObject:init(_gameObject.index,seat or (_gameObject.index > 3 and _gameObject.index + 3 or _gameObject.index),_prefab)
                break
            end
		end
		return
	end
	local lerpPos,limit = cc.p(80,2),3
    local _gameObject = GameObject.new(self.gameObject:clone())

    local itemNode = _gameObject.node
    local startPos = cc.p(itemNode:size().width/2+lerpPos.x
        ,itemNode:size().height/2-lerpPos.y)

    self.parent:addItemToScrollView(self.gameObjects,itemNode,lerpPos,startPos,limit)
    itemNode:onTouch(functools.handler(self,self.dragSprite,_gameObject))
	itemNode:addClickEventListener(functools.handler(self.parent,self.parent.onlyShowSelect,self.gameObjects,_gameObject))
    itemNode:get("del"):addClickEventListener(functools.handler(self,self.delGameObject,_gameObject))

	table.insert(self.scene,_gameObject)
	seat = seat or #self.scene
    _gameObject:init(#self.scene,seat > 3 and seat + 3 or seat,_prefab)
end

-- 删除阵营单位
function CraftGate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end
    _gameObject:init(_gameObject.index)
end

-- 清除布阵
function CraftGate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    for i=1,6 do
		self:addGameObject()
	end
end

-- 获取场上单位索引
function CraftGate:getGameObjectIndex(count)
	return count > 2 and (count + 3) or count
end

function CraftGate:parseRecord(record)
	self:cleanGameObject()
	for k,roleData in pairs(record) do
		local index = k--self:indexToSeat(k)
		self:initGameObjectByRoleId(index,k,roleData.roleId,roleData)
	end
end

function CraftGate:initGameObjectByRoleId(index,seat,roleId,extraData)
    if not self.parent.resources[roleId] then
        self.parent:addRes(roleId,extraData)
    end
    self.scene[index > 6 and index - 3 or index]:init(index,seat,self.parent.resources[roleId])
    self.scene[index > 6 and index - 3 or index]:loadRoleData(extraData)
end


function CraftGate:getFightRoleData()
	local roleOut = {}
	local isCanOpen = {0,0}
	local _roleData
	for _,_gameObject in ipairs(self.scene) do
		_roleData = _gameObject:getRoleData()
		if _roleData then
			roleOut[_gameObject.seat] = _roleData
			-- local wave = _gameObject.seat % 6
			-- roleOut[wave] = roleOut[wave] or {}
			-- roleOut[wave][_gameObject.seat < 4 and 2 or 8] = _roleData
			isCanOpen[_gameObject.force] = isCanOpen[_gameObject.force] + 1
		end
	end

	if isCanOpen[1] == 0 or isCanOpen[2] == 0 then
		roleOut = {}
	end

	return {roleOut}
end



return CraftGate