#####################################################################
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Denis Dekhtyarenko, 1006316675, dekhtyar, d.dekhtyarenko@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# - Milestone 3 
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. double jump
# 2. fail condition (no health)
# 3. moving platforms
# 4. win condition: timer
# 5. health bar and timer (score)
# 6. enemies shoot back
# 7. moving objects (enemy)
# total: 11 marks (overdid it, oops)
#
# Link to video demonstration for final submission:
# - https://youtu.be/BPrUhosfRgA
#
# Are you OK with us sharing the video with people outside course staff?
# - yes and please share this project github link as well https://github.com/Umenemo/CSCB58_Final 
#  (Private and can't be accessed until end of semester as per the handout)
#
# Any additional information that the TA needs to know: 
# - made the game a bit hard, to make it easier to win "timer" can be set lower to finish faster (line 88)
#####################################################################
.eqv BASE_ADDRESS 0x10008000
.eqv blue 0x0056c9ef
.eqv spike_inside 0x00dfdfdf
.eqv spike_outline 0x002f2f2f	
.eqv board_back 0x004a4a4a
.eqv yellow 0x00ffeb3b
.eqv red 0x00e50000
.eqv blue_pants 0x003f51b5
.eqv platform 0x00f57f17
.eqv green 0x004caf4f
.eqv yellow_damage 0x00fff3b0
.eqv red_damage 0x00c75050
.eqv blue_pants_damage 0x007d87b3
.eqv grey_cannon 0x00333333
.eqv white 0x00eeeeee

.data
.align 2
buffer_copy: .space 32768	# copy of the bufferframe for static elements
player_position: .word 0
.align 2
platform_positions: .space 48	# array to store platforms' positions and their direction of movement
n_platforms: .word 6
standing: .word -1
double_jump: .word 1
health: .word 3
invincible: .word 0
cannon_position: .word 120
cannonball: .word -1
cannonball_pos: .word 0
timer: .word 750 	# 30 seconds at 25 fps

.text
main:
	la $t0, standing	# refresh values in case of a restart
	li $t1, -1
	sw $t1, 0($t0)
	la $t0, health
	li $t1, 3
	sw $t1, 0($t0)
	la $t0, double_jump
	li $t1, 1
	sw $t1, 0($t0)
	la $t0, invincible
	li $t1, 0
	sw $t1, 0($t0)
	la $t0, cannonball
	li $t1, -1
	sw $t1, 0($t0)
	la $t0, timer
	li $t1, 750
	sw $t1, 0($t0)
	la $t0, cannonball_pos
	li $t1, 0
	sw $t1, 0($t0)
	
	# paint the sky, scoreboard and spikes
	li $t9, BASE_ADDRESS
	li $t0, blue
	move $t1, $t9	# $t1 is the counter
	addi $t2, $t1, 27648	# $t2 = target address (64px * 108px * 4 bytes per unit = 27648)
	la $s6, buffer_copy	# load location of copy bufferframe
	
start_loop_paint_sky:
	bge $t1, $t2, end_loop_paint_sky	# run while $t1 < $t2
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the unit to blue
	addi $t1, $t1, 4	# increment counter
	j start_loop_paint_sky	
end_loop_paint_sky:	

	addi $t2, $t2, 256 
start_loop_paint_board3:
	bge $t1, $t2, end_loop_paint_board3	# run while $t1 < $t2
	sw $zero, 0($t1)
	addi $t1, $t1, 4
	j start_loop_paint_board3
end_loop_paint_board3:
	addi $t2, $t2, 4608	# $t2 = new target address (64px * 20px * 4 bytes per unit - 256 (last line) = 4864 )
	li $t4, 0	# counter for inner start_loop
	li $t0, board_back
start_loop_paint_board2:
	bge $t1, $t2, end_loop_paint_board2	# run while $t1 < $t2
	sw $zero, 0($t1)
	addi $t1, $t1, 4	
start_loop_paint_board1:
	bgt $t4, 61, end_loop_paint_board1	# run while $t4 < 61
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the unit to board_back (dark grey)
	addi $t1, $t1, 4	# increment counters
	addi $t4, $t4, 1	
	j start_loop_paint_board1	
end_loop_paint_board1:
	li $t4, 0	# $t4 = 0, reset counter for inner start_loop 
	sw $zero, 0($t1)
	addi $t1, $t1, 4	# skip last pixel 
	j start_loop_paint_board2
end_loop_paint_board2:
	addi $t2, $t2, 256 
start_loop_paint_board4:
	bge $t1, $t2, end_loop_paint_board4	# run while $t1 < $t2
	sw $zero, 0($t1)
	addi $t1, $t1, 4
	j start_loop_paint_board4
