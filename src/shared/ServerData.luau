
SharedData = {}

SharedData.Players = game:GetService("Players")
SharedData.UIS = game:GetService("UserInputService")
SharedData.RunService = game:GetService("RunService")

SharedData.player = SharedData.Players.LocalPlayer

-- SETTINGS _________________________

-- Slide
SharedData.SLIDE_SPEED = 60          -- forward push strength
SharedData.SLIDE_DURATION = 0.6      -- seconds
SharedData.SLIDE_COOLDOWN = 0.8      -- seconds
SharedData.MIN_MOVE_SPEED = 6        -- must be moving at least this fast to slide

-- Double Jump
SharedData.DOUBLE_JUMP_BOOST = 1   -- speed multiplier when double jumping


-- ___________________________________

function SharedData.getCharacter()
	return SharedData.player.Character or SharedData.player.CharacterAdded:Wait()
end

print("ServerData module loaded.")

return SharedData