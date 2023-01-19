local EasyView = {}

EasyView.CustomBtnType = {
	LeftToRight = 1,
	Center = 2,
	RightToLeft = 3,
}

EasyView.stage = {}
EasyView.btnItem = {}
function EasyView.initBaseView(self)
	local view = {}
	view.root = ccui.Layout:create()
		:size(self.stage:width(),self.stage:height())
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,0,0))
		:opacity(200)
		:addTo(self.stage,9999,"baseView")
		:xy(0,0)
		:setTouchEnabled(true)
		:setSwallowTouches(true)

	EasyView.addBtnListToView(
		view,
		{"btnClose|关闭"},
		cc.p(self.stage:width()/2,100),
		EasyView.CustomBtnType.Center
	)

	return view
end

function EasyView.initScrollView(self,width,height)
	local view = EasyView.initBaseView(self)
	view.scrollView = ccui.ScrollView:create()
		:size(self.stage:width(),self.stage:height() - 200)
		:setInnerContainerSize(cc.size(width or self.stage:width()*4,height or self.stage:height() - 200))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,255,0))
		:opacity(100)
		:xy(0,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(0)
	return view
end

local ATTR_WIDTH = 700
local UNIT_WIDTH = 300
function EasyView.initForceScrollView(self,width)
	local view = EasyView.initBaseView(self)
	view.leftFrontUnitScrollView = ccui.ScrollView:create()
		:size(UNIT_WIDTH,(self.stage:height() - 200)/2)
		:setInnerContainerSize(cc.size(UNIT_WIDTH,(self.stage:height() - 200)/2 + 100 ))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(255,0,0))
		:opacity(100)
		:xy(0,200+(self.stage:height() - 200)/2)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(1)

	view.leftBackUnitScrollView = ccui.ScrollView:create()
		:size(UNIT_WIDTH,(self.stage:height() - 200)/2)
		:setInnerContainerSize(cc.size(UNIT_WIDTH,(self.stage:height() - 200)/2 + 100 ))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(255,0,0))
		:opacity(100)
		:xy(0,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(1)

	view.rightFrontUnitScrollView = ccui.ScrollView:create()
		:size(UNIT_WIDTH,(self.stage:height() - 200)/2)
		:setInnerContainerSize(cc.size(UNIT_WIDTH,(self.stage:height() - 200)/2 + 100))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,0,255))
		:opacity(100)
		:xy(UNIT_WIDTH,200+(self.stage:height() - 200)/2)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(1)

	view.rightBackUnitScrollView = ccui.ScrollView:create()
		:size(UNIT_WIDTH,(self.stage:height() - 200)/2)
		:setInnerContainerSize(cc.size(UNIT_WIDTH,(self.stage:height() - 200)/2 + 100))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,0,255))
		:opacity(100)
		:xy(UNIT_WIDTH,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(1)

	view.scrollForceView = ccui.ScrollView:create()
		:size(self.stage:width() - ATTR_WIDTH - 2 * UNIT_WIDTH,self.stage:height() - 200)
		:setInnerContainerSize(cc.size(width or self.stage:width()*4,self.stage:height() - 200))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,255,0))
		:opacity(100)
		:xy(UNIT_WIDTH*2,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"scrollView")
		:setDirection(2)

	view.attrView = ccui.ListView:create()
		:size(ATTR_WIDTH,self.stage:height() - 200)
		:setInnerContainerSize(cc.size(ATTR_WIDTH,self.stage:height()*2))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(123,123,123))
		:opacity(100)
		:addTo(view.root,1,"attrView")
		:xy(self.stage:width() - ATTR_WIDTH,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:setItemsMargin(5)

	return view
end

function EasyView.initForceAttrView(self,width)

end

function EasyView.initListView(self)
	local view = EasyView.initBaseView(self)
	view.listView = ccui.ListView:create()
		:size(self.stage:width(),self.stage:height() - 200)
		:setInnerContainerSize(cc.size(self.stage:width(),self.stage:height()*2))
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,255,0))
		:opacity(100)
		:xy(0,200)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"listView")
		:setItemsMargin(5)


	return view
end

function EasyView.addTextListView(view, pos, size)
	if view.listView then
		view.listView:removeAllItems()
		return
	end
	view.listView = ccui.ListView:create()
		:size(size)
		:setInnerContainerSize(size)
		:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
		:color(cc.c3b(0,255,0))
		:opacity(100)
		:xy(pos)
		:setTouchEnabled(true)
		:setSwallowTouches(true)
		:addTo(view.root,1,"listView")
		:setItemsMargin(5)
end


function EasyView.addInputControl(view, pos, mode, default, idx)
	local editBox = ccui.EditBox:create(cc.size(600,100), "img/editor/input.png")
					:addTo(view.root,1,"input")
					:setFontSize(72)
					:setFontColor(ui.COLORS.NORMAL.DEFAULT)
					:xy(pos)
					:setInputMode(mode)
					:setPlaceHolder(default)
	if idx then
		view.editBox = view.editBox or {}
		view.editBox[idx] = editBox
	else
		view.editBox = editBox
	end
end

-- btnList = {"key|info"}
function EasyView.addBtnListToView(view,btnList,pos,typ)
	local startPos,lerpSize
	local lerpX = 10

	if view.btnClose then
		view.btnClose:removeSelf()
		view.btnClose = nil
	end

	if typ == EasyView.CustomBtnType.Center then
		startPos = cc.p(pos.x - (EasyView.btnItem:width()/3 + lerpX) * (#btnList - 1),pos.y)
		lerpSize = cc.p(EasyView.btnItem:width()/3*2 + 2*lerpX,0)
	end

	local index,btnInfo,btn
	for i,str in ipairs(btnList) do
		index = i - 1
		btnInfo = string.split(str,'|')
		btn = EasyView.btnItem:clone()
		btn:get("label"):text(btnInfo[2])
        btn:addTo(view.root,1,btnInfo[1])
            :xy(startPos.x+lerpSize.x*index,startPos.y+lerpSize.y*index)
        if btnInfo[1] == "btnClose" then
            btn:addClickEventListener(function()
                view.root:removeSelf()
            end)
        end
        view[btnInfo[1]] = btn
	end
end

return EasyView