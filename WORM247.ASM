
MAX_DIR     equ 16
FP          equ 6       ; Fixed Point constants
FP1         equ 64      ; Fixed Point constants ( FP1 == 1 << FP )
KEY_LEFT    equ 1       ; ah
KEY_RIGHT   equ 2       ; ah
KEY_THRUST  equ 1       ; al
KEY_QUIT    equ 32      ; ah
LEN_START   equ 20
LEN_SIDE    equ 32
LEN_BOT     equ 23
LEN_LOOK    equ 23
N_POINT     equ 3
COL         equ 15
BLIT_BUFFER equ 1

        .MODEL TINY
HELLO  SEGMENT                  ;Set up code and data section
       ASSUME CS:HELLO,DS:HELLO ;Tell assembler about conditions at entry
       ORG  100H                ;A .COM program begins with 100H byte prefix
MAIN:                           ;Control must start here
        .286

        mov ax,0013h            ; Videomode 13h 320*200*256
        int 10h
Menu:
        mov bx, 0A000h
        mov es, bx
        mov ax, score           ; Print score
        shr ax, 5
        mov bh, 10
        div bh
        add ax, '0'*256+'0'
        mov word ptr [score_str+6], ax

WLoop:
        inc bp
        inc cx
        call DrawLine
        mov dx, offset score_str
        mov ah, 9
        int 21h
        mov ah, 1
        int 16h
        jz WLoop
        mov ah, 0
        int 16h
        cmp al, 27
        je TheEnd

        mov ax,0013h            ; Videomode 13h 320*200*256, clear screen
        int 10h

;       xor ax, ax
        mov score, ax
        mov di, 160*FP1+16      ; di = Ship X
        mov si, 100*FP1         ; si = Ship Y
        mov bp, di              ; bp = Ship dir 


;===========
MainLoop:
;===========
        inc score

        pusha                    ; Draw ship
        mov ch, byte ptr [score+1]
        inc ch
        mov dl, LEN_START
        call DrawLine
        add bp, 7*4
        mov dl, LEN_SIDE
        call DrawLine
        add bp, 5*4
        mov dl, LEN_BOT
        call DrawLine
        add bp, 5*4
        mov dl, LEN_SIDE
        call DrawLine
        popa

        mov dx, 03DAh           ; Wait vertical blank
    LoopVbl:
        in  al, dx
        test al, 8
        je LoopVbl

        mov ah, 012h            ; Read keyboard
        int 16h
        test ah, KEY_RIGHT      ; Turn right
        jz KeyNotRight
        dec bp                  ; ship_dir
KeyNotRight:
        test ah, KEY_LEFT       ; Turn left
        jz KeyNotLeft
        inc bp                  ; ship_dir
KeyNotLeft:

        mov dl,1                ; Thrust, move ship forward
        call SinCos

        pusha
        mov cx, LEN_LOOK
ColLoop:                            ; Check collision
        mov dl, 1
        call SinCos
        loop ColLoop

        call CalcPixel
        test byte ptr es:[bx+di], 255
        popa
        jz MainLoop
        jmp Menu

;
;   Loppusiivoukset
;
TheEnd:
        mov ax,0003             ; Back to textmode
        int 10h
        ret                      ;Return to system


;-------------------
DrawLine PROC NEAR
;-------------------
;   di = x * FP1
;   si = y * FP1
;   ch = len
;   cl = color
;   bp = dir

DLLoop:
    pusha
    call CalcPixel
    mov byte ptr es:[bx+di], ch  ; put_pixel(di+(x>>FP), si+(y>>FP), cl)
    popa

SinCos PROC NEAR
    push bp
    sar bp, 2
    and bp, MAX_DIR-1
    mov al, byte ptr [sint+bp]  ; x += sint[dir]
    cbw
    add di, ax
    mov al, byte ptr [sint+MAX_DIR/4+bp] ; y += cost[dir]
    cbw
    add si, ax
    pop bp
    dec dl
    jnz DLLoop
    ret
SinCos ENDP
DrawLine ENDP

CalcPixel PROC NEAR
    sar si, FP
    imul bx, si, 320 
    sar di, FP
    ret
CalcPixel ENDP


sint        db 0, 24, 45, 59, 64, 59, 45, 24
            db 0,-23,-44,-58,-63,-58,-44,-23
            db 0, 24, 45, 59

score_str   db "Score " ; 00", 13, '$'
score       dw  0
            db 13, '$'

HELLO   ENDS                     ;End of code and data section
        END  MAIN                 ;Terminate assembler and specify entry point


