local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

handler = {}

function handler:playAnim(animTrack)
	if not animTrack then
		return false
	end

	local ok = pcall(function()
		animTrack:Play()
	end)
	if ok and animTrack.Animation then
		print(animTrack.Animation.AnimationId .. " played.")
	end
	return ok
end

function handler:loadAnim(anim)
	if not anim or not anim:IsA("Animation") then
		warn("Slide animation is missing or not an Animation.")
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok then
		warn("Slide animation failed to load.")
		return nil
	end

	return track
end