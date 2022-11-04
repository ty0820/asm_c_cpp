;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;         Distributed under the Boost Software License, Version 1.0.         ;;
;;            (See accompanying file LICENSE or copy at                       ;;
;;                 https://www.boost.org/LICENSE_1_0.txt)                     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .text

global _start

extern XBlackPixel
extern XClearWindow
extern XFillRectangle
extern XFlush
extern XLookupKeysym
extern XSync
extern XSetForeground
extern XWhitePixel

extern assert_not_null
extern assert_null
extern create_window
extern try_get_event
extern render_begin
extern render_end
extern draw_rectangle
extern exit
extern get_time
extern print
extern print_num
extern sleep_ms

_start:

    lea rdi, [hello_world]
    call print

    call create_window

main_loop_start:
    ; get time at start of frame
    call get_time
    mov [frame_time], rax

    call try_get_event
    mov r12, rax

    ; no event so go to game logic
    cmp rax, 0x0
    je game_logic

    ; check if its a press event
    mov eax, [r12]
    cmp rax, 0x2
    je handle_key

    ; check if its a release event
    mov eax, [r12]
    cmp rax, 0x3
    jne game_logic ; if not go to game logic

handle_key:
    ; get the key code for the release event
    lea rdi, [r12]
    mov rsi, 0x0
    call XLookupKeysym

    ; see if its an XK_Escape
    cmp rax, 0xff1b
    jne handle_arrow_key

    ; if its key press then exit the game
    mov eax, [r12]
    cmp rax, 0x2
    je main_loop_end

handle_arrow_key:
    ; if it's not an XK_Right then check if its an XK_Left
    cmp rax, 0xff53
    jne left_check

    mov eax, [r12]
    cmp rax, 0x2
    jne right_release

    mov rax, 0x1
    mov [right_arrow_status], rax
    jmp game_logic

right_release:
    mov rax, 0x0
    mov [right_arrow_status], rax
    jmp game_logic

left_check:
    ; if its not an XK_Left then go to game logic
    cmp rax, 0xff51
    jne game_logic

    mov eax, [r12]
    cmp rax, 0x2
    jne left_release

    mov rax, 0x1
    mov [left_arrow_status], rax
    jmp game_logic

left_release:
    mov rax, 0x0
    mov [left_arrow_status], rax

game_logic:
    mov rax, [right_arrow_status]
    cmp rax, 0x0
    je right_arrow_update_finish

    mov rax, [paddle_x]
    add rax, 10
    mov [paddle_x], rax
right_arrow_update_finish:

    mov rax, [left_arrow_status]
    cmp rax, 0x0
    je left_arrow_update_finish

    mov rax, [paddle_x]
    sub rax, 10
    mov [paddle_x], rax
left_arrow_update_finish:

    call render_begin

    call ball_update

    mov rdi, [paddle_x]
    mov rsi, [paddle_y]
    mov rdx, [paddle_width]
    mov rcx, [paddle_width]
    call draw_rectangle

    mov rdi, [ball_x]
    mov rsi, [ball_y]
    mov rdx, [ball_width]
    mov rcx, [ball_width]
    call draw_rectangle

    call render_end
    
    ; get end frame time
    call get_time

    ; see if we have spent less than 30ms in this frame
    mov rbx, [frame_time]
    sub rax, rbx
    cmp rax, 30

    jg main_loop_start

    ; sleep for remainder of 30ms
    mov rbx, 30
    sub rbx, rax
    mov rdi, rbx
    call sleep_ms
        
    jmp main_loop_start
main_loop_end:

    lea rdi, [goodbye]
    call print

    mov rdi, 0x0
    call exit

; Perform ball update logic
ball_update:
    push rbp
    mov rbp, rsp

    ; add y velocity to ball
    mov rax, [ball_y]
    add rax, [ball_velocity_y]
    mov [ball_y], rax

    ; check if ball has gone off the bottom of the screen
    mov rax, [ball_y]
    cmp rax, 0x320
    jl ball_update_y_min_check

    ; invert y velocity
    mov rax, 0xfffffffffffffff6
    mov [ball_velocity_y], rax
    jmp ball_update_end

ball_update_y_min_check:
    ; check if ball has gone off the top of the screen
    mov rax, [ball_y]
    cmp rax, 0x0
    jg ball_update_end

    ; invert y velocity
    mov rax, 0xa
    mov [ball_velocity_y], rax

ball_update_end:
    pop rbp
    ret

section .data
    paddle_width: dq 0xc8
    paddle_height: dq 0x14
    paddle_x: dq 0x12c
    paddle_y: dq 0x30c
    ball_width: dq 0xa
    ball_height: dq 0xa
    ball_x: dq 0x190
    ball_y: dq 0x190
    ball_velocity_y: dq 0xa
    left_arrow_status: dq 0x0
    right_arrow_status: dq 0x0
    frame_time: dq 0x0

section .rodata
    hello_world: db "hello world", 0xa, 0x0
    goodbye: db "goodbye", 0xa, 0x0
    sleep_for: db "sleep_for: ", 0x0
