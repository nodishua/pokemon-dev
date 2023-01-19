-- @date 2021-03-11
-- @desc 走格子-厄运卡界面

local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
local GridWalkScratch = class("GridWalkScratch", Dialog)

GridWalkScratch.RESOURCE_FILENAME = "grid_walk_scratch.json"
GridWalkScratch.RESOURCE_BINDING = {
	["imgBG"] = "imgBG",
    ["imgBG.imgGJ"] = "imgGJ",
    ["imgBG.resultPanel"] = "resultPanel",
    ["imgBG.drawPanel"] = "drawPanel",
    ["imgBG.touchPanel"] = {
		binds = {
			event = "touch",
			method = bindHelper.self("onScratchClick"),
			scaletype = 0,
		},
	},
	["imgBG.textNum"] = {
		varname = "textNum",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("num"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.NORMAL.DEFAULT, size = 6}},
			},
		},
	},
	["imgBG.icon"] = {
		varname = "icon",
		binds = {
			event = "texture",
			idler = bindHelper.self("img"),
		},
	},
	["textNote"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("opened"),
		},
	},
	["imgBG.resultPanel.text"] = "text",
	["imgBG.resultPanel.text1"] = "text1",
	["imgBG.resultPanel.num"] = {
		varname = "leftNum",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		},
	},
}

function GridWalkScratch:onCreate(params)
	self.callBack = params.callBack
	local iconNum = params.iconNum
	local event = params.event
	local index = event.params.outcome + 1
	local cfg = csv.yunying.grid_walk_events[event.csv_id]
	local items = cfg.params.items[index]
	local leftNum = dataEasy.getNumByKey(items[1])
	if items[1] == gridWalkTools.BADGE_ID then
		self.badgeNum = items[2]
		leftNum = math.max(iconNum - self.badgeNum, 0)
	end
	local itemCfg = dataEasy.getCfgByKey(items[1])
	local n = items[2]
	self.leftNum:text(leftNum)
	adapt.oneLinePos(self.text, {self.leftNum, self.text1}, cc.p(10, 0))
	self.imgGJ:show()
	self.img = idler.new(itemCfg.icon)
	self.num = idler.new(-n)
	self.opened = idler.new(false)

	self.moveLength = 0
	self.lastX = 0
	self.lastY = 0
	self.showType = 0
	self.resultPanel:hide()
	Dialog.onCreate(self)
end

function GridWalkScratch:onScratchClick(sender, event)
	if event.name == "began" then
		self.lastX = event.x
		self.lastY = event.y
	elseif event.name == "moved" then
		self.moveLength = self.moveLength + math.sqrt(math.pow((self.lastX - event.x), 2) +  math.pow((self.lastY - event.y), 2))
		self.lastX = event.x
		self.lastY = event.y
		if self.moveLength > 2000 then
			self:showMask(3)
		elseif self.moveLength > 1350 then
			self:showMask(2)
		elseif self.moveLength > 600 then
			self:showMask(1)
		end
	elseif event.name == "ended" then
		if self.moveLength > 2000 then
			performWithDelay(self, function()
				self.opened:set(true)
				self.drawPanel:hide()
				self.resultPanel:show()
				sender:hide()
			end, 0)
		end
	end
end

function GridWalkScratch:showMask(type)
	if type <= self.showType then return end
	self.imgGJ:hide()
	self.showType = type
	self.drawPanel:removeAllChildren()
	local bgRender = cc.RenderTexture:create(self.drawPanel:width(), self.drawPanel:height())
		:addTo(self.drawPanel, 5, "bgRender")
	bgRender:begin()
	local bg = ccui.ImageView:create("activity/grid_walk/img_eyk5.png"):xy(self.imgGJ:x(), self.imgGJ:y())
	bg:visit()
	for i=1, 3 do
		local stencil = ccui.ImageView:create("activity/grid_walk/img_eyk_mask.png"):xy(self.imgGJ:x(), self.imgGJ:y() - 100 + 50*i)
		stencil:setBlendFunc({src = GL_DST_ALPHA, dst = GL_SRC_ALPHA})
		if type == 2 then
			stencil:scale(1.1)
		elseif type == 3 then
			stencil:scale(1.3)
		end
		stencil:visit()
		if type == i then break end
	end
	bgRender:endToLua()
end

function GridWalkScratch:onClose()
	if self.opened:read() == true then
		self:addCallbackOnExit(functools.partial(self.callBack, self.badgeNum))
		Dialog.onClose(self)
	end
end

return GridWalkScratch