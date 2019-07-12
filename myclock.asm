
DATA SEGMENT
    MENU DB '1. system time', 0AH
        DB '2. set time', 0AH
        DB '3. timer', 0AH
        DB '4. exit', 0AH, '$'
DATA ENDS

STACK SEGMENT
    DB 128 DUP(?)
STACK ENDS

CODE SEGMENT
	ASSUME CS:CODE, SS:STACK, DS:DATA
START:
    call clear_screen
clock:
    ; 显示菜单
    mov ax,DATA
    mov ds,ax
    lea dx, MENU
    mov AH,09H
    int 21H  
select:; 菜单项选择
    mov ah, 08H
    int 21H
    cmp al, '1'
    jz operation_one
    cmp al, '2'
    jz operation_two
    cmp al, '3'
    jz operation_three
    cmp al, '4'
    jz THE_END
    jmp select

operation_one:
    call clear_screen
    op_one_loop:
        call cursor_reset
        call get_system_time
        call print_time
        call one_second
        mov ah, 01H
        int 16H   ; 对缓冲区进行检查，空则ZF=1，不空则ZF=0
        jz op_one_loop
        mov ah, 00H
        int 16H
        cmp al, 1BH
        jz START

operation_two:
    call clear_screen
    call cursor_reset
    call input_time
    op_two_loop:
        call clear_screen
        call cursor_reset
        call print_time
        call one_second
        call add_one_second
        mov ah, 01H
        int 16H   ; 对缓冲区进行检查，空则ZF=1，不空则ZF=0
        jz op_two_loop
        mov ah, 00H
        int 16H
        cmp al, 1BH
        jz START

operation_three:
    call clear_screen
    call cursor_reset
    call input_time
    mov di, 0
    op_three_loop:
        call clear_screen
        call cursor_reset
        call print_time
        call one_second
        call sub_one_second
        cmp di, 1
        jz THE_END
        mov ah, 01H
        int 16H   ; 对缓冲区进行检查，空则ZF=1，不空则ZF=0
        jz op_three_loop
        mov ah, 00H
        int 16H
        cmp al, 1BH
        jz START

check_esc:
    mov ah, 01H
    int 16H   ; 对缓冲区进行检查，空则ZF=1，不空则ZF=0
    jz check_end
    mov ah, 00H
    int 16H
    cmp al, 1BH
    jz THE_END
    check_end: 
        ret
    

get_system_time:
    mov ah,2CH    ; To get System Time
    int 21H
    ; INT 21H (ah=2CH)功能
    ; Hour in CH
    ; Minutes is in CL
    ; Seconds is in DH
    ret


print_time:
    push ax
    push bx
    push dx
    mov al,ch     ; Hour is in CH
    aam           ; 把AL转为十进制ah放十位，AL放个位?
    mov bx,ax
    call DISP
    mov dl,':'
    mov ah,02H    ; To Print : in DOS
    int 21H
    mov al,cl     ; Minutes is in CL
    aam
    mov bx,ax
    call DISP
    mov dl,':'    ; To Print : in DOS
    mov ah,02H
    int 21H
    mov al,dh     ; Seconds is in DH
    aam
    mov bx,ax
    call DISP
    pop dx
    pop bx
    pop ax
    ret
    
; 等待一秒
one_second:
    ; set 1 million microseconds interval (1 second)
    push ax
    push cx
    push dx
    mov     cx, 0fh
    mov     dx, 4240h
    mov     ah, 86h
    int     15h
    pop dx
    pop cx
    pop ax
    ret

THE_END:
    mov ax, 4C00H
    int 21H

cursor_reset:
    push ax
    push bx
    push dx
    mov bh, 0 ; 页
    mov dh, 0 ; 行
    mov dl, 0 ; 列
    mov ah, 2
    int 10H
    pop dx
    pop bx
    pop ax
    ret

clear_screen:
    push ax
    mov ah,15
    int 10h
    mov ah,0
    int 10h
    pop ax
    ret

