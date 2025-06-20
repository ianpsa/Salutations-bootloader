; ---------- boot.asm ----------
[BITS 16]          ; 16 bits
[ORG 0x7C00]       ; Endereço onde o BIOS carrega o setor de boot

start:
    cli   
    cld            ; Direção crescente para operações de string

    xor ax, ax     ; AX = 0
    mov ds, ax     ; Data Segment = 0
    mov es, ax     ; Extra Segment = 0
    mov ss, ax     ; Stack Segment = 0
    mov sp, 0x7C00 ; Ponteiro de pilha logo abaixo do bootloader
    call clear_screen

main_loop:
    mov  si, prompt_msg      ; mostra o prompt
    call print_string

    call read_line           ; obtém texto

    cmp  byte [input_buf], 0 ; linha vazia?
    je   say_goodbye

    call print_message       ; “Olá, {nome}!”
    jmp  main_loop           ; volta ao início

say_goodbye:
    mov  si, bye_msg
    call print_string
    jmp  hang                ; trava



; ---------- Rotina: read_line ----------
;  Entradas: nada
;  Saídas : input_buf preenchido + byte 00 final
read_line:
    xor cx, cx          ; cx = 0 (número de caracteres)
    mov di, input_buf   ; ES:DI aponta para onde gravaremos (ES já é 0)

.get_key:
    mov ah, 0
    int 16h             ; AL ← caractere ASCII
    cmp al, 0x0D        ; Enter?
    je  .done
    cmp al, 0x08        ; Backspace?
    je  .backspace

    cmp cx, max_len-1   ; buffer cheio?
    jae .get_key        ; ignora se exceder
    stosb               ; grava AL em [DI], DI++ (STOS usa ES:DI)
    inc cx

    ; ecoa caractere
    mov ah, 0x0E
    mov bh, 0
    mov bl, 0x07        ; atributo: cinza sobre preto
    int 10h
    jmp .get_key

.backspace:
    cmp cx, 0           ; há algo para apagar?
    je  .get_key
    dec di              ; “volta” no buffer
    dec cx
    ; move cursor para trás, apaga e volta novamente
    mov ah, 0x0E
    mov al, 0x08
    int 10h
    mov al, ' '
    int 10h
    mov al, 0x08
    int 10h
    jmp .get_key

.done:
    mov byte [di], 0    ; terminador NUL
    ; pula a linha na tela
    mov ah, 0x0E
    mov al, 0x0D
    int 10h
    mov al, 0x0A
    int 10h
    ret


; ---------- Dados ----------
max_len     equ 64             ; tamanho máximo permitido
input_buf   times max_len db 0 ; reserva 64 bytes para o texto
greeting    db 'O','l',0xA0,', ',0    ; "Olá, "
prompt_msg   db 'Digite seu nome: ',0
bye_msg      db 'Flw irmao!',0



; ---------- Rotina: print_message ----------
print_message:
    push si
    mov  si, greeting
    call print_string        ; “Olá, ”
    mov  si, input_buf
    call print_string        ; nome

    ; imprime ‘!’
    mov  ah, 0x0E
    mov  bh, 0
    mov  al, '!'
    int  10h

    ; quebra de linha
    mov  ah, 0x0E
    mov  al, 0x0D
    int  10h
    mov  al, 0x0A
    int  10h

    pop  si
    ret


; ---------- Rotina: print_string ----------
;  Entrada: DS:SI aponta para string 0-terminated
   print_string:
       mov ah, 0x0E
       mov bh, 0
   .next_char:
       lodsb
       cmp al, 0
       je  .done
       int 10h
       jmp .next_char
   .done:
       ret



; ---------- Rotina: clear_screen ----------
; Limpa toda a página de texto e posiciona
    clear_screen:
        mov ax, 0600h        ; AH=06h: scroll; AL=0 → limpar
        mov bh, 07h          ; atributo (cinza sobre preto)
        mov cx, 0            ; canto sup esq (fila 0, coluna 0)
        mov dx, 184Fh        ; canto inf dir (fila 24, col 79)
        int 10h
        mov ah, 02h          ; AH=02h: posicionar cursor
        mov bh, 0            ; página 0
        xor dx, dx           ; linha=0, coluna=0
        int 10h
        ret



; ---------- Rotina: hang ----------
; Laço infinito – impede que o bootloader continue executando lixo de memória
hang:
        hlt
        jmp hang




times 510 - ($ - $$) db 0  ; Preenche o setor (512 B) com zeros…
dw 0xAA55                  ; Não sei exatamente o que isso faz