main:
    addi $a0,$zero,10	  # N= 10
    addi $a1,$zero,5 	  # K = 5
    jal pascal        	 # call pascal(10, 5)
    j exit

pascal:
	slt $t1,$a1,$a0 
	slt $t2,$zero,$a1 	 # K > 0 
	add $t3,$t1,$t2
	addi $t4,$zero,2
	beq $t3,$t4,recursion
	
	addi $v0,$zero,1
	jr $ra
	
recursion:
	addi $sp,$sp,-16
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	add $s0,$a0,$zero 	#copy N
	add $s1,$a1,$zero 	#copy K
	
	addi $a0,$s0,-1
	addi $a1,$s1,-1
	jal pascal
	sw $v0,12($sp)
	
	addi $a0,$s0,-1
	addi $a1,$s1,0
	jal pascal
	lw $t5,12($sp)
	add $v0,$v0,$t5
	
	lw $s1,8($sp)
	lw $s0,4($sp)
	lw $ra,0($sp)
	addi $sp,$sp,16
	jr $ra

exit:
