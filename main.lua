--[[pod_format="raw",created="2026-06-13 05:26:30",modified="2026-06-13 11:45:18",revision=33,xstickers={}]]
--include "cpu6502.lua"

function _init()
	--local cpu = createCpu6502()
	
	-- VBL is 4550 cycles
	-- HBL is 25 cycles
	-- 262 HBLs for every one VBL (frame) (only 192 of which are displayed)
	--   (the remaining 70 must be the ones for VBL)
	-- After HBL, 7 pixels are sent per cycle (one row of a character's bitmap)
	-- a cycle is .98us
	-- since 40 characters are displayed in a line, that's 40 cycles.
	--   Plus 25 cycles for HBL. The final (65th) cycle is double-long (1.96us)
	-- This means each line takes 66 cycles. 66 * 262 lines = 17,292 cycles per frame
	-- 17,292 cycles * 0.98us = 16956.6us, so 59.01042 frames in a second
	
	--[[
		For our purposes, we'll round that up to 60 frames so as to fit
		Picotron's framerate. We'll ensure that 17,292 cycles occur, both
		in CPU and in video generation, alternating each, so that the CPU
		can properly affect the frame-in-progress
	]]
	
	window{
		width = 280,
		height = 192,
	}
	
	bus = createBus()
	video = createVideo(bus)
	
	a2font =
--[[pod_type="image"]]unpod("b64:bHo0AK4CAABKBAAA8RVweHUAQyCAIATwcy8ZUA5APkAuMD4wTiBOMD4gDiAOMC5wDiACABNgCAAwMC4wBgAwDgAOCAAGAgARYAIA9AMgDkAOgA4gDhAOMA5gHgAeIA4CADMADgAKAAZOAAo0AFIADkAOYCgAIR4QIABBIA4ALggAIj4wMgAgPjAKABFOMAAkHlAuAAMGAAACAEwAHjBOYgA7EB4gZAAAEAACFgAEKAAIAgAClAACNAA0QA4gzgAHKAACHAEUICwBIw5wLAERQBwBEyCCAAASACHwdCUAJEAulwALAgCZTiBOoE7wAw4gAgAEeAAMmAAA9AArkB4vABmALQARMOMA8wAADmAOMB5gDoAeQA7APjCtABdQKgATAAsBgGAOQB5wDnAeOAAXsFEBAFYACi4AACIAEFACAEEegA5gPQExoA5gGwEABAAEtQAAJgATMPkBAMcAUGAekA5QswAzcB4AFAE3UA5QiwAxQA5ABQFjoE7wfQ5QvgBxUA5AHmAOcKAARWAO8CcZACJAPhwCAOEAMVAOgG8AABoAQfARDsAlAABoATEADnAZAFFgDkAOoHEAYPAQDtAO0CoAAH4AQQ7QDqB4AJGgTsAO4A7ATkDfABFQTAAToDMAcGAO8AYO8A8aACE_MC4CNxAOwHIAcWAO8AUO8AFWABBQQQFBHgAOwK8AcdAO8AAO8H7oAKAwTlAOME5ALiBOHgIg8AcjAAJBAyEeQNMBc0AeMA5wDpANARAgVQAT4BwBIBAetAIAKgEChAAVkHIDEUD_ACBQTqYABZAAMB5QHosBQHAOID56AHBAPvADDvAD6ABgHhAOQA5QZQAjTmAlAhJQfQAFSAACkAEBsQFFDiAOUGoAAioAADIBUGAO4A7Q4gKgTjAuYA5ALkAuQMsAoC7QDoAOwA5wDiA=")

end

function _update()
	for f=1,17292 do
		video:cycle()
	end
	assert(video:check(), "Video framegen out of sync!")
end

function _draw()
	video:display()
end

function createBus()
	local bus = {
		_mem = {},
		get = function(self, addr)
			return _mem[addr]
		end
	}
	local s = "HELLO"
	for i=1,#s do
		bus._mem[1023 + i] = chr(s[i])
	end
	return bus
end

function createVideo(bus)
	local video = {
		_bus = bus,
		cycle = function(self)
		end,
		check = function(self)
			-- TODO: actually check
			return true
		end,
		display = function(self)
			cls()
			print("HELLO")
			spr(a2font, 20, 20)
		end,
	}
	return video
end