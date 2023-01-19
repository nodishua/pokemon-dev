--
--  战斗胜利界面 -- 通用的界面
--

local BattleEndWinView = class("BattleEndWinView", cc.load("mvc").ViewBase)

BattleEndWinView.RESOURCE_FILENAME = "battle_end_clone_win.json"
BattleEndWinView.RESOURCE_BINDING = {
	["receiveBtn.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
    ["backBtn.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["receiveBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReceiveBtnClick")}
		},
	},
    ["backBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackBtnClick")}
		},
	},
    ["exitText"] = "exitText",
    ["receiveBtn.awardCondText"] = "awardCondText",
    ["receiveBtn.awardInfoText"] = "awardInfoText",
}

function BattleEndWinView:playEndEffect()
	local pnode = self:getResourceNode()
    local pnodePosX,pnodePosY = pnode:get("awardPnl"):getPosition()
	-- 结算特效
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,1.0))
	textEffect:setPosition(pnodePosX,pnodePosY)
	textEffect:visible(true)
    textEffect:setName("spine_1")
	-- 播放结算特效
	textEffect:play("jiesuan_shenglizi")
	textEffect:addPlay("jiesuan_shenglizi_loop")
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,1.0))
	bgEffect:setPosition(pnodePosX,pnodePosY)
	bgEffect:visible(true)
    bgEffect:setName("spine_2")
	-- 播放结算特效
	bgEffect:play("jiesuan_shenglitu")
	bgEffect:addPlay("jiesuan_shenglitu_loop")
	bgEffect:retain()

    self.awardEffect = CSprite.new("clone_battle/baoxiang.skel")		-- 底部特效
	self.awardEffect:addTo(pnode, 99)
	self.awardEffect:setAnchorPoint(cc.p(0.5,0.5))
	self.awardEffect:setPosition(pnodePosX,pnodePosY - 250)
	self.awardEffect:visible(true)
    self.awardEffect:scale(2)
    self.awardEffect:setName("spine_3")
	-- 播放结算特效
	self.awardEffect:play("huangxiangzi_loop")
	self.awardEffect:retain()
end

-- results: 放数据的
function BattleEndWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")
	self.data = data
	self.results = results
	self.sceneID = sceneID
    self.isFirstAward = true
    self.drawNum = 0
    self.consumeNum = 1
    local places = gGameModel.clone_room:read("places")
   	local monsterCsvId
   	local roleId = gGameModel.role:read('id')
   	for k,v in pairs(places) do
   		if v.id == roleId then
   			monsterCsvId = v.monster
   		end
   	end
   	local cardCsvId = csv.clone.monster[monsterCsvId].cardID
   	local unitId = csv.cards[cardCsvId].unitID
   	local rarity = csv.unit[unitId].rarity
   	self.seqParam = csv.clone.draw_box_cost[rarity].seqParam
    self.receiveMax = table.length(self.seqParam)

	local pnode = self:getResourceNode()
	local btnTextTb = {
		receiveBtn = "commonTextGet",
        backBtn = "back",
	}
	for btnName, str in pairs(btnTextTb) do
		pnode:get(btnName .. ".text"):text(gLanguageCsv[str])
	end

	--self:showPlayerExpInfo()

    self.exitText:text(gLanguageCsv.click2Exit)
    self.exitText:visible(false)

	-- 结算特效
	self:playEndEffect()
    self:updateAwardInfo(0)
end

--奖励布局相关
function BattleEndWinView:updateAwardInfo(receiveTime)
    local pnode = self:getResourceNode()
    local receiveBtn = pnode:get("receiveBtn")
    local backBtn = pnode:get("backBtn")

    if self.isFirstAward then
        backBtn:visible(false)
        self.awardCondText:get("icon"):visible(false)
        self.awardInfoText:setString(gLanguageCsv.canOpen .. string.format("(%s/%s)",self.receiveMax,self.receiveMax))
        --self.exitText:visible(false)
    else
		if receiveTime == 0 then
			backBtn:visible(true)
			self.awardCondText:get("icon"):visible(true)
			receiveBtn:setPositionX(2*receiveBtn:getPositionX()-backBtn:getPositionX())
			pnode:get("bg"):setColor(cc.c3b(0,0,0))
			pnode:get("bkg"):visible(false)
			--移除胜利动画
			pnode:removeChildByName("spine_1")
			pnode:removeChildByName("spine_2")
			--self.exitText:visible(true)
		end

        local lerpTime = self.receiveMax - receiveTime
        if lerpTime ~= 0 then
--            self.awardCondText:visible(false)
--            uiEasy.setBtnShader(receiveBtn, nil, 3)
			local consume = self.seqParam[self.consumeNum]
            self.awardCondText:setString(string.format(gLanguageCsv.cost..": %s", consume))
            self.consumeNum = self.consumeNum + 1
        end
        self.awardInfoText:setString(string.format(gLanguageCsv.canOpenTimes,lerpTime,self.receiveMax))
    end
end

function BattleEndWinView:onReceiveBtnClick()
    self:dealDealyTime(false)
    local callback = function(tb,fromServer)
		local result = tb.view.result
        self.drawNum = tb.drawNum
        self:updateAwardInfo(tb.drawNum)
        self.awardEffect:play("huangxiangzikaixiang")
        performWithDelay(self,function()
            gGameUI:showGainDisplay(result,{raw =fromServer , cb = function()
                if self.drawNum == self.receiveMax then
                    self:onBackBtnClick()
                    gGameUI:showTip(gLanguageCsv.rewardBoxReciveOver)
                else
                    self.awardEffect:play("huangxiangzi_loop")
                end
            end})
			self:dealDealyTime(true)
        end,1)
	end
	if self.isFirstAward then
		self.isFirstAward = false
		callback({
			view = {result = self.results.freeBox},
			drawNum = self.drawNum,
		},false)
	else
        local cost = self.seqParam[self.drawNum + 1]
        local function tryOpenRecharge()
		    -- 点金和购买体力，已经在充值界面上的，直接关闭其界面返回充值
		    if not gGameUI:goBackInStackUI("city.recharge") then
			    gGameUI:stackUI("city.recharge", nil, {full = true})
		    end
	    end
        if cost > gGameModel.role:getIdler("rmb"):read() then
            gGameUI:showDialog({title = gLanguageCsv.rmbNotEnough, content = gLanguageCsv.noDiamondGoRecharge, cb = tryOpenRecharge, btnType = 2, clearFast = true})
            self:dealDealyTime(true)
        else
        	 self.drawNum = self.drawNum + 1
            gGameApp:requestServer("/game/clone/box/draw", callback)
        end
	end
end

function BattleEndWinView:dealDealyTime(isFinish)
    local pnode = self:getResourceNode()
    local receiveBtn = pnode:get("receiveBtn")
    local backBtn = pnode:get("backBtn")

    receiveBtn:setEnabled(isFinish)
    backBtn:setEnabled(isFinish)
end

function BattleEndWinView:onBackBtnClick()
	gGameUI:switchUI("city.view")
	gGameUI:goBackInStackUI("city.adventure.clone_battle.base")
end

return BattleEndWinView

