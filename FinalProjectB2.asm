# Academic Performance Analytics System
# MIPS Assembly Code

.data
###############################################################
# Data Section
###############################################################
    grades:             .word   0:50        # Array to store up to 50 grades (sorted)
    originalGrades:     .word   0:50        # Array to store grades in original order
    letterGrades:       .space  50          # Array to store corresponding letter grades
    gradeCount:         .word   0           # Number of grades entered
    highestGrade:       .word   0
    lowestGrade:        .word   0
    classAverage:       .word   0
    medianGrade:        .word   0
    passCount:          .word   0
    failCount:          .word   0
    histogram:          .word   0:10        # Histogram bins for grade distribution
    trendData:          .word   0:49        # Array for storing trend data (n-1 differences)
    predictedGrade:     .word   0
    confidenceLevel:    .word   0
    trendSymbols:       .space  50          # Array to store trend symbols
    atRiskFlags:        .space  50          # Array to store at-risk flags (0 or 1)
    trendFlag:          .word   0           # Stores the overall trend flag
    weights:            .word   0:50        # Weights for each grade (up to 50)
    weightedAverage:    .word   0
    weightMsg:          .asciiz "\nEnter weight for grade "
    
# Messages for User Interaction
    noDataMsg:          .asciiz "\nNo grades entered. Exiting program.\n"
    noWeightsMsg:       .asciiz "\nNo weights entered. Exiting program.\n"  # New Message
    enterGradeMsg:      .asciiz "\nEnter grade (0-100) or -1 to finish: "
    invalidGradeMsg:    .asciiz "Invalid grade! Please enter a value between 0 and 100.\n"
    invalidWeightMsg:   .asciiz "Invalid weight! Please enter a value between 1 and 5.\n"
    maxGradesMsg:       .asciiz "Maximum number of grades reached.\n"

    classAvgMsg:        .asciiz "\nClass Average: "
    weightedAvgMsg:     .asciiz "\nWeighted Average: "
    weightRangeMsg:     .asciiz " (1-5): "
    highestGradeMsg:    .asciiz "\nHighest Grade: "
    lowestGradeMsg:     .asciiz "\nLowest Grade: "
    medianGradeMsg:     .asciiz "\nMedian Grade: "
    passRateMsg:        .asciiz "\nPass Rate: "
    failRateMsg:        .asciiz "\nFail Rate: "
    percentSymbol:      .asciiz "%"
    histogramTitle:     .asciiz "\nGrade Distribution Histogram:\n"
    gradeRange:         .asciiz "-"
    barLabel:           .asciiz ": "
    graphChar:          .asciiz "*"
    newline:            .asciiz "\n"
    separator:          .asciiz "\n---------------------------\n"  # New Separator
    space:             .asciiz " "
    
    originalGradesMsg:  .asciiz "\nEntered Grades:\n"  # New Message
    prediction_msg:     .asciiz "\nPredicted Next Grade: "
    confidence_msg:     .asciiz "\nConfidence Level: "
    notEnoughDataMsg:   .asciiz "\nNot enough data to make a prediction.\n"
    gradesAndLettersMsg:.asciiz "Grades and Letter Grades (Sorted):\n"  # Updated Message
    dashSpace:          .asciiz " - "

    gradeTrendsMsg:     .asciiz "\nGrade Trends:\n"
    atRiskStudentsMsg:  .asciiz "\nAt-Risk Students:\n"
    studentMsg:         .asciiz "Student "
    colonGradeMsg:      .asciiz ": Grade "
    noneMsg:            .asciiz "None\n"

    trend_up:           .asciiz "Upward trend detected\n"
    trend_down:         .asciiz "Downward trend detected\n"
    trend_stable:       .asciiz "Stable trend detected\n"
    differenceMsg:      .asciiz "Difference between successive grades: "
    
    upMsg:              .asciiz "up "
    downMsg:            .asciiz "down "
    stableMsg:          .asciiz "stable "
    # trendBetweenMsg (if using optional label)
    # trendBetweenMsg: .asciiz "Trends between successive grades: "

.text
###############################################################
# Main Program
###############################################################
.globl main
main:
    jal     inputGrades          # Input grades from the user

    # Check if any grades were entered
    lw      $t0, gradeCount
    beq     $t0, $zero, noDataEntered
    
    jal     inputWeights         # Input weights for each grade
    
    # Verify that weights have been entered for all grades
    lw      $t1, gradeCount
    beq     $t1, $zero, noWeightsEntered  # If no grades, weights shouldn't exist, but safety check
    
    jal     calculateStats       # Calculate statistics
    jal     calculateWeightedAverage  # Calculate weighted average
        jal     analyzeTrend         # Analyze grade trends (based on originalGrades)
            jal     predictiveAnalysis   # Perform predictive analytics
    jal     sortGrades           # Sort grades for median calculation
    jal     calculateMedian      # Calculate median grade
    jal     convertToLetterGrades# Convert numerical grades to letter grades
    jal     createHistogram      # Create histogram data


    jal     displayDashboard     # Display analytics dashboard
    jal     exitProgram          # Exit program

noDataEntered:
    # Display no data message
    li      $v0, 4
    la      $a0, noDataMsg
    syscall
    jal     exitProgram

noWeightsEntered:
    # Display no weights message
    li      $v0, 4
    la      $a0, noWeightsMsg
    syscall
    jal     exitProgram

###############################################################
# Procedures
###############################################################

# Procedure: inputGrades
# Purpose: Input grades from the user with validation
inputGrades:
    addi    $sp, $sp, -16        # Adjust stack to save two pointers
    sw      $ra, 12($sp)
    sw      $s0, 8($sp)
    sw      $s1, 4($sp)
    sw      $s2, 0($sp)

    li      $s0, 0               # Grade counter
    la      $s1, grades          # Pointer to grades array (sorted)
    la      $s2, originalGrades  # Pointer to originalGrades array

inputLoop:
    li      $v0, 4
    la      $a0, enterGradeMsg
    syscall

    li      $v0, 5               # Read integer
    syscall
    move    $t0, $v0             # Store input in $t0

    beq     $t0, -1, endInput    # If input is -1, end input
    blt     $t0, 0, invalidInput # If input < 0, invalid
    bgt     $t0, 100, invalidInput # If input > 100, invalid

    # Store valid grade in grades array
    sw      $t0, ($s1)

    # Store valid grade in originalGrades array
    sw      $t0, ($s2)

    addi    $s1, $s1, 4          # Move to next grade slot in grades
    addi    $s2, $s2, 4          # Move to next grade slot in originalGrades
    addi    $s0, $s0, 1          # Increment grade counter
    li      $t3, 50
    bge     $s0, $t3, maxGradesReached
    j       inputLoop

invalidInput:
    li      $v0, 4
    la      $a0, invalidGradeMsg
    syscall
    j       inputLoop

maxGradesReached:
    li      $v0, 4
    la      $a0, maxGradesMsg
    syscall
    j       endInput

endInput:
    sw      $s0, gradeCount      # Store number of grades

    lw      $s2, 0($sp)          # Restore registers
    lw      $s1, 4($sp)
    lw      $s0, 8($sp)
    lw      $ra, 12($sp)
    addi    $sp, $sp, 16
    jr      $ra


# Procedure: inputWeights
# Purpose: Prompt user to enter a weight for each grade, showing the grade in the prompt
inputWeights:
    addi    $sp, $sp, -12
    sw      $ra, 8($sp)
    sw      $s0, 4($sp)
    sw      $s1, 0($sp)

    la      $s0, weights         # Pointer to weights array
    lw      $s1, gradeCount      # Number of grades
    move    $t0, $zero           # Counter

    # Pointer to originalGrades array to display the grade
    la      $t9, originalGrades

weightInputLoop:
    blt     $t0, $s1, promptWeight
    j       endWeightInput

promptWeight:
    # Compute current grade address in originalGrades
    sll     $t2, $t0, 2          # t2 = t0 * 4
    add     $t3, $t9, $t2        # Address of originalGrades[t0]
    lw      $t4, ($t3)           # Load the grade

    # Print: "Enter weight for grade X (1-5): "
    li      $v0, 4
    la      $a0, weightMsg       # "Enter weight for grade "
    syscall

    # Print the grade number
    li      $v0, 1
    move    $a0, $t4             # The actual grade
    syscall

    # Print continuation of prompt: " (1-5): "
    li      $v0, 4
    la      $a0, weightRangeMsg  # " (1-5): "
    syscall

    # Now read the weight input
    li      $v0, 5               # Read integer
    syscall
    move    $t1, $v0

    # Validate weight (1-5)
    li      $t2, 1
    li      $t3, 5
    blt     $t1, $t2, invalidWeight
    bgt     $t1, $t3, invalidWeight

    # Store valid weight
    sw      $t1, ($s0)

    addi    $s0, $s0, 4          # Move to next weight slot
    addi    $t0, $t0, 1
    j       weightInputLoop

invalidWeight:
    li      $v0, 4
    la      $a0, invalidWeightMsg  # orint invalid weight msg
    syscall
    j       weightInputLoop

endWeightInput:
    # Verify that all weights have been entered
    lw      $t1, gradeCount
    la      $t2, weights
    move    $t3, $zero           # Counter

