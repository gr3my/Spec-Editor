-- AutoStartLobby.luau -- a lobby that counts players in and starts by itself.
-- Comes with the example level of the same name (Levels tab); or pick it in Game Modes > Script > "Start from example".
--
-- Set up in the Game Modes window:
--   Teams:  place one team changer per team (players join a team by walking into it)
--   Rules:  Start = Manual (this script starts the round), Countdown = 5, Restart automatically = on
--   Pieces: a Force field with the role "Wall - between rounds only" across the arena entrance
--   A Text object with the text:   {Lobby}
--
-- The custom setting "min_each" (Game Modes > Custom settings) sets how many players each team needs;
-- it defaults to 1.

local function needed(): number
	local n = Game.settingNumber("min_each")
	return if n > 0 then n else 1
end

local function lobbyText(): string
	local parts = {}
	local ready = true
	for t = 1, Game.teams() do
		local size = Game.teamSize(t)
		table.insert(parts, Game.teamName(t) .. " " .. size .. "/" .. Game.teamMax(t))
		if size < needed() then
			ready = false
		end
	end
	local line = table.concat(parts, "   ")
	return if ready then line .. "   -- starting!" else line .. "   -- waiting for players"
end

local function check()
	if Game.state() ~= "idle" then
		return
	end
	Game.setText("Lobby", lobbyText())
	for t = 1, Game.teams() do
		if Game.teamSize(t) < needed() then
			return
		end
	end
	Game.startRound()
end

function OnLobby()
	check()
end

function OnTeamChanged(team: number, size: number, old: number)
	check()
end

function OnCountdown(seconds: number)
	Game.setText("Lobby", "Starting in " .. seconds)
end

function OnTime(secondsLeft: number)
	if Game.state() == "countdown" then
		Game.setText("Lobby", "Starting in " .. secondsLeft)
	elseif Game.isRunning() then
		Game.setText("Lobby", secondsLeft .. " s left")
	end
end
