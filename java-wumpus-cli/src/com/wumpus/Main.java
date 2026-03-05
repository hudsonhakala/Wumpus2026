package com.wumpus;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Random;
import java.util.Scanner;
import java.util.Set;

public class Main {
    private static final int ROOM_COUNT = 20;
    private static final int INITIAL_ARROWS = 5;
    private static final int PIT_COUNT = 2;
    private static final int BAT_COUNT = 2;
    private static final int MAX_SHOT_LENGTH = 5;

    private static final int[][] CAVE = {
            {2, 5, 8},
            {1, 3, 10},
            {2, 4, 12},
            {3, 5, 14},
            {1, 4, 6},
            {5, 7, 15},
            {6, 8, 17},
            {1, 7, 9},
            {8, 10, 18},
            {2, 9, 11},
            {10, 12, 19},
            {3, 11, 13},
            {12, 14, 20},
            {4, 13, 15},
            {6, 14, 16},
            {15, 17, 20},
            {7, 16, 18},
            {9, 17, 19},
            {11, 18, 20},
            {13, 16, 19}
    };

    private final Random rng = new Random();
    private final Scanner scanner = new Scanner(System.in);

    private int playerRoom;
    private int wumpusRoom;
    private int arrows;
    private Set<Integer> pitRooms;
    private Set<Integer> batRooms;
    private boolean gameOver;

    public static void main(String[] args) {
        new Main().run();
    }

    private void run() {
        printIntro();

        boolean keepPlaying = true;
        while (keepPlaying) {
            setupGame();
            gameLoop();
            keepPlaying = askReplay();
        }

        System.out.println("Thanks for playing Hunt the Wumpus.");
    }

    private void printIntro() {
        System.out.println("=== Hunt the Wumpus (CLI) ===");
        System.out.println("Commands:");
        System.out.println("  m <room>             Move to an adjacent room");
        System.out.println("  s <r1 r2 ... rN>     Shoot arrow through up to 5 rooms");
        System.out.println("  q                    Quit");
        System.out.println();
    }

    private void setupGame() {
        arrows = INITIAL_ARROWS;
        gameOver = false;

        List<Integer> rooms = new ArrayList<>();
        for (int room = 1; room <= ROOM_COUNT; room++) {
            rooms.add(room);
        }
        Collections.shuffle(rooms, rng);

        int index = 0;
        playerRoom = rooms.get(index++);
        wumpusRoom = rooms.get(index++);

        pitRooms = new HashSet<>();
        for (int i = 0; i < PIT_COUNT; i++) {
            pitRooms.add(rooms.get(index++));
        }

        batRooms = new HashSet<>();
        for (int i = 0; i < BAT_COUNT; i++) {
            batRooms.add(rooms.get(index++));
        }
    }

    private void gameLoop() {
        while (!gameOver) {
            printStatus();
            System.out.print("> ");

            if (!scanner.hasNextLine()) {
                gameOver = true;
                break;
            }

            String input = scanner.nextLine().trim();
            if (input.isEmpty()) {
                continue;
            }

            String[] parts = input.split("\\s+");
            String command = parts[0].toLowerCase();

            switch (command) {
                case "m":
                case "move":
                    handleMove(parts);
                    break;
                case "s":
                case "shoot":
                    handleShoot(parts);
                    break;
                case "q":
                case "quit":
                    System.out.println("You gave up the hunt.");
                    gameOver = true;
                    break;
                default:
                    System.out.println("Unknown command. Use m, s, or q.");
            }
        }
    }

    private void printStatus() {
        System.out.println();
        System.out.printf("You are in room %d. Tunnels lead to %s.%n",
                playerRoom, Arrays.toString(CAVE[playerRoom - 1]));

        List<String> warnings = new ArrayList<>();
        for (int neighbor : CAVE[playerRoom - 1]) {
            if (neighbor == wumpusRoom) {
                warnings.add("You smell a Wumpus.");
            }
            if (pitRooms.contains(neighbor)) {
                warnings.add("You feel a draft.");
            }
            if (batRooms.contains(neighbor)) {
                warnings.add("You hear bats.");
            }
        }

        for (String warning : warnings) {
            System.out.println(warning);
        }

        System.out.printf("Arrows left: %d%n", arrows);
    }

