-- SampleRace__gamemode.luau -- game-mode script: a minimal state machine driven by
-- timers. Sample content for the template (not from any game). States are plain
-- functions in a table; each state has an onEnter, an optional nextState and an
-- optional timer length in seconds.

local BasicTimer: TimerComponent = nil

local States: { [string]: any } = {
	idle = {
		onEnter = function()
			log("race idle")
		end,
		nextState = "countdown",
	},
	countdown = {
		length = 3,
		onEnter = function()
			BasicTimer:start(3)
		end,
		nextState = "running",
	},
	running = {
		onEnter = function()
			log("race running")
		end,
	},
}

local current: string = "idle"

local function SwitchState(state: string)
	current = state
	local S = States[state]
	if S ~= nil and S.onEnter ~= nil then
		S.onEnter()
	end
end

function BeginPlay()
	BasicTimer.finished.Listen(function()
		local S = States[current]
		if S ~= nil and S.nextState ~= nil then
			SwitchState(S.nextState)
		end
	end)
	SwitchState("idle")
end
