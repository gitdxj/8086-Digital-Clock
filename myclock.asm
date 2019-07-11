
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
    ret
operation_three:
    ret

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
    mov bh, 0 ; 页
    mov dh, 0 ; 行
    mov dl, 0 ; 列
    mov ah, 2
    int 10H
    ret

clear_screen:
    mov ah,15
    int 10h
    mov ah,0
    int 10h
    ret

input_time:
    ; 时间 AB:CD:EF
    ; A的范围是0~2
    ; C、E的范围是0~5
    ; B、D、F的范围是0~9
    ; 时
    input_hour:
            mov ah, 08H
            int 21H
    input_minite:

    input_second:

check_A:
    

;Display Part
; 输入BX，BH和BL中是一个十进制数
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
