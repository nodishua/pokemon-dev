--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 音乐、音效相关
-- extend cocos.framework.audio
--

local audio = audio

local schedulerEntry
local minVolumn = 0.2
local maxVolume = 1
local endDeltaTime = 0
local beginDeltaTime = 0
-- 弱化背景音乐音量 handle 音效的ID time 音效持续时间(秒) handle uInt类型
local function beWeekMusic(handle, time)
	maxVolume = userDefault.getForeverLocalKey("musicVolume", 100, {rawKey = true}) / 100.0
	if maxVolume <= 0 then
		-- print("[AUDIO TEST] Not Playing")
		return
	end


	time = time * 0.5
	endDeltaTime = math.max(endDeltaTime, time)
	beginDeltaTime = 0.3

	-- print("[AUDIO TEST] Add New Effect Handle",handle, effectAllCount)
	-- print("[AUDIO TEST] preSetMusicVolume--------",targetVolumn)

	local curVolume = math.min(audio.getMusicVolume(true), maxVolume)
	local scheduler = cc.Director:getInstance():getScheduler()
	if schedulerEntry == nil then
		-- every frame to check
		schedulerEntry = scheduler:scheduleScriptFunc(function(dt)
			-- 1  ->  0.2  ->  1
			--  0.3s      0.3s
			local vt = 0
			beginDeltaTime = beginDeltaTime - dt
			endDeltaTime = endDeltaTime - dt
			if endDeltaTime < 0.3 then
				vt = dt / 0.3 * 0.8
			elseif beginDeltaTime > 0 then
				vt = -dt / 0.3 * 0.8
			end
			curVolume = curVolume + vt
			curVolume = cc.clampf(curVolume, minVolumn, maxVolume)

			-- print('--- curVolume', curVolume, endDeltaTime, vt, dt)
			audio.setMusicVolume(curVolume, true)

			if endDeltaTime < 0 then
				audio.setMusicVolume(maxVolume) -- 恢复音量
				-- print("[AUDIO TEST] reSetMusicVolume--------",volume)
				scheduler:unscheduleScriptEntry(schedulerEntry)
				schedulerEntry = nil
				endDeltaTime = 0
			end
		end, 1./60, false)
	end
end

function audio.playEffectWithWeekBGM(fileName, isLoop, weekCfg)
	local handle = audio.playSound(fileName, isLoop)
	local tb = weekCfg or ui.SOUND_LIST[fileName]
	if tb and tb.musicLens and tb.weekOpen and not isLoop then
		beWeekMusic(handle, tb.musicLens)
	end
	return handle
end