end_loop_paint_board4:

	# left and right spikes 
	li $t0, spike_outline
	li $s7, spike_inside
	# pointer for each side of the wall. $t1 is left, $t2 is right
	addi $t1, $t9, 2560	# row 10 unit 0
	addi $t2, $t9, 2812	# row 10 unit 63
	li $t3, 0	# $t3 = counter for 12 spikes
	li $t4, 12
	li $t5, 0	# $t5 = counter for first 3 pixels
	li $t6, 3	# $t6 = target for $t5 and $t8
	li $t7, 0	# $t7 = counter for last 4 pixels
start_loop_paint_spike1: # outline of the spike
	bge $t3, $t4, end_loop_paint_spike1	# run while $t3 < 12
	addi $s3, $t6, 2	# $s3 = heigth of next fill, starts at 5
start_loop_paint_spike2: # top 4 pixels + filling
	bge $t5, $t6, end_loop_paint_spike2	# run while $t5 < 3
	
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sub $s5, $t2, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the units to spike_outline (dark grey)
	sw $t0, 0($t2)
	
	move $s0, $s3		# get height of next fill
	move $s1, $t1		# copy current pointers
	move $s2, $t2		# $s1 = $t1, $s2 = $t2
start_loop_paint_spike4:	# filling
	blez $s0, end_loop_paint_spike4	# run while $s0 > 0	
	addi $s1, $s1, 256	# move down one row
	addi $s2, $s2, 256
	
	sub $s5, $s1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $s7, 0($s5)		# save a copy into static
	
	sub $s5, $s2, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $s7, 0($s5)		# save a copy into static
	
	sw $s7, 0($s1)		# set the units to spike_inside (grey)
	sw $s7, 0($s2)
	addi $s0, $s0, -1	# decrement
	j start_loop_paint_spike4
end_loop_paint_spike4:
	addi $s3, $s3, -2	# match the next column of filling to the height of the spike
	
	addi $t1, $t1, 260	# go down 1 right 1
	addi $t2, $t2, 252	# go down 1 left 1
	addi $t5, $t5, 1	# increment counter
	j start_loop_paint_spike2
end_loop_paint_spike2:

start_loop_paint_spike3:	#bottom 3 pixels
	bge $t7, $t6, end_loop_paint_spike3	# run while $t7 < 3
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sub $s5, $t2, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the units to spike_outline (dark grey)
	sw $t0, 0($t2)
	addi $t1, $t1, 252	# go down 1 left 1
	addi $t2, $t2, 260	# go down 1 right 1
	addi $t7, $t7, 1	# increment counter
	j start_loop_paint_spike3
end_loop_paint_spike3:

	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sub $s5, $t2, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# last pixel before next spike
	sw $t0, 0($t2)
	li $t5, 0	# $t5 = counter for first 4 pixels
	li $t7, 0	# $t7 = counter for last 3 pixels
	addi $t1, $t1, 512	# go down 2 rows each side
	addi $t2, $t2, 512	
	addi $t3, $t3, 1	# increment counter
	j start_loop_paint_spike1
end_loop_paint_spike1:

	# bottom spikes 
	addi $t1, $t9, 27392	# $t1 = row 107 unit 0
	li $t3, 0
	li $t4, 8
start_loop_paint_spike5: # outline of the spike
	bge $t3, $t4, end_loop_paint_spike5	# run while $t3 < 8
	addi $s3, $t6, 2	# $s3 = width of next fill, starts at 5
start_loop_paint_spike6: # left 4 pixels + filling
	bge $t5, $t6, end_loop_paint_spike6	# run while $t5 < 3
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the units to spike_outline (dark grey)
	
	move $s0, $s3		# get width of next fill
	move $s1, $t1		# copy current pointer, $s1 = $t1
start_loop_paint_spike8:	# filling
	blez $s0, end_loop_paint_spike8	# run while $s0 > 0	
	addi $s1, $s1, 4	# move right one pixel
	sub $s5, $s1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $s7, 0($s5)		# save a copy into static
	
	sw $s7, 0($s1)		# set the units to spike_inside (grey)
	addi $s0, $s0, -1	# decrement
	j start_loop_paint_spike8
end_loop_paint_spike8:
	addi $s3, $s3, -2	# match the next column of filling to the height of the spike
	
	addi $t1, $t1, -252	# go up 1 right 1
	addi $t5, $t5, 1	# increment counter
	j start_loop_paint_spike6
end_loop_paint_spike6:

start_loop_paint_spike7:	# bottom 3 pixels
	bge $t7, $t6, end_loop_paint_spike7	# run while $t7 < 3
	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# set the units to spike_outline (dark grey)
	addi $t1, $t1, 260	# go down 1 right 1
	addi $t7, $t7, 1	# increment counter
	j start_loop_paint_spike7
end_loop_paint_spike7:

	sub $s5, $t1, $t9	# calculate relative location in the buffer
	add $s5, $s5, $s6	# location in the copy buffer
	sw $t0, 0($s5)		# save a copy into static
	
	sw $t0, 0($t1)		# last pixel before next spike
	li $t5, 0	# $t5 = counter for first 4 pixels
	li $t7, 0	# $t7 = counter for last 3 pixels
	addi $t1, $t1, 8	# go right 2 pixels
	addi $t3, $t3, 1	# increment counter
	j start_loop_paint_spike5
