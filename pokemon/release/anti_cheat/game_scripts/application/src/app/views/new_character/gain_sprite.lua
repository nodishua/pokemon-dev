local CharacterGainSpriteView = class("CharacterGainSpriteView", cc.load("mvc").ViewBase)
CharacterGainSpriteView.RESOURCE_FILENAME = "character_gain_sprite.json"
CharacterGainSpriteView.RESOURCE_BINDING = {
	["txt"] = "txt",
	["pos"] = "pos",
	["btnBegin"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBegin")},
		},
	}
}

function CharacterGainSpriteView:onCreate(id, cb)
	self.cb = cb

	audio.playEffectWithWeekBGM("card_gain.mp3")
	local title = widget.addAnimationByKey(self.pos, "effect/gongxihuode.skel", "titleEft", "effect")
		title:xy(self.pos:size().width/2, 580)

	title:setSpriteEventHandler(function(event, eventArgs)
		title:play("effect_loop")
	end, sp.EventType.ANIMATION_COMPLETE)

	local unit = csv.unit[csv.cards[id].unitID]
	local unitRes = unit.unitRes
	local spine = widget.addAnimationByKey(self.pos, unitRes, "effect", "standby_loop")
	spine:xy(self.pos:size().width/2, 0)
		:scale(3)
	spine:setSkin(unit.skin)
	self.txt:text(string.format(gLanguageCsv.congratulationGetCard, csv.cards[id].name))
end

function CharacterGainSpriteView:onBegin()
	self.cb()
end

return CharacterGainSpriteView
