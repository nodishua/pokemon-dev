-- @date:   2019-11-14
-- 可捕捉精灵界面
local ViewBase = cc.load("mvc").ViewBase
local CaptureLimitView = class("CaptureLimitView", ViewBase)

local SpineInfo = {
	[1] = {pos = cc.p(407,511), scale = 0.8, effect = "cao2_loop", effect2 = "cao2_effect_loop", direction = "right"},
	[2] = {pos = cc.p(1049,514), scale = 0.8, effect = "cao1_loop", effect2 = "cao1_effect_loop", direction = "left"},
	[3] = {pos = cc.p(304,359), scale = 1, effect = "cao2_loop", effect2 = "cao2_effect_loop", direction = "right"},
	[4] = {pos = cc.p(783,362), scale = 1, effect = "cao1_loop", effect2 = "cao1_effect_loop", direction = "right"},
	[5] = {pos = cc.p(1358,366), scale =  1, effect = "shitou1_loop",  effect2 = "shitou1_effect_loop",direction = "left"},
	[6] = {pos = cc.p(262,157), scale = 1.1, effect = "shitou2_loop",  effect2 = "shitou2_effect_loop",direction = "right"},
	[7] = {pos = cc.p(1330,172), scale = 1.1, effect = "cao3_loop",  effect2 = "cao3_effect_loop",direction = "left"},
}
CaptureLimitView.RESOURCE_FILENAME = "capture_limit.json"
CaptureLimitView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["rightDownPanel.btnSprite"] = {
		varname = "btnSprite",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSpriteBtnClick")}
		},
	},
	["rightDownPanel.btnSprite.textSprite"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.DEFAULT, outline = {color=ui.COLORS.NORMAL.WHITE}},
		}
	},
	["rightDownPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleBtnClick")}
		},
	},
	["rightDownPanel.btnRule.textRule"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.DEFAULT, outline = {color=ui.COLORS.NORMAL.WHITE}},
		}
	},

	["leftDownPanel.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("capture", 'level'),
		},
	},

	["leftDownPanel.textExp"] = {
		varname = "textExp",
		binds = {
			event = "text",
			idler = bindHelper.model("capture", 'level_exp'),

		},
	},
	["leftDownPanel.textExpFull1"] = {varname = "textExpFull1"},
	["leftDownPanel.textExpFull"] = {
		varname = "textExpFull",
		binds = {
			event = "text",
			idler = bindHelper.self("expFull"),
		},
	},

	["leftDownPanel.textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("captureTitle"),
		},
	},

	["leftDownPanel.progressBar"] = {
		varname = "progressBar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("expSlider"),
			},
		}
	},
	["leftDownPanel.imgScan"] = "imgScan",
	["panelSprite"] = "panelSprite",
	["panelSprite.textName"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.DEFAULT, outline = {color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["panelSprite.textTimes"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.WHITE, outline = {color=ui.COLORS.BLACK,size = 2}}
		}
	},
	["panelSprite.textTime"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.WHITE, outline = {color=ui.COLORS.BLACK,size = 2}}
		}
	},
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}
CaptureLimitView.RESOURCE_STYLES = {
	full = true,
}

function CaptureLimitView:onCreate(cb)
	-- topUI
	gGameUI.topuiManager:createView("capture", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.capture, subTitle = "CAPTURE"})

	self.captureCount1, self.captureCount2 = 0, 0 --判断是否有精灵(没有时关闭界面销毁红点)
	self.cb = cb
	self.spriteTable = {} --存放精灵、遮挡物节点的表
	self:initAction()
	self:initBgSpine()
	self:initGrassSpine()
	self:initModel()
end

function CaptureLimitView:onClose()
	if self.behindGrassEff then
		audio.stopSound(self.behindGrassEff)
		self.behindGrassEff = nil
	end
	local execute = false
	if self.captureCount1 == self.captureCount2 and self.captureCount1 ~= 0 then
		execute = true
	else
		execute = false
	end
	if self.cb then
		self:addCallbackOnExit(functools.partial(self.cb, execute))
	end
	ViewBase.onClose(self)
end

--初始化model
function CaptureLimitView:initModel( )
	-- 等级
	self.level = gGameModel.capture:getIdler("level")
	-- 当前等级累积的经验
	self.levelExp = gGameModel.capture:getIdler("level_exp")
	-- 捕捉称号
	self.captureTitle = idler.new("")
	idlereasy.when(self.level, function (_, value)
		self.captureTitle:set(csv.capture.level[value].name)
	end)

	-- 当前经验百分比
	self.expFull = idler.new(0)
	self.expSlider = idler.new(0)
	idlereasy.any({self.level, self.levelExp}, function(_, level, levelExp)
		local percent = 0
		if level < csvSize(csv.capture.level) then
			percent = cc.clampf(100 * levelExp / csv.capture.level[level].needExp, 0, 100)
		else
			self.textExpFull:hide()
			self.textExp:hide()
			self.textExpFull1:text(gLanguageCsv.levelMax)
			self.textExpFull1:setAnchorPoint(0.5,0.5)
			percent = 100
		end
		self.expFull:set(csv.capture.level[level].needExp)
		self.expSlider:set(percent)
	end)

	-- 限时捕捉精灵
	self.limitSprites = gGameModel.capture:getIdler("limit_sprites")
	idlereasy.when(self.limitSprites, function(_, limitSprites)
		self.captureCount1, self.captureCount2 = 0, 0
		for k, v in pairs(limitSprites) do
			if csv.capture.sprite[v.csv_id] then
				self:initSpriteInfo(k,v)
			end
		end
	end)