end_loop_paint_spike5:

	li $a0, 3		# draw initial timer
	li $a1, 0
	jal draw_number
	li $a0, 0
	li $a1, 1
	jal draw_number

	li $s6, BASE_ADDRESS
	addi $t3, $s6, 8704	# $t3 = row pointer, start at row 34
	la $t1, platform_positions	# get pointer to beginning of array
	li $t2, 0	# initialize counter
start_loop_initialize_platforms:
	bge $t2, 48, end_loop_initialize_platforms
	li $v0, 42
	move $a0, $t3
	li $a1, 48
	syscall			# $a0 = random number 0-47
	addi $a0, $a0, 1	# $a0 is from 1-48
	li $t4, 4
	mult $a0, $t4
	mflo $a0		# $a0 = 4*(1 to 48)
	add $a0, $t3, $a0	# random location for the platform
	sw $a0, 0($t1)
	li $v0, 42
	# $a0 already random, use as seed
	li $a1, 2
	syscall		# $a0 = random number 0 or 1
	bne $a0, $zero, dir_not_zero
	li $a0, -1	# we are here so $a0 = 0, set it to -1
dir_not_zero:
	li $t4, 4
	mult $a0, $t4
	mflo $a0	# $a0 = -4 or 4 for platform direction
	sw $a0, 4($t1)
	addi $t1, $t1, 8	# increment counters
	addi $t2, $t2, 8	
	addi $t3, $t3, 3072	# move down 10 rows
	j start_loop_initialize_platforms
end_loop_initialize_platforms:

	la $s7, player_position		# set initial player position
	addi $a0, $t9, 16512
	sw $a0, 0($s7)		# $a0 = initial player position
	li $a1, 1
	jal draw_character
	
	li $a1, green
	li $a0, 0
	jal draw_health
	li $a0, 1
	jal draw_health
	li $a0, 2
	jal draw_health		# initialize health bar to full
	
	la $s3, health
	lw $s3, 0($s3)		# $s3 = health
	la $s4, invincible
	lw $s4, 0($s4)		# $s4 = invincible
	la $s5, standing
	lw $s5, 0($s5)		# $s5 = standing
	
start_loop_main:
	la $t1, platform_positions	# get pointer to beginning of array
	addi $t2, $t1, 48	# $t2 = target
	li $t8, 0	# number of the platform
start_loop_update_platforms:	
	bge $t1, $t2, end_loop_update_platforms # loop while $t1 < platform_positions[8]
	lw $t3, 0($t1)	# $t3 = current position
	lw $t4, 4($t1) 	# $t4 = direction change
	
	move $s0, $t1		# save registers
	move $s1, $t2
	move $s2, $t3
	move $s6, $t4
	move $a0, $t3
	move $a1, $t4
	jal draw_platform	# draw new platform
	move $t1, $s0		# restore registers
	move $t2, $s1
	move $t3, $s2
	move $t4, $s6
	
	add $t3, $t3, $t4	# $t3 = new position
	sw $t3, 0($t1)		# update position
	
	addi $t5, $t3, -256	
	lw $t7, 0($s7)		# $t7 = player position
				# $s5 = standing status
	bgt $s5, -1, after_standing	# skip logic if player is already standing
	bge $t5, $t7, not_on_platform 	# standing if $t3 - 256 < $t7 < $t3 - 195
	addi $t5, $t5, 60
	ble $t5, $t7, not_on_platform 
	# we are here so character is on the platform
	move $s5, $t8		# update standing flag
	la $t5, double_jump
	li $t9, 1
	sw $t9, 0($t5)		# reset double jump
	j after_standing
not_on_platform:
	li $s5, -1	# set as not standing
after_standing:

	li $t5, 256	# bytes per row
	div $t3, $t5
	mfhi $t5
	# check if $t5 is less than 4 or greater than 251 => multiply $t4 by -1 and update array
	bge $t5, 4, not_lt_4
	mul $t4, $t4, -1	# less than 4 pixels to the left wall => flip directions
	sw $t4, 4($t1)
not_lt_4:
	ble $t5, 195, not_gt_195
	mul $t4, $t4, -1	# less than 4 pixels to the right wall => flip directions
	sw $t4, 4($t1)
not_gt_195:
	addi $t8, $t8, 1
	addi $t1, $t1, 8	# go to next platform
	j start_loop_update_platforms
end_loop_update_platforms:
	
	lw $a0, 0($s7)		# load player position
	li $a1, 0
	jal draw_character	# erase old character
	
	li $t9, 0xffff0000	
	lw $t8, 0($t9)
	bne $t8, 1, no_press	# check for key press
	jal keypress_handle	# we are here so a key was pressed
