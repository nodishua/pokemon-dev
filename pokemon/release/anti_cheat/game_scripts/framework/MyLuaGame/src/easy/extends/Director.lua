--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- cc.Director原生类的扩展
--

local Director = cc.Director

local pause = Director.pause

function Director:pause()
	-- if pause and untouchability, the client was dead for user
	-- but onPausedUpdate will be called in GameApp
	self:getEventDispatcher():setEnabled(true)
	return pause(self)
end

