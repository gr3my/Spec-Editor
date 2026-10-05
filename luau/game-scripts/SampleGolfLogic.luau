--!strict
-- SampleGolfLogic.luau -- tiny shared module required by SampleCourseLogic.
-- Sample content for the template (not from any game).

local SampleGolfLogic = {}

function SampleGolfLogic.describe(score: number): string
	if score > 0 then
		return "leading with " .. score
	end
	return "yet to score"
end

return SampleGolfLogic
