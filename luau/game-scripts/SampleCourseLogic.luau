--!strict
-- SampleCourseLogic.luau -- server-side listener: receives per-client event data
-- and records it. Sample content for the template (not from any game).

local Logic = require("SampleGolfLogic")

-- External Dependencies
local MainEventRepeater: EventComponent = nil
-- End External Dependencies

function BeginPlay()
	if MainEventRepeater == nil then
		return
	end
	MainEventRepeater.serverEventData.Listen(function(Data: any)
		Logging.warn("SampleCourse", Data)
		log("heard: " .. Logic.describe(1))
	end)
end
