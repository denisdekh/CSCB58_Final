#####################################################################
#
# CSCB58 Winter 2022 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Denis Dekhtyarenko, 1006316675, dekhtyar, d.dekhtyarenko@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 1024 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... Features TODO: double jump, fail condition: no health, win condition: timer, health bar and timer (score), moving platforms, enemies shoot back
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes and please share this project github link as well https://github.com/Umenemo/CSCB58_Final (Private and can't be accessed until end of semester as per the handout)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.eqv BASE_ADDRESS 0x10008000
.eqv blue 0x0056c9ef
.eqv spike_inside 0x00dfdfdf
.eqv spike_outline 0x002f2f2f	
.eqv board_back 0x004a4a4a
.eqv yellow 0x00ffeb3b
.eqv red 0x00ff0000
.eqv blue_pants 0x000000ff
.eqv platform 0x00f57f17
.eqv green 0x004caf4f

.data
.align 2
buffer_copy: .space 32768	# copy of the bufferframe for static elements
player_position: .word 0
.align 2
platform_positions: .space 64	# array to store platforms' positions and their direction of movement
n_platforms: .word 8
standing: .word -1
double_jump: .word 1
health: .word 3
invincible: .word 0
laser_position: .word -100

.text
main:
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
	
	addi $t1, $t1, 256	# skip a line
	addi $t2, $t2, 4864 	# $t2 = new target address (64px * 20px * 4 bytes per unit - 256 (last line) = 4864 )
	li $t4, 0	# counter for inner start_loop
	li $t0, board_back
start_loop_paint_board2:
	bge $t1, $t2, end_loop_paint_board2	# run while $t1 < $t2
	addi $t1, $t1, 4	# skip first pixel
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
	addi $t1, $t1, 4	# skip last pixel 
	j start_loop_paint_board2
end_loop_paint_board2:

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

	li $s6, BASE_ADDRESS
	addi $t3, $s6, 3584	# $t3 = row pointer, start at row 14
	la $t1, platform_positions	# get pointer to beginning of array
	li $t2, 0	# initialize counter
start_loop_initialize_platforms:
	bge $t2, 64, end_loop_initialize_platforms
	li $v0, 42
	li $a0, 0
	li $a1, 48
	syscall		# $a0 = random number 0-47
	addi $a0, $a0, 1	# $a0 is from 1-48
	li $t4, 4
	mult $a0, $t4
	mflo $a0		# $a0 = 4*(1 to 48)
	add $a0, $t3, $a0	# random location for the platform
	sw $a0, 0($t1)
	li $v0, 42
	li $a0, 0
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
	
start_loop_main:
	la $t1, platform_positions	# get pointer to beginning of array
	addi $t2, $t1, 64	# $t2 = target
	li $t8, 0	# number of the platform
start_loop_update_platforms:	
	bge $t1, $t2, end_loop_update_platforms # loop while $t1 < platform_positions[8]
	lw $t3, 0($t1)	# $t3 = current position
	lw $t4, 4($t1) 	# $t4 = direction change
	
	addi $sp, $sp, -16	# save registers
	sw $t1, 0($sp)	
	sw $t2, 4($sp)
	sw $t3, 8($sp)
	sw $t4, 12($sp)	
	move $a0, $t3
	move $a1, $t4
	jal draw_platform	# draw new platform
	lw $t1, 0($sp)		# restore registers
	lw $t2, 4($sp)
	lw $t3, 8($sp)
	lw $t4, 12($sp)
	addi $sp, $sp, 16
	
	add $t3, $t3, $t4	# $t3 = new position
	sw $t3, 0($t1)		# update position
	
	addi $t5, $t3, -256
	la $t6, standing
	lw $t9, 0($t6)		# $t9 = standing status
	lw $t7, 0($s7)		# $t7 = player position
	
	bgt $t9, -1, after_standing	# skip logic if player is already standing
	bge $t5, $t7, not_on_platform 	# standing if $t3 - 256 < $t7 < $t3 - 195
	addi $t5, $t5, 60
	ble $t5, $t7, not_on_platform 
	# we are here so character is on the platform
	sw $t8, 0($t6)		# update standing flag
	la $t8, double_jump
	li $t9, 1
	sw $t9, 0($t8)		# reset double jump
	j after_standing
not_on_platform:
	li $t5, -1
	sw $t5, 0($t6)	# set as not standing
after_standing:

	li $t5, 256	# bytes per row
	div $t3, $t5
	mfhi $t5
	# TODO check if $t5 is less than 4 or greater than 251 => multiply $t4 by -1 and update array
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
	la $t1, standing
	lw $t3, 0($t1)		# $t1 = platform index
	bgt $t3, -1, standing1	# if $t1 > -1 then player is on a platform
	lw $t2, 0($s7)
	addi $t5, $s6, 27392	# $t5 = base address + 104 rows	
	bge $t2, $t5, nstanding	# check if player is above the scoreboard
	addi $t2, $t2, 256	# we are here so player is falling
	sw $t2, 0($s7)		# update player position
	j nstanding