no_press:
	# la $t1, standing
	move $t3, $s5	# $t1 = platform index
	bgt $t3, -1, standing1	# if $t1 > -1 then player is on a platform
	lw $t2, 0($s7)		# $t2 = player position
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 27392	# $t5 = base address + 104 rows	
	bge $t2, $t5, nstanding	# check if player is above the scoreboard
	addi $t2, $t2, 256	# we are here so player is falling
	sw $t2, 0($s7)		# update player position
	j nstanding
standing1:
	mul $t3, $t3, 8
	la $t4, platform_positions
	add $t4, $t4, $t3
	lw $t4, 4($t4)		# $t4 = movement of platform player is standing on
	lw $t3, 0($s7)		# $t3 = player position
	add $t3, $t3, $t4	# move player with platform
	sw $t3, 0($s7)		
nstanding:
	li $s5, -1		# set standing to -1
	lw $a0, 0($s7)		# load new player position
	li $a1, 1
	jal draw_character	# draw new character
	
	# if invincible => decrement, if not check for incoming damage and reset invincibility\
	move $t5, $s4	# $t5 = invincibility counter
	bgtz $t5, invincible_gtz
	# we are here so we can take damage
	lw $t0, 0($s7)		# $t0 = player position
	li $t3, 256
	li $t4, BASE_ADDRESS
	sub $t4, $t0, $t4	# $t4 = position in buffer (y*256 + x*4)
	div $t4, $t3
	mfhi $t1		# $t1 = horizontal position of player
	blt $t1, 28, take_damage
	bgt $t1, 227, take_damage
	bge $t4, 26368, take_damage
	la $t6, cannonball_pos
	lw $t6, 0($t6)		# $t6 = position of cannonball
	li $t2, BASE_ADDRESS
	sub $t6, $t6, $t2	# $t6 = relative position of CB
	addi $t6, $t6, 260	# $t6 = center of cannonball
	li $t3, 256
	div $t6, $t3	
	mfhi $t7		# $t7 = hor. pos. of cannonball
	sub $t8, $t1, $t7	# $t8 = difference between Hor. positions of player and cannonball
	sra $t9, $t8, 31   
	xor $t8, $t8, $t9  
	sub $t8, $t8, $t9	# $t8 = absolute hor. distance between player and cannonball
	bge $t8, 12, end_damage_calc	# if further than 16 then no contact with ball
	# here, so close enough horizontally - check vertical
	addi $t8, $t4, -1024	# $t8 = center of character
	div $t8, $t8, 256	# $t8 = vertical height of player center (in bytes)
	div $t6, $t6, 256	# $t6 = vertical height of cannonball center (in bytes)
	
	sub $t6, $t6, $t8	# $t6 = difference between Hor. positions of player and ball
	sra $t7, $t6, 31   
	xor $t6, $t6, $t7   
	sub $t6, $t6, $t7	# $t6 = absolute vertical distance between player and ball
	blt $t6, 16,take_damage	# if closer than 24 then take damage
	j end_damage_calc	# no damage taken, don't do anything
invincible_gtz:
	addi $s4, $s4, -1	# decrement invincibility counter
	bgtz $s4, still_invincible
	move $a0, $s3		# $a0 = health of player
	move $a1, $zero
	jal draw_health		# update health bar
still_invincible:
	j end_damage_calc	# continue the game
take_damage:	# $s3 = health of player
	addi $s3, $s3, -1	# take off 1 health
	beqz $s3, game_over
	li $s4, 75		# invincible = 75 cycles (3 seconds of invincibility at 40ms sleep)
	move $a0, $s3
	li $a1, red	
	jal draw_health		# update health bar
end_damage_calc:

	la $t0, cannonball
	lw $t1, 0($t0)
	beq $t1, 1, cannonball_flying	
	mul $t1, $t1, -1	# we are here so cannonball reached bottom 
	sw $t1, 0($t0)
	jal draw_cannon
	la $t0, cannon_position
	lw $t1, 0($t0)		# $t1 = cannon position
	addi $t1, $t1, 1028
	li $t2, BASE_ADDRESS
	add $t1, $t1, $t2	# $t1 = pos of cannonball in the buffer
	la $t2, cannonball_pos
	sw $t1, 0($t2)
	j cannonball_launched
cannonball_flying:
	jal move_cannonball
cannonball_launched:
	
	la $t0, timer
	lw $t1, 0($t0)
	addi $t1, $t1, -1
	sw $t1, 0($t0)		# decrement timer by one
	ble $t1, $zero, victory	# check if time is up
	li $t2, 25
	div $t1, $t2		# $t1 = timer in seconds (from cycles)
	mfhi $t3
	mflo $t1
	bne $t3, $zero, skip_timer_refresh
	li $t2, 10		
	div $t1, $t2		# get digits to draw:
	mflo $a0		# first
	mfhi $t7		# second
	li $a1, 0
	jal draw_number
	move $a0, $t7
	li $a1, 1
	jal draw_number
