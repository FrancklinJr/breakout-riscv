.eqv BASE_ADDR 0x10010000
.eqv LARGURA 128
.eqv ALTURA 128

.eqv KEY_READY 0xFFFF0000
.eqv KEY_DATA 0xFFFF0004

.eqv TECLA_A 0x61
.eqv TECLA_D 0x64
.eqv TECLA_Q 0x71

.eqv PADDLE_W 20
.eqv PADDLE_H 2
.eqv PADDLE_Y 120

.data
paddle_x: .word 54

.text
.globl main

main:
jal ra, limpar_tela
jal ra, desenha_blocos

li a0, 63
li a1, 110
li a2, 3
li a3, 3
li a4, 0x00FF0000
jal ra, desenha_rect

jal ra, desenha_paddle


game_loop:
jal ra, ler_teclado
j game_loop

limpar_tela:
li t0, BASE_ADDR
li t1, 128
mul t1, t1, t1
slli t1, t1, 2
add t1, t0, t1

limpar_loop:
bge t0, t1, limpar_fim
sw zero, 0(t0)
addi t0, t0, 4
j limpar_loop

limpar_fim:
ret

desenha_rect:
addi sp, sp, -28
sw ra,  0(sp)
sw s0,  4(sp)
sw s1,  8(sp)
sw s2, 12(sp)
sw s3, 16(sp)
sw s4, 20(sp)
sw s5, 24(sp)

mv s0, a0
mv s1, a1
mv s2, a2
mv s3, a3
mv s4, a4

li s5, 0

desenha_rect_outer:
bge s5, s3, desenha_rect_fim
li t6, 0

desenha_rect_inner:
bge t6, s2, desenha_rect_next

add t0, s1, s5
li t1, 128
mul t0, t0, t1
add t1, s0, t6
add t0, t0, t1
slli t0, t0, 2
li t1, BASE_ADDR
add t0, t0, t1
sw s4, 0(t0)


addi t6, t6, 1
j desenha_rect_inner

desenha_rect_next:
addi s5, s5, 1
j desenha_rect_outer

desenha_rect_fim:
lw ra, 0(sp)
lw s0, 4(sp)
lw s1, 8(sp)
lw s2, 12(sp)
lw s3, 16(sp)
lw s4, 20(sp)
lw s5, 24(sp)
addi sp, sp, 28
ret

desenha_blocos:
addi sp, sp -12
sw ra, 0(sp)
sw s6, 4(sp)
sw s7, 8(sp)

li s6, 0
li s7, 8

fileira1:
bge s6, s7, fileira2_init

li t1, 15
mul t1, t1, s6
addi a0, t1, 4
li a1, 10
li a2, 12
li a3, 5
li a4, 0x00FF2222
jal ra, desenha_rect

addi s6, s6, 1
j fileira1

fileira2_init:
li s6, 0

fileira2:
bge s6, s7, desenha_blocos_fim

li t1, 15
mul t1, t1, s6
addi a0, t1, 4
li a1, 18
li a2, 12
li a3, 5
li a4, 0x0022AAFF
jal ra, desenha_rect

addi s6, s6, 1
j fileira2

desenha_blocos_fim:
lw ra, 0(sp)
lw s6, 4(sp)
lw s7, 8(sp)
addi sp, sp, 12
ret

desenha_paddle:
addi sp, sp, -4
sw ra, 0(sp)

li a0, 0
li a1, PADDLE_Y
li a2, LARGURA
li a3, PADDLE_H
li a4, 0x00000000
jal ra, desenha_rect

la t0, paddle_x
lw a0, 0(t0)
li a1, PADDLE_Y
li a2, PADDLE_W
li a3, PADDLE_H
li a4, 0x00FFFFFF
jal ra, desenha_rect

lw ra, 0(sp)
addi sp, sp, 4
ret

ler_teclado:
addi sp, sp, -4
sw ra, 0(sp)

li t0, KEY_READY
lw t1, 0(t0)
andi t1, t1, 1
beq t1, zero, teclado_fim

li t0, KEY_DATA
lw t2, 0(t0)

la t3, paddle_x
lw t4, 0(t3)

li t5, TECLA_A
bne t2, t5, checa_d

addi t4, t4, -3
li t5, 0
bge t4, t5, salva_x
li t4, 0
j salva_x

checa_d:
li t5, TECLA_D
bne t2, t5, checa_q

addi t4, t4, 3
li t5, LARGURA
sub t5, t5, zero
li t5, 108
ble t4, t5, salva_x
li t4, 108
j salva_x

checa_q:
li t5, TECLA_Q
bne t2, t5, teclado_fim
li a7, 10
ecall

salva_x:
sw t4, 0(t3)
jal ra, desenha_paddle

teclado_fim:
lw ra, 0(sp)
addi sp, sp, 4
ret
