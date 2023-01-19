-- 新号创建控制界面

local NewCharacterView = class("NewCharacterView", cc.load("mvc").ViewBase)
NewCharacterView.RESOURCE_FILENAME = "character.json"
NewCharacterView.RESOURCE_BINDING = {
}

function NewCharacterView:onCreate()
	-- stackUI 开始会 ignoreGuide, 延迟一帧触发
	performWithDelay(self, function()
		self:gotoNext()
		-- 点击背景进入下个界面
		self:getResourceNode():onClick(function()
			self:onShowNextView()
		end)
	end, 0)
	audio.playMusic("city.mp3")
end

-- 自动进行下一步操作，有引导则显示，否则进入下个界面
function NewCharacterView:gotoNext()
	if gGameUI.guideManager:isInGuiding() then
		return
	end
	self.showView = false
	if gGameUI.guideManager:checkGuide({specialName = "nameAndFigureBefore", endCb = functools.partial(self.onShowNextView, self)}) then
		return
	end
	if gGameUI.guideManager:checkGuide({specialName = "chooseCardBefore", endCb = functools.partial(self.onShowNextView, self)}) then
		return
	end
	self:onShowNextView()
end

function NewCharacterView:onShowNextView()
	if gGameUI.guideManager:isInGuiding() then
		return
	end
	if self.showView then
		return
	end
	self.showView = true
	if not gGameUI.guideManager:checkFinished(1) then
		gGameUI:stackUI("new_character.select_figure", nil, nil, self:createHandler("gotoNext"))
		return
	end
	if not gGameUI.guideManager:checkFinished(2) then
		gGameUI:stackUI("new_character.rotation_card", nil, nil, self:createHandler("gotoNext"))
		return
	end
	-- 进入游戏创建角色4
	sdk.commitRoleInfo(4,function()
		print("sdk commitRoleInfo new role")
	end)
	if matchLanguage({"kr"}) then
		sdk.commitRoleInfo(1,function()
			print("info upload for kr version")
		end)
	end
	gGameUI:switchUI("city.view")
end

return NewCharacterView