verifyWeightsLoop:
    beq     $t3, $t1, weightsVerified
    lw      $t4, 0($t2)           # Load weight
    blt     $t4, 1, invalidWeights
    bgt     $t4, 5, invalidWeights
    addi    $t2, $t2, 4
    addi    $t3, $t3, 1
    j       verifyWeightsLoop

weightsVerified:
    j       finishWeightInput

invalidWeights:
    # Display no weights message and exit
    li      $v0, 4
    la      $a0, noWeightsMsg
    syscall
    jal     exitProgram

finishWeightInput:
    lw      $s1, 0($sp)
    lw      $s0, 4($sp)
    lw      $ra, 8($sp)
    addi    $sp, $sp, 12
    jr      $ra


# Procedure: calculateStats
# Purpose: Calculate class average, highest, lowest grades, and pass/fail counts
calculateStats:
    addi    $sp, $sp, -32
    sw      $ra, 28($sp)
    sw      $s7, 24($sp)
    sw      $s6, 20($sp)
    sw      $s5, 16($sp)
    sw      $s4, 12($sp)
    sw      $s3, 8($sp)
    sw      $s2, 4($sp)
    sw      $s1, 0($sp)

    # Initialize variables
    la      $s0, grades          # Pointer to grades array (sorted)
    lw      $s1, gradeCount      # Number of grades
    move    $s2, $zero           # Sum of grades
    move    $s3, $zero           # Highest grade
    li      $s4, 100             # Lowest grade (initialize to max possible)
    move    $s5, $zero           # Pass count
    move    $s6, $zero           # Fail count

    # Loop through grades
    move    $t0, $zero           # Counter
calcLoop:
    lw      $t1, ($s0)           # Load grade

    # Sum grades
    add     $s2, $s2, $t1

    # Check for highest grade
    slt     $t2, $s3, $t1
    beq     $t2, $zero, checkLowest
    move    $s3, $t1             # Update highest grade

checkLowest:
    # Check for lowest grade
    slt     $t2, $t1, $s4
    beq     $t2, $zero, checkPassFail
    move    $s4, $t1             # Update lowest grade

checkPassFail:
    # Check pass/fail
    li      $t2, 60
    slt     $t3, $t1, $t2
    bne     $t3, $zero, incrementFail
    addi    $s5, $s5, 1          # Increment pass count
    j       nextGrade

incrementFail:
    addi    $s6, $s6, 1          # Increment fail count

nextGrade:
    addi    $s0, $s0, 4          # Move to next grade
    addi    $t0, $t0, 1
    blt     $t0, $s1, calcLoop

    # Calculate class average
    div     $s2, $s1
    mflo    $s7                   # Class average stored in $s7

    # Store results in memory
    sw      $s3, highestGrade
    sw      $s4, lowestGrade
    sw      $s7, classAverage
    sw      $s5, passCount
    sw      $s6, failCount

    # Restore registers
    lw      $s1, 0($sp)
    lw      $s2, 4($sp)
    lw      $s3, 8($sp)
    lw      $s4, 12($sp)
    lw      $s5, 16($sp)
    lw      $s6, 20($sp)
    lw      $s7, 24($sp)
    lw      $ra, 28($sp)
    addi    $sp, $sp, 32
    jr      $ra


# Procedure: calculateWeightedAverage
# Purpose: Calculate the weighted average of the grades using the inputted weights
calculateWeightedAverage:
    addi    $sp, $sp, -36
    sw      $ra, 32($sp)
    sw      $s4, 28($sp)
    sw      $s3, 24($sp)
    sw      $s2, 20($sp)
    sw      $s1, 16($sp)
    sw      $s0, 12($sp)
    sw      $t0, 8($sp)
    sw      $t1, 4($sp)
    sw      $t2, 0($sp)

    la      $s0, grades          # Grades array (sorted)
    la      $s1, weights         # Weights array
    lw      $s2, gradeCount      # Number of grades
    li      $s3, 0               # Sum of weighted grades
    li      $s4, 0               # Sum of weights
    move    $t0, $zero           # Counter

weightCalcLoop:
    blt     $t0, $s2, doWeightCalc
    j       finishWeightedCalc

doWeightCalc:
    lw      $t1, ($s0)           # Load grade
    lw      $t2, ($s1)           # Load weight

    mul     $t3, $t1, $t2        # Weighted grade
    add     $s3, $s3, $t3        # Add to sum of weighted grades
    add     $s4, $s4, $t2        # Add weight to total

    addi    $s0, $s0, 4
    addi    $s1, $s1, 4
    addi    $t0, $t0, 1
    j       weightCalcLoop

