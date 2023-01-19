require "battle.app_views.battle.preload_res"

local LOADING_STATE = {
	loading = 1,
	loadOver = 2,
	switchUI = 3,
}

local ViewBase = cc.load("mvc").ViewBase
local BattleLoadingView = class("BattleLoadingView", ViewBase)

BattleLoadingView.RESOURCE_FILENAME = "battle_loading.json"
BattleLoadingView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("percent"),
				maskImg = "common/icon/mask_bar_red.png"
			}
		},
	},
	["percentText"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("percent"),
				method = function(val)
					return math.floor(val) .. "%"
				end
			},{
				event = "effect",
				data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
			},
		}
	},
	["tipText"] = {
		varname = "tipText",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	}
}

local function fillResMap(resT, t)
	for k, v in pairs(t) do
		resT[v] = 1 + (resT[v] or 0)
	end
end

function BattleLoadingView:onCreate(data, sceneID, modes, entrance)
	assert(entrance, "entrance was nil !")

	self.data = data
	self.sceneID = sceneID
	self.modes = modes or {}
	self.entrance = entrance 
	self.percent = idler.new(0)

	local idx = math.random(1, csvSize(csv.loading_tips))
	self.tipText:text(csv.loading_tips[idx].tip)

	local bgIdx = math.random(1, table.length(gCommonConfigArrayCsv.loadingBgTotal))
	self.bg:texture(string.format("loading/bg_%d.png", gCommonConfigArrayCsv.loadingBgTotal[bgIdx]))

	self:enableAsyncload()
		:asyncFor(functools.partial(self.onLoading, self), functools.partial(self.onLoadOver, self))

	local x, y = self.bar:xy()
	local size = self.bar:box()
	local effect = widget.addAnimationByKey(self:getResourceNode(), "loading/loading_pikaqiu.skel", "effect", "effect_loop", 5)
		:xy(x - size.width/2, y + size.height/2)
		:scale(1.6)

	idlereasy.when(self.percent, function(_, percent)
		effect:x(x - size.width/2 + percent * size.width / 100)
	end)

	self.canPlayMusic = false
	if not self.modes.baseMusic then
		--背景音乐就一个,不一样的接口特殊加
		local bgMusic = math.random(1, 5)
		local sMusic = string.format("battle%d.mp3", bgMusic) -- 音乐文件过大，电脑上无法播放
		--记录当前的音乐,方便技能中换了背景音乐后还能再换回来
		self.modes.baseMusic = sMusic
	end
	audio.preloadMusic(self.modes.baseMusic)
end

