local UIS = game:GetService("UserInputService")
local Keycode = Enum.KeyCode

local Keyboard_Binds = {
	-- Movement
	UP_KEY = Keycode.W or Keycode.Up,
	LEFT_KEY = Keycode.A or Keycode.Left,
	DOWN_KEY = Keycode.S or Keycode.Down,
	RIGHT_KEY = Keycode.D or Keycode.Right,
	
	DOUBLE_JUMP_KEY = Keycode.Space,
	SLIDE_KEY = Keycode.LeftControl,
	DASH_KEY = Keycode.LeftShift,

	-- Combat
	JAB_KEY = Keycode.MouseLeftButton,
	HEAVY_KEY = Keycode.MouseRightButton,
	SHIELD_KEY = Keycode.E,
}

local function isGamepadInput(inputType)
	return inputType == Enum.UserInputType.Gamepad1
		or inputType == Enum.UserInputType.Gamepad2
		or inputType == Enum.UserInputType.Gamepad3
		or inputType == Enum.UserInputType.Gamepad4
		or inputType == Enum.UserInputType.Gamepad5
		or inputType == Enum.UserInputType.Gamepad6
		or inputType == Enum.UserInputType.Gamepad7
		or inputType == Enum.UserInputType.Gamepad8
end

function getInputDevice()
	local lastInputType = UIS:GetLastInputType()

	if isGamepadInput(lastInputType) then
		return "controller"
	end

	if lastInputType == Enum.UserInputType.Touch then
		return "touch"
	end

	if lastInputType == Enum.UserInputType.Keyboard
		or lastInputType == Enum.UserInputType.MouseButton1
		or lastInputType == Enum.UserInputType.MouseButton2
		or lastInputType == Enum.UserInputType.MouseButton3
		or lastInputType == Enum.UserInputType.MouseMovement
		or lastInputType == Enum.UserInputType.MouseWheel then
		return "keyboard_mouse"
	end

	-- Fallback when there is no meaningful last input yet.
	if UIS.TouchEnabled and not UIS.KeyboardEnabled and not UIS.GamepadEnabled then
		return "touch"
	end
	if UIS.GamepadEnabled and not UIS.KeyboardEnabled then
		return "controller"
	end
	if UIS.KeyboardEnabled then
		return "keyboard_mouse"
	end

	return "unknown"
end

return Keyboard_Binds