end

--初始化精灵
function CaptureLimitView:initSpriteInfo(k,v)
	if self.spriteTable[k]:get("spriteInfoPanel") then
		self:unSchedule(k)
		self.spriteTable[k]:removeChildByName("spine")
		self.spriteTable[k]:removeChildByName("spriteInfoPanel")
	end

	--有效精灵判断
	self.captureCount1 = self.captureCount1 + 1
	local spriteCfg = csv.capture.sprite[v.csv_id]
	local endTime = v.find_time + spriteCfg.time
	local totalTimes = spriteCfg.totalTimes
	if v.state == 0 or endTime - time.getTime() < 0 or totalTimes - v.total_times == 0 then
		self.spriteTable[k]:get("effect"):play(SpineInfo[k].effect)
		self.captureCount2 = self.captureCount2 + 1
		return
	end

	local unitID = csv.cards[spriteCfg.cardID].unitID
	local unitCfg = csv.unit[unitID]
	-- 精灵Spine
	local cardSprite = widget.addAnimation(self.spriteTable[k], unitCfg.unitRes, "standby_loop", 0)
		:scale(unitCfg.scale * SpineInfo[k].scale * 0.6)
		:setName("spine")
		:anchorPoint(cc.p(0.5,0.5))
	cardSprite:setSkin(unitCfg.skin)
	self.spriteTable[k]:get("effect"):play(SpineInfo[k].effect2)

	-- 精灵信息
	local panel = self.panelSprite:clone()
		:xy(0,0)
		:z(2)
		:show()
		:scale(0.5)
		:addTo(self.spriteTable[k])
		:setName("spriteInfoPanel")
	--名字
	local name = panel:get("textName")
		:text(unitCfg.name)
	--捕捉次数
	panel:get("textTimes"):text((totalTimes - v.total_times).."/".. totalTimes)
	-- 品级
	panel:get("imgIconLeft"):texture(ui.RARITY_ICON[unitCfg.rarity])
	-- 剩余时间
	local function setLabel()
		local textTime = panel:get("textTime")
		local x,y = panel:getPosition()
		local visible = panel:isVisible()
		local remainTime = time.getCutDown(endTime - time.getTime())
		textTime:text(remainTime.str)
		if remainTime.hour < 1 and remainTime.day < 1 then
			text.addEffect(textTime, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
		else
			text.addEffect(textTime, {color = ui.COLORS.NORMAL.ALERT_GREEN})
		end
		if endTime - time.getTime() <= 0 then
			self.captureCount2 = self.captureCount2 + 1
			self:unSchedule(k)
			self.spriteTable[k]:removeChildByName("spine")
			self.spriteTable[k]:removeChildByName("spriteInfoPanel")
			self.spriteTable[k]:get("effect"):play(SpineInfo[k].effect)
			--停止草丛音效
			if self.behindGrassEff then
				audio.stopSound(self.behindGrassEff)
				self.behindGrassEff = nil
			end
			return false
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, k)
	-- 调整左右方向
	if SpineInfo[k].direction == "left" then
		cardSprite:scaleX(-1 * cardSprite:scaleX())
		cardSprite:x(-100)
		panel:x(-100)
	else
		cardSprite:x(100)
		panel:x(100)
	end
	--播放草丛音效
	if not self.behindGrassEff then
		self.behindGrassEff = audio.playEffectWithWeekBGM("capture/behindgrass.mp3", true)
	end

	-- 触摸事件
	bind.touch(self, panel, {methods = {ended = function()
		local parms = {captureData = spriteCfg, captureID = k - 1, node = nil, limitData = v}
		gGameUI:stackUI("city.capture.capture_entrace", nil, nil, parms)
	end}})
end

--背景Spine
function CaptureLimitView:initBgSpine( )
	widget.addAnimation(self.bg, "capture/buzhuo_changjing_qianjing.skel", "effect_loop", 10)
		:xy(self.bg:width()/2, self.bg:height()/2)
		:anchorPoint(cc.p(0.0,0.0))
		:z(3)
end

-- 草丛spine
function CaptureLimitView:initGrassSpine( )
	for i, info in ipairs(SpineInfo) do
		self.spriteTable[i] = cc.Node:create()
			:xy(info.pos)
			:addTo(self.bg)
		local effName = info.effect
		widget.addAnimationByKey(self.spriteTable[i], "capture/buzhuo_changjing.skel", "effect", effName, 1)
		:anchorPoint(cc.p(0.5,0.5))
		:scale(info.scale)
	end
end

--Actcion初始化
function CaptureLimitView:initAction( )
	self.imgScan:runAction(cc.RepeatForever:create(
		cc.RotateBy:create(1,360)
	))
end

--可捕捉精灵按钮回调
function CaptureLimitView:onSpriteBtnClick( )
	gGameUI:stackUI("city.capture.capture_handbook", nil, {blackLayer = true, clickClose = true})
end

--规则按钮回调
function CaptureLimitView:onRuleBtnClick( )
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

--规则
function CaptureLimitView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.capture..gLanguageCsv.playRule..gLanguageCsv.rule)
		end),
		c.noteText(108),
		c.noteText(2101, 2109),
	}
	return context
end

return CaptureLimitView