# Tug of War Project

The purpose of this project was to develop a 2-player push-to-play simulation of "Tug of War" onto an FPGA in System Verilog. KEYs and LEDs were used to demonstrate on-board gameplay. 
The tug of war game uses the KEY[0] and KEY[3] buttons, whose input triggers the corresponding output from a FSM, allowing the LEDs to light up. Each time the first player presses the KEY[3] button, the light moves one LED to the left. Conversely, if the second player presses the KEY[0] button, the light moves one LED to the right. The game continues to shift the lights back and forth until the last output signal is reached on the leftmost or rightmost LED of the FPGA.

