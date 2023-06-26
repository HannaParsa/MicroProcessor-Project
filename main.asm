STACK SEGMENT PARA STACK
    DB 64 DUP (' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
    
    TIME_AUX DB 0 ; to check if time has changed(used to update the screen)
    TIME_AUX_BALL DB 0 ; to check if time has changed(used to calculate ball speed)

    BALL_X DW 10h ; x position of the ball
    BALL_Y DW 10h ; y position of the ball
    BALL_SIZE DW 06H ; size of the ball
    
    BALL_V_X DW 05h ; v of ball in x dir
    BALL_V_Y DW 05h ; v of ball in y dir
    
    WINDOW_W DW 140h ; width of window:320px
    WINDOW_H DW 0C8h ; height of window:200px
    WINDOW_BOUND DW 10  ; to check collisions
    
    PADDLE_W DW 05h ; paddle width
    PADDLE_H DW 3Fh ; paddle height
    
    PADDLE_X DW 10h ; x val of the paddle
    PADDLE_Y DW 0A9h; y val of the paddle

    

    NEXT_PADDLE_X DW 0 ; holds position for the next paddle appearence x
    NEXT_PADDLE_Y DW 0 ; holds position for the next paddle appearence y
    
    COLLIDED DW 0 ; collided ? 0 : 1


    INCREASING_FLAG DB 0 ; is BALL_V_Y increasing?
    COUNT DB 0 ; auxilary variable to increase the speed

    POINTS DW 0 ; keep track of players point
    POINTS_TXT DW '0','$' ; a string to show as player point

    GAME_ACTIVE DB 1 ; game active ? 1:0

    GAME_OVER_TITLE DB 'GAME OVER','$' ; game over text
    YOUR_SCORE_TITLE DB 'YOUR SCORE:','$' ; your score banner

    RAND_NUM DW 0 ; holds the random number
    MAX DW 0 ; the max range for rand number
    MIN DW 0 ; the min range for rand numbers

    MINE_SIZE DW 04h ; mine size
    MINE_X DW 33h ; mine x
    MINE_Y DW 66h ; mine y
    MINE_EXP DB 0 ; has the current mine exploded

DATA ENDS

CODE SEGMENT PARA 'CODE'
    
    ; the main proc  
      
    MAIN PROC FAR
        
    ; preparing segments to use in main proc
       
    ASSUME CS:CODE,DS:DATA,SS:STACK ; define segments for main
    PUSH DS ; push to stack the DS segment
    SUB AX,AX ; clear the ax reg
    PUSH AX ; push ax to stack
    MOV AX, DATA ; move the content of data to ax
    MOV DS, AX ; save to ds the content of ax
    POP AX ; pop the first element from stack and save it to ax
    POP AX ; pop the first element from stack and save it to ax
          
        ; setting the graphical mode
           
        CALL CLEARSCREEN
        
        
        ; a routine to check the time
        
        CHECK_TIME:
            CMP GAME_ACTIVE, 0 ; if game is not active: game over
            JE SHOW_GAME_OVER
            MOV AH, 2Ch ; setting the functionality of int21h to sys time
            INT 21h     ; calling the interrupt
            CMP DL, TIME_AUX ; is the current time equal to the previous one. also note that dl now contains 1/100 seconds of sys time
            
            JE CHECK_TIME
            
            MOV TIME_AUX, DL ; update TIME_AUX to keep the previous time
            

            
            
            CALL CLEARSCREEN
            
            CALL VELOCITY_ACCELERATOR

            CALL MOVEBALL
            
            CALL COL_MINE

            CALL DRAW_MINE

            CALL DRAWBALL
            
            CALL DRAWPADDLE

            CALL DRAW_POINT
               
            JMP CHECK_TIME ; do it again

            SHOW_GAME_OVER:
                CALL GAME_OVER_MENU
                ; JMP CHECK_TIME

        RET
    MAIN ENDP

    COL_MINE PROC NEAR
        MOV AX, BALL_X
        ADD AX, BALL_SIZE ;MAXX1
        CMP AX, MINE_X       ;MINX2
        JNG NO_COL_MINE   ;IF THERE'S NO COLLISION, RETURN
      
        MOV AX, MINE_X
        ADD AX, MINE_SIZE      ;MAXX2
        CMP BALL_X, AX ;MINX1
        JNL NO_COL_MINE   ;IF THERE'S NO COLLISION, RETURN
      
        MOV AX, BALL_Y
        ADD AX, BALL_SIZE             ;MAXY1
        CMP AX, MINE_Y        ;MINY2
        JNG NO_COL_MINE   ;IF THERE'S NO COLLISION, RETURN
      
        MOV AX, MINE_Y
        ADD AX, MINE_SIZE      ;MAXY2
        CMP BALL_Y, AX ;MINY1
        JNL NO_COL_MINE   ;IF THERE'S NO COLLISION, RETURN
      
      
       ;IF IT REACHES HERE, THERE'S A COLLISION WITH THE BAR AS AN ENEMY
        MOV GAME_ACTIVE, 0
        NO_COL_MINE:
            RET
       RET
    COL_MINE ENDP

    DRAW_MINE PROC NEAR
        MOV CX, MINE_X ; set the initial x
        MOV DX, MINE_Y ; set the initial y        
        
        DRAW_M:
        
            MOV AH, 0Ch ; setting the functionality of int10h to
            MOV AL, 4h ; choose the color of pixel
            MOV BH, 00h ; set page number
            INT 10h ; calling the interrupt
            
            INC CX ; loop variable
            MOV AX, CX ; cx - ball_X > ball_size ? next line : iter
            SUB AX, MINE_X
            CMP AX, MINE_SIZE
            JNG DRAW_M
            
            MOV CX, MINE_X ; the cx goes to initial col
            INC DX ; go to next line
            
            MOV AX, DX ; dx - ball_y > ball_size ? exit : iter
            SUB AX, MINE_Y
            CMP AX, MINE_SIZE
            JNG DRAW_M    

        
        RET
    DRAW_MINE ENDP

    ; a proc to draw the point of the player

    DRAW_POINT PROC NEAR
        MOV AH, 02h ; set cursor position
        MOV BH, 00h ; set page number
        MOV DH, 01h ; row num
        MOV DL, 01h ; col num
        INT 10h

        MOV AH, 09h ; write string to std output
        LEA DX, POINTS_TXT ; give dx a pointer to string result
        INT 21h
        RET
    DRAW_POINT ENDP   

    ; a proc to draw the bell
    DRAWBALL PROC NEAR


        MOV CX, BALL_X ; set the initial x
        MOV DX, BALL_Y ; set the initial y        
        
        DRAW:
        
            MOV AH, 0Ch ; setting the functionality of int10h to
            MOV AL, 0Fh ; choose the color of pixel
            MOV BH, 00h ; set page number
            INT 10h ; calling the interrupt
            
            INC CX ; loop variable
            MOV AX, CX ; cx - ball_X > ball_size ? next line : iter
            SUB AX, BALL_X
            CMP AX, BALL_SIZE
            JNG DRAW
            
            MOV CX, BALL_X ; the cx goes to initial col
            INC DX ; go to next line
            
            MOV AX, DX ; dx - ball_y > ball_size ? exit : iter
            SUB AX, BALL_Y
            CMP AX, BALL_SIZE
            JNG DRAW
                
        RET             
    DRAWBALL ENDP
    
    ; a proc to clear the screen and initialize it
    
    CLEARSCREEN PROC NEAR
        
        MOV AH, 00h ; setting the functionality of int10h to video mode
        MOV AL, 13h ; setting the graphical mode to video, 320*320 256 color
        INT 10h ; calling the interrupt
        
        ; set the background color
        
        MOV AH, 0Bh ; setting the functionality of int10h to
        MOV BH, 00h ; set the background color
        MOV BL, 01h ; choosing the background color
        INT 10h     ; calling the interrupt        
        
        RET
    CLEARSCREEN ENDP
    
    ; a proc to move the ball
    
    MOVEBALL PROC NEAR
        
        
        
        ; check if any key is pressed, else, normal speed of ball
        
        ; check which key is pressesd
        
        
        ; d for right: 64H
        
        ; a for left: 61H
        
        
        MOV AH, 01h ; check if any key is pressed
        INT 16h
        
        JZ COL ; if not, do the proper action
        
        MOV AH, 00h ; if so, check which key is pressed
        INT 16h
        
        
        
        CMP AL,61h ; if 'a' key is pressed, go left
        JE MOVE_BALL_LEFT

        CMP AL,64h
        JE MOVE_BALL_RIGHT ; if 'd' key is pressed, go right                
        
        JMP COL
        
        RET
        
        ; negate the speed of x
        NEG_VEL_X:
            NEG BALL_V_X
            RET

        ; move ball in +x dir
            
        MOVE_BALL_RIGHT:
            MOV AX, BALL_V_X ; move the ball in x dir
            ADD BALL_X, AX
            JMP COL
            RET   
            
        
        ; move ball in -x dir
                    
        MOVE_BALL_LEFT:
            MOV AX, BALL_V_X ; move the ball in -x dir
            NEG AX
            ADD BALL_X, AX
            JMP COL
            RET
        
        
        ; if reached top of the screen start from bottom




        ; checks if collision has happened between ball and paddle
        
        COL:              
            ; checks : ball_y + ball_size >= paddle_y
            
            MOV AX, BALL_Y
            MOV CX, BALL_SIZE
            ADD AX, CX
            MOV DX, PADDLE_Y
            CMP AX, DX
            JL MOVE_BALL_VERTICALLY
            
            ; checks : paddle_x <= ball_x
            
            MOV AX, PADDLE_X
            MOV DX, BALL_X
            CMP AX, DX
            JG MOVE_BALL_VERTICALLY
            
            ; checks : paddle_x + paddle_w >= ball_x + ball_size
            
            MOV AX, PADDLE_X
            MOV DX, BALL_X
            ADD AX, PADDLE_H
            ADD DX, BALL_SIZE
            CMP AX, DX
            JL MOVE_BALL_VERTICALLY
            
            CMP BALL_V_Y, 0
            JL MOVE_BALL_VERTICALLY


            ; if reaches here, collision has happened. so we negate the ball velocity
            
            NEG BALL_V_Y

            CALL INC_POINT

            MOV CX, BALL_X
            MOV MIN, CX
            MOV MAX, 320
            CALL GENERATE_RAND
            MOV AX, RAND_NUM

            MOV CX, PADDLE_Y
            SUB CX, WINDOW_BOUND
            MOV MIN, CX
            MOV MAX, 200
            CALL GENERATE_RAND
            MOV BX, RAND_NUM

            MOV PADDLE_X, AX
            MOV PADDLE_Y, BX

            MOV INCREASING_FLAG, 1
            MOV COLLIDED, 1

            JMP MOVE_BALL_VERTICALLY
            RET
         
         ; moves ball in y dir
         
         MOVE_BALL_VERTICALLY:    
            MOV AX, BALL_V_Y ; move the ball in y dir
            ADD BALL_Y, AX
        
            MOV AX, WINDOW_BOUND
            CMP BALL_Y, AX ; if we reach the top of screen, then we'll start from the exact x but with max y
            JL NEG_VEL_Y
            
            ; if collided, we dont check for game over, else we do
            CMP COLLIDED, 0
            JE CHECK_GAME_OVER
            MOV COLLIDED, 0
            RET
        
        ; checks if the ball has reached the ground
        
        CHECK_GAME_OVER:
            MOV AX, WINDOW_H
            SUB AX, WINDOW_BOUND 
            SUB AX, BALL_SIZE
            CMP BALL_Y, AX
            JL DUMMY
            CMP BALL_V_Y, 0
            JG GAMEOVER
            RET
            
       ; if raeches here, game over
            
       GAMEOVER:
            MOV GAME_ACTIVE, 0
            RET

        NEG_VEL_Y:
            MOV AX, 0C8h
            MOV BALL_Y, AX
            RET

        DUMMY:
            RET                                                   
                
    MOVEBALL ENDP
    
    ; a proc to draw the paddles

    DRAWPADDLE PROC NEAR
        MOV CX, PADDLE_X ; set the initial x
        MOV DX, PADDLE_Y ; set the initial y
        
        DRAW_P:
            MOV AH, 0Ch ; setting the functionality of int10h to
            MOV AL, 0Fh ; choose the color of pixel
            MOV BH, 00h ; set page number
            INT 10h ; calling the interrupt
            
            INC CX ; loop variable
            MOV AX, CX ; cx - paddle_X > paddle_h ? next line : iter
            SUB AX, PADDLE_X
            CMP AX, PADDLE_H
            JNG DRAW_P
            
            MOV CX, PADDLE_X ; the cx goes to initial col
            INC DX ; go to next line
            
            MOV AX, DX ; dx - paddle_y > paddle_w ? exit : iter
            SUB AX, PADDLE_Y
            CMP AX, PADDLE_W
            JNG DRAW_P                
        RET
    DRAWPADDLE ENDP

   ; a proc to handle v after collisions. ball_v_y starts from -5 and ends in 5 in 0.5 seconds

    VELOCITY_ACCELERATOR PROC NEAR
        IS_INCREASING:
            CMP INCREASING_FLAG, 1
            JNE NO_INC
            JMP INCREASE
        INCREASE:
            CMP BALL_V_Y, 5
            JGE NO_INC
            CMP COUNT, 5
            JL INC_COUNT
            INC BALL_V_Y
            MOV COUNT, 0
            JMP END_INC
        NO_INC:
            MOV INCREASING_FLAG, 0
            RET    
        END_INC:
            RET
        INC_COUNT:
            INC COUNT 
            RET       
    VELOCITY_ACCELERATOR ENDP

    ; a proc to increase the point and show it to user

    INC_POINT PROC NEAR
        INC POINTS
        SUB AX, AX ; clear reg
        MOV AX, POINTS
        ; we should convert number to string
        ADD AX, 30h
        MOV [POINTS_TXT], AX
        
        RET
    INC_POINT ENDP
    

    ; a proc to draw the game over screen

    GAME_OVER_MENU PROC NEAR
        CALL CLEARSCREEN
        MOV AH, 02h ; set cursor position
        MOV BH, 00h ; set page number
        MOV DH, 00h ; row num
        MOV DL, 01h ; col num
        INT 10h

        MOV AH, 09h ; write string to std output
        LEA DX, GAME_OVER_TITLE ; give dx a pointer to string result
        INT 21h

        MOV AH, 02h ; set cursor position
        MOV BH, 00h ; set page number
        MOV DH, 01h ; row num
        MOV DL, 01h ; col num
        INT 10h

        MOV AH, 09h ; write string to std output
        LEA DX, YOUR_SCORE_TITLE ; give dx a pointer to string result
        INT 21h


        MOV AH, 02h ; set cursor position
        MOV BH, 00h ; set page number
        MOV DH, 01h ; row num
        MOV DL, 0Dh ; col num 10a 11b 12c 13d
        INT 10h

        MOV AH, 09h ; write string to std output
        LEA DX, POINTS_TXT ; give dx a pointer to string result
        INT 21h

        RET
    GAME_OVER_MENU ENDP    
    
    GENERATE_RAND PROC NEAR
        ; Initialize random seed with system time
        MOV AH, 2CH ; Get system time (hours, minutes, seconds)
        INT 21H ; AH=hours, CH=minutes, CL=seconds
        MOV AX, DX; AX=minutes*60+seconds
        XOR AH, AH ; Clear high byte of AX
        MOV CX, AX ; CX=random seed

        ; Generate random number in range (MIN, MAX)
        MOV BX, MAX ; Load MAX into BX
        SUB BX, MIN ; Subtract 10 from MAX to get range size
        ROL CX, 1 ; Rotate left the random seed
        MUL BX ; Multiply CX by range size
        DIV MAX ; Divide DX:AX by MAX to get remainder in AX
        ADD AX, MIN ; Add 10 to the remainder to get the random number
        MOV RAND_NUM, AX
        RET
    GENERATE_RAND ENDP
    
CODE ENDS

END