finishWeightedCalc:
    # Calculate weighted average = sum of weighted grades / sum of weights
    div     $s3, $s4
    mflo    $t4

    sw      $t4, weightedAverage

    lw      $t2, 0($sp)
    lw      $t1, 4($sp)
    lw      $t0, 8($sp)
    lw      $s0, 12($sp)
    lw      $s1, 16($sp)
    lw      $s2, 20($sp)
    lw      $s3, 24($sp)
    lw      $s4, 28($sp)
    lw      $ra, 32($sp)
    addi    $sp, $sp, 36
    jr      $ra


# Procedure: sortGrades
# Purpose: Sort the grades array using bubble sort for median calculation
sortGrades:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    lw      $t0, gradeCount      # Number of grades
    subi    $t0, $t0, 1          # n-1 iterations
    blez    $t0, sortDone        # If less than 2 grades, no need to sort

outerLoop:
    move    $t1, $zero           # Inner loop counter
    move    $s0, $zero           # Index

innerLoop:
    la      $t2, grades
    sll     $t3, $s0, 2
    add     $t2, $t2, $t3
    lw      $t4, ($t2)           # grades[s0]
    lw      $t5, 4($t2)          # grades[s0+1]

    slt     $t6, $t5, $t4
    beq     $t6, $zero, noSwap

    # Swap grades[s0] and grades[s0+1]
    sw      $t5, ($t2)
    sw      $t4, 4($t2)

noSwap:
    addi    $s0, $s0, 1
    addi    $t1, $t1, 1
    lw      $t7, gradeCount
    subi    $t7, $t7, 1
    blt     $t1, $t7, innerLoop

    subi    $t0, $t0, 1
    bgtz    $t0, outerLoop

sortDone:
    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addi    $sp, $sp, 8
    jr      $ra


# Procedure: calculateMedian
# Purpose: Calculate the median grade
calculateMedian:
    lw      $t0, gradeCount
    rem     $t1, $t0, 2          # Check if count is odd or even
    beq     $t1, $zero, evenMedian

    # Odd number of grades
    li      $t8, 2
    div     $t0, $t8             # Divide $t0 by 2
    mflo    $t2                  # Middle index
    la      $t3, grades
    sll     $t4, $t2, 2
    add     $t3, $t3, $t4
    lw      $t5, ($t3)
    sw      $t5, medianGrade
    jr      $ra

evenMedian:
    # Even number of grades
    li      $t8, 2
    div     $t0, $t8             # Divide $t0 by 2
    mflo    $t2                  # First middle index
    subi    $t2, $t2, 1          # Adjust index for zero-based array
    la      $t3, grades
    sll     $t4, $t2, 2
    add     $t3, $t3, $t4
    lw      $t5, ($t3)           # First middle grade

    # Get second middle grade
    addi    $t3, $t3, 4          # Move pointer to next grade
    lw      $t6, ($t3)           # Second middle grade

    # Now compute average of $t5 and $t6
    add     $t7, $t5, $t6
    li      $t8, 2
    div     $t7, $t8             # Divide sum by 2
    mflo    $t7                  # Median
    sw      $t7, medianGrade
    jr      $ra


# Procedure: convertToLetterGrades
# Purpose: Convert numerical grades to letter grades
convertToLetterGrades:
    la      $s0, grades           # Pointer to grades array (sorted)
    la      $s1, letterGrades     # Pointer to letter grades array
    lw      $s2, gradeCount       # Number of grades
    move    $t0, $zero            # Counter

conversionLoop:
    lw      $t1, ($s0)            # Load numerical grade

    # Determine letter grade
    li      $t2, 90
    bge     $t1, $t2, gradeA
    li      $t2, 80
    bge     $t1, $t2, gradeB
    li      $t2, 70
    bge     $t1, $t2, gradeC
    li      $t2, 60
    bge     $t1, $t2, gradeD
    j       gradeF

gradeA:
    li      $t3, 'A'
    j       storeLetter

gradeB:
    li      $t3, 'B'
    j       storeLetter

gradeC:
    li      $t3, 'C'
    j       storeLetter

gradeD:
    li      $t3, 'D'
    j       storeLetter

gradeF:
    li      $t3, 'F'

storeLetter:
    sb      $t3, ($s1)            # Store letter grade
    addi    $s0, $s0, 4           # Next numerical grade
    addi    $s1, $s1, 1           # Next letter grade
    addi    $t0, $t0, 1
    blt     $t0, $s2, conversionLoop
    jr      $ra


# Procedure: createHistogram
# Purpose: Create histogram data from grades
createHistogram:
    addi    $sp, $sp, -20
    sw      $ra, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)

    # Initialize variables
    la      $s0, grades          # Grades array pointer (sorted)
    la      $s1, histogram       # Histogram array pointer
    move    $s2, $zero           # Counter
    lw      $s3, gradeCount      # Total number of grades

