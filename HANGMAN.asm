; ==========================================================
;   HANGMAN GAME (Single Player, Simplified)
;   8086 Assembly - MASM / TASM Syntax
; ----------------------------------------------------------
;   Features:
;     - Secret word is hardcoded ("HELLO")
;     - Player guesses letters until word is complete
;     - Displays hangman outline and word progress
;     - Shows messages for correct and wrong guesses
;     - Exits automatically after a win
; ==========================================================

.model small
.stack 100h

.data
    ; ---------------------------
    ; Display Messages
    ; ---------------------------
    welcome_msg db 13,10,'===== HANGMAN GAME =====',13,10,'$'
    start_msg   db 13,10,'Guess the secret word!',13,10,'$'
    word_prompt db 13,10,'Word: $'
    guess_prompt db 13,10,'Enter a letter: $'
    correct_msg db 13,10,'Correct guess!',13,10,'$'
    wrong_msg   db 13,10,'Wrong guess!',13,10,'$'
    win_msg     db 13,10,13,10,'*** YOU WIN! ***',13,10,'$'
    thanks_msg  db 13,10,'Thanks for playing!',13,10,'$'

    ; ---------------------------
    ; Game Data
    ; ---------------------------
    secret_word db 'H','E','L','L','O','$'   ; The secret word
    display_word db 6 dup('$')               ; Word display buffer (underscores)
    word_length dw 5                         ; Number of letters in secret word
    guessed_letters db 26 dup(0)             ; A–Z guessed flag array

    ; ---------------------------
    ; Hangman Graphics (Static)
    ; ---------------------------
    hangman0 db 13,10,'  +---+',13,10,'  |   |',13,10,'      |',13,10,\
              '      |',13,10,'      |',13,10,'      |',13,10,'=========',13,10,'$'

.code
main proc
    ; ------------------------------------------------------
    ; Initialize Data Segment
    ; ------------------------------------------------------
    mov ax, @data
    mov ds, ax

    ; Clear the screen and print welcome messages
    call clear_screen
    lea dx, welcome_msg
    call print_string
    lea dx, start_msg
    call print_string

    ; ------------------------------------------------------
    ; Initialize display_word with underscores ("_____")
    ; ------------------------------------------------------
    lea si, display_word
    mov cx, word_length
init_display:
    mov byte ptr [si], '_'
    inc si
    loop init_display
    mov byte ptr [si], '$'      ; Mark end of display string

; ----------------------------------------------------------
; MAIN GAME LOOP
; ----------------------------------------------------------
game_loop:
    call display_hangman        ; Display static hangman image
    call display_current_word   ; Show word progress (underscores and letters)

    lea dx, guess_prompt        ; Prompt for input
    call print_string
    call get_guess              ; Read letter into AL
    call process_guess          ; Check against secret word

    call check_win              ; Determine if all letters guessed
    cmp al, 1
    jne continue_game           ; If not yet complete, keep playing
    jmp player_wins

continue_game:
    jmp game_loop

; ----------------------------------------------------------
; WIN SCENARIO
; ----------------------------------------------------------
player_wins:
    call display_current_word
    lea dx, win_msg
    call print_string
    lea dx, thanks_msg
    call print_string

    mov ah, 4Ch                 ; Exit to DOS
    int 21h
main endp

; ==========================================================
; Subroutines
; ==========================================================

; ----------------------------------------------------------
; get_guess
; Reads a character from keyboard and converts to uppercase.
; Result stored in AL.
; ----------------------------------------------------------
get_guess proc
    mov ah, 01h
    int 21h                     ; Wait for key input -> AL = key
    cmp al, 'a'
    jb guess_done
    cmp al, 'z'
    ja guess_done
    and al, 0DFh                ; Convert lowercase to uppercase
guess_done:
    ret
get_guess endp

; ----------------------------------------------------------
; process_guess
; Checks if letter already guessed; updates display_word
; with correct letters if found.
; ----------------------------------------------------------
process_guess proc
    push ax                     ; Save guessed letter

    ; Calculate index in guessed_letters (0–25)
    sub al, 'A'
    xor bh, bh
    mov bl, al
    lea si, guessed_letters
    add si, bx

    ; If already guessed, return early
    cmp byte ptr [si], 1
    je already_guessed
    mov byte ptr [si], 1        ; Mark letter as guessed

    pop ax                      ; Restore guessed letter
    push ax

    ; Compare guessed letter with each character in secret_word
    lea si, secret_word
    lea di, display_word
    mov cx, word_length
    mov bl, 0                   ; Flag: 1 = correct guess

check_loop:
    cmp al, [si]
    jne next_char
    mov [di], al                ; Reveal correct letter
    mov bl, 1
next_char:
    inc si
    inc di
    loop check_loop

    ; Print message depending on correctness
    cmp bl, 1
    je correct_guess
    lea dx, wrong_msg
    call print_string
    jmp process_done

correct_guess:
    lea dx, correct_msg
    call print_string
    jmp process_done

already_guessed:
    pop ax
    ret

process_done:
    pop ax
    ret
process_guess endp

; ----------------------------------------------------------
; check_win
; Checks if display_word contains any underscores.
; If none remain, player has won (AL=1).
; ----------------------------------------------------------
check_win proc
    lea si, display_word
    mov cx, word_length
check_loop_win:
    cmp byte ptr [si], '_'
    je not_won
    inc si
    loop check_loop_win
    mov al, 1
    ret
not_won:
    mov al, 0
    ret
check_win endp

; ----------------------------------------------------------
; display_current_word
; Prints the current state of display_word (e.g. "_ E _ L _")
; ----------------------------------------------------------
display_current_word proc
    lea dx, word_prompt
    call print_string
    lea si, display_word
    mov cx, word_length
display_loop:
    mov dl, [si]
    mov ah, 02h
    int 21h
    mov dl, ' '
    int 21h
    inc si
    loop display_loop
    ret
display_current_word endp

; ----------------------------------------------------------
; display_hangman
; Prints a static hangman graphic (no life tracking).
; ----------------------------------------------------------
display_hangman proc
    lea dx, hangman0
    call print_string
    ret
display_hangman endp

; ----------------------------------------------------------
; clear_screen
; Clears text screen using BIOS interrupt 10h.
; ----------------------------------------------------------
clear_screen proc
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0
    mov dh, 24
    mov dl, 79
    int 10h

    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h
    ret
clear_screen endp

; ----------------------------------------------------------
; print_string
; Displays a $-terminated string using DOS interrupt 21h.
; ----------------------------------------------------------
print_string proc
    mov ah, 09h
    int 21h
    ret
print_string endp

end main
