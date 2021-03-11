code segment para public
assume cs:code, ds:data
; вторая процедура печатает 10 слов Two фиолетовым цветом и стирает в
бесконечном цикле
two proc
assume ss:stk_two
mov ax, data ;настройка сегментов данных и стека
mov ds, ax
mov ax, stk_two
mov ss, ax
mov sp, stk_two_top
mov bx, offset words2
mov ax, 0b800h
mov es, ax ;начало терминального окна
mov di, 320
mov ah, 05h
mm2: ; начало бесконечного цикла
mov cx, 3
m2: mov al, [bx]
stosw ; печать слова Two
inc bx
loop m2
mov bx, offset words2
add di, 2
cmp di, 400
jne pass2 ; если не напечатали 10 слов, то пропускаем стирание
mov di, 320
jmp clean2 ; если напечатали 10 слов, то начинаем стирать
pass2:
jmp mm2
clean2:
mov bx, offset word_empty
mov ah, 00h
mov al, [bx]
mov cx, 80
c2:
stosw ; печать черных пробелов. стирание
loop c2
mov ah, 05h
mov bx, offset words2
mov di, 320
jmp mm2 ; обеспечение бесконечного цикла
ret
endp two
; вторая процедура печатает 10 слов One белым цветом и стирает в
бесконечном цикле
one proc
assume ss:stk_one
mov ax, data ;настройка сегментов данных и стека
mov ds, ax
mov ax, stk_one
mov ss, ax
mov sp, stk_one_top
mov bx, offset words1
mov ax, 0b800h
mov es, ax ;начало бесконечного цикла
mov di, 480
mov ah, 0fh
mm1: ; начало бесконечного цикла
mov cx, 3
m1: mov al, [bx]
stosw ; печать слова One
inc bx
loop m1
mov bx, offset words1
add di, 2
cmp di, 560
jne pass1 ; если не напечатали 10 слов, то пропускаем стирание
mov di, 480
jmp clean1 ; если напечатали 10 слов, то начинаем стирать
pass1:
jmp mm1
clean1:
mov bx, offset word_empty
mov ah, 00h
mov al, [bx]
mov cx, 80
c1:
stosw ; печать черных пробелов. стирание
loop c1
mov ah, 0fh
mov bx, offset words1
mov di, 480
jmp mm1 ; обеспечение бесконечного цикла
ret
endp one
main proc
mov ax, data
mov ds, ax
xor ax, ax
mov es, ax ; сохранение оригинального вектора прерываний
mov ax, es:[08h*4]
mov word ptr oldvect, ax
mov ax, es:[08h*4+2]
mov word ptr [oldvect+2], ax
cli
lea ax, catch ; замена вектора прерываний
mov es:[08h*4], ax
mov ax, cs
mov es:[08h*4+2], ax
sti
loop_: ; бесконечный цикл для ожидания прерывания
cmp val, 1
jne loop_
mov ax, word ptr oldvect ; восстановление оригинального
mov es:[08h*4], ax ; значения вектора прерываний
mov ax, word ptr [oldvect+2]
mov es:[08h*4+2], ax
mov ah, 4ch : завершение программы
int 21h
catch: ; перехват прерывания
pushf ; передача управления стандартной процедуре
call dword ptr oldvect ; обработки прерываний
cli
cmp init, 0 ; если init 0, то процедуры не запущены либо не все запущены
je first_init ; тогда переходим к первой инициализации
save: ; сохранение регистров в стек
push ax
push bx
push cx
push es
push di
cmp next_proc, 2 ; сохранение для той процедуры, которая была прервана
jne second_save ; если next_proc не 2, то прервана вторая процедура и для
нее нужно сохранение
first_save: ; иначе сохранение для первой процедуры
mov bx, offset one_ss ; сохранение ss:sp для первой процедуры по адресу
переменной one_ss
mov [bx], sp
mov [bx+2], ss
jmp return ; переход для восстановления для следующей процедуры
second_save:
mov bx, offset two_ss ; сохранение ss:sp для первой процедуры по адресу
переменной two_ss
mov [bx], sp
mov [bx+2], ss
jmp return ; переход для восстановления для следующей процедуры
first_init: ; запуск первой процедуры
cmp next_proc, 1 ; если запущена первая процедура (next_proc == 2)
jne save ;то сохранить ее и запустить вторую
inc next_proc ; иначе запускаем первую процедуру, а next_proc = 2
sti ; чтоб в следующий раз запустить вторую процедуру
call one ; запуск процедуры one
return:
cmp init, 0 ; если вторая процедура еще не запущена,
je start_two ; то запустить, иначе начать восстановление следующей
процедуры
cmp next_proc, 2 ; в зависимости от того, на какую процедуру нужно
переключиться, восстановить ss:sp из переменной
je second_restore ; если next_proc == 2, то восстановление для второй
процедуры
fisrt_restore: ; иначе восстановить для первой процедуры
inc next_proc ; инкрементируется next_proc, чтоб следующей выполнялась
вторая процедура
mov bx, offset one_ss ; относительный адрес one_ss записывается в bx
mov sp, [bx] ; значение по адресу в bx записывается в sp
mov ss, [bx+2] ; значение по адресу в bx со смещением на 2 записывается в
ss
jmp restore ; переход для того, чтоб вытащить значения регистров из стека
second_restore: ;восстановить для второй процедуры
dec next_proc ; декрементируется next_proc, чтоб следующей выполнялась
первая процедура
mov bx, offset two_ss ; относительный адрес two_ss записывается в bx
mov sp, [bx] ; значение по адресу в bx записывается в sp
mov ss, [bx+2] ; значение по адресу в bx со смещением на 2 записывается в
ss
restore: ; вытащить значения регистров из стека
pop di
pop es
pop cx
pop bx
pop ax
jmp continue ; переход для продолжения выполнения прерванной процедуры
start_two: ; запуск второй процедуры
inc init ; инкремент init, чтоб сообщить о том, что все процедуры были
запущены
dec next_proc ; декрементируется next_proc, чтоб следующей выполнялась
первая процедура
sti
call two ; запуcall two ; запуск процедуры two
call two ; запуск процедуры two
continue:
sti
iret ; продолжить выполнение прерванной процедуры
endp main
code ends
; сегмент стека процедуры one
stk_one segment stack
db 256 dup (?)
stk_one_top label word
stk_one ends
; сегмент стека процедуры two
stk_two segment stack
db 256 dup (?)
stk_two_top label word
stk_two ends
; сегмент данных
data segment para public
next_proc db 1 ; процесс, к которому нужно перейти или запустить при
прерывании
val db 0 ; переменная для обеспечения бесконечного цикла для ожидания
прерывания
one_ss dd ? ; переменные для хранение
two_ss dd ? ; ss:sp для процедур
oldvect dd ? ; переменная для хранения оригинального значения вектора
прерываний
init db 0 ; переменная для проверки того, что обе процедуры запущены
words1 db "One" ; слова, которые
words2 db "Two" ; печатают процедуры
word_empty db " " ; пробел для стирания терминального окна
data ends
end main