histogramLoop:
    # Load current grade
    lw      $t0, ($s0)

    # Calculate bin number (grade / 10)
    div     $t0, $t0, 10
    mflo    $t0                   # Bin number in $t0

    # Cap bin number at 9 for grade=100
    li      $t1, 9
    ble     $t0, $t1, proceedBin
    move    $t0, $t1

proceedBin:
    # Update bin count
    sll     $t2, $t0, 2           # Multiply bin by 4 for word offset
    add     $t2, $s1, $t2         # Get address of bin
    lw      $t3, ($t2)            # Load current bin count
    addi    $t3, $t3, 1           # Increment count
    sw      $t3, ($t2)            # Store updated count

    # Update loop
    addi    $s0, $s0, 4           # Next grade
    addi    $s2, $s2, 1           # Increment counter
    blt     $s2, $s3, histogramLoop

    # Restore registers and return
    lw      $s0, 0($sp)
    lw      $s1, 4($sp)
    lw      $s2, 8($sp)
    lw      $s3, 12($sp)
    lw      $ra, 16($sp)
    addi    $sp, $sp, 20
    jr      $ra


# Procedure: analyzeTrend
# Purpose: Analyze grade trends and store trend symbols and at-risk flags
analyzeTrend:
    la      $s0, originalGrades   # Pointer to originalGrades array
    la      $s1, trendSymbols     # Pointer to trend symbols array
    lw      $s2, gradeCount
    subi    $s2, $s2, 1           # Number of trends (n-1)
    blez    $s2, trendAnalysisDone

    move    $t0, $zero            # Counter

trendAnalysisLoop:
    lw      $t1, ($s0)            # Current grade from originalGrades
    lw      $t2, 4($s0)           # Next grade from originalGrades

    # Compare grades
    sub     $t3, $t2, $t1

    # Determine trend symbol
    bgtz    $t3, trendUp
    bltz    $t3, trendDown
    li      $t4, '='              # Stable trend
    j       checkAtRisk

trendUp:
    li      $t4, '+'              # Upward trend
    j       checkAtRisk

trendDown:
    li      $t4, '-'              # Downward trend

checkAtRisk:
    sb      $t4, ($s1)            # Store trend symbol

    # At-Risk Condition: Only if grade < 60
    li      $t5, 60
    slt     $t6, $t1, $t5         # $t6 = 1 if $t1 < 60
    li      $t9, 0                # Default at-risk flag

    beq     $t6, $zero, storeAtRiskFlag
    j       setAtRisk

setAtRisk:
    li      $t9, 1                # Set at-risk flag

storeAtRiskFlag:
    sb      $t9, atRiskFlags($t0) # Store at-risk flag at index t0

    # Move to next grade and symbol
    addi    $s0, $s0, 4
    addi    $s1, $s1, 1
    addi    $t0, $t0, 1
    blt     $t0, $s2, trendAnalysisLoop

trendAnalysisDone:
    # Set atRiskFlag for the last grade (n-1)
    lw      $t0, gradeCount      # t0 = n
    subi    $t0, $t0, 1          # t0 = n-1

    # Load grade[n-1] from originalGrades
    la      $s0, originalGrades
    sll     $t1, $t0, 2          # offset = t0*4
    add     $s0, $s0, $t1        # address of originalGrades[t0]
    lw      $t2, ($s0)           # grade[n-1]

    # Check if grade[n-1] <60
    li      $t3, 60
    slt     $t4, $t2, $t3        # t4=1 if grade[n-1]<60
    sb      $t4, atRiskFlags($t0) # set atRiskFlags[n-1]

    jr      $ra


# Procedure: predictiveAnalysis
# Purpose: Predict next grade based on trend and calculate confidence level
predictiveAnalysis:
    addi    $sp, $sp, -24
    sw      $ra, 20($sp)
    sw      $s4, 16($sp)
    sw      $s3, 12($sp)
    sw      $s2, 8($sp)
    sw      $s1, 4($sp)
    sw      $s0, 0($sp)

    # Initialize variables
    la      $s0, grades          # Grades array (sorted)
    la      $s1, trendData       # Trend data array
    move    $s2, $zero           # Counter
    lw      $s3, gradeCount      # Number of grades
    move    $s4, $zero           # Sum of differences

    # Need at least 2 grades for trend analysis
    li      $t0, 2
    blt     $s3, $t0, insufficientData

    # Calculate grade-to-grade differences
