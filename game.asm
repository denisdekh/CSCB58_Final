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

.data
.align 2
buffer_copy: .space 32768	# copy of the bufferframe for static elements
player_position: .word 0

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


	la $s7, player_position		# set initial player position
	addi $t1, $t9, 16512
	sw $t1, 0($s7)		# $t1 = initial player position
	move $a0, $t1
	li $a1, 1
	jal draw_character
start_loop_main:
	
	li $t9, 0xffff0000	# check for key press
	lw $t8, 0($t9)
	bne $t8, 1, no_press
	jal keypress_handle	# we are here so a key was pressed 
no_press:
	
	li $v0, 32
	li $a0, 50 # Wait 50ms (20 FPS)
	syscall

	j start_loop_main
end_loop_main:
	
	li $v0, 10 # terminate the program gracefully
	syscall
	
keypress_handle:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $s2, player_position		
	lw $s0, 0($s2)	# $s0 = current player position
	lw $s1, 4($t9)  # $s1 = pressed key
	bne $s1, 0x61, not_a
	move $a0, $s0		# we are here so 'a' was pressed
	li $a1, 0
	jal draw_character
	addi $s0, $s0, -4
	sw $s0, 0($s2)		# update player position	
	move $a0, $s0
	li $a1, 1
	jal draw_character
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# restore $ra and return
	jr $ra
not_a:	bne $s1, 0x64, not_d
	move $a0, $s0		# we are here so 'd' was pressed
	li $a1, 0
	jal draw_character
	addi $s0, $s0, 4
	sw $s0, 0($s2)		# update player position	
	move $a0, $s0
	li $a1, 1
	jal draw_character
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# restore $ra and return
	jr $ra
not_d:	bne $s1, 0x73, not_s
	move $a0, $s0		# we are here so 's' was pressed
	li $a1, 0
	jal draw_character
	addi $s0, $s0, 256
	sw $s0, 0($s2)		# update player position	
	move $a0, $s0
	li $a1, 1
	jal draw_character
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# restore $ra and return
	jr $ra
not_s:	bne $s1, 0x77, not_w
	move $a0, $s0		# we are here so 'w' was pressed
	li $a1, 0
	jal draw_character
	addi $s0, $s0, -256
	sw $s0, 0($s2)		# update player position	
	move $a0, $s0
	li $a1, 1
	jal draw_character
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# restore $ra and return
	jr $ra
not_w:
	lw $ra, 0($sp)
	addi $sp, $sp, 4	# restore $ra and return
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
