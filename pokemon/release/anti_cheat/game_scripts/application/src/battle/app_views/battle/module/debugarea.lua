--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 调试区域


local DebugArea = class('DebugArea', battleModule.CBase)

function DebugArea:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	if EDITOR_ENABLE then
		self:addPauseBtn()
		self:addFrameControlBtn()
		self:addEffectControlBtn()
		self:addAutoTestDebug()
		self:addDebugEnabled()
		self:addFullManual()

		-- 新手关卡不显示返回主城测试按钮，需要选角色选卡
		if self.parent.gateType ~= game.GATE_TYPE.newbie and self.parent.gateType ~= game.GATE_TYPE.test then
			self:addEnterCity()
		end

		self.backView = "city.view"
		self.layer = cc.Layer:create()
		self.parent.layer:add(self.layer, 999)

		self:addSpeedControlBtn()
		self:addFrontBgBtn()
		self:addBattleRecordBtn()
		self:addBattleSpriteDebug()
		self:addEffectDebug()

		self:addTintColorDebug()
		self:addCRenderTargetDebug()
		self:addA4Debug()
		self:addThreadDebug()
		self:addSpineDebug()

		self:addSpineTimeScaleDebug()
	end
end

local function getImageName()
	local imagePath = {}
	local path = "res/resources/battle/scene/"
	local fs = require "editor.fs"
	local files = fs.listAllFiles(path, function (name)
		return name:match("%.[jpg|png]")
	end, false)
	local count = 0
	for name, _ in pairs(files) do
		local pos = nil
		while true do
			pos = string.find(name, "/")
			if not pos then break end
			name = string.sub(name, pos + 1)
		end
		count = count + 1
	    local strInfo = "battle/scene/"..name
	    imagePath[count] = strInfo
	end
	return imagePath
end

-- @param next:下一张，front：上一张；
local bgImgPath
function DebugArea:chooseBgImage(chooseTyp)
	if not bgImgPath then
		bgImgPath = getImageName()
	end
	self.currentBg = self.currentBg or 0

	if self.bgSpr then
		self.bgSpr:removeSelf()
	end

	if chooseTyp == "next" then
		self.currentBg = self.currentBg + 1 >= table.length(bgImgPath) and 1 or self.currentBg + 1
	else
		self.currentBg = self.currentBg - 1 <= 0 and table.length(bgImgPath) or self.currentBg - 1
	end
	-- print("查看下状态值：", self.currentBg)
	-- local bgSpr = self:call("setStage", bgImgPath[self.currentBg], 1)
	local bgSpr = cc.Sprite:create(bgImgPath[self.currentBg])
	bgSpr:xy(display.center):scale(2) -- TODO: temp
	self.parent.stageLayer:add(bgSpr)
	self.bgSpr = bgSpr
end

function DebugArea:newBtn(x, y, s)
	local btnContent = cc.Label:createWithTTF(s, ui.FONT_PATH, 40)
	btnContent:setPosition(106, 61)
	local btn = ccui.Button:create("common/btn/btn_normal.png")
	btn:add(btnContent)
	btn:setPressedActionEnabled(true)
	btn:setPosition(cc.p(x, y))
	btn:setOpacity(150)

	if self.layer then
		self.layer:add(btn, 999)
	else
		self.parent.layer:add(btn, 999)
	end

	btn.content = btnContent
	adapt.dockWithScreen(btn, "left")
	btn:setScaleY(0.8)
	return btn
end

-- 测试用,暂停按钮
function DebugArea:addPauseBtn()
	local btn = self:newBtn(80*2, display.cy + 160*2, " stop!")
	btn:onClick(function()
		if display.director:isPaused() then
			display.director:resume()
			gRootViewProxy:proxy():setEffectDebugBreakpoint(nil)
			btn.content:setString(" stop!")
		else
			display.director:pause()
			btn.content:setString(" run! ")
		end
	end)
end

-- 测试用,下一帧按钮
function DebugArea:addFrameControlBtn()
	local btn = self:newBtn(80*2, display.cy + 160*2 - 80, "下一帧")
	btn:onClick(function()
		display.director:resume()
		print('resume')
		performWithDelay(btn, function()
			print('pause')
			display.director:pause()
		end, 1/60)
	end)
end

function DebugArea:addEffectControlBtn()
	local btn = self:newBtn(80*2, display.cy + 160*2 - 2*80, "下一Effect")
	btn:onClick(function()
		display.director:resume()
		print('resume effect')
		gRootViewProxy:proxy():setEffectDebugBreakpoint(function(manager, id, effect)
			print('pause effect', string.format('%d/%d', id, manager.queTailID), effect, toDebugString(effect))
			display.director:pause()
			return false
		end)
	end)
end

function DebugArea:backToLogin()
	self.backView = "login.view"
end

-- 测试用,返回主城界面
function DebugArea:addEnterCity()
	local btn = self:newBtn(80*2, display.cy + 160*2 - 3*80, "返回主城")
	btn:onClick(function ()
		local goldIdler = gGameModel.role:getRawIdler_("gold")
		if goldIdler then
			print("refresh gold for test", goldIdler, gold)
			goldIdler:notify()
		end

		gGameUI:switchUI(self.backView)

		if goldIdler then
			print("refresh gold for test", goldIdler, gold)
			goldIdler:notify()
		end
	end)
end

function DebugArea:addDebugEnabled()
	local flag = false
	local btn = self:newBtn(80*2, display.cy + 160*2 - 8*80, "debug开关")
	btn:onClick(function ()
		flag = not flag
		self.layer:setVisible(flag)
	end)
end

-- 全局手动
function DebugArea:addFullManual(  )
	local flag = false
	local btn = self:newBtn(80*2, display.cy + 160*2 - 9*80, "全局手动关")
	local isAuto
	btn:onClick(function ()
		local scene = gGameUI.uiRoot._model.scene
		local gate = scene.play
		-- test,玩家对战和战报才可以控制
		if scene.isRecord or gate.data.gateType == game.GATE_TYPE.test or gate.data.gateType == game.GATE_TYPE.friendFight then
			if not flag then
				isAuto = scene.autoFight
				scene:setAutoFight(false)
			else
				if not gate:isMyTurn() then
					gGameUI:showTip("攻击切换至本方阵营再关闭")
					return
				end
				scene:setAutoFight(isAuto)
			end
			flag = not flag
			btn.content:setString(flag and "全局手动开" or "全局手动关")
			scene:setFullManual(flag)
		else
			gGameUI:showTip("该场景不支持全局手动")
		end
	end)
end

-- 测试用 模拟本场战斗100次
function DebugArea:addAutoTestDebug()
	local btn = self:newBtn(80*2, display.cy + 160*2 - 7*80, "模拟战斗100次")
	btn:onClick(function ()
		local data = self.parent.data
		gGameUI:switchUI("city.view")
		performWithDelay(gGameUI.scene,function()
			local testTimes = 100
			local winTimes = 0
			local loseTimes = 0
			for i = 1,testTimes do
			-- only for test battle
			-- hacked some data and func
				data.randSeed = math.random(1, 99999999)
				local result = battleEntrance.battleRecord(data, 'unknown', {fromRecordFile=true})
				:run()
				if result.result == "win" then
					winTimes = winTimes + 1
				elseif result.result == "fail" then
					loseTimes = loseTimes + 1
				end
				print(string.format("[INFO] 当前: %d (%d vs %d)",testTimes,winTimes,loseTimes))
				print(string.format("[INFO] RunTime: (%d/%d), Seed: %d",i,testTimes,data.randSeed))
			end
			print(string.format("[INFO] 总战斗测试次数: %d 其中赢%d次 输%d次",testTimes,winTimes,loseTimes))
		end,5)
	end)
