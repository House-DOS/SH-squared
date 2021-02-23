; ========================================================================
; SUPERIOR House-DOS SHELL
; 
; Written by Jacob Bates
; ========================================================================

    BITS 16

; ========================================================================
; Header
; ========================================================================

header:
    jmp main                            ; Don't execute the header

h_creator       dw creator              ; Creator string
h_desc          dw desc                 ; Description string
h_usage         dw usage                ; Usage string


; ========================================================================
; Main code
; ========================================================================

main:
    mov ah, 0x0A                        ; Set screen attribute
    mov bl, 0b00011111                  ; White on blue
    int 0x7E

    mov ah, 0x0C                        ; Print line formatted
    mov si, start_lines                 ; Starting lines
    mov bl, 0b00011110                  ; Light yellow on blue
    int 0x7E

.command:
    mov ah, 0x05                        ; Line break
    int 0x7E

    mov ah, 0x0F                        ; Edit interface config
    mov al, 0b0000011                   ; Error messages off, commentary off
    int 0x7E

    mov ah, 0x01                        ; Print string
    mov si, prompt                      ; Our prompt
    int 0x7E

    mov ah, 0x04                        ; Teletype input
    mov di, command_buffer              ; Our buffer
    mov cx, 0x0080                      ; 128 character hard limit
    int 0x7E

    mov ax, 0x8010                      ; Upcase string
    mov si, command_buffer              ; Our command
    mov di, si                          ; Overwrite what is there
    int 0x7E

    mov ah, 0x88                        ; Find character within string
    mov al, 0x20                        ; Look for a space
    mov si, command_buffer              ; Our command
    mov bx, 0x0000                      ; Start at beginning of string
    mov cx, 0x0000                      ; Search until end of string
    int 0x7E

    jc .no_params                       ; If not found, use a separate routine to copy the filename

    cmp bx, 0x0010                      ; Is the command longer than 16 bytes?
    ja .bad                             ; If so, invalid

    mov ax, 0x8013                      ; Get substring (indices)
    mov si, command_buffer              ; Our command
    mov di, command_name                ; Our buffer
    mov cx, bx                          ; End at the index we found
    mov bx, 0x0000                      ; Start at the beginning
    int 0x7E

    jmp .param                          ; Proceed

.no_params:
    mov ax, 0x8020                      ; Get string length
    mov si, command_buffer              ; Our command
    int 0x7E

    cmp cx, 0x0010                      ; Is the command longer than 16 bytes?
    ja .bad                             ; If so, invalid

    mov ax, 0x8002                      ; Copy string
    mov si, command_buffer              ; Our command
    mov di, command_name                ; Our buffer
    int 0x7E

.param:
    mov ax, 0x8040                      ; Replace characters in string
    mov si, command_buffer              ; Source is command input
    add si, cx                          ; Start at first space
    inc si                              ; Avoid an O.B.O.E
    mov di, params                      ; Desination is parameters
    mov dh, 0x20                        ; Search for spaces
    mov dl, 0x2C                        ; Replace with commas
    int 0x7E

.handler:
    mov ax, 0x8000                      ; Compare strings
    mov si, command_name                ; Our command

    mov di, cmd_exit                    ; EXIT
    int 0x7E
    je cmd.exit

    mov di, cmd_beep                    ; BEEP
    int 0x7E
    je cmd.beep

    mov di, cmd_cp                      ; CP
    int 0x7E
    je cmd.cp

    mov di, cmd_rm                      ; RM
    int 0x7E
    je cmd.rm

    mov di, cmd_mv                      ; MV
    int 0x7E
    je cmd.mv

.bad:
    mov ah, 0x02                        ; Print line
    mov si, invalid                     ; Invalid command line
    int 0x7E

    jmp .command                        ; Retrieve new command


cmd:                                    ; The commands

.exit:
    mov ah, 0xFF                        ; Perform handback
    int 0x7E

