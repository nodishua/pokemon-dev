-- @date:   2020-06-04
-- @desc:   竞技场段位改变页面

local BattleEndPvpStageUpView = class("BattleEndPvpStageUpView", cc.load("mvc").ViewBase)
BattleEndPvpStageUpView.RESOURCE_FILENAME = "battle_end_pvp_stage_up.json"
BattleEndPvpStageUpView.RESOURCE_BINDING = {
	["stage"] = {
		varname = "stage",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.DEFAULT}}
		}
	},
	["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onCloseClick"),
		},
    },
	["stageChange"] = "stageChange",
	["stageTxt"] = "stageTxt",
}

-- 播放段位底特效
function BattleEndPvpStageUpView:playEffect(prepinyin, curpinyin)
	-- 默认段位底特效为effect_loop, 钻石-大师、大师-王者、钻石-王者 底特效为effect_up
	local cureffect = "effect_loop"
	if (prepinyin == "zuanshi" and curpinyin == "dashi")
		or (prepinyin == "dashi" and curpinyin == "wangzhe")
		or (prepinyin == "zuanshi" and curpinyin == "wangzhe") then
		cureffect = "effect_up"
	end
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "crossarena/duanwei_di.skel", "selEffect", cureffect, 100)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self.stageChange:xy())
		:scale(2)
		:play(cureffect)
end

-- 播放段位特效
function BattleEndPvpStageUpView:playUPEffect(prepinyin, curpinyin, preMidTxt, curMidTxt)
	-- 大段位提升用段位名_up, 小段位提升用段位名_loop
	local cureffect = prepinyin .. "_loop"
	if prepinyin ~= curpinyin then cureffect = prepinyin .. "_up" end
	local pnode = self:getResourceNode()
	local selEffect1 = widget.addAnimationByKey(pnode, "crossarena/duanwei.skel", "selEffect1", cureffect, 100)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self.stageChange:xy())
		:scale(2.2)

	local function getMidTxt(txtInfo, pinyinInfo)
		-- 大师和王者中间不需要加数字标记
		local midTxt = txtInfo
		if txtInfo == 'K' then
			if pinyinInfo == "dashi" then midTxt = gLanguageCsv.crossArenaStage18
			else midTxt = gLanguageCsv.crossArenaStage19 end
		end
		return midTxt
	end
	-- 小段位提升增加一次性特效 光效
	if prepinyin == curpinyin then
		self.stageTxt:text(getMidTxt(curMidTxt, curpinyin))
		local oncePnode = self:getResourceNode()
		widget.addAnimationByKey(oncePnode, "crossarena/duanwei_shengji.skel", "selEffect2", "effect", 100)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self.stageChange:xy())
		:play("effect")
	else
		-- 大段位提升放完up特效后 延迟1.8s后释放loop特效
		local needMorePnode = self:getResourceNode()
		performWithDelay(needMorePnode, function()
			selEffect1:hide()
			widget.addAnimationByKey(needMorePnode, "crossarena/duanwei.skel", "selEffect3", curpinyin .. "_loop", 100)
			:anchorPoint(cc.p(0.5,0.5))
			:xy(self.stageChange:xy())
			:scale(2.2)
			:play(curpinyin .. "_loop")
		end, 1.8)
		-- 中间文字渐隐渐现处理
		transition.executeSequence(self.stageTxt)
		:func(function ()
			self.stageTxt:text(getMidTxt(preMidTxt, prepinyin))
		end)
		:fadeOut(0.8)
		:done()
		performWithDelay(self.stageTxt, function()
			transition.executeSequence(self.stageTxt)
			:func(function ()
				self.stageTxt:text(getMidTxt(curMidTxt, curpinyin))
			end)
			:fadeIn(1)
			:done()
		end, 1)
	end
	self.stageTxt:scale(1.5)
end

function BattleEndPvpStageUpView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("pvp_win.mp3")
	self.data = data
	self.results = results
	local serverDataView = results.serverData.view
	local curRank = serverDataView.rank
	local preRank = curRank + serverDataView.rank_move
	local predata = dataEasy.getCrossArenaStageByRank(preRank)
	local curdata = dataEasy.getCrossArenaStageByRank(curRank)
	self.stage:text(gLanguageCsv.crossArenaRankUPTo .. curdata.stageName)
	local prepinyin, curpinyin, preMidTxt, curMidTxt
	local csvId = gGameModel.cross_arena:read("csvID")
	local version = csv.cross.service[csvId].version
	for k, v in ipairs(csv.cross.arena.stage) do
		if v.version == version then
			if curdata.stageName == v.stageName then
				curMidTxt = v.stageLevel
				curpinyin = v.stagePinyin
			end
			if predata.stageName == v.stageName then
				preMidTxt = v.stageLevel
				prepinyin = v.stagePinyin
			end
		end
	end
	self:playEffect(prepinyin, curpinyin)
	self:playUPEffect(prepinyin, curpinyin, preMidTxt, curMidTxt)
end

function BattleEndPvpStageUpView:onCloseClick()
	gGameUI:switchUI("city.view")
end

return BattleEndPvpStageUpView

