function Gamble (betAmount)
    print("Welcome to the Gambling Game!")
    print("You can bet an amount of coins. If you win, you double your bet")
    local outcome = math.random(1, 2) -- 1 for win, 2 for lose

    if outcome == 1 then
        print("You won! You gain " .. betAmount .. " coins.")
        return betAmount
    else
        print("You lost! You lose " .. betAmount .. " coins.")
        return -betAmount
    end
end

print("Enter your bet amount:")
