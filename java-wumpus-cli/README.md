# Hunt the Wumpus (Java CLI)

A terminal implementation of Hunt the Wumpus.

## Requirements

- JDK 17+ (or any recent JDK with `javac` and `java`)

## Compile

```bash
cd java-wumpus-cli
mkdir -p out
javac -d out src/com/wumpus/Main.java
```

## Run

```bash
cd java-wumpus-cli
java -cp out com.wumpus.Main
```

## Commands

- `m <room>`: move to an adjacent room
- `s <r1 r2 ...>`: shoot through up to 5 rooms
- `q`: quit the current round

## Rules implemented

- 20-room cave (3 tunnels per room)
- Hazards: 1 Wumpus, 2 pits, 2 bat rooms
- Adjacent warnings for Wumpus/pits/bats
- 5 arrows total
- Crooked arrows: invalid shot hops choose a random adjacent room
- Missed shot can wake and move the Wumpus
