-- @date 2021-6-8
-- @desc 学习芯片方案遮罩

local ViewBase = cc.load("mvc").ViewBase
local ChipPlanMaskView = class("ChipPlanMaskView", ViewBase)

ChipPlanMaskView.RESOURCE_FILENAME = "chip_plan_mask.json"
ChipPlanMaskView.RESOURCE_BINDING = {
	["maskPanel"] = "maskPanel",
	["panel"] = "panel",
}

-- params {onClose}
function ChipPlanMaskView:onCreate(params)
	self.params = params
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onMaskClose")})
		:init()

	adapt.dockWithScreen(self.panel, "left")
	text.addEffect(self.panel:get("tip1"), {outline = {color = cc.c4b(250, 93, 107, 255), size = 8}})
	text.addEffect(self.panel:get("tip2"), {outline = {color = cc.c4b(250, 93, 107, 255), size = 8}})

	local box = self.panel:get("bg"):box()
	local pos = self.panel:convertToWorldSpace(cc.p(box.x, box.y))
	local rect = cc.rect(pos.x, pos.y, box.width, box.height)

	local dx, dy = 20, 20
	-- 设置裁剪区域
	local bgRender = cc.RenderTexture:create(display.sizeInView.width, display.sizeInView.height)
		:addTo(self:getResourceNode(), 0, "bgRender")
	local colorLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 178), display.sizeInView.width, display.sizeInView.height)
	local stencil = ccui.Scale9Sprite:create()
	stencil:initWithFile(cc.rect(80, 80, 1, 1), "other/guide/icon_mask.png")
	stencil:anchorPoint(0, 0)
		:size(rect.width - dx * 2, rect.height - dy * 2)
		:xy(self.panel:box().x + box.x + dx, self.panel:box().y + box.y + dy)
	stencil:setBlendFunc({src = GL_DST_ALPHA, dst = 0})
	bgRender:begin()
	colorLayer:visit()
	stencil:visit()
	bgRender:endToLua()

	local img = self.panel:get("img")
	local x, y = img:xy()
	local delay = cc.DelayTime:create(1)
	local sequence = cc.Sequence:create(
		cc.CallFunc:create(function()
			img:xy(x + 100, y + 50)
				:rotate(-30)
				:opacity(0)
				:show()
		end),
		cc.Spawn:create(
			cc.FadeIn:create(0.5),
			cc.RotateTo:create(0.5, 0),
			cc.MoveTo:create(0.5, cc.p(x, y))
		),
		cc.DelayTime:create(0.3),
		cc.CallFunc:create(function()
			img:hide()
		end),
		cc.DelayTime:create(0.5)
	)
	local action = cc.RepeatForever:create(sequence)
	img:runAction(action)

	local bg = self.panel:get("bg")
	bg:clone():addTo(self.panel)
		:xy(bg:xy())
		:z(bg:z() - 1)

	bg:runAction(cc.RepeatForever:create(
		cc.Sequence:create(
			cc.FadeTo:create(1, 50),
			cc.FadeTo:create(1, 255)
		)
	))

	self.maskPanel:setTouchEnabled(false)
	uiEasy.addTouchOneByOne(self.maskPanel, {
		beforeBegan = function(pos, dx, dy)
			if cc.rectContainsPoint(rect, pos) then
				return true
			end
			return false
		end,
	})
end

function ChipPlanMaskView:onMaskClose()
	if self.params.onClose then
		self.params.onClose()
	else
		self:onClose()
	end
end

return ChipPlanMaskView