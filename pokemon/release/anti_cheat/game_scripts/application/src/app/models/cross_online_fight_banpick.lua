--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
--  实时对战扳选卡数据源
--

local BanPickModel = class("BanPickModel")
function BanPickModel:ctor(game)
	self.game = game
	self.remote = {
		step = 0,
		countdown = 0,
		done = {false, false},
		offline = {false, false},
		countdown_timestamp = 0,
		inputsteps = {}, -- {[1]={step, action, cards}, [2]={step, action, cards}}
	}
end

function BanPickModel:init(tb)
	-- banpicks { {ban=3,pick=0,second=10}, ... }
	-- card_deck1 { dbid, ... }
	-- card_deck2 { dbid, ... }
	-- cards {dbid= {id, card_id, skin_id, level, fighting_point, star, advance}}
	-- role1
	-- role2
	for k, v in pairs(tb) do
		self[k] = v
	end
	return self
end

function BanPickModel:fromServer(d)
	print(' ***************************** BanPickModel.fromServer(d) !!!! ')
	print(' --- step = ', d.step, d.countdown, d.countdown_timestamp, dump(d.inputsteps))
	self.remote.done = d.done
	self.remote.offline = d.offline
	if d.countdown then
		self.remote.countdown = d.countdown
	end
	if d.countdown_timestamp then
		self.remote.countdown_timestamp = d.countdown_timestamp
	end
	local last = #self.remote.inputsteps
	for _, inputs in ipairs(d.inputsteps) do
		if inputs[1] then
			local step = inputs[1].step + 1
			if step > last then
				print("table insert inputs", dump(inputs), step, last)
				assertInWindows(step == last + 1, "BanPickModel:fromServer step error")
				table.insert(self.remote.inputsteps, inputs)
				last = last + 1
			end
		end
	end
	self.remote.step = #self.remote.inputsteps
end

function BanPickModel:ban(step, cards, done)
	self:sendPacket({step = step - 1, action = 1, cards = cards, done = done})
end

function BanPickModel:pick(step, cards, done)
	self:sendPacket({step = step - 1, action = 2, cards = cards, done = done})
end

function BanPickModel:deploy(step, cards, done, nature_choose)
	self:sendPacket({step = step - 1, action = 3, cards = cards, done = done, nature_choose = nature_choose})
end

function BanPickModel:sendPacket(input)
	gGameApp:requestPacket('/onlinefight/input', function(ret, err)
		if err then
			gGameUI:showTip(err.err)
		end
	end, {input = input})
end

return BanPickModel