    private void handleMove(String[] parts) {
        if (parts.length != 2) {
            System.out.println("Usage: m <adjacent-room>");
            return;
        }

        Integer target = parseRoom(parts[1]);
        if (target == null) {
            return;
        }

        if (!isAdjacent(playerRoom, target)) {
            System.out.println("You can only move through a connected tunnel.");
            return;
        }

        playerRoom = target;
        resolveCurrentRoom();
    }

    private void handleShoot(String[] parts) {
        if (parts.length < 2) {
            System.out.println("Usage: s <room1 room2 ...> (max 5 rooms)");
            return;
        }

        if (arrows <= 0) {
            System.out.println("You have no arrows left.");
            return;
        }

        int length = Math.min(parts.length - 1, MAX_SHOT_LENGTH);
        List<Integer> path = new ArrayList<>();
        for (int i = 1; i <= length; i++) {
            Integer room = parseRoom(parts[i]);
            if (room == null) {
                return;
            }
            path.add(room);
        }

        arrows--;
        int arrowRoom = playerRoom;

        for (int targetRoom : path) {
            if (isAdjacent(arrowRoom, targetRoom)) {
                arrowRoom = targetRoom;
            } else {
                int[] neighbors = CAVE[arrowRoom - 1];
                arrowRoom = neighbors[rng.nextInt(neighbors.length)];
            }

            if (arrowRoom == wumpusRoom) {
                System.out.println("Your arrow strikes true. You killed the Wumpus!");
                gameOver = true;
                return;
            }

            if (arrowRoom == playerRoom) {
                System.out.println("The arrow loops back and hits you. You lose.");
                gameOver = true;
                return;
            }
        }

        if (arrows == 0) {
            System.out.println("Your last arrow missed. You are defenseless.");
            System.out.println("The Wumpus eventually finds you. You lose.");
            gameOver = true;
            return;
        }

        System.out.println("Missed.");
        wakeWumpus();
    }

    private void wakeWumpus() {
        if (rng.nextDouble() < 0.75) {
            int[] neighbors = CAVE[wumpusRoom - 1];
            wumpusRoom = neighbors[rng.nextInt(neighbors.length)];
            if (wumpusRoom == playerRoom) {
                System.out.println("The Wumpus moved into your room and ate you.");
                gameOver = true;
            } else {
                System.out.println("You hear heavy footsteps in the tunnels.");
            }
        } else {
            System.out.println("The Wumpus stays put.");
        }
    }

    private void resolveCurrentRoom() {
        while (!gameOver) {
            if (playerRoom == wumpusRoom) {
                System.out.println("You walked into the Wumpus. You lose.");
                gameOver = true;
                return;
            }

            if (pitRooms.contains(playerRoom)) {
                System.out.println("You fell into a bottomless pit. You lose.");
                gameOver = true;
                return;
            }

            if (batRooms.contains(playerRoom)) {
                System.out.println("Super bats grab you and drop you elsewhere!");
                playerRoom = rng.nextInt(ROOM_COUNT) + 1;
                continue;
            }

            return;
        }
    }

    private Integer parseRoom(String token) {
        try {
            int room = Integer.parseInt(token);
            if (room < 1 || room > ROOM_COUNT) {
                System.out.println("Room number must be between 1 and 20.");
                return null;
            }
            return room;
        } catch (NumberFormatException ex) {
            System.out.printf("Invalid room: %s%n", token);
            return null;
        }
    }

    private boolean isAdjacent(int from, int to) {
        int[] neighbors = CAVE[from - 1];
        return neighbors[0] == to || neighbors[1] == to || neighbors[2] == to;
    }

    private boolean askReplay() {
        while (true) {
            System.out.print("Play again? (y/n): ");
            if (!scanner.hasNextLine()) {
                return false;
            }

            String answer = scanner.nextLine().trim().toLowerCase();
            if (answer.equals("y") || answer.equals("yes")) {
                return true;
            }
            if (answer.equals("n") || answer.equals("no")) {
                return false;
            }

            System.out.println("Please enter y or n.");
        }
    }
}
