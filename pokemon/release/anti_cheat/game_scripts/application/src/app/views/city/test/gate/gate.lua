local GameObject = require "app.views.city.test.model.gameobject"

local Gate = class("Gate")

function Gate:ctor(_parent)
	self.parent = _parent

	self.scene = {} -- 场上的单位
	self.gameObjects = _parent.gameObjects

	self.gameObject = _parent.gameObject

	self.lastClickObj = nil -- 上一次点击的单位
end

function Gate:init()
end

function Gate:parseScene(_scene)
	if _scene and next(_scene) then
		for k,_obj in pairs(_scene) do
			self:addGameObject(_obj,k)
		end
	end
end

function Gate:parseRecord(record)
end

function Gate:initGameObjectByRoleId(index,seat,roleId,extraData)
    if not self.parent.resources[roleId] then
        self.parent:addRes(roleId,extraData)
    end
    self.scene[index]:init(index,seat,self.parent.resources[roleId])
    self.scene[index]:loadRoleData(extraData)
end

-- 添加阵营单位
function Gate:addGameObject(_prefab,seat)
    -- local lerpPos,limit = cc.p(10,2),3
    -- local limitNum,isNew = 12,false
    -- if self.fightType == FightType.Normal then
    --     isNew = true
    -- elseif self.fightType == FightType.Craft then
    --     lerpPos = cc.p(80,2)
    --     limitNum = 6
    --     isNew = true
    -- end

    -- if isNew and #self.scene == limitNum then
    --     for _,_gameObject in ipairs(self.scene) do
    --         if not _gameObject:getRoleData() then
    --             _gameObject:init(_gameObject.index,_prefab)
    --             break
    --         end
    --     end
    --     return
    -- end
	local lerpPos,limit = cc.p(10,2),3
    local _gameObject = GameObject.new(self.gameObject:clone())

    local itemNode = _gameObject.node
    local startPos = cc.p(itemNode:size().width/2+lerpPos.x
        ,itemNode:size().height/2-lerpPos.y)

    self.parent:addItemToScrollView(self.gameObjects,itemNode,lerpPos,startPos,limit)
    -- itemNode:onTouch(functools.handler(self,self.dragSprite,_prefab))
    itemNode:addClickEventListener(functools.handler(self.parent,self.parent.onlyShowSelect,self.gameObjects,_gameObject))
    itemNode:get("del"):addClickEventListener(functools.handler(self,self.delGameObject,_gameObject))

	table.insert(self.scene,_gameObject)
	seat = seat or #self.scene
    _gameObject:init(#self.scene,seat,_prefab)
    -- print("addGameObject success")
end
-- 删除阵营单位
function Gate:delGameObject(_gameObject)
    if self.lastClickObj and self.lastClickObj.id == _gameObject.id then
        self.lastClickObj = nil
        self.parent:showAttr()
    end

    -- if self.fightType == FightType.Normal or self.fightType == FightType.Craft then -- 阵容不需要刷新
    --     _gameObject:init(_gameObject.index)
    --     return
    -- end

    self.scene[_gameObject.index] = self.scene[#self.scene]
    self.scene[#self.scene] = nil
    self.parent:delItemFromScrollView(self.gameObjects,_gameObject.node)
    _gameObject:clean()
end

-- 清除布阵
function Gate:cleanGameObject()
	self.gameObjects:removeAllChildren()
    self.scene = {}
    -- if self.fightType == FightType.Normal then
    --     for i=1,12 do
    --         self:addGameObject()
    -- --            local node = self.gameObjects:convertToWorldSpace(cc.p(self.scene[i].node:x(),self.scene[i].node:y()))
    -- --            self.drawNode:drawPoint(cc.p(node.x,node.y),10,cc.c4b(153,75,244,1))
    --     end
    -- elseif self.fightType == FightType.Craft then
    --     for i=1,6 do
    --         self:addGameObject()
    -- --            local node = self.gameObjects:convertToWorldSpace(cc.p(self.scene[i].node:x(),self.scene[i].node:y()))
    -- --            self.drawNode:drawPoint(cc.p(node.x,node.y),10,cc.c4b(153,75,244,1))
    --     end
    -- end
end

function Gate:exchange()
end

function Gate:exchangeSeat(seat)
	local seatMap = {7,8,9,10,11,12,1,2,3,4,5,6}
	return seatMap[seat]
end

function Gate:indexToSeat(index)
	local seatMap = {4,5,6,1,2,3}
	return seatMap[index] or index
end
-- 获取场上单位索引
function Gate:getGameObjectIndex(count)
	-- if self.fightType == FightType.Normal and count > 5 then
	-- 	count = count + limit
	-- elseif self.fightType == FightType.Craft and count > 2 then
	-- 	count = count + limit
	-- end
	return count
end

-- 获得战斗布阵信息
-- @return roleOut table {[1]= {[1] = {...},[9]= {...}}}
function Gate:getFightRoleData()
	return {}
end

-- 拖拽精灵注册事件
function Gate:dragSprite(_gameObject,event)
    if _gameObject.roleId <= 0 then return end
	local beganPos
	if event.name == "began" then
        self.gameObjects:setDirection(0)
		self.parent.dragSpriteNow.collider = nil
		beganPos = event.target:getTouchBeganPosition()
	elseif event.name == "moved" then
		local icon = self.parent.dragSpriteNow:get("icon")
		local movePos = event.target:getTouchMovePosition()
		local rect = self.parent.dragSpriteNow.collider and self.parent.dragSpriteNow.collider:getRect() or nil
		if not icon then
			local cardSprite = widget.addAnimation(self.parent.dragSpriteNow, _gameObject.unit.unitRes, "standby_loop", 5)
				:name("icon")
				:anchorPoint(0.5, 1)
				:xy(0, 10)
				:scale(1)
			cardSprite:setSkin(_gameObject.unit.skin)
		end
		self.parent.dragSpriteNow:xy(movePos.x,movePos.y)
		if cc.rectContainsPoint(self.parent.gameObjectsRect,movePos) then
			if rect and cc.rectContainsPoint(rect,movePos) then return end
			for k,_object in ipairs(self.scene) do
				rect = _object:getRect()
				if cc.rectContainsPoint(_object:getRect(),movePos) then
					self.parent.dragSpriteNow.collider = _object
					self.parent.drawNode:clear()
					self.parent.drawNode:drawRect(cc.p(rect.x,rect.y),cc.p(rect.x+rect.width,rect.y+rect.height),cc.c4f(1, 0, 0, 1))
					return
				end
			end
		end
		self.parent.drawNode:clear()
		self.parent.dragSpriteNow.collider = nil
	elseif event.name == "ended" or event.name == "cancelled" then
		local icon = self.parent.dragSpriteNow:get("icon")
		local movePos = event.target:getTouchMovePosition()
		if self.parent.dragSpriteNow.collider and self.parent.dragSpriteNow.collider.roleId ~= _gameObject.roleId then
			self.parent.dragSpriteNow.collider:init(self.parent.dragSpriteNow.collider.index,self.parent.dragSpriteNow.collider.seat,_gameObject)
			self.parent.drawNode:clear()
			self.parent.dragSpriteNow.collider = nil
		end
		if icon then
			icon:removeFromParent()
		end
        self.gameObjects:setDirection(2)
	end
end

return Gate