skip_timer_refresh:
	li $v0, 32
	li $a0, 40 # Wait 40ms (25 FPS)
	syscall

	j start_loop_main
end_loop_main:
	
	li $v0, 10 # terminate the program gracefully
	syscall
	
victory:
	li $t9, BASE_ADDRESS
	move $t1, $t9	# $t1 is the counter
	addi $t2, $t1, 32768	# $t2 = last pixel
	li $t3, green
start_loop_paint_green:
	bge $t1, $t2, end_loop_paint_green	# run while $t1 < $t2
	sw $t3, 0($t1)		# set the unit to black
	addi $t1, $t1, 4	# increment counter
	j start_loop_paint_green	
end_loop_paint_green:

	li $t3, white
	addi $t2, $t9, 15948	# $t2 = middle of screen ish
	
	sw $t3, 0($t2)
	sw $t3, 16($t2)
	sw $t3, 260($t2)
	sw $t3, 268($t2)
	sw $t3, 520($t2)
	sw $t3, 776($t2)
	addi $t2, $t2, 24
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	sw $t3, 264($t2)
	sw $t3, 520($t2)
	addi $t2, $t2, 16
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 8($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	sw $t3, 264($t2)
	sw $t3, 520($t2)
	addi $t2, $t2, 20
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 772($t2)
	sw $t3, 520($t2)
	sw $t3, 772($t2)
	sw $t3, 780($t2)
	sw $t3, 16($t2)
	sw $t3, 272($t2)
	sw $t3, 528($t2)
	addi $t2, $t2, 24
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	addi $t2, $t2, 8
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 260($t2)
	sw $t3, 520($t2)
	sw $t3, 12($t2)
	sw $t3, 268($t2)
	sw $t3, 524($t2)
	sw $t3, 780($t2)
	li $t9, 0xffff0000
start_loop_wait_for_p1:	
	lw $t8, 0($t9)
	bne $t8, 1, no_press_restart1	# check for key press
	lw $t1, 4($t9)		# we are here so a key was pressed
	bne $t1, 0x70, no_press_restart1
	j main			# p was pressed, restart game
no_press_restart1:

	li $v0, 32
	li $a0, 100 # Wait 100ms
	syscall
	j start_loop_wait_for_p1	
	
game_over:	
	li $t9, BASE_ADDRESS
	move $t1, $t9	# $t1 is the counter
	addi $t2, $t1, 32768	# $t2 = last pixel
	
start_loop_paint_black:
	bge $t1, $t2, end_loop_paint_black	# run while $t1 < $t2
	sw $zero, 0($t1)		# set the unit to black
	addi $t1, $t1, 4	# increment counter
	j start_loop_paint_black	
end_loop_paint_black:	
	
	li $t3, white
	addi $t2, $t9, 15944	# $t2 = middle of screen ish
	sw $t3, 0($t2)
	sw $t3, 16($t2)
	sw $t3, 260($t2)
	sw $t3, 268($t2)
	sw $t3, 520($t2)
	sw $t3, 776($t2)
	addi $t2, $t2, 24
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	sw $t3, 264($t2)
	sw $t3, 520($t2)
	addi $t2, $t2, 16
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 8($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	sw $t3, 264($t2)
	sw $t3, 520($t2)
	addi $t2, $t2, 20
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	addi $t2, $t2, 16
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 512($t2)
	sw $t3, 768($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	sw $t3, 264($t2)
	sw $t3, 520($t2)
	addi $t2, $t2, 16
	sw $t3, 0($t2)
	sw $t3, 256($t2)
	sw $t3, 768($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 260($t2)
	sw $t3, 516($t2)
	sw $t3, 520($t2)
	sw $t3, 772($t2)
	sw $t3, 776($t2)
	addi $t2, $t2, 16
	sw $t3, 0($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 260($t2)
	sw $t3, 516($t2)
	sw $t3, 772($t2)
	
	li $t9, 0xffff0000
start_loop_wait_for_p:	
	lw $t8, 0($t9)
	bne $t8, 1, no_press_restart	# check for key press
	lw $t1, 4($t9)		# we are here so a key was pressed
	bne $t1, 0x70, no_press_restart
	j main		# p was pressed, restart game
no_press_restart:

	li $v0, 32
	li $a0, 100 # Wait 100ms
	syscall
	j start_loop_wait_for_p	
	
	
move_cannonball:	# uses $t0-5
	la $t0, cannonball_pos	# $t0 = address of cannonball_pos
	lw $t1, 0($t0)		# $t1 = cannonball position
	li $t2, BASE_ADDRESS
	la $t3, buffer_copy
	sub $t4, $t1, $t2	# $t4 = relative pos in buffer
	add $t4, $t4, $t3	# $t4 = pos in buffer copy
	addi $t2, $t2, 26112 	# $t2 = row 102
	
	lw $t5, 0($t4)		# erase old cannonball
	sw $t5, 0($t1)
	lw $t5, 4($t4)
	sw $t5, 4($t1)
	lw $t5, 8($t4)
	sw $t5, 8($t1)
	lw $t5, 256($t4)
	sw $t5, 256($t1)
	lw $t5, 260($t4)
	sw $t5, 260($t1)
	lw $t5, 264($t4)
	sw $t5, 264($t1)
	lw $t5, 512($t4)
	sw $t5, 512($t1)
	lw $t5, 516($t4)
	sw $t5, 516($t1)
	lw $t5, 520($t4)
	sw $t5, 520($t1)
	
	blt $t1, $t2, draw_new_cannonball
	la $t1, cannonball	# we are here so ball reached bottom
	lw $t2, 0($t1)
	mul $t2, $t2, -1
	sw $t2, 0($t1)		# set cannonball as -1 (need to fire a new one)
	jr $ra			# return
	
draw_new_cannonball:
	addi $t1, $t1, 512	# move cannon ball down 1 rows
	sw $t1, 0($t0)
		
	sw $zero, 0($t1)	# draw new cannonball
	sw $zero, 4($t1)
	sw $zero, 8($t1)
	sw $zero, 256($t1)
	sw $zero, 260($t1)
	sw $zero, 264($t1)
	sw $zero, 512($t1)
	sw $zero, 516($t1)
	sw $zero, 520($t1)
	
	jr $ra		# return
	
draw_cannon: # uses $t0-6
	la $t0, cannon_position
	lw $t1, 0($t0)		# $t1 = cannon position
	li $t3, BASE_ADDRESS
	add $t3, $t3, $t1	# $t3 = position in main buffer
	li $t4, 0
	li $t5, 0
	li $t6, blue
start_loop_cannon_draw1:
	bge $t4, 5, end_loop_cannon_draw1
start_loop_cannon_draw2:
	bge $t5, 5, end_loop_cannon_draw2
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	addi $t5, $t5, 1
	j start_loop_cannon_draw2
end_loop_cannon_draw2:
	addi $t3, $t3, 236
	li $t5, 0
	addi $t4, $t4, 1
	j start_loop_cannon_draw1
end_loop_cannon_draw1:

	li $v0, 42
	move $a0, $t1
	li $a1, 52
	syscall		# $a0 = random number 0-51
	addi $a0, $a0, 4 # $a0 = random number 4-55
	mul $t1, $a0, 4		# $t2 = position 16-220
	sw $t1, 0($t0)	
	li $t3, BASE_ADDRESS
	add $t3, $t3, $t1	# $t3 = position in main buffer
	li $t6, grey_cannon	# $t6 = colour
	li $t4, 0	# counters for loops
	li $t5, 0
	
start_loop_cannon_draw3:
	bge $t4, 5, end_loop_cannon_draw3
start_loop_cannon_draw4:
	bge $t5, 5, end_loop_cannon_draw4
	sw $t6, 0($t3)
	addi $t3, $t3, 4
	addi $t5, $t5, 1
	j start_loop_cannon_draw4
end_loop_cannon_draw4:
	addi $t3, $t3, 236
	li $t5, 0
	addi $t4, $t4, 1
	j start_loop_cannon_draw3
end_loop_cannon_draw3:
	li $t6, blue
	sw $t6, -252($t3)
	sw $t6, -248($t3)
	sw $t6, -244($t3)
	
	jr $ra
	
draw_platform:	# $a0 = position to draw at, $a1 = amount to move the platform (<0 = left, 0 = initial draw, >0 = right)
		# assume the position is correct with enough space. Uses $t1-6
	la $t2, buffer_copy	# $t2 = load address of static reference
	li $t1, BASE_ADDRESS	# $t1 = load address of $gp
	sub $t3, $a0, $t1	# offset in framebuffer
	add $t3, $t2, $t3	# $t3 = location in buffer_copy
	add $t4, $a0, $a1	# $t4 = new position of the platform 
	
	add $t5, $a0, 60	# $t5 = 15 pixels to the right
start_loop_platform_erase:
	bge $a0, $t5, end_loop_platform_erase 
	lw $t6, 0($t3)	# load static color
	sw $t6, 0($a0)	# erase the pixel
	addi $t3, $t3, 4 # move buffer pointers
	addi $a0, $a0, 4
	j start_loop_platform_erase
end_loop_platform_erase:

	add $t5, $t4, 60	# $t5 = 15 pixels to the right
	li $t2, platform
start_loop_platform_draw:
	bge $t4, $t5, end_loop_platform_draw
	sw $t2, 0($t4)	# draw pixel
	addi $t4, $t4, 4 # move buffer pointer
	j start_loop_platform_draw
end_loop_platform_draw:
	jr $ra		# return `
	
keypress_handle:	# uses $t0-5
	la $t2, player_position		
	lw $t0, 0($t2)	# $t0 = current player position
	lw $t1, 4($t9)  # $t1 = pressed key
	
	li $t3, 256
	li $t4, BASE_ADDRESS
	sub $t4, $t0, $t4
	div $t4, $t3
	mfhi $t4	# $t4 = player's horizontal position
	bne $t1, 0x61, not_a 
	ble $t4, 15, not_a	# skip if player is touching the left wall
	addi $t0, $t0, -8	# we are here so 'a' was pressed
	sw $t0, 0($t2)		# update player position
	jr $ra
not_a:	bne $t1, 0x64, not_d
	bge $t4, 239, not_d	# skip if player is touching the right wall
	addi $t0, $t0, 8	# we are here so 'd' was pressed
	sw $t0, 0($t2)		
	jr $ra
not_d:	# $s5 = standing status
	bne $t1, 0x73, not_s	# check if s is pressed
	beq $s5, -1, not_s	# check if player is already falling
	addi $t0, $t0, 256	# we are here so we are not already falling
	sw $t0, 0($t2)		# update player position
	jr $ra
not_s:	bne $t1, 0x77, not_w
	beq $s5, -1, not_stand	
	addi $t0, $t0, -3584	# we are here so we are standing
	sw $t0, 0($t2)		# update player position
	j not_w
not_stand:
	li $t5, BASE_ADDRESS
	addi $t5, $t5, 27392	
	blt $t0, $t5, not_on_bottom	# check if player is on top of the scoreboard
	addi $t0, $t0, -3584	# we are here so we are standing on the scoreboard
	sw $t0, 0($t2)	
	la $t3, double_jump
	li $t5, 1
	sw $t5, 0($t3)		# reset double jump
	jr $ra
not_on_bottom:
	la $t3, double_jump
	lw $t4, 0($t3)		# $t3 = double jump flag. 1 = available, 0 = spent
	beqz $t4, not_w
	li $t4, 0		# we are here so double jump is available
	sw $t4, 0($t3)		# remove double jump
	addi $t0, $t0, -3584	
	sw $t0, 0($t2)		# update player position
	jr $ra
not_w:	bne $t1, 0x70, not_p
	j restart		# restart program
not_p:
	jr $ra

restart:
	la $t0, health
	la $t1, invincible
	li $t2, 3
	sw $t2, 0($t0)
	li $t2, 0
	sw $t2, 0($1)
	j main	
	
draw_number:	# $a0 = number to draw (0-9) $a1 = which digit (0 or 1). uses $t0-4
	li $t0, BASE_ADDRESS
	addi $t1, $t0, 29620	# $t1 = top left corner of clock
	li $t2, board_back
	li $t3, white
	mul $t4, $a1, 20
	add $t1, $t1, $t4	# choose which digit to change (add 20 or do nothing)
	
	sw $t3, 0($t1)		# paint the whole 7 segment display white
	sw $t3, 4($t1)		# top: 		0, 	4, 	8, 	12
	sw $t3, 8($t1)		# left: 	0, 	256, 	512, 	768, 	1024
	sw $t3, 12($t1)		# right: 	12, 	268, 	524, 	780, 	1036
	sw $t3, 256($t1)	# middle: 	512, 	516, 	520, 	524
	sw $t3, 512($t1)	# bottom: 	1024, 	1028, 	1032, 	1036
	sw $t3, 768($t1)
	sw $t3, 1024($t1)
	sw $t3, 516($t1)
	sw $t3, 520($t1)
	sw $t3, 524($t1)
	sw $t3, 268($t1)
	sw $t3, 780($t1)
	sw $t3, 1028($t1)
	sw $t3, 1032($t1)
	sw $t3, 1036($t1)
	
	bgt $a0, 0, not_0	# filter #a0, set correct segments back to grey
	sw $t2, 516($t1)		
	sw $t2, 520($t1)
	j end_draw_number
not_0:	bgt $a0, 1, not_1
	sw $t2, 4($t1)		
	sw $t2, 8($t1)
	sw $t2, 12($t1)		
	sw $t2, 516($t1)
	sw $t2, 520($t1)		
	sw $t2, 524($t1)
	sw $t2, 1028($t1)
	sw $t2, 1032($t1)		
	sw $t2, 1036($t1)
	sw $t2, 268($t1)		
	sw $t2, 780($t1)
	j end_draw_number
not_1:  bgt $a0, 2, not_2
	sw $t2, 256($t1)		
	sw $t2, 780($t1)
	j end_draw_number
not_2:	bgt $a0, 3, not_3
	sw $t2, 256($t1)		
	sw $t2, 768($t1)
	j end_draw_number
not_3:	bgt $a0, 4, not_4
	sw $t2, 4($t1)		
	sw $t2, 8($t1)
	sw $t2, 768($t1)		
	sw $t2, 1024($t1)
	sw $t2, 1028($t1)		
	sw $t2, 1032($t1)
	j end_draw_number
not_4:	bgt $a0, 5, not_5
	sw $t2, 268($t1)		
	sw $t2, 768($t1)
	j end_draw_number
not_5:	bgt $a0, 6, not_6
	sw $t2, 268($t1)
	j end_draw_number
not_6:	bgt $a0, 7, not_7
	sw $t2, 256($t1)		
	sw $t2, 512($t1)
	sw $t2, 768($t1)		
	sw $t2, 1024($t1)
	sw $t2, 516($t1)		
	sw $t2, 520($t1)
	sw $t2, 1028($t1)		
	sw $t2, 1032($t1)
	j end_draw_number
not_7:	bgt $a0, 8, not_8
	j end_draw_number
not_8:	bgt $a0, 9, not_9
	sw $t2, 768($t1)
	j end_draw_number
not_9:
end_draw_number:
	jr $ra
	
draw_health: # $a0 = bar portion (0/1/2), $a1 = color. uses $t0-5
	li $t0, BASE_ADDRESS
	addi $t1, $t0, 29204	# $t1 = top left corner of bar
	li $t2, 40
	mult $a0, $t2
	mflo $t3
	add $t1, $t1, $t3	# $t1 = starting position for draw
	li $t4, 0 	# $t4 = counter for inner loop
	li $t5, 0 	# $t4 = counter for outer loop
start_loop_draw_health2:
	bge $t5, 7, end_loop_draw_health2	# run while $t5 < 10
start_loop_draw_health1:
	bge $t4, 10, end_loop_draw_health1	# run while $t4 < 10
	sw $a1, 0($t1)	# paint the pixel
	addi $t1, $t1, 4
	addi $t4, $t4, 1	# increment counters
	j start_loop_draw_health1
end_loop_draw_health1:
	li $t4, 0		# reset inner counter
	addi $t5, $t5, 1	# increment counter
	addi $t1, $t1, 216	# go to next row and 10 pixels left
	j start_loop_draw_health2
end_loop_draw_health2:
	jr $ra
	
draw_character: 
# $a0 = position, $a1 = 0 for erase, 1 for draw. Uses: $t0-3, $a0
	beqz $a1, draw_chatacter_erase	# erase if $a0 == 0
	
	li $t0, blue_pants_damage
	bgtz $s4, change_color1	# change color if taken damage
	li $t0, blue_pants
change_color1:		
	addi $a0, $a0, -4	# we are here so draw at $a0
	sw $t0, 0($a0)
	addi $a0, $a0, 8
	sw $t0, 0($a0)
	addi $a0, $a0, -768
	sw $t0, 0($a0)
	addi $a0, $a0, -8
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	li $t0, red_damage
	bgtz $s4, change_color2	# change color if taken damage
	li $t0, red
change_color2:	
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, -8
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	li $t0, yellow_damage
	bgtz $s4, change_color3	# change color if taken damage
	li $t0, yellow
change_color3:	
	addi $a0, $a0, 256
	sw $t0, 0($a0)
	addi $a0, $a0, 256
	sw $t0, 0($a0)
	addi $a0, $a0, 256
	sw $t0, 0($a0)
	addi $a0, $a0, 16
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, -516
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, 4
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, -4
	sw $t0, 0($a0)
	addi $a0, $a0, 2048
	sw $t0, 0($a0)
	addi $a0, $a0, 256
	sw $t0, 0($a0)
	addi $a0, $a0, 8
	sw $t0, 0($a0)
	addi $a0, $a0, -256
	sw $t0, 0($a0)
	
	jr $ra	# return
draw_chatacter_erase: # we are here so erase at $a0
	la $t2, buffer_copy	# load address of static reference
	la $t1, BASE_ADDRESS	# load address of $gp
	sub $t3, $a0, $t1	# offset in framebuffer
	add $t3, $t2, $t3	# location in buffer_copy
	
	addi $t3, $t3, -4
	addi $a0, $a0, -4
	lw $t0, 0($t3)
	sw $t0, 0($a0)
	addi $t3, $t3, 8	
	addi $a0, $a0, 8
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -768
	addi $a0, $a0, -768
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -8	
	addi $a0, $a0, -8
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -8	
	addi $a0, $a0, -8
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 256	
	addi $a0, $a0, 256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 256	
	addi $a0, $a0, 256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 256	
	addi $a0, $a0, 256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 16	
	addi $a0, $a0, 16
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -516
	addi $a0, $a0, -516
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 4	
	addi $a0, $a0, 4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256	
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -4	
	addi $a0, $a0, -4
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 2048	
	addi $a0, $a0, 2048
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 256	
	addi $a0, $a0, 256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, 8	
	addi $a0, $a0, 8
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)
	addi $t3, $t3, -256
	addi $a0, $a0, -256
	lw $t0, 0($t3) 	
	sw $t0, 0($a0)

	jr $ra 	# return
