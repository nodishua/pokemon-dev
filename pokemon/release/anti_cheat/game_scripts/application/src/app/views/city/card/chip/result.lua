local ChipDrawResultView = class('ChipDrawResultView', cc.load('mvc').ViewBase)
ChipDrawResultView.RESOURCE_FILENAME = 'gem_result.json'

ChipDrawResultView.RESOURCE_BINDING = {
	['bgPanel'] = 'bgPanel',
	['item'] = 'item',
	['movePanel'] = 'movePanel',
	['list'] = 'list',
	['subList'] = 'subList',
	['downPanel'] = 'downPanel',
	['downPanel.btnOk'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onClose')}
		}
	},
	['downPanel.btnOk.textNote'] = {
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	['downPanel.btnAgain'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('drawAgain')}
		}
	},
	['downPanel.btnAgain.textNote'] = {
		binds = {
			{
				event = 'text',
				data = bindHelper.self('drawAgainStr')
			},
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	["effect"] = {
		varname = "effect",
		binds = {
			{
				event = "click",
				method = bindHelper.self("onClickEffect"),
			},
			{
				event = "visible",
				idler = bindHelper.self("showEffect"),
			},
		},
	},
	['downPanel.costInfo.imgIcon'] = 'costIcon',
	['downPanel.costInfo.textCost'] = 'textCost',
	['downPanel.costInfo.textNote'] = 'textNote',
}
ChipDrawResultView.RESOURCE_STYLES = {
    full = true,
}

-- local SOUNDS = {
-- 	item = {
-- 		[1] = 'gem_draw_1.mp3',
-- 		[10] = 'gem_gold_10.mp3'
-- 	},
-- 	rmb = {
-- 		[1] = 'gem_draw_1.mp3',
-- 		[10] = 'gem_diamond_10.mp3'
-- 	}
-- }

function ChipDrawResultView:onCreate(tb, costType, drawTimes, costNum, ticketKey, againCb)
	self.bgPanel:get('cover'):visible(false)
	self.costType   = costType
	self.drawTimes  = drawTimes
	self.againCb    = againCb
	self.costNum    = costNum
	self.ticketKey  = ticketKey

	self.isJump = false
	self.item:visible(false)
	self.showEffect = idler.new(false)
	self.item:visible(false)
	self.drawAgainStr = string.format(gLanguageCsv.drawNum, drawTimes)
	local time1 =  2
	local time2 = 0

	widget.addAnimationByKey(self.bgPanel, 'chip/xdck.skel', "effectBg", "effect", -2)
		:alignCenter(self.bgPanel:size()):scale(2)

	self.list:setClippingEnabled(false)
	self.downPanel:visible(false)
	self.list:setScrollBarEnabled(false)
	-- audio.pauseMusic()
	-- audio.playEffectWithWeekBGM(SOUNDS[costType][drawTimes])

	performWithDelay(self, function()
		local skel, skelname, actionName = 'chip/xdck.skel', "effectBg2", "effect_loop"

		widget.addAnimationByKey(self.bgPanel, skel, skelname, actionName, -1)
			:alignCenter(self.bgPanel:size()):scale(2)
		performWithDelay(self, function()
			local effect = widget.addAnimationByKey(self.bgPanel, "effect/chouka.skel", "efc1", "huode", 11)
				:scale(2)
				:alignCenter(self.bgPanel:size())
				:y(720)
				self:showItems(tb)
		end, time2)
	end, time1)


	self:initModel()
	local ticketIdler = idler.new()
	idlereasy.when(self.items, function(_, items)
		ticketIdler:set(items[self.ticketKey])
	end)
	idlereasy.any({self.rmb, ticketIdler}, function()
		local tickets = dataEasy.getNumByKey(self.ticketKey)

		local costEnough = true
		if self.costType == "rmb" then
			if tickets >= self.drawTimes  then
				self.textCost:text(tickets..'/'..self.drawTimes)
				self.costIcon:texture(dataEasy.getIconResByKey(self.ticketKey))
			else
				self.textCost:text(self.costNum)
				self.costIcon:texture(dataEasy.getIconResByKey(self.costType))
				costEnough = dataEasy.getNumByKey(self.costType) >= self.costNum

			end
		elseif self.costType == "item" then
			local num = dataEasy.getNumByKey(self.ticketKey)
			self.textCost:text(num..'/'..self.costNum)
			self.costIcon:texture(dataEasy.getIconResByKey(self.ticketKey))
			costEnough = num > self.costNum
		end

		text.addEffect(self.textCost, {color = costEnough and ui.COLORS.NORMAL.BLACK or ui.COLORS.NORMAL.RED})

	end)
end

function ChipDrawResultView:onClickEffect()
	self.showEffect:set(false)
	self.isJump = true
end

function ChipDrawResultView:showItems(tb)
	self.decomposedItems = {}
	self.list:removeAllItems()
	self.downPanel:visible(false)
	self.movePanel:visible(true)
	self.data = tb
	self:getResourceNode():removeChildByName('centerItem')
	-- 十连显示遮罩
	if self.drawTimes > 1  then
		self.bgPanel:get('cover'):visible(true)
	end
	self:showOneItem(1)
end

function ChipDrawResultView:showOneItem(i)
	local data = self.data[i]
	if not data then
		self:showEnd()
		return
	end

	local item = self.item:clone():show()
	item:get('textName'):visible(false)
	item:get('imgBg'):visible(false)
	self:pushBackCustomItem(item)
	local moveItem = self.item:get('icon'):clone():addTo(self.movePanel):visible(false)
	bind.extend(self, moveItem, {
		class = 'icon_key',
		props = {
			data = {
				key = data.key,
				dbId = data.dbId
			},
		}
	})
	local time = 0.1

	performWithDelay(self, function()
		local pos = cc.p(0, 0)
		if self.drawTimes == 10 then
			pos = gGameUI:getConvertPosAR(item:get('icon'), self.movePanel)
		end
		moveItem:xy(1280, 120):visible(true):scale(0)
		moveItem:runAction(cc.Sequence:create(
			cc.MoveTo:create(time, cc.p(pos.x + self.movePanel:width() / 2, pos.y + self.movePanel:height() / 2)),
			cc.CallFunc:create(function()
				bind.extend(self, item:get('icon'), {
					class = 'icon_key',
					props = {
						effect = "drawcard",
						data = {
							key = data.key,
							num = data.num,
							dbId = data.dbId,
						}
					}
				})
				if data.decomposed then
					item:get('textName')
						:text(gLanguageCsv.decomposed)
						:color(ui.COLORS.GREEN)
					table.insert(self.decomposedItems, {item, data})
				else
					local name, effect = uiEasy.setIconName(data.key)
					local name = beauty.singleTextLimitWord(name, {fontSize = 40}, {width = 240,onlyText = true})
					item:get('textName'):text(name)
					text.addEffect(item:get('textName'), effect)
				end
				item:get('textName'):visible(true)
				item:get('imgBg'):visible(true)
				moveItem:removeSelf()
			end)
		))
		moveItem:runAction(cc.Spawn:create(
			cc.RotateTo:create(time, 720),
			cc.ScaleTo:create(time, 1)
		))
		performWithDelay(self, function()
			self:showOneItem(i + 1)
		end, 0.03)
	end, 0.02)
end

function ChipDrawResultView:pushBackCustomItem(item)
	if self.drawTimes == 1 then
		self:getResourceNode():add(item, 100)
		item:alignCenter(self:getResourceNode():size())
		item:setName('centerItem'):y(620)
		return
	end

	local subList
	local subLists = self.list:getItems()
	if #subLists > 0 then
		subList = subLists[#subLists]
	else
		subList = self.subList:clone()
		subList:setScrollBarEnabled(false)
		self.list:pushBackCustomItem(subList)
	end

	local items = subList:getItems()
	if #items > 4 then
		subList = self.subList:clone()
		subList:setScrollBarEnabled(false)
		self.list:pushBackCustomItem(subList)
	end

	subList:pushBackCustomItem(item)
	subList:setClippingEnabled(false)
end

function ChipDrawResultView:showEnd()
	-- audio.stopAllSounds()
	-- audio.resumeMusic()
	self.downPanel:visible(true)
	adapt.oneLineCenterPos(cc.p(139, 35), {self.textNote, self.textCost, self.costIcon})

	local count = 1
	self:enableSchedule():schedule(function(dt)
		count = count + 1
		for k, v in ipairs(self.decomposedItems) do
			local item, data = v[1], v[2]
			if count % 2 == 1 then
				bind.extend(self, item:get('icon'), {
					class = 'icon_key',
					props = {
						data = {
							key = data.key,
							num = data.num,
							dbId = data.dbId,
						}
					}
				})
			else
				local cfg = csv.gem.gem[data.key]
				local key, num = csvNext(cfg.decomposeReturn)
				bind.extend(self, item:get('icon'), {
					class = 'icon_key',
					props = {
						data = {
							key = data.decomposed.key,
							num = data.decomposed.num
						}
					}
				})
			end
		end
	end, 1, 0, "playEffect")
end

function ChipDrawResultView:drawAgain()
	if self.againCb then
		self.againCb(self.costType, self.drawTimes, function(data)
			self:showItems(data)
		end)
	end
end

function ChipDrawResultView:initModel()
	self.rmb = gGameModel.role:getIdler('rmb')
	self.items = gGameModel.role:getIdler('items')
end

return ChipDrawResultView