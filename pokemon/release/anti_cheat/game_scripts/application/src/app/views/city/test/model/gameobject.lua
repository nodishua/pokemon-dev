local IDCount = 0
local GameObject = class("GameObject")

-- local index2seat = function(index)
--     local seat = seatMap[index] or index
--     return seat
-- end

function GameObject:ctor(node)
    self.node = node
    self.unit = {}
    self.roleData = {}
    self.force = 1
    self.seat = 0
    self.index = 0
    self.selectShowChild = {"del"}
    text.addEffect(self.node:get("heroName"), {color=ui.COLORS.GREEN, outline={color=ui.COLORS.BLUE},
		shadow={color=ui.COLORS.RED, offset=cc.size(6,-6), size=6}, italic=true})

    IDCount = IDCount + 1
    self.id = IDCount
    self.node:setName("gameObject_" .. IDCount)

end

function GameObject:_init(index,seat,_object)
	self.unit = _object and csv.unit[_object.roleId] or {}
    self.roleId = _object and _object.roleId or 0
    self.roleData.roleId = self.roleId

    self.index = index
    self.seat = seat or index
    self.force = self.seat > 6 and 2 or 1

    if self.node:get("icon") then
        self.node:get("icon"):removeFromParent()
    end

    if self.unit.unitRes then
        local rate = self.force == 2 and -1 or 1
        local cardSprite = widget.addAnimation(self.node, self.unit.unitRes, "standby_loop", 5)
            :name("icon")
		    :anchorPoint(0.5, 0)
		    :xy(self.node:size().width/2, 80)
		    :scale(rate*2,2)
        cardSprite:setSkin(self.unit.skin)
    end

    local name = self.node:get("heroName")
    if self.unit.name then
        name:text(self.unit.name)
    else
        name:text("heroName")
    end

    for _,childName in ipairs(self.selectShowChild) do
        self.node:get(childName):visible(false)
    end
end

function GameObject:init(index, seat, _prefab)
    self.roleData = _prefab and _prefab:getRoleData() or {}
    self.prefab = _prefab

	self:_init(index, seat, _prefab)
end

function GameObject:initByObject(index,seat,_object)
    self.roleData = _object and _object:getRoleData() or {}

	self:_init(index,seat,_object)
end

function GameObject:initByRoleData(index,seat,_roleData)
    self.roleData = _roleData or {}

	self:_init(index,seat,_roleData)
end

function GameObject:clean()
    self.node:removeFromParent()
end

function GameObject:loadRoleData(roleData)
    roleData = roleData or {}
    for attrName,val in pairs(roleData) do
        self.roleData[attrName] = val
    end
end

function GameObject:getRect()
    local _parent = self.node:parent()
    local pos = _parent:convertToWorldSpace(cc.p(self.node:x(),self.node:y()))
    local size = cc.size(self.node:width()*self.node:scaleX(),self.node:height()*self.node:scaleY())
    local lerpPos = cc.p(pos.x - size.width/2 , pos.y - size.height/2)
    return cc.rect(lerpPos.x
        ,lerpPos.y
        ,size.width
        ,size.height)
end

function GameObject:getRoleData()
    return self.roleId ~= 0 and csvClone(self.roleData) or nil
end

return GameObject