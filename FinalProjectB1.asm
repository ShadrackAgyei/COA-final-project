        .data
            .align 2

            # Maximum allowed size for the array
            max_size:          .word 32

            # Variables to store user inputs
            array_size:        .word 0
            left_size:         .word 0
            right_size:        .word 0

            # Array allocations based on max_size
            array:             .space 128    # 32 words * 4 bytes = 128 bytes
            left_half:         .space 128    # 32 words * 4 bytes = 128 bytes
            right_half:        .space 128    # 32 words * 4 bytes = 128 bytes
            merged_array:      .space 128    # 32 words * 4 bytes = 128 bytes

            # Bubble sort state storage
            left_state:
                .word 0  # i
                .word 0  # j
                .word 0  # done

            right_state:
                .word 0  # i
                .word 0  # j
                .word 0  # done

            # Messages for user interaction and error handling
            msg_prompt_total_size:    .asciiz "Enter total array size (0 to 32): "
            msg_prompt_left_size:     .asciiz "Enter left half size: "
            msg_prompt_right_size:    .asciiz "Enter right half size: "
            msg_empty:                .asciiz "Empty array.\n"
            msg_too_large:            .asciiz "Array too large.\n"
            msg_section_too_large:    .asciiz "Array section too large.\n"
            msg_invalid_size:         .asciiz "Invalid section sizes. (left + right is not equal to total)\n"
            msg_negative_size:        .asciiz "Negative size not allowed.\n"          # New Message
            msg_prompt_element:       .asciiz "Enter element: "
            msg_sorted_array:         .asciiz "\nSorted array:\n"                      # New Message

        .text
            .globl main

        main:
            # -------------------------------
            # Step 1: Read Total Array Size
            # -------------------------------
            # Print prompt for total array size
            la $a0, msg_prompt_total_size
            li $v0, 4
            syscall

            # Read integer (total_size)
            li $v0, 5
            syscall
            move $t0, $v0            # $t0 = total_size

            # Store total_size
            sw $t0, array_size

            # -------------------------------
            # Step 2: Validate Total Array Size
            # -------------------------------
            # Check if total_size == 0 (Empty Array)
            beqz $t0, handle_empty

            # Check if total_size < 0 (Negative Size)
            bltz $t0, handle_negative_size

            # Load max_size
            la $t1, max_size
            lw $t2, 0($t1)            # $t2 = max_size

            # Check if total_size > max_size (Too-Large Array)
            bgt $t0, $t2, handle_too_large

            # -------------------------------
            # Step 3: Read Left Half Size
            # -------------------------------
            # Print prompt for left half size
            la $a0, msg_prompt_left_size
            li $v0, 4
            syscall

            # Read integer (left_size)
            li $v0, 5
            syscall
            move $t3, $v0            # $t3 = left_size

            # Store left_size
            sw $t3, left_size

            # -------------------------------
            # Step 4: Read Right Half Size
            # -------------------------------
            # Print prompt for right half size
            la $a0, msg_prompt_right_size
            li $v0, 4
            syscall

            # Read integer (right_size)
            li $v0, 5
            syscall
            move $t4, $v0            # $t4 = right_size

            # Store right_size
            sw $t4, right_size

            # -------------------------------
            # Step 5: Validate Section Sizes
            # -------------------------------
            # Check if left_size + right_size == total_size
            add $t5, $t3, $t4        # $t5 = left_size + right_size
            lw $t6, array_size
            bne $t5, $t6, handle_invalid_size

            # Check if left_size > max_size or right_size > max_size
            bgt $t3, $t2, handle_section_too_large
            bgt $t4, $t2, handle_section_too_large

            # Check if left_size < 0 or right_size < 0
            bltz $t3, handle_negative_size
            bltz $t4, handle_negative_size

            # -------------------------------
            # Step 6: Read Array Elements
            # -------------------------------
            # Initialize loop counter
            move $t7, $zero          # $t7 = 0 (current index)
            la $t8, array            # $t8 = address of array

        read_elements_loop:
            # Compare $t7 with array_size
            beq $t7, $t0, proceed_sort

            # Print prompt for element
            la $a0, msg_prompt_element
            li $v0, 4
            syscall

            # Read integer
            li $v0, 5
            syscall
            move $t9, $v0            # $t9 = element

            # Store element in array
            sw $t9, 0($t8)

            # Increment address and counter
            addi $t8, $t8, 4         # Move to next array element
            addi $t7, $t7, 1         # Increment index

            j read_elements_loop

        handle_empty:
            # Print 'Empty array' message
            la $a0, msg_empty
            li $v0, 4
            syscall

            # Exit
            li $v0, 10
            syscall

        handle_too_large:
            # Print 'Array too large' message
            la $a0, msg_too_large
            li $v0, 4
            syscall

            # Exit
            li $v0, 10
            syscall

        handle_section_too_large:
            # Print 'Array section too large' message
            la $a0, msg_section_too_large
            li $v0, 4
            syscall

            # Exit
            li $v0, 10
            syscall

        handle_invalid_size:
            # Print 'Invalid array sizes' message
            la $a0, msg_invalid_size
            li $v0, 4
            syscall

            # Exit
            li $v0, 10
            syscall

        handle_negative_size:
            # Print 'Negative size not allowed' message
            la $a0, msg_negative_size
            li $v0, 4
            syscall

            # Exit
            li $v0, 10
            syscall

        proceed_sort:
            # -------------------------------
            # Step 7: Split Array into Halves
            # -------------------------------
            # Load left_size and right_size
            lw $t0, array_size
            lw $t1, left_size
            lw $t2, right_size

            # Calculate byte offsets
            sll $t3, $t1, 2          # $t3 = left_size * 4
            sll $t4, $t2, 2          # $t4 = right_size * 4

            # Initialize pointers for left_half and right_half
            la $t5, array             # $t5 = base address of array
            la $t6, left_half         # $t6 = base address of left_half
            la $t7, right_half        # $t7 = base address of right_half

            # Copy left_size elements to left_half
            move $t8, $zero           # $t8 = index

        copy_left_loop:
            beq $t8, $t1, copy_right_half
            lw $a0, 0($t5)            # Load element from array
            sw $a0, 0($t6)            # Store to left_half
            addi $t5, $t5, 4          # Move to next element in array
            addi $t6, $t6, 4          # Move to next element in left_half
            addi $t8, $t8, 1          # Increment index
            j copy_left_loop

        copy_right_half:
            move $t8, $zero           # $t8 = index

        copy_right_loop:
            beq $t8, $t2, sort_halves
            lw $a0, 0($t5)            # Load element from array
            sw $a0, 0($t7)            # Store to right_half
            addi $t5, $t5, 4          # Move to next element in array
            addi $t7, $t7, 4          # Move to next element in right_half
            addi $t8, $t8, 1          # Increment index
            j copy_right_loop

        sort_halves:
            # -------------------------------
            # Step 8: Initialize Bubble Sort States
            # -------------------------------
            # Initialize bubble sort states for left_half
            la $a0, left_state
            li $a1, 8                # Size (not used in init)
            jal bubble_sort_init

            # Initialize bubble sort states for right_half
            la $a0, right_state
            li $a1, 8                # Size (not used in init)
            jal bubble_sort_init

            # -------------------------------
            # Step 9: Simulate Multithreaded Bubble Sort
            # -------------------------------
            la $s0, left_state        # $s0 = address of left_state
            la $s1, right_state       # $s1 = address of right_state
            la $s2, left_half         # $s2 = address of left_half
            la $s3, right_half        # $s3 = address of right_half
            lw $s4, left_size         # $s4 = left_size
            lw $s7, right_size        # $s7 = right_size

        multithreading_loop:
            # Step left half
            move $a0, $s0             # state pointer
            move $a1, $s2             # array pointer
            move $a2, $s4             # size
            jal bubble_sort_step
            move $t0, $v0             # left done?

            # Step right half
            move $a0, $s1
            move $a1, $s3
            move $a2, $s7
            jal bubble_sort_step
            move $t1, $v0             # right done?

            # If both done, break loop
            and $t2, $t0, $t1
            bnez $t2, halves_sorted
            j multithreading_loop

        halves_sorted:
            # -------------------------------
            # Step 10: Merge the Two Sorted Halves
            # -------------------------------
            la $a0, left_half          # left array
            la $a1, right_half         # right array
            la $a2, merged_array       # merged array
            lw $a3, left_size          # size of left_half
            lw $t0, right_size         # size of right_half

            addi $sp, $sp, -4
            sw $t0, 0($sp)             # Push size_of_right
            jal merge_arrays
            # No need to pop here since merge_arrays handles it

            # -------------------------------
            # Step 11: Print the Sorted Array Message and Merged Array
            # -------------------------------
            la $a0, msg_sorted_array   # Load "Sorted array: " message
            li $v0, 4
            syscall

            jal print_merged_array

            # -------------------------------
            # Step 12: Exit Program
            # -------------------------------
            li $v0, 10
            syscall

        ############################
        # bubble_sort_init
        # Initializes i=0, j=0, done=0 in state block
        # a0 = state pointer, a1 = size (not used)
        ############################
        bubble_sort_init:
            sw $zero, 0($a0)    # i=0
            sw $zero, 4($a0)    # j=0
            sw $zero, 8($a0)    # done=0
            jr $ra

        ############################
        # bubble_sort_step
        # Performs one step of bubble sort for the given array section.
        # One step = one comparison and possible swap
        # Returns v0=1 if done, else 0.
        # a0 = state pointer
        # a1 = array pointer
        # a2 = size
        ############################
        bubble_sort_step:
            # Load i, j, done from state
            lw $t0, 0($a0)       # i
            lw $t1, 4($a0)       # j
            lw $t2, 8($a0)       # done

            bnez $t2, step_done # If already done, just return

            # Check if i == size-1 (fully sorted)
            addi $t3, $a2, -1
            beq $t0, $t3, mark_done

            # If j >= size - i -1, start next pass
            sub $t4, $a2, $t0    # t4 = size - i
            addi $t4, $t4, -1    # t4 = size - i -1
            bge $t1, $t4, next_pass

            # Compare arr[j] and arr[j+1]
            sll $t5, $t1, 2      # t5 = j * 4
            add $t6, $a1, $t5    # address of arr[j]
            lw $t7, 0($t6)       # arr[j]
            lw $t8, 4($t6)       # arr[j+1]

            ble $t7, $t8, no_swap
            # Swap if arr[j] > arr[j+1]
            sw $t8, 0($t6)
            sw $t7, 4($t6)
        no_swap:

            # Increment j
            addi $t1, $t1, 1
            j finish_step

        next_pass:
            # Completed one pass, increment i, reset j to 0
            addi $t0, $t0, 1
            move $t1, $zero

        finish_step:
            # Check if done now
            addi $t9, $a2, -1
            beq $t0, $t9, mark_done

            # Store updated state
            sw $t0, 0($a0)        # i
            sw $t1, 4($a0)        # j
            sw $zero, 8($a0)      # done=0
            li $v0, 0              # not done
            jr $ra

        mark_done:
            # Mark done
            sw $t0, 0($a0)        # i
            sw $t1, 4($a0)        # j
            li $t3, 1
            sw $t3, 8($a0)        # done=1
            li $v0, 1              # done
            jr $ra

        step_done:
            # Already done
            li $v0, 1
            jr $ra

        ############################
        # merge_arrays
        # Merges two sorted arrays into a merged array
        # a0=left_half ptr, a1=right_half ptr, a2=merged ptr, a3=size_of_left
        # stack top before call: size_of_right
        ############################
        merge_arrays:
            lw $t1, 0($sp)      # size_right
            addi $sp, $sp, 4    # pop size_right

            # Save $s registers ($s0-$s4)
            addi $sp, $sp, -20
            sw $s0, 0($sp)
            sw $s1, 4($sp)
            sw $s2, 8($sp)
            sw $s3, 12($sp)
            sw $s4, 16($sp)

            move $s0, $a0       # left ptr
            move $s1, $a1       # right ptr
            move $s2, $a2       # merged ptr
            move $s3, $zero     # i
            move $s4, $zero     # j

            move $t0, $a3       # size_left
            # $t1 already has size_right from stack

            move $t2, $zero     # k index in merged

        merge_loop:
            # If i == size_left, copy remaining right
            beq $s3, $t0, copy_remaining_right
            # If j == size_right, copy remaining left
            beq $s4, $t1, copy_remaining_left

            # Compare left[i] and right[j]
            sll $t3, $s3, 2
            add $t4, $s0, $t3
            lw $t5, 0($t4)       # left[i]

            sll $t3, $s4, 2
            add $t6, $s1, $t3
            lw $t7, 0($t6)       # right[j]

            ble $t5, $t7, take_left

        take_right:
            # merged[k] = right[j]
            sll $t3, $t2, 2
            add $t4, $s2, $t3
            sw $t7, 0($t4)
            addi $s4, $s4, 1
            addi $t2, $t2, 1
            j merge_loop

        take_left:
            # merged[k] = left[i]
            sll $t3, $t2, 2
            add $t4, $s2, $t3
            sw $t5, 0($t4)
            addi $s3, $s3, 1
            addi $t2, $t2, 1
            j merge_loop

        copy_remaining_left:
            # Copy remaining elements from left_half
            beq $s3, $t0, merge_done
            sll $t3, $s3, 2
            add $t4, $s0, $t3
            lw $t5, 0($t4)
            sll $t3, $t2, 2
            add $t6, $s2, $t3
            sw $t5, 0($t6)
            addi $s3, $s3, 1
            addi $t2, $t2, 1
            j copy_remaining_left

        copy_remaining_right:
            # Copy remaining elements from right_half
            beq $s4, $t1, merge_done
            sll $t3, $s4, 2
            add $t4, $s1, $t3
            lw $t7, 0($t4)
            sll $t3, $t2, 2
            add $t6, $s2, $t3
            sw $t7, 0($t6)
            addi $s4, $s4, 1
            addi $t2, $t2, 1
            j copy_remaining_right

        merge_done:
            # Restore $s registers ($s0-$s4)
            lw $s0, 0($sp)
            lw $s1, 4($sp)
            lw $s2, 8($sp)
            lw $s3, 12($sp)
            lw $s4, 16($sp)
            addi $sp, $sp, 20
            jr $ra

        ############################
        # print_merged_array
        # Prints the merged array elements
        # a0 not used
        ############################
        print_merged_array:
            addi $sp, $sp, -8
            sw $s0, 0($sp)
            sw $s1, 4($sp)

            la $s0, merged_array     # $s0 = address of merged_array
            lw $t0, array_size       # $t0 = array_size
            move $s1, $t0            # $s1 = array_size (loop counter)

        print_loop:
            beqz $s1, print_done
            lw $a0, 0($s0)           # Load merged_array[k]
            li $v0, 1                # syscall for print integer
            syscall

            # Print space
            li $v0, 11               # syscall for print character
            li $a0, 32               # ASCII code for space
            syscall

            addi $s0, $s0, 4         # Move to next element
            addi $s1, $s1, -1        # Decrement loop counter
            j print_loop

        print_done:
            # Print newline
            li $v0, 11               # syscall for print character
            li $a0, 10               # ASCII code for newline
            syscall

            # Restore $s registers ($s0-$s1)
            lw $s0, 0($sp)
            lw $s1, 4($sp)
            addi $sp, $sp, 8
            jr $ra