calculateTrends:
    lw      $t1, ($s0)           # Current grade
    lw      $t2, 4($s0)          # Next grade
    sub     $t3, $t2, $t1        # Calculate difference

    # Store trend data
    sw      $t3, ($s1)
    add     $s4, $s4, $t3        # Add to sum of differences

    # Update pointers and counter
    addi    $s0, $s0, 4
    addi    $s1, $s1, 4
    addi    $s2, $s2, 1
    subi    $t4, $s3, 1
    blt     $s2, $t4, calculateTrends

    # Calculate average trend
    move    $t5, $s2             # Number of differences
    div     $s4, $t5
    mflo    $s4                  # Average difference

    # Determine overall trend
    blez    $s4, checkDownward    # if s4 <= 0 jump to checkDownward
    # Upward trend
    li      $t6, 1
    j       storeTrendFlag

checkDownward:
    bgez    $s4, checkStable
    # s4 < 0 => Downward
    li      $t6, -1
    j       storeTrendFlag

checkStable:
    # s4 = 0 => Stable
    li      $t6, 0

storeTrendFlag:
    sw      $t6, trendFlag

    # Predict next grade
    la      $t0, grades
    lw      $t1, gradeCount
    subi    $t1, $t1, 1          # Index of last grade
    sll     $t2, $t1, 2          # Offset for last grade
    add     $t0, $t0, $t2
    lw      $t3, ($t0)           # Load last grade

    # Predicted grade = last grade + average trend
    add     $t4, $t3, $s4

    # Cap predicted grade between 0 and 100
    blt     $t4, $zero, setToZero
    bgt     $t4, 100, setToHundred
    j       storePredictedGrade

setToZero:
    li      $t4, 0
    j       storePredictedGrade

setToHundred:
    li      $t4, 100

storePredictedGrade:
    sw      $t4, predictedGrade

    # Calculate confidence level
    jal     calculateConfidence

    # Restore registers and return
    lw      $s0, 0($sp)
    lw      $s1, 4($sp)
    lw      $s2, 8($sp)
    lw      $s3, 12($sp)
    lw      $s4, 16($sp)
    lw      $ra, 20($sp)
    addi    $sp, $sp, 24
    jr      $ra

insufficientData:
    # Not enough data to predict
    li      $t4, -1              # Indicate insufficient data
    sw      $t4, predictedGrade
    li      $t5, 0
    sw      $t5, confidenceLevel

    # Store trend flag as 0 (stable) when insufficient data
    li      $t6, 0
    sw      $t6, trendFlag

    # Restore registers and return
    lw      $s0, 0($sp)
    lw      $s1, 4($sp)
    lw      $s2, 8($sp)
    lw      $s3, 12($sp)
    lw      $s4, 16($sp)
    lw      $ra, 20($sp)
    addi    $sp, $sp, 24
    jr      $ra


# Procedure: calculateConfidence
# Purpose: Calculate the confidence level of the prediction
calculateConfidence:
    # Analyze variance in trends
    la      $t0, trendData
    move    $t1, $zero           # Variance sum
    move    $t2, $zero           # Counter
    lw      $t5, gradeCount
    subi    $t5, $t5, 1          # Number of trend data points

    # Handle division by zero if only one trend data point
    blez    $t5, setMaxConfidence

varianceLoop:
    lw      $t3, ($t0)           # Load trend value
    sub     $t4, $t3, $s4        # Subtract mean
    mul     $t4, $t4, $t4        # Square difference
    add     $t1, $t1, $t4        # Add to variance sum

    addi    $t0, $t0, 4
    addi    $t2, $t2, 1
    blt     $t2, $t5, varianceLoop

    # Calculate variance
    div     $t1, $t5
    mflo    $t6                   # Variance

    # Calculate confidence level
    li      $t7, 100
    sub     $t7, $t7, $t6         # Higher variance = lower confidence

    # Ensure confidence is between 0 and 100
    blez    $t7, zeroConfidence
    li      $t8, 100
    bgt     $t7, $t8, maxConfidence
    j       storeConfidence

setMaxConfidence:
    li      $t7, 100
    j       storeConfidence

zeroConfidence:
    li      $t7, 0
    j       storeConfidence

maxConfidence:
    li      $t7, 100

storeConfidence:
    sw      $t7, confidenceLevel
    jr      $ra


# Procedure: displayDashboard
# Purpose: Display all calculated analytics
displayDashboard:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

# Display Original Grades
li      $v0, 4
la      $a0, originalGradesMsg
syscall

la      $s0, originalGrades   # Pointer to originalGrades array
lw      $s1, gradeCount       # Number of grades
move    $t0, $zero            # Counter

displayOriginalGradesLoop:
    beq     $t0, $s1, endOriginalGrades
    lw      $t1, ($s0)
    li      $v0, 1
    move    $a0, $t1
    syscall

    # Print space after each grade
    li      $v0, 4
    la      $a0, space
    syscall

    addi    $s0, $s0, 4
    addi    $t0, $t0, 1
    j       displayOriginalGradesLoop

