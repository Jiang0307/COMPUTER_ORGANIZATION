main:
    addi $a0, $zero, 19654   #a0= 19654
    addi $a1, $zero, 100654  #a1=100654
    addi $a2, $zero, 10065   #a2= 10065
    jal average              # call average
    j exit

average:
    addi $sp, $sp, -4
    sw $ra, 0x0($sp)    # Save $ra register into stack
	#t0 = a0+a1+a2 
	add $t0,$a0,$a1
    add $t0,$t0,$a2
    addi $v0,$v0,0
	addi $t3,$zero,2
	loop:
		slt $t1,$t3,$t0
		beq $t1,$zero,endloop
		addi $v0,$v0,1
		addi,$t0,$t0,-3
		j loop
		    
	endloop:
    	lw $ra, 0x0($sp)    # Load $ra register from stack
    	addi $sp, $sp, 4
    	jr $ra
    	
exit: