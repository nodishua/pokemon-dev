local GameObject = require "app.views.city.test.model.gameobject"

local Gate = require "app.views.city.test.gate.gate"
local CrossMineGate = class("CrossMineGate",Gate)

function CrossMineGate:init()
	for i=1,36 do
		self:addGameObject()
	end
end

function CrossMineGate:parseRecord(record)
	self:cleanGameObject()

	for force, data in ipairs(record) do
		for group, v in ipairs(data) do
			for seat, roleData in pairs(v) do
				local baseIndex = (group -1) * 12
				self:initGameObjectByRoleId(baseIndex+seat, seat, roleData.roleId, roleData)
			end
		end
	end
end

function CrossMineGate:parseScene(_scene)
	self:cleanGameObject()
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			self:initGameObjectByRoleId(_obj.index,self:indexToSeat(k),_obj._prefab.roleId,_obj._prefab.data)
		end
	end
end

function Gate:indexToSeat(index)
	local seatMap = {4,5,6,1,2,3,7,8,9,10,11,12,4,5,6,1,2,3,7,8,9,10,11,12,4,5,6,1,2,3,7,8,9,10,11,12}
	return seatMap[index] or index
end

-- 添加阵营单位
function CrossMineGate:addGameObject(_prefab,seat)
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
function CrossMineGate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end

    _gameObject:init(_gameObject.index)
end

-- 清除布阵
function CrossMineGate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    for i=1,36 do
		self:addGameObject()
	end
end

-- 获取场上单位索引
function CrossMineGate:getGameObjectIndex(count)
	count = count > 11 and count + 3 or count
	count = count > 20 and count + 3 or count
	count = count > 29 and count + 3 or count
	count = count > 38 and count + 3 or count
	return count > 5 and (count + 3) or count
end

function CrossMineGate:getFightRoleData()
	local roleOut1 = {{},{},{}}
	local roleOut2 = {{},{},{}}

	local function addData(seat, data, group)
		if seat < 7 then
			roleOut1[group][seat] = data
		else
			roleOut2[group][seat] = data
		end
	end

	local _roleData
	for id, _gameObject in ipairs(self.scene) do
		_roleData = _gameObject:getRoleData()
		if _roleData then
			if id < 13 then
				addData(_gameObject.seat, _roleData, 1)
			elseif id < 25 then
				addData(_gameObject.seat, _roleData, 2)
			else
				addData(_gameObject.seat, _roleData, 3)
			end
		end
	end

	return {{roleOut1, roleOut2}}
end

return CrossMineGate