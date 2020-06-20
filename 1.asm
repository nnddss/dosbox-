assume cs:code
stack segment
    db 512 dup(0)
stack ends
data segment
        db 'this is message 1',0,'this is message 2',0,'this is message 3',0
        db '00:00:00',0
        hourh db 0
        hourl db 0
        tab db '0123456789'
        x db 0
data ends
code segment
assume ds:data,cs:code,ss:stack
start:
    mov ax,stack
    mov ss,ax
    mov sp,512
    push cs
    pop ds
    mov ax,0
    mov es,ax
    push es:[9*4]
    pop es:[200h]
    push es:[9*4+2]
    pop es:[202h]
    mov si,offset int9
    mov di,204h
    mov cx,offset int9end-offset int9
    cld
    rep movsb

    cli
    mov word ptr es:[9*4],204H
    mov word ptr es:[9*4+2],0
    sti
    mov cx,1
 s:
    inc cx
    loop s
    mov ax,0
    mov es,ax
    push es:[200h]
    pop es:[9*4]
    push es:[202h]
    pop es:[9*4+2]
    mov ax,4c00h
    int 21H



int9:
    push ax
    push bx 
    push cx
    push es
    
    in al,60h
    pushf
    call dword ptr cs:[200h]
    cmp al,84h
    je int93
    cmp al,83h
    je int92
    cmp al,82h
    je int91

    pop es
    pop cx
    pop bx
    pop ax
    iret

int93:
    pop es
    pop cx
    dec cx
    pop bx
    pop ax
    iret
int91:  
        push si         ;开始求余数，x为变量
        
        mov ax,data
        mov ds,ax
        mov ah,0
        mov al,x
        
        mov bl,3
        div bl
        mov al,ah
        and ah,0
        mov bl,18
        mul bl
        mov si,ax

        mov dh,0
        mov dl,30
        mov cl,7
        mov al,x
        inc al
        mov x,al
        call show_str
    pop si
    pop es
    pop cx
    pop bx
    pop ax
    iret

int92:
 push si
 mov ax,data
 mov ds,ax
 
 mov ah,2ch
 int 21h

 mov ax,data
 mov ds,ax
 mov si,54
 mov al,ch
 and ah,0
 mov bl,10
 div bl
 mov hourh,al
 mov hourl,ah
 and bh,0
 mov bl,hourh
 mov al,tab[bx]
 mov [si],al
 inc si
 mov bl,hourl
 mov al,tab[bx]
 mov [si],al
 add si,2

 mov al,cl
 and ah,0
 mov bl,10
 div bl
 mov hourh,al
 mov hourl,ah
 and bh,0
 mov bl,hourh
 mov al,tab[bx]
 mov [si],al
 inc si
 mov bl,hourl
 mov al,tab[bx]
 mov [si],al
 add si,2

 mov al,dh
 and ah,0
 mov bl,10
 div bl
 mov hourh,al
 mov hourl,ah
 and bh,0
 mov bl,hourh
 mov al,tab[bx]
 mov [si],al
 inc si
 mov bl,hourl
 mov al,tab[bx]
 mov [si],al

        mov dh,0
        mov dl,72
        mov cl,7
        mov ax,data
        mov ds,ax
        mov si,54
        call show_str
    pop si
    pop es
    pop cx
    pop bx
    pop ax
    iret


show_str:   push dx
            push cx
            push si     
            mov di,0    
            mov bl,dh   
            mov al,160  
            mul bl      
            mov bx,ax   
            mov al,2    
            mul dl      
            add bx,ax   
            mov ax,0b800h
            mov es,ax  
            mov al,cl   
     s1:    mov ch,0
            mov cl,ds:[si] 
            jcxz ok         
            mov es:[bx+di],cl   
            mov es:[bx+di+1],al 
            add di,2   
            inc si      
            loop s1     
    
    ok:     pop si    
            pop cx
            pop dx   ; 还原寄存器变量
            ret         ; 结束子程序调用
int9ret:
    pop es
    pop cx
    pop bx
    pop ax
    iret

int9end:nop
code ends
end start
