# CSCB58 Winter 2022 Assembly Final Project

A Platformer game made from scratch in MIPS assembler

Made by: Denis Dekhtyarenko, denis.dekh@gmail.com

### Link to video demonstration:
[![Demonstration Link](https://img.youtube.com/vi/BPrUhosfRgA/0.jpg)](https://youtu.be/BPrUhosfRgA) 

### Instructions for running the game:

There are 2 prerequisities for running the game: Java and the MIPS Simulator MARS.

- Java can be downloaded from Oracle's official website [here](https://www.java.com/en/download/manual.jsp) (If you don't already have one installed)
- A version of MARS is included in the repository for ease of use

Once you have Java installed, you should be able to open the simulator file Mars45.jar (you might need to select a Java Runtime to launch it). 
Then in the File menu in the top left corner, you can select to Open (CTRL + O). Select the game.asm file included in the repo. 

Once the file is open you can follow these steps to the game:
- Press Assemble (F3) to compile the machine code
- Open Tools>Bitmap Display and Tools>Keyboard and Display MMIO Simulator
- Press Connect to MIPS on both
- On the display set the following settings:
```
Unit width in pixels: 4 (update this as needed)
Unit height in pixels: 4 (update this as needed)
Display width in pixels: 256 (update this as needed)
Display height in pixels: 512 (update this as needed)
Base Address for Display: 0x10008000 ($gp)
```
- You can make the display bigger/smaller by increasing/decreasing the Unit width and height as well as the display width and height by the same proportion (double one -> double the other)
- Once you are ready to run the game you can press Run (F5) and click on the Keyboard area of the "Keyboard and Display MMIO Simulator" window. Typing into that textbox will pass the keypresses to the simulator
- The controls are as follows:
```
W - Jump / Double Jump
A/D - Left/Right
S - Drop Down
P - Restart the Game
```

Have Fun!