end

-- 测试用,加速减速按钮
function DebugArea:addSpeedControlBtn()
	local btn1 = self:newBtn(950, 150, "加速")
	btn1:onClick(function()
		local old = display.director:getScheduler():getTimeScale()
		local new = math.min(20, old + 1)
		display.director:getScheduler():setTimeScale(new)
		gGameUI:showTip("加速，现在速度"..new)
		print('speed up', new)
	end)

	local btn2 = self:newBtn(950, 150 - 80, "减速")
	btn2:onClick(function()
		local old = display.director:getScheduler():getTimeScale()
		local new = old - 1
		if old - 1 < 1 then
			new = old - 0.3
		end
		new = math.max(0.1, new)
		display.director:getScheduler():setTimeScale(new)
		if new >= 1 then
			gGameUI:showTip("减速，现在速度"..new)
		else
			gGameUI:cleanTip()
		end
		print('speed down', new)
	end)
end

-- 测试用，临时覆盖一层，场景循环切换,上一张
function DebugArea:addFrontBgBtn()
	local btn = self:newBtn(1150, 150, "上一张")
	btn:onClick(function ()
		self:chooseBgImage("front")
	end)
end


function DebugArea:addBattleRecordBtn()
	local btn = self:newBtn(1150, 150 - 80, "战斗数据")
	local lastUnitIds = {}
	local ignoreUnitIds = {
		[3245] = true, --酋雷姆的冰块
	}
	btn:onClick(function ()
		if gGameUI.rootViewName:find("battle.view") then
			if not self.battleDataDisplay then
				local scene = gGameUI.uiRoot._model.scene
				self.battleDataDisplay = gGameUI:createView("city.test.test_battle_data_display", gGameUI.uiRoot):init():z(999)

				local function getData()
					if gGameUI.rootViewName:find("battle.view") then
						local data = {}
						-- 死亡单位没有, 用之前存的对象数据计算
						local newIds = {}
						for _, obj in scene:ipairsHeros() do
							newIds[obj.seat] = obj.unitID
							if not ignoreUnitIds[obj.orginUnitId] then
								data[obj.seat] = {
									seat = obj.seat,
									dbID = obj.dbID,
									unitID = obj.orginUnitId,
									star = obj.star,
									advance = obj.data.advance,
									level = obj.level,
									totalDamage = obj.totalDamage,
									totalResumeHp = obj.totalResumeHp,
									totalTakeDamage = obj.totalTakeDamage,
									bigSkillUseTimes = obj:getEventByKey(battle.MainSkillType.BigSkill)
								}
							end
						end
						if not itertools.equal(newIds, lastUnitIds) then
							-- print_r(newIds)
							lastUnitIds = newIds
						end
						return data
					end
				end
				self.battleDataDisplay:refresh(getData())
				schedule(self.battleDataDisplay, function()
					self.battleDataDisplay:refresh(getData())
				end, 1/30)
			else
				self.battleDataDisplay:visible(not self.battleDataDisplay:visible())
			end
		end
	end)
end

function DebugArea:addBattleSpriteDebug()
	local flag = false
	local btn = self:newBtn(1350, 150, "点位显示")
	btn:onClick(function ()
		btn.content:setString(flag and "点位显示" or "点位隐藏")
		flag = not flag
		local objs = gRootViewProxy:call("getSceneObjs")
		for key, sprite in pairs(objs) do
			if sprite.seat < 13 then
				sprite:setDebugEnabled(flag)
			end
		end
	end)
end

function DebugArea:addEffectDebug()
	local flag = false
	local btn = self:newBtn(1350, 150 - 80, "Effect显示")
	btn:onClick(function ()
		btn.content:setString(flag and "Effect显示" or "Effect隐藏")
		flag = not flag
		local objs = gRootViewProxy:call("getSceneObjs")
		for key, sprite in pairs(objs) do
			if sprite.seat < 13 then
				sprite:setEffectDebugEnabled(flag)
			end
		end
		gRootViewProxy:proxy():setEffectDebugEnabled(flag)
	end)