standing1:
	mul $t3, $t3, 8
	la $t4, platform_positions
	add $t4, $t4, $t3
	lw $t4, 4($t4)		# $t4 = movement of platform player is standing on
	lw $t3, 0($s7)
	add $t3, $t3, $t4	# move player with platform
	sw $t3, 0($s7)		
nstanding:
	li $t3, -1
	sw $t3, 0($t1)		# set standing to -1
	lw $a0, 0($s7)		# load new player position
	li $a1, 1
	jal draw_character	# draw new character
	
	# if invincible => decrement, if not check for incoming damage and reset invincibility
	la $t4, invincible
	lw $t5, 0($t4)	# $t5 = invincibility counter
	bgtz $t5, invincible_gtz
	lw $t0, 0($s7)	# $t0 = player position
	li $t3, 256
	li $t4, BASE_ADDRESS
	sub $t4, $t0, $t4	# $t4 = position in buffer
	div $t4, $t3
	mfhi $t1	# $t1 = horizontal position
	blt $t1, 28, take_damage
	bgt $t1, 227, take_damage
	bge $t4, 26368, take_damage
	la $t6, laser_position
	lw $t6, 0($t6)		# $t6 = position of laser
	sub $t6, $t1, $t6	# $t6 = difference between Hor. positions of player and laser
	sra $t7, $t6, 31   
	xor $t6, $t6, $t7   
	sub $t6, $t6, $t7	# $t6 = absolute distance between player and laser
	blt $t6, 16, take_damage
	j end_damage_calc	# no damage taken, don't do anything
invincible_gtz:
	la $t4, invincible
	lw $t5, 0($t4)		# $t5 = invincibility counter
	addi $t5, $t5, -1	# decrement invincibility counter
	sw $t5, 0($t4)
	bgtz $t5, still_invincible
	la $t1, health
	lw $a0, 0($t1)		# $a0 = health of player
	move $a1, $zero
	jal draw_health		# update health bar
still_invincible:
	j end_damage_calc	# continue the game
take_damage:
	la $t1, health
	lw $t2, 0($t1)		# $t2 = health of player
	addi $t2, $t2, -1	# take off 1 health
	beqz $t2, game_over
	sw $t2, 0($t1)		# we are here so game is not over, update health
	la $t4, invincible
	li $t3, 75		# invincible = 75 cycles (3 seconds of invincibility at 40ms sleep)
	sw $t3, 0($t4)	
	move $a0, $t2
	li $a1, red	
	jal draw_health		# update health bar
end_damage_calc:
	# TODO: optimize damage checks using registers
	li $v0, 32
	li $a0, 50 # Wait 50ms (20 FPS)
	syscall

	j start_loop_main
end_loop_main:
	
	li $v0, 10 # terminate the program gracefully
	syscall
	
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
	
	li $t9, 0xffff0000
start_loop_wait_for_p:	
	lw $t8, 0($t9)
	bne $t8, 1, no_press_restart	# check for key press
	lw $t1, 4($t9)		# we are here so a key was pressed
	bne $t1, 0x70, no_press_restart
	j restart		# p was pressed, restart game
no_press_restart:

	li $v0, 32
	li $a0, 100 # Wait 100ms
	syscall
	j start_loop_wait_for_p	
end_loop_wait_for_p:
	
	
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
not_d:	la $t3, standing
	lw $t4, 0($t3)		# $t3 = standing status
	bne $t1, 0x73, not_s	# check if s is pressed
	beq $t4, -1, not_s	# check if player is already falling
	addi $t0, $t0, 256	# we are here so we are not already falling
	sw $t0, 0($t2)		# update player position
	jr $ra
not_s:	bne $t1, 0x77, not_w
	beq $t4, -1, not_stand	
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
	
draw_health: # $a0 = bar portion (0/1/2), $a1 = color. uses $t0-5
	li $t0, BASE_ADDRESS
	addi $t1, $t0, 28692	# $t1 = top left corner of bar
	li $t2, 40
	mult $a0, $t2
	mflo $t3
	add $t1, $t1, $t3	# $t1 = starting position for draw
	li $t4, 0 	# $t4 = counter for inner loop
	li $t5, 0 	# $t4 = counter for outer loop
start_loop_draw_health2:
	bge $t5, 10, end_loop_draw_health2	# run while $t5 < 10
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
	li $t0, blue_pants		# we are here so draw at $a0
	addi $a0, $a0, -4
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
	li $t0, red
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
	li $t0, yellow
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