input_time:
    ; 时间 AB:CD:EF
    ; A的范围是0~2
    ; C、E的范围是0~5
    ; B、D、F的范围是0~9
    ; 当A为2的时候，B的范围是0~3
    ; 时
    call check_NUM
    mov bh, al
    mov dl, al
    mov ah, 02H
    int 21H
    call check_NUM
    mov bl, al
    mov dl, al
    mov ah, 02H
    int 21H
    mov dl, ':'
    mov ah, 02H
    int 21H
    sub bl, 30H
    sub bh, 30H
    mov al, 0AH
    mul bh
    add bl, al
    mov ch, bl 
    ; 分
    call check_NUM
    mov bh, al
    mov dl, al
    mov ah, 02H
    int 21H
    call check_NUM
    mov bl, al
    mov dl, al
    mov ah, 02H
    int 21H
    mov dl, ':'
    mov ah, 02H
    int 21H
    sub bl, 30H
    sub bh, 30H
    mov al, 0AH
    mul bh
    add bl, al
    mov cl, bl
    ; 秒
    call check_NUM
    mov bh, al
    mov dl, al
    mov ah, 02H
    int 21H
    call check_NUM
    mov bl, al
    mov dl, al
    mov ah, 02H
    int 21H
    sub bl, 30H
    sub bh, 30H
    mov al, 0AH
    mul bh
    add bl, al
    mov dh, bl
    ret

check_NUM:
    mov ah, 08H
    int 21H
    cmp al, 30H
    jl check_NUM
    cmp al, 39H
    jle DONE_NUM
    jmp check_BDF
    DONE_NUM:
        ret

check_A:
    mov ah, 08H
    int 21H
    cmp al, 30H
    jl check_A
    cmp al, 32H
    jle DONE_A
    jmp check_A
    DONE_A:
        ret

check_B:
    pop ax
    push ax
    cmp al, '2'
    jnz CALL_BDF
    mov ah, 08H
    int 21H
    cmp al, 30H
    jl check_B
    cmp al, 33H
    jle DONE_B
    jmp check_B
    DONE_B:
        ret
    CALL_BDF:
        call check_BDF
        ret

check_CE:
    mov ah, 08H
    int 21H
    cmp al, 30H
    jl check_CE
    cmp al, 35H
    jle DONE_CE
    jmp check_CE
    DONE_CE:
        ret

check_BDF:
    mov ah, 08H
    int 21H
    cmp al, 30H
    jl check_BDF
    cmp al, 39H
    jle DONE_BDF
    jmp check_BDF
    DONE_BDF:
        ret

; 时CH 分CL 秒DH
; 加一秒后对CH、CL、DH进行修改
add_one_second:
    inc dh
    cmp dh, 3CH
    jl add_one_second_done
    mov dh, 0
    inc cl
    cmp cl, 3CH
    jl add_one_second_done
    mov cl, 0
    inc ch
    cmp ch, 18H ; 24
    jl add_one_second_done
    mov ch, 0
    add_one_second_done:
        ret

sub_one_second:
    dec dh
    cmp dh, 0
    jge sub_one_second_done
    mov dh, 3BH
    dec cl
    cmp cl, 0
    jge sub_one_second_done
    mov cl, 38H
    dec ch
    cmp ch, 0
    jge sub_one_second_done
    mov di, 1
    sub_one_second_done:
        ret


;Display Part
; 输入BX，BH和BL中是一个十进制数的ASCII码
; 把BH和BL中的数字转为字符后显示
DISP PROC
    push ax
    push dx
    mov dl,BH      ; Since the values are in BX, BH Part
    add dl,30H     ; ASCII Adjustment
    mov ah,02H     ; To Print in DOS
    int 21H
    mov dl,bl      ; BL Part 
    add dl,30H     ; ASCII Adjustment
    mov ah,02H     ; To Print in DOS
    int 21H
    pop dx
    pop ax
    ret
DISP ENDP      ; End Disp Procedure


CODE ENDS
END START
