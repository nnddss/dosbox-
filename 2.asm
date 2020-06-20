;示例代码
assume cs:code

stack segment 
    StackA db 128 dup (0)
    StackB db 128 dup (0)
    StackC db 128 dup (0)
    UniStack       db 128 dup (0) ;不能够共用栈
stack ends

data segment
    dw 0, 0 ;保存原来的中断例程地址
    Current db 0;记录当前时谁正在运行,1A,2B,3C

    A_SS_SP dw 0, 0 ;记录上次被切换前ss sp的位置
    B_SS_SP dw 0, 0
    C_SS_SP dw 0, 0
data ends

code segment
start:
        mov ax, stack
        mov ss, ax
        mov sp, offset UniStack
        add sp, 128
        
        call init ;初始化中断例程
        ;初始化3个函数运行情况，也就是将CS:IP指向对应函数位置
        ;以及设置正确的栈，避免共用栈
        call init_state         
    lp:
        jmp lp 
    
;修改对应data段保存中内容，也就是程序运行状态
;主要是将cs:ip指向对应函数，然后设置正确的栈空间
; ax bx cx dx si di es ds bp ip cs psw
; 0  2  4  6  8  10 12 14 16 18 20 22
init_state:
        push ax
        push bx
        push cx
        push bp
        mov bp, sp ;因为下面需要改动sp，所以需要保存sp的值

    initA:
        mov sp, offset StackB
        ; ax bx cx dx si di es ds bp ip cs psw
        ; 0  2  4  6  8  10 12 14 16 18 20 22 24
        ;                                     ↑sp此时指向这里

        mov cx, 5 * 160 + 40 ;预设si的值，作为打印地址
        mov bx, offset A_SS_SP
        mov dx, 0

        pushf
        pop ax
        push ax ;push psw
        push cs ;push cs
        mov ax, offset func
        push ax ;push ip
        push dx ;push bp
        push ds ;push ds
        push es ;push es
        push dx ;push di  计数器di预设为0
        push cx ;push si
        push dx ;push dx
        push dx ;push cx
        push dx ;push bx
        push dx ;push ax
        mov ds:[bx], ss ;记录当前ss:sp的位置
        mov ds:[bx + 2], sp 
    initB:
        mov sp, offset StackC
        ; ax bx cx dx si di es ds bp ip cs psw
        ; 0  2  4  6  8  10 12 14 16 18 20 22 24
        ;                                     ↑sp此时指向这里

        mov cx, 5 * 160 + 80 ;预设si的值，作为打印地址
        mov bx, offset B_SS_SP
        mov dx, 0

        pushf
        pop ax
        push ax ;push psw
        push cs ;push cs
        mov ax, offset func
        push ax ;push ip
        push dx ;push bp
        push ds ;push ds
        push es ;push es
        push dx ;push di  计数器di预设为0
        push cx ;push si
        push dx ;push dx
        push dx ;push cx
        push dx ;push bx
        push dx ;push ax
        mov ds:[bx], ss ;记录当前ss:sp的位置
        mov ds:[bx + 2], sp 
    initC:
        mov sp, offset UniStack
        ; ax bx cx dx si di es ds bp ip cs psw
        ; 0  2  4  6  8  10 12 14 16 18 20 22 24
        ;                                     ↑sp此时指向这里

        mov cx, 5 * 160 + 120 ;预设si的值，作为打印地址
        mov bx, offset C_SS_SP
        mov dx, 0

        pushf
        pop ax
        push ax ;push psw
        push cs ;push cs
        mov ax, offset func
        push ax ;push ip
        push dx ;push bp
        push ds ;push ds
        push es ;push es
        push dx ;push di  计数器di预设为0
        push cx ;push si
        push dx ;push dx
        push dx ;push cx
        push dx ;push bx
        push dx ;push ax
        mov ds:[bx], ss ;记录当前ss:sp的位置
        mov ds:[bx + 2], sp 
    Back:
        mov sp, bp
        pop bp
        pop cx
        pop bx
        pop ax
        ret

