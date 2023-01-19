--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Gem
--

local Gem = class("Gem", require("app.models.base"))

local Gems = class("Gems", require("app.models.bases"))

function Gems:newModel(t)
	return Gem.new(self.game):init(t)
end

return Gems