local ViewBase = cc.load("mvc").ViewBase
local CardChoose1In2 = class("CardChoose1In2", ViewBase)

CardChoose1In2.RESOURCE_FILENAME = "drawcard_2choose1.json"
CardChoose1In2.RESOURCE_BINDING = {
	['left.btn'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickLeft')}
		}
	},
	['left.card'] = {
		varname = 'card1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickLeft')}
		}
	},
	['right.btn'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickRight')}
		}
	},
	['right.card'] = {
		varname = 'card2',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickRight')}
		}
	}
}

function CardChoose1In2:onCreate(id, cb)
	self.id = id
	self.cb = cb
	local cfg = dataEasy.getCfgByKey(id)
	self.cardId = {}
	for i = 1, 2 do
		local k = "choose" .. i
		local v = cfg.specialArgsMap[k]
		assertInWindows(v, "道具2选1必须要有choose1和choose2, error id(%s)", id)
		local card = csv.cards[v.card.id]
		local unit = csv.unit[card.unitID]
		self.cardId[i] = v.card.id
		local cardSprite = widget.addAnimationByKey(self['card'..i], unit.unitRes, "hero", "standby_loop", 1000)
			:scale(unit.scale)
		cardSprite:setSkin(unit.skin)

	end
end

function CardChoose1In2:clickLeft()
	local str = string.format(gLanguageCsv.confirmSelectSprite, csv.cards[self.cardId[1]].name)
	gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, btnType = 2, cb = function ()
		gGameApp:requestServer("/game/role/gift/choose", function(tb)
			self.choosed_dbid = tb.view.carddbIDs[1][1]
			self:onClose()
		end, self.id, 1, "choose1", true)
	end})

end

function CardChoose1In2:clickRight()
	local str = string.format(gLanguageCsv.confirmSelectSprite, csv.cards[self.cardId[2]].name)
	gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, btnType = 2, cb = function ()
		gGameApp:requestServer("/game/role/gift/choose", function(tb)
			self.choosed_dbid = tb.view.carddbIDs[1][1]
			self:onClose()
		end, self.id, 1, 'choose2', true)
	end})
end

function CardChoose1In2:onClose()
	if self.cb then
		self:addCallbackOnExit(functools.partial(self.cb, self.choosed_dbid))
	end
	ViewBase.onClose(self)
end

return CardChoose1In2