.model small
.stack 100h

.data
    ; Game messages
    welcome_msg db 13,10,'HANGMAN GAME',13,10,'$'
    start_msg db 13,10,'Guess the secret word!',13,10,'$'
    word_prompt db 13,10,'Word: $'
    guess_prompt db 13,10,'Enter a letter: $'
    correct_msg db 13,10,'Correct guess!',13,10,'$'
    wrong_msg db 13,10,'Wrong guess!',13,10,'$'
    win_msg db 13,10,13,10,'*** YOU WIN! ***',13,10,'$'
    thanks_msg db 13,10,'Thanks for playing!',13,10,'$'

    ; Game variables
    secret_word db 'H','E','L','L','O','$'
    display_word db 6 dup('$')
    word_length dw 5
    guessed_letters db 26 dup(0)

    ; Hangman stages (optional visual feedback)
    hangman0 db 13,10,'  +---+',13,10,'  |   |',13,10,'      |',13,10,'      |',13,10,'      |',13,10,'      |',13,10,'=========',13,10,'$'
    hangman1 db 13,10,'  +---+',13,10,'  |   |',13,10,'  O   |',13,10,'      |',13,10,'      |',13,10,'      |',13,10,'=========',13,10,'$'
    hangman2 db 13,10,'  +---+',13,10,'  |   |',13,10,'  O   |',13,10,'  |   |',13,10,'      |',13,10,'      |',13,10,'=========',13,10,'$'
    hangman3 db 13,10,'  +---+',13,10,'  |   |',13,10,'  O   |',13,10,' /|\  |',13,10,'      |',13,10,'      |',13,10,'=========',13,10,'$'

.code
main proc
    mov ax, @data
    mov ds, ax

    call clear_screen
    lea dx, welcome_msg
    call print_string
    lea dx, start_msg
    call print_string

    ; Initialize display word with underscores
    lea si, display_word
    mov cx, word_length
init_display:
    mov byte ptr [si], '_'
    inc si
    loop init_display
    mov byte ptr [si], '$'

game_loop:
    call display_hangman
    call display_current_word

    lea dx, guess_prompt
    call print_string
    call get_guess
    call process_guess

    call check_win
    cmp al, 1
    jne continue_game
    jmp player_wins

continue_game:
    jmp game_loop

player_wins:
    call display_current_word
    lea dx, win_msg
    call print_string
    lea dx, thanks_msg
    call print_string

    mov ah, 4Ch
    int 21h
main endp

;---------------------------------------------
; Subroutines
;---------------------------------------------

get_guess proc
    mov ah, 01h
    int 21h
    cmp al, 'a'
    jb guess_done
    cmp al, 'z'
    ja guess_done
    and al, 0DFh ; convert to uppercase
guess_done:
    ret
get_guess endp

process_guess proc
    push ax

    sub al, 'A'
    xor bh, bh
    mov bl, al
    lea si, guessed_letters
    add si, bx

    cmp byte ptr [si], 1
    je already_guessed

    mov byte ptr [si], 1

    pop ax
    push ax

    lea si, secret_word
    lea di, display_word
    mov cx, word_length
    mov bl, 0

check_loop:
    cmp al, [si]
    jne next_char
    mov [di], al
    mov bl, 1
next_char:
    inc si
    inc di
    loop check_loop

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

display_hangman proc
    ; Display a static hangman (no lives tracking)
    lea dx, hangman0
    call print_string
    ret
display_hangman endp

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

print_string proc
    mov ah, 09h
    int 21h
    ret
print_string endp

end main