.beep:
    mov ah, 0xC2                        ; Play PC Speaker tone
    mov dx, 0x0180                      ; Something Hz
    int 0x7E

    mov ah, 0xC1                        ; Sleep frames
    mov bx, 0x0008                      ; 1/8 of a second
    mov cx, 0x0001                      ; One frame
    int 0x7E

    mov ah, 0xC3                        ; Mute PC Speaker
    int 0x7E

    jmp main.command                    ; We're done!

.cp:
    mov cx, 0x0000                      ; First parameter
    mov di, buffer                      ; Buffer space
    call get_param                      ; Get this parameter

    jc main.bad                         ; Invalid command if no parameter

    mov ah, 0x60                        ; Verify file
    mov si, buffer                      ; Our filename
    int 0x7E

    jc main.command                     ; Exit if file not found

    mov ax, 0x4020                      ; Output file
    int 0x7E

    jc main.command                     ; Exit if error

    mov cx, 0x0001                      ; Second parameter
    mov di, buffer                      ; Buffer space
    call get_param                      ; Get this parameter

    jc main.bad                         ; Invalid command if no parameter

    mov ah, 0x4F                        ; Output to file
    mov si, buffer                      ; New filename
    int 0x7E

    jmp main.command                    ; We're done!

.rm:
    mov cx, 0x0000                      ; First parameter
    mov di, buffer                      ; Buffer space
    call get_param                      ; Get this parameter

    jc main.bad                         ; Invalid command if no parameter

    mov ah, 0x60                        ; Verify file
    mov si, buffer                      ; Our filename
    int 0x7E

    jc main.command                     ; Exit if file not found

    mov ah, 0x79                        ; Delete a file
    int 0x7E

    jmp main.command                    ; We're done!

.mv:
    mov cx, 0x0000                      ; First parameter
    mov di, buffer                      ; Buffer space
    call get_param                      ; Get this parameter

    jc main.bad                         ; Invalid command if no parameter

    mov ah, 0x60                        ; Verify file
    mov si, buffer                      ; Our filename
    int 0x7E

    jc main.command                     ; Exit if file not found

    mov cx, 0x0001                      ; Second parameter
    mov di, buffer                      ; Buffer space
    call get_param                      ; Get this parameter

    jc main.bad                         ; Invalid command if no parameter

    mov ah, 0x78                        ; Rename file
    mov si, buffer                      ; Our filename
    int 0x7E

    jmp main.command                    ; We're done!


; ========================================================================
; Subroutines
; ========================================================================

get_param:                              ; Gets parameter with number CX and places it in DI
    pusha                               ; Save register states to stack

    mov ax, 0x8100                      ; Get item from list
    mov si, params                      ; Parameter list
    int 0x7E

    popa                                ; Restore register states
    ret                                 ; Return to caller


data:

prompt          db 0x20, 0xE4, 0x20, 0x00

start_lines     db "The Superior House-DOS Shell", 0x0A
                db "SH", 0xFD, 0x20, "v0.0", 0x0A
                db "By Derrick and Jacob", 0x00

invalid         db "Invalid command given.", 0x00

command_name    dq 0x0000000000000000
                dq 0x0000000000000000
                db 0x00

cmd_exit        db "EXIT", 0x00
cmd_beep        db "BEEP", 0x00
cmd_cp          db "CP", 0x00
cmd_rm          db "RM", 0x00
cmd_mv          db "MV", 0x00

space           db " ", 0x00

creator         db "House-DOS Developers", 0x00
desc            db "The Superior House-DOS Shell.", 0x0A
                db "An alternative to the default command shell,", 0x0A
                db "this shell offers much more powerful features,", 0x0A
                db "and can be used for scripting.", 0x00
usage           db "SH2", 0x0A
                db "Flags: none", 0x00

command_buffer:
times 0x0080    db 0x00

params:
times 0x0080    db 0x00

buffer:
