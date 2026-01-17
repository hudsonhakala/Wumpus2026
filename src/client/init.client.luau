local SharedData = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ServerData"))
local Keybinds = require(script:WaitForChild("keybinds"))

local slideClient = require(script:WaitForChild("slide"))
local dJumpClient = require(script:WaitForChild("doubleJump"))

print("Client Connected.")

local UIS = game:GetService("UserInputService")

dJumpClient:watchForLanding()

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Keybinds.SLIDE_KEY then
        print("SLIDE KEY PRESSED")
        slideClient.startSlide()
    end
    if input.KeyCode == Keybinds.DOUBLE_JUMP_KEY then
        if dJumpClient:checkCanDoubleJump() then
            dJumpClient:performDoubleJump()
        end
    end
end)
