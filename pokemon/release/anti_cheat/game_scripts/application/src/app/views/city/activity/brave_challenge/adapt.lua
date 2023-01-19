local BCAdapt = {}
local BC_TYPE = game.BRAVE_CHALLENGE_TYPE
local url = {
	main = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/main",
		[BC_TYPE.common] = "/game/brave_challenge/main"
	},
	preStart = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/prepare/start",
		[BC_TYPE.common] = "/game/brave_challenge/prepare/start"
	},
	preEnd = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/prepare/end",
		[BC_TYPE.common] = "/game/brave_challenge/prepare/end"
	},
	deploy = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/deploy",
		[BC_TYPE.common] = "/game/brave_challenge/deploy"
	},
	battleStart = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/battle/start",
		[BC_TYPE.common] = "/game/brave_challenge/battle/start"
	},
	battleEnd = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/battle/end",
		[BC_TYPE.common] = "/game/brave_challenge/battle/end"
	},
	choose = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/badge/choose",
		[BC_TYPE.common] = "/game/brave_challenge/badge/choose"
	},
	buy = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/buy",
		[BC_TYPE.common] = "/game/brave_challenge/buy"
	},

	quit = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/quit",
		[BC_TYPE.common] = "/game/brave_challenge/quit"
	},

	rank = {
		[BC_TYPE.anniversary] = "/game/yy/brave_challenge/rank",
		[BC_TYPE.common] = "/game/brave_challenge/rank"
	},

	award = {
		[BC_TYPE.anniversary] = "/game/yy/award/get",
		[BC_TYPE.common] = "/game/brave_challenge/award/get"
	}

}

function BCAdapt.set(typ)
	BCAdapt.typ = typ
end

function BCAdapt.url(name)
	return url[name][BCAdapt.typ]
end


return BCAdapt