-- loading 预加载资源有 spine，png，jpg，audio
-- 图片资源通过CSprite.preLoad完成
-- spine的预加载会生成实际的CSprite，并存入cache
-- png和jpg只是用addImageAsync加载了贴图
function BattleLoadingView:onLoading()
	local mem = collectgarbage("count")
	self.loadingState = LOADING_STATE.loading

	self.percent:set(1)
	coroutine.yield()

	self.percent:set(4)
	cache.onBattleClear()
	coroutine.yield()

	self.percent:set(5)
	checkGGCheat()
	coroutine.yield()

	self.percent:set(6)
	battleEntrance.preloadConfig()

	-- async load image
	self.percent:set(7)
	cache.texturePreload("battle_common_ui")
	cache.texturePreload("battle_module")
	coroutine.yield()

	local resT = {}
	local audioT = {} --所有音效,除了背景音乐
	local monsterCfg = gMonsterCsv[self.sceneID][1]
	if not monsterCfg then
		printError(" 查找 monster_scenes 时出错!!! 有场景第一波的配置不存在: sceneID=%s", self.sceneID)
	end
	visitFightResources(resT, audioT, monsterCfg, self.data)
	-- 预加载所有波次音效
	for i = 2, itertools.size(gMonsterCsv[self.sceneID]) do
		local monsterCfg = gMonsterCsv[self.sceneID][i]
		for _, unitId in ipairs(monsterCfg.monsters) do
			if unitId > 0 then
				local cfg = csv.unit[unitId]
				for i, skillId in ipairs(cfg.skillList) do
					local skillCfg = csv.skill[skillId]
					if skillCfg.sound then
						audioT[skillCfg.sound.res] = true
					end
				end
			end
		end
	end

	-- res define in battle code
	fillResMap(resT, battle.SpriteRes)
	fillResMap(resT, battle.ShowHeadNumberRes)
	fillResMap(resT, battle.MainAreaRes)
	fillResMap(resT, battle.StageRes)
	fillResMap(resT, battle.RestraintTypeIcon)

	local current = 0
	local allCount = itertools.sum(resT) + itertools.size(audioT)
	log.battleloading.preload(" ---- preLoad res, allCount=", allCount, itertools.sum(resT), itertools.size(audioT))
	self.percent:set(10)
	coroutine.yield()

	-- must invoke in main, not in coroutine, otherwise ymrand will be crash
	performWithDelay(self, function()
		-- _runBattleModel if exist, like arena
		self:onRunBattleModel()
	end, 0.01)

	cc.SpriteFrameCache:getInstance():addSpriteFrames('battle/buff_icon/buffs0.plist')
	cc.SpriteFrameCache:getInstance():addSpriteFrames('battle/txt/txts0.plist')
	coroutine.yield()

	-- 最后加载实际资源
	for k, count in pairs(resT) do
		log.battleloading.preload(' ---- preload: file path=', k, count)
		for i = 1, count do
			CSprite.preLoad(k) --专门提供一个预加载的，不然实际创建出来太浪费
			current = current + 1
			self.percent:set(10 + 70*current/allCount)
			coroutine.yield()
		end
	end

	-- remove unsed textures
	-- -1是因为ios/android实现上的bug，导致texture removeLongTimeUnusedTexturesWithCallback永远不成功
	local fileUtils = cc.FileUtils:getInstance()
	local n = display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
		local path = fileUtils:getRawPathInRepoCache(tex:getPath())
		return not ((path:find("battle/") ~= nil) or (path:find("res/spine/koudai_") ~= nil))
	end, 0, -1) -- 60
	if n > 0 then
		printInfo('remove %d textures in battle.loading', n)
	end
	coroutine.yield()

	self.canPlayMusic = true

	for k, v in pairs(audioT) do
		log.battleloading.preload(' ---- preload: audio path=', k, v)
		audio.preloadSound(k)
		current = current + 1
		self.percent:set(10 + 70*current/allCount)
		coroutine.yield()
	end

	-- step gc
	for i = 1, 15 do
		collectgarbage("step", 10000)
		self.percent:set(80 + i)
		coroutine.yield()
	end

	-- wait for onRunBattleModel
	while self.loadingState ~= LOADING_STATE.loadOver do
		collectgarbage("step", 10000)
		coroutine.yield()
	end

	-- full gc
	local clock = os.clock()
	collectgarbage()
	printInfo('battle loading gc over %.2f KB %s s', mem - collectgarbage("count"), os.clock() - clock)

	self.percent:set(100)
	coroutine.yield()

	self.loadingState = LOADING_STATE.loadOver
end

-- args: volumn-- 音量;
function BattleLoadingView:onPlayMusic(musicPath, args)
	if not self.canPlayMusic then
		return
	end
	if musicPath then
		audio.playMusic(musicPath)
	else
		audio.playMusic(self.modes.baseMusic)
		self.canPlayMusic = false
	end
end

function BattleLoadingView:onLoadOver()
	if self.loadingState ~= LOADING_STATE.loadOver then
		return
	end

	self.percent:set(100)
	performWithDelay(self, function()
		if not gGameUI.isPlayVideo then
			self.loadingState = LOADING_STATE.switchUI
			self:onPlayMusic()
			-- switchUI 里包含了 self:onClose()
			gGameUI:switchUI("battle.view", self.data, self.sceneID, self.modes, self.entrance)
		end
	end, 0)
end

function BattleLoadingView:onRunBattleModel()
	-- for _localHack.onRunBattleModel to hack it
	-- do not edit code in here !!!

	self.loadingState = LOADING_STATE.loadOver
end

return BattleLoadingView