endOriginalGrades:
    # Print newline after all grades
    #li      $v0, 4
    #la      $a0, newline
    #syscall

    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Class Average
    li      $v0, 4
    la      $a0, classAvgMsg
    syscall

    li      $v0, 1
    lw      $a0, classAverage
    syscall

    # Display Weighted Average
    li      $v0, 4
    la      $a0, weightedAvgMsg
    syscall

    li      $v0, 1
    lw      $a0, weightedAverage
    syscall

    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Highest Grade
    li      $v0, 4
    la      $a0, highestGradeMsg
    syscall

    li      $v0, 1
    lw      $a0, highestGrade
    syscall

    # Display Lowest Grade
    li      $v0, 4
    la      $a0, lowestGradeMsg
    syscall

    li      $v0, 1
    lw      $a0, lowestGrade
    syscall

    # Display Median Grade
    li      $v0, 4
    la      $a0, medianGradeMsg
    syscall

    li      $v0, 1
    lw      $a0, medianGrade
    syscall

    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Pass Rate
    li      $v0, 4
    la      $a0, passRateMsg
    syscall

    lw      $t0, passCount
    lw      $t1, gradeCount
    mul     $t0, $t0, 100
    div     $t0, $t1
    mflo    $t2

    li      $v0, 1
    move    $a0, $t2
    syscall

    li      $v0, 4
    la      $a0, percentSymbol
    syscall

    # Display Fail Rate
    li      $v0, 4
    la      $a0, failRateMsg
    syscall

    lw      $t0, failCount
    lw      $t1, gradeCount
    mul     $t0, $t0, 100
    div     $t0, $t1
    mflo    $t2

    li      $v0, 1
    move    $a0, $t2
    syscall

    li      $v0, 4
    la      $a0, percentSymbol
    syscall

    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Histogram
    jal     displayHistogram

    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Grades and Letter Grades (Sorted)
    li      $v0, 4
    la      $a0, newline          # Print a newline for formatting
    syscall

    li      $v0, 4
    la      $a0, gradesAndLettersMsg
    syscall

    la      $s0, grades           # Pointer to grades array (sorted)
    la      $s1, letterGrades     # Pointer to letter grades array
    lw      $s2, gradeCount       # Number of grades
    move    $t0, $zero            # Counter

displayGradesLoop:
    beq     $t0, $s2, endGradesDisplay
    # Display numerical grade
    lw      $t1, ($s0)
    li      $v0, 1
    move    $a0, $t1
    syscall

    # Display corresponding letter grade
    li      $v0, 4
    la      $a0, dashSpace
    syscall

    li      $v0, 11               # Print character syscall
    lb      $a0, ($s1)
    syscall

    # Print newline
    li      $v0, 4
    la      $a0, newline
    syscall

    # Move to next grade and letter grade
    addi    $s0, $s0, 4
    addi    $s1, $s1, 1
    addi    $t0, $t0, 1
    j       displayGradesLoop

endGradesDisplay:
    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display At-Risk Students (Based on Original Grades)
    li      $v0, 4
    la      $a0, atRiskStudentsMsg
    syscall

    la      $s0, originalGrades   # Pointer to originalGrades array
    lw      $s2, gradeCount
    move    $t0, $zero            # Counter
    li      $t1, 0                # Flag to check if any at-risk students were printed

displayAtRiskLoop:
    beq     $t0, $s2, endAtRiskLoop  # End loop if all students checked
    lb      $t2, atRiskFlags($t0)
    beq     $t2, $zero, skipAtRiskDisplay

    # Display student number and grade
    li      $v0, 4
    la      $a0, studentMsg
    syscall

    li      $v0, 1
    addi    $a0, $t0, 1           # Student number (1-based index)
    syscall

    li      $v0, 4
    la      $a0, colonGradeMsg
    syscall

    lw      $a0, ($s0)
    li      $v0, 1
    syscall

    # Print newline
    li      $v0, 4
    la      $a0, newline
    syscall

    li      $t1, 1                # At least one at-risk student found

skipAtRiskDisplay:
    addi    $s0, $s0, 4           # Move to next grade
    addi    $t0, $t0, 1
    j       displayAtRiskLoop

endAtRiskLoop:
    # After checking all students, determine if we print "None"
    beq     $t1, $zero, noAtRiskStudents
    j       endAtRiskDisplay

noAtRiskStudents:
    li      $v0, 4
    la      $a0, noneMsg
    syscall

endAtRiskDisplay:
    # Print Separator
    li      $v0, 4
    la      $a0, separator
    syscall

    # Display Grade Trends
    li      $v0, 4
    la      $a0, gradeTrendsMsg
    syscall

    # number_of_differences = gradeCount - 1
    lw      $t0, gradeCount
    subi    $t0, $t0, 1          # t0 now holds the number of differences
    blez    $t0, skipTrendSymbolPrint

    la      $s0, trendData       # s0 points to the first difference
    move    $t1, $zero           # t1 is loop counter