func:
        xor di, di ;di是计数器
    _loop:
        call delay

        inc di
        mov ax, di
        call calculate
        call print

        jmp _loop

;还原中断并退出
exit:
        cli
        mov ax, 0
        mov es, ax
        mov ax, data
        mov ds, ax
        
        push ds:[0]
        pop es:[9 * 4]
        push ds:[2]
        pop es:[9 * 4 + 2]
        sti
        mov ax, 4c00h
        int 21h

;delay函数空循环 0x7fffff 次
delay: 
        push ax
        push cx
        mov cx, 7
    s1:
        mov ax, 0ffffh
    s2:
        dec ax
        jnz s2

        dec cx
        jnz s1

        pop cx
        pop ax
        ret

;es:si目标显存地址，十位在ch，个位在cl
print:
        add ch, '0'
        add cl, '0'

        mov byte ptr es:[si], ch
        mov byte ptr es:[si + 1], 21h
        mov byte ptr es:[si + 2], cl
        mov byte ptr es:[si + 3], 21h

        ret

;参数值放在ax
calculate:
        push bx
        
        mov bl, 10

        div bl
        mov cl, ah

        xor ah, ah
        div bl
        mov ch, ah

        pop bx
        ret


;初始化中断例程
init:
        push ax
        mov ax, data
        mov ds, ax
        mov ax, 0
        mov es, ax
        cli     ;关中断修改中断处理程序
        push es:[9 * 4]
        pop ds:[0]
        push es:[9 * 4 + 2]
        pop ds:[2] ;保存原来的9号中断例程地址
        mov word ptr es:[9 * 4], offset int9 ; 将键盘中断处理程序指向自己编写的例程
        mov es:[9 * 4 + 2], cs
        sti
        mov ax, 0b800h ;指向显存
        mov es, ax

        pop ax
        ret

save_all macro
        cli
        cmp Current,0
        push bp ;push bp
        push ds ;push ds
        push es ;push es
        push di ;push di  计数器di预设为0
        push si ;push si
        push dx ;push dx
        push cx ;push cx
        push bx ;push bx
        push ax ;push ax

        mov bh,0
        mov bl,Current
        add bl,bl
        add bl,bl
        sub bl,2
        add bx,offset A_SS_SP
        mov ds:[bx],sp

        ; ax bx cx dx si di es ds bp ip cs psw
        ; 0  2  4  6  8  10 12 14 16 18 20 22  24
        ;                            ↑sp此时指向这里
        
        ;按上图所示，保存剩下的寄存器
        ;然后在数据段中更新ss:sp的值
        endm

restore_all macro
        
        ; ax bx cx dx si di es ds bp ip cs psw
        ; 0  2  4  6  8  10 12 14 16 18 20 22  24
        ;↑sp此时指向这里
        ;按照顺序恢复寄存器
        cmp Current ,0
        je r
        mov bh,0
        mov bl,Current
        add bl,bl
        add bl,bl
        sub bl,2
        add bx,offset A_SS_SP
        mov sp ,ds:[bx]

        pop ax
        pop bx
        pop cx
        pop dx
        pop si
        pop di
        pop es
        pop ds
        pop bp
     
    
   r:   sti
        iret
        endm

switch macro
cli
        cmp Current,al
        je s
        cmp al,3h
        je cal
        cmp al,2h
        je cal
        cmp al,1h
        je cal
        jmp s

cal:    cmp Current,0
        je go

go:     mov Current,al

        mov bh,0
        mov bl,al
        add bl,bl
        add bl,bl
        sub bl,2
        add bx,offset A_SS_SP
        mov sp,ds:[bx]
        

        ;根据al中的值，切换到ds段中保存的ss sp
        ;更新当前正在运行的程序
       s:
        endm

int9:
        cmp Current,0
        je get
        save_all
        
get:    in al, 60h
        dec al ;从而按下1234 获得的扫描码就是1234
        
        pushf
        call dword ptr ds:[0];调用系统自带的例程
        cmp al,5h ; 按5
        je stop

        switch
        
        jmp int9ret

    stop:
        call exit
    int9ret:
        restore_all
       


code ends
end start