end

function DebugArea:addTintColorDebug()
	local flag = false
	local btn = self:newBtn(950, 150 + 80, "TintColor开")
	btn:onClick(function ()
		btn.content:setString(flag and "TintColor开" or "TintColor关")
		flag = not flag
		for sp, sprite in pairs(SpineSpritesMap) do
			if tolua.isnull(sp) then
				printWarn("spine %s released but no gc", tostring(sp))
			else
				printInfo("spine %s	%s %s tint color", tostring(sp), sprite.__aniRes, flag and "open" or "close")
				sp:setTwoColorTint(flag)
			end
		end
	end)
end


function DebugArea:addCRenderTargetDebug()
	local flag = true
	local btn = self:newBtn(1150, 150 + 80*2, "RT关")
	btn:onClick(function ()
		btn.content:setString(flag and "RT开" or "RT关")
		flag = not flag
		for rt, dbg in pairs(CRenderSpritesMap) do
			if tolua.isnull(rt) then
				printWarn("render_target %s released but no gc", tostring(rt))
			else
				printInfo("render_target %s	%s %s", tostring(rt), rt:name(), flag and "show" or "hide")
				rt:setVisible(flag)
				if dbg then
					rt:addDebugLayer()
					CRenderSpritesMap[rt] = false
				end
			end
		end
	end)
end

function DebugArea:addA4Debug()
	local flag = false
	local btn = self:newBtn(1150, 150 + 80, "A4开")
	btn:onClick(function ()
		btn.content:setString(flag and "A4开" or "A4关")
		flag = not flag

		local format = cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888
		if flag then
			format = cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444
		end

		printInfo("A4 default %s %s", flag and "true" or "false", format)

		cc.Texture2D:setDefaultAlphaPixelFormat(format)
		display.textureCache:removeAllTextures()
	end)
end

function DebugArea:addThreadDebug()
	local flag = false
	local btn = self:newBtn(1350, 150 + 80*2, "Thread开")
	btn:onClick(function ()
		btn.content:setString(flag and "Thread开" or "Thread关")
		flag = not flag

		printInfo("Thread %s", flag and "true" or "false")

		display.director:setSpineThreadDrawEnabled(flag)
	end)
end


function DebugArea:addSpineDebug()
	local btn = self:newBtn(1350, 150 + 80, "Spine隐藏")
	btn:onClick(function ()
		local cnt = 0
		for sp, sprite in pairs(SpineSpritesMap) do
			if tolua.isnull(sp) then
				printWarn("spine %s released but no gc", tostring(sp))
			else
				if sp:isVisible() then
					printInfo("spine %s	%s hide", tostring(sp), sprite.__aniRes)
					sp:setVisible(false)
					cnt = cnt + 1
					return
				end
			end
		end

		if cnt == 0 then
			for sp, sprite in pairs(SpineSpritesMap) do
				if not tolua.isnull(sp) then
					sp:setVisible(true)
					printInfo("spine %s	%s show", tostring(sp), sprite.__aniRes)
				end
			end
		end
	end)
end

function DebugArea:addSpineTimeScaleDebug()
	local step = 10
	local fps = 60
	local btn = self:newBtn(950, 150 + 80 * 2, "Spine帧率"..tostring(fps))
	btn:onClick(function ()
		display.director:setSpineInterval(1. / fps)
		printInfo("spine fps %s", tostring(fps))

		if fps <= 30 then
			display.director:setAnimationInterval(1. / 30)
		else
			display.director:setAnimationInterval(1. / 60)
		end

		fps = fps - step
		if fps <= 0 then
			fps = 60
		end
		btn.content:setString("Spine帧率"..tostring(fps))
	end)
end

return DebugArea