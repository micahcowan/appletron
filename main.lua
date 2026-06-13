--[[pod_format="raw",created="2026-06-13 05:26:30",modified="2026-06-13 21:46:03",revision=80,xstickers={}]]
--include "cpu6502.lua"

cycles_per_frame = 17292
cycles_per_line = 65
vblank_cycles = 70 * cycles_per_line

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
	--]]
	
	bus = createBus()
	video = createVideo(bus)
	
	palt(0) -- no transparent pixels
end

function _update()
	for f=1,cycles_per_frame do
		video:cycle()
	end
	assert(video:check(), "Video framegen out of sync! cycles = "
			 .. video._cycle)
end

function _draw()
	--if not btn(5) then return end
	video:display()
end

function createBus()
	local bus = {
		_mem = {},
		get = function(self, addr)
			return self._mem[addr] or 0
		end
	}
	local s = "HELLO"
	for i=1,#s do
		bus._mem[1023 + i] = ord(s[i])
	end
	return bus
end

-- image data corresponding to Apple ][ font ROM
a2font =
--[[pod_type="image"]]unpod("b64:bHo0AK4CAABKBAAA8RVweHUAQyCAIATwcy8ZUA5APkAuMD4wTiBOMD4gDiAOMC5wDiACABNgCAAwMC4wBgAwDgAOCAAGAgARYAIA9AMgDkAOgA4gDhAOMA5gHgAeIA4CADMADgAKAAZOAAo0AFIADkAOYCgAIR4QIABBIA4ALggAIj4wMgAgPjAKABFOMAAkHlAuAAMGAAACAEwAHjBOYgA7EB4gZAAAEAACFgAEKAAIAgAClAACNAA0QA4gzgAHKAACHAEUICwBIw5wLAERQBwBEyCCAAASACHwdCUAJEAulwALAgCZTiBOoE7wAw4gAgAEeAAMmAAA9AArkB4vABmALQARMOMA8wAADmAOMB5gDoAeQA7APjCtABdQKgATAAsBgGAOQB5wDnAeOAAXsFEBAFYACi4AACIAEFACAEEegA5gPQExoA5gGwEABAAEtQAAJgATMPkBAMcAUGAekA5QswAzcB4AFAE3UA5QiwAxQA5ABQFjoE7wfQ5QvgBxUA5AHmAOcKAARWAO8CcZACJAPhwCAOEAMVAOgG8AABoAQfARDsAlAABoATEADnAZAFFgDkAOoHEAYPAQDtAO0CoAAH4AQQ7QDqB4AJGgTsAO4A7ATkDfABFQTAAToDMAcGAO8AYO8A8aACE_MC4CNxAOwHIAcWAO8AUO8AFWABBQQQFBHgAOwK8AcdAO8AAO8H7oAKAwTlAOME5ALiBOHgIg8AcjAAJBAyEeQNMBc0AeMA5wDpANARAgVQAT4BwBIBAetAIAKgEChAAVkHIDEUD_ACBQTqYABZAAMB5QHosBQHAOID56AHBAPvADDvAD6ABgHhAOQA5QZQAjTmAlAhJQfQAFSAACkAEBsQFFDiAOUGoAAioAADIBUGAO4A7Q4gKgTjAuYA5ALkAuQMsAoC7QDoAOwA5wDiA=")

function createVideo(bus)
	local video = {
		-- private data members
		_bus = bus,
		_buffer = userdata("u8", 280, 192),
		_cycle = 0,
		_x = -25 * 7,
		_y = -70,
		
		-- public methods
		cycle = function(self)
			if not self:in_blank() then
				self:_do_buffer()
			end
			self._cycle += 1
			if self._cycle == cycles_per_frame then
				self._cycle = 0
				self._x = -25 * 7
				self._y = -70	-- for vblank
			elseif self._x ~= 40 * 7 then
				self._x += 7
			else
				self._x = 0
				self._y += 1
			end
		end,
		check = function(self)
			return self._cycle == 0
		end,
		display = function(self)
			spr(self._buffer, 0, 0)
			print(tostr(stat(7)).." \t"..tostr(stat(1)), 80, 80)
		end,
		in_blank = function(self)
			return self._y < 0 or self._x < 0
		end,
		
		-- private methods
		_do_buffer = function(self)
			-- get character address for screen pos
			-- TODO: get *real* address
			local addr = 1024 + self._x//7 + 40*(self._y//8)
			local cp = self._bus:get(addr)
			
			cp &= 0x3f -- 0 to 63
			local cpx = (cp & 0xf) * 8
			local cpy = ((cp & 0x30) >> 4) * 8
			cpy += (self._y & 0x7)
			
			for i=0,6 do
				local pxl = a2font:get(cpx+i, cpy)
				self._buffer:set(self._x+i, self._y, pxl)
			end
		end,
	}
	return video
end