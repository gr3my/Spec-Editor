--!strict
-- SampleCourse.luau -- object script: runs a small single-hole course from a plain Cube.
-- Sample content for the template (not from any game). Attach it to any object with
-- a BallSpawnerComponent wired as Tee; each player gets their own personal ball.

-- External Dependencies
local Tee: BallSpawnerComponent = nil
local Cup: GolfCupComponent = nil
-- End External Dependencies

local function spawnPersonalBall()
	if Tee == nil then
		return
	end
	local Parameters = BallSpawnParameters.new({
		targetPlayerIndex = VRPawn.getLocalPlayerIndex(),
	})
	Tee:spawnBallWithParameters(Parameters):andThen(function(Disc: DiscEntity)
		Disc:setEnableHUDIndicator(true)
		Disc.onGoToSleep.Listen(function()
			Disc:addSmoothOffset(Disc:getGravityDirection() * -10)
		end)
	end)
end

function BeginPlay()
	spawnPersonalBall()
end