printTrendSymbolsLoop:
    beq     $t1, $t0, endTrendSymbols
    lw      $t2, ($s0)           # Load the current difference
    bgtz    $t2, printUp
    bltz    $t2, printDown
    j       printStable

printUp:
    li      $v0, 4
    la      $a0, upMsg           # upMsg: .asciiz "up "
    syscall
    j       continueLoop

printDown:
    li      $v0, 4
    la      $a0, downMsg         # downMsg: .asciiz "down "
    syscall
    j       continueLoop

printStable:
    li      $v0, 4
    la      $a0, stableMsg       # stableMsg: .asciiz "stable "
    syscall

continueLoop:
    addi    $s0, $s0, 4
    addi    $t1, $t1, 1
    j       printTrendSymbolsLoop

endTrendSymbols:
    # Print newline after trend symbols
    li      $v0, 4
    la      $a0, newline
    syscall

skipTrendSymbolPrint:

    # Now print the overall trend
    lw      $t0, trendFlag        # Load trend flag
    li      $t1, 1
    beq     $t0, $t1, displayUpwardTrend

    li      $t1, -1
    beq     $t0, $t1, displayDownwardTrend

    li      $t1, 0
    beq     $t0, $t1, displayStableTrend

    # Default case (should not occur)
    #j       endDisplayTrends

displayUpwardTrend:
    li      $v0, 4
    la      $a0, trend_up
    syscall
    j       displayAtRiskStudents

displayDownwardTrend:
    li      $v0, 4
    la      $a0, trend_down
    syscall
    j       displayAtRiskStudents

displayStableTrend:
    li      $v0, 4
    la      $a0, trend_stable
    syscall

displayAtRiskStudents:
    # Already printed "At-Risk Students" before "Grade Trends"
    # So this label can be adjusted or removed if unnecessary
    # If you need to perform additional actions, include them here

    # Display Prediction
    lw      $t0, predictedGrade
    bge     $t0, $zero, showPrediction
    j       noPrediction

showPrediction:
    li      $v0, 4
    la      $a0, prediction_msg
    syscall

    li      $v0, 1
    lw      $a0, predictedGrade
    syscall

    li      $v0, 4
    la      $a0, confidence_msg
    syscall

    li      $v0, 1
    lw      $a0, confidenceLevel
    syscall

    li      $v0, 4
    la      $a0, percentSymbol
    syscall
    
    # Print newline
    li      $v0, 4
    la      $a0, newline
    syscall
    
    j       endDisplay

noPrediction:
    li      $v0, 4
    la      $a0, notEnoughDataMsg
    syscall

endDisplay:
    # Restore registers and return
    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addi    $sp, $sp, 8
    jr      $ra


# Procedure: displayHistogram
# Purpose: Display the grade distribution histogram
displayHistogram:
    # Print histogram title
    li      $v0, 4
    la      $a0, histogramTitle
    syscall

    # Initialize bin counter
    li      $s0, 0              # Current bin

displayBinLoop:
    beq     $s0, 10, endHistogram   # Exit loop after 10 bins

    # Print bin range
    mul     $t0, $s0, 10        # Lower bound
    li      $t1, 9              # Default upper bound offset

    # Check if it's the last bin (90-100)
    li      $t2, 9
    beq     $s0, $t2, adjustLastBin
    addi    $t1, $t0, 9         # Upper bound for regular bins
    j       printBin

adjustLastBin:
    li      $t1, 100            # Set upper bound to 100 for the last bin

printBin:
    # Print formatted bin label: "X-Y: "
    li      $v0, 1
    move    $a0, $t0
    syscall

    li      $v0, 4
    la      $a0, gradeRange
    syscall

    li      $v0, 1
    move    $a0, $t1
    syscall

    li      $v0, 4
    la      $a0, barLabel
    syscall

    # Get and print bin stars
    la      $t2, histogram
    sll     $t3, $s0, 2        # Bin offset (word size)
    add     $t2, $t2, $t3      # Bin address
    lw      $t4, ($t2)         # Load bin count

starLoop:
    blez    $t4, endStars
    li      $v0, 4
    la      $a0, graphChar
    syscall
    addi    $t4, $t4, -1
    j       starLoop

endStars:
    # Print newline
    li      $v0, 4
    la      $a0, newline
    syscall

    # Next bin
    addi    $s0, $s0, 1
    j       displayBinLoop

endHistogram:
    jr      $ra


# Procedure: exitProgram
# Purpose: Exit the program gracefully
exitProgram:
    li      $v0, 10
    syscall
