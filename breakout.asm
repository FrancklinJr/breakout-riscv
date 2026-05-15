# ============================================================
# breakout.asm — Jogo Breakout em Assembly RISC-V
# Disciplina: Arquitetura de Computadores
# Universidade Católica de Santos
# ============================================================

# Display
.eqv BASE_ADDR  0x10010000
.eqv LARGURA    128
.eqv ALTURA     128

# Teclado MMIO
.eqv KEY_READY  0xFFFF0000
.eqv KEY_DATA   0xFFFF0004
.eqv TECLA_A    0x61
.eqv TECLA_D    0x64
.eqv TECLA_Q    0x71

# Paddle
.eqv PADDLE_W   20
.eqv PADDLE_H   2
.eqv PADDLE_Y   118

# Bola
.eqv TAM_BOLA   3

# Blocos
# Largura 13, espaçamento 14 → gap de 1px entre blocos
# Fileiras espaçadas 7px (altura 5 + gap 2)
# y = 8 + fileira * 7
.eqv BLOCO_W    13
.eqv BLOCO_H    5
.eqv BLOCO_Y1   8    # fileira 0
.eqv BLOCO_Y2   15   # fileira 1
.eqv BLOCO_Y3   22   # fileira 2 — resistente
.eqv BLOCO_Y4   29   # fileira 3
.eqv BLOCO_Y5   36   # fileira 4 — resistente

# Valores dos blocos no array:
# 0 = destruído
# 1 = normal (1 pancada)
# 2 = resistente cheio  (laranja brilhante, 2 pancadas)
# 3 = resistente danificado (laranja escuro, 1 pancada)

# ─────────────────────────────────────────────
.data
display_buffer: .space 65536
paddle_x: .word 54
bola_x:   .word 63
bola_y:   .word 64
vel_x:    .word 1
vel_y:    .word 1
# 40 blocos: fileiras 0,1,3 normais (1), fileiras 2,4 resistentes (2)
blocos: .word 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2

# ─────────────────────────────────────────────
.text
.globl main

main:
    jal  ra, limpar_tela
    jal  ra, desenha_blocos
    jal  ra, desenha_paddle
    jal  ra, desenha_bola

game_loop:
    jal  ra, ler_teclado
    jal  ra, mover_bola
    jal  ra, delay
    j    game_loop


# ════════════════════════════════════════
# delay
# ════════════════════════════════════════
delay:
    li   t0, 20000
delay_loop:
    addi t0, t0, -1
    bne  t0, zero, delay_loop
    ret


# ════════════════════════════════════════
# mover_bola
# ════════════════════════════════════════
mover_bola:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s0, 4(sp)

    la   t0, bola_x
    lw   a0, 0(t0)
    la   t0, bola_y
    lw   a1, 0(t0)
    li   a2, TAM_BOLA
    li   a3, TAM_BOLA
    li   a4, 0x00000000
    jal  ra, desenha_rect

    la   t0, bola_x
    lw   t1, 0(t0)
    la   t2, vel_x
    lw   t3, 0(t2)
    add  t1, t1, t3
    sw   t1, 0(t0)

    la   t0, bola_y
    lw   t1, 0(t0)
    la   t2, vel_y
    lw   t3, 0(t2)
    add  t1, t1, t3
    sw   t1, 0(t0)

    jal  ra, checa_colisoes
    jal  ra, desenha_bola

    lw   ra, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    ret


# ════════════════════════════════════════
# checa_colisoes
# ════════════════════════════════════════
checa_colisoes:
    addi sp, sp, -36
    sw   ra,  0(sp)
    sw   s0,  4(sp)
    sw   s1,  8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)
    sw   s5, 24(sp)
    sw   s6, 28(sp)
    sw   s7, 32(sp)

    la   s0, bola_x
    lw   s1, 0(s0)
    la   s2, bola_y
    lw   s3, 0(s2)
    la   s4, vel_x
    lw   s5, 0(s4)
    la   s6, vel_y
    lw   s7, 0(s6)

    # parede esquerda
    li   t0, 0
    bgt  s1, t0, col_direita
    li   s1, 1
    neg  s5, s5
    sw   s5, 0(s4)
    sw   s1, 0(s0)

col_direita:
    li   t0, 125
    blt  s1, t0, col_teto
    li   s1, 124
    neg  s5, s5
    sw   s5, 0(s4)
    sw   s1, 0(s0)

col_teto:
    li   t0, 0
    bgt  s3, t0, col_blocos
    li   s3, 1
    neg  s7, s7
    sw   s7, 0(s6)
    sw   s3, 0(s2)

col_blocos:
    jal  ra, checa_colisao_blocos
    lw   s1, 0(s0)
    lw   s3, 0(s2)
    lw   s7, 0(s6)

col_paddle:
    li   t0, 0
    ble  s7, t0, col_fundo

    li   t0, TAM_BOLA
    add  t0, s3, t0
    li   t1, PADDLE_Y
    blt  t0, t1, col_fundo

    li   t1, PADDLE_Y
    li   t2, PADDLE_H
    add  t1, t1, t2
    bge  s3, t1, col_fundo

    la   t2, paddle_x
    lw   t2, 0(t2)
    li   t3, PADDLE_W
    add  t3, t2, t3

    li   t4, TAM_BOLA
    add  t4, s1, t4
    ble  t4, t2, col_fundo
    bge  s1, t3, col_fundo

    li   s3, PADDLE_Y
    addi s3, s3, -3
    sw   s3, 0(s2)
    neg  s7, s7
    sw   s7, 0(s6)

    # calcula onde no paddle a bola bateu
    # t2 ainda tem paddle_x das checagens acima
    # hit_pos = bola_x - paddle_x (0=borda esq, ~20=borda dir)
    sub  t5, s1, t2

    # zona esquerda (hit_pos < 7) → vai para esquerda
    li   t6, 7
    bge  t5, t6, paddle_meio
    li   s5, -1
    sw   s5, 0(s4)
    j    col_fim

paddle_meio:
    # zona central (7 <= hit_pos < 14) → mantém direção atual
    li   t6, 14
    bge  t5, t6, paddle_direita
    j    col_fim

paddle_direita:
    # zona direita (hit_pos >= 14) → vai para direita
    li   s5, 1
    sw   s5, 0(s4)
    j    col_fim

col_fundo:
    li   t0, 128
    blt  s3, t0, col_fim

    mv   a0, s1
    mv   a1, s3
    li   a2, TAM_BOLA
    li   a3, TAM_BOLA
    li   a4, 0x00000000
    addi sp, sp, -4
    sw   s1, 0(sp)
    jal  ra, desenha_rect
    lw   s1, 0(sp)
    addi sp, sp, 4

    li   t1, 63
    sw   t1, 0(s0)
    li   t1, 64
    sw   t1, 0(s2)
    li   t1, 1
    sw   t1, 0(s4)
    li   t1, 1
    sw   t1, 0(s6)

col_fim:
    lw   ra,  0(sp)
    lw   s0,  4(sp)
    lw   s1,  8(sp)
    lw   s2, 12(sp)
    lw   s3, 16(sp)
    lw   s4, 20(sp)
    lw   s5, 24(sp)
    lw   s6, 28(sp)
    lw   s7, 32(sp)
    addi sp, sp, 36
    ret


# ════════════════════════════════════════
# checa_colisao_blocos
# 40 blocos, 5 fileiras de 8
# y = 8 + (i / 8) * 7
# valores: 1=normal, 2=resistente cheio, 3=resistente danificado
# ════════════════════════════════════════
checa_colisao_blocos:
    addi sp, sp, -20
    sw   ra,  0(sp)
    sw   s8,  4(sp)
    sw   s9,  8(sp)
    sw   s10, 12(sp)
    sw   s11, 16(sp)

    la   s8, blocos
    li   s9, 0
    li   s10, 40             # 40 blocos no total

bl_loop:
    bge  s9, s10, bl_fim

    # lê valor do bloco
    slli t0, s9, 2
    add  t0, s8, t0
    lw   t1, 0(t0)
    beq  t1, zero, bl_prox   # morto, pula

    # calcula x: col = i % 8, bx = col * 14 + 4
    li   t2, 8
    rem  t3, s9, t2
    li   t2, 14
    mul  t3, t3, t2
    addi t3, t3, 4            # t3 = bx

    # calcula y: fileira = i / 8, by = 8 + fileira * 7
    li   t2, 8
    div  t4, s9, t2           # t4 = fileira (0 a 4)
    li   t2, 7
    mul  t4, t4, t2           # t4 = fileira * 7
    addi t4, t4, 8            # t4 = by

bl_testa:
    # AABB — 4 checagens de separação

    # borda direita da bola <= borda esquerda do bloco?
    li   t5, TAM_BOLA
    add  t5, s1, t5
    ble  t5, t3, bl_prox

    # borda esquerda da bola >= borda direita do bloco?
    li   t5, BLOCO_W
    add  t5, t3, t5
    bge  s1, t5, bl_prox

    # borda baixo da bola <= topo do bloco?
    li   t5, TAM_BOLA
    add  t5, s3, t5
    ble  t5, t4, bl_prox

    # borda topo da bola >= base do bloco?
    li   t5, BLOCO_H
    add  t5, t4, t5
    bge  s3, t5, bl_prox

    # ── colisão detectada! ──

    # inverte vel_y
    neg  s7, s7
    la   t0, vel_y
    sw   s7, 0(t0)

    # checa se é resistente cheio (valor 2)
    li   t6, 2
    beq  t1, t6, bl_danifica

    # valor 1 ou 3: destroi o bloco
    slli t0, s9, 2
    add  t0, s8, t0
    sw   zero, 0(t0)          # marca como morto

    # apaga bloco da tela (preto)
    addi sp, sp, -16
    sw   s9,  0(sp)
    sw   s1,  4(sp)
    sw   s3,  8(sp)
    sw   t4, 12(sp)           # salva by pois desenha_rect usa t4
    mv   a0, t3
    mv   a1, t4
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x00000000
    jal  ra, desenha_rect
    lw   s9,  0(sp)
    lw   s1,  4(sp)
    lw   s3,  8(sp)
    lw   t4, 12(sp)
    addi sp, sp, 16
    j    bl_empurra

bl_danifica:
    # resistente cheio → danificado: valor 2 vira 3
    slli t0, s9, 2
    add  t0, s8, t0
    li   t6, 3
    sw   t6, 0(t0)

    # redesenha com cor danificada (laranja escuro)
    addi sp, sp, -16
    sw   s9,  0(sp)
    sw   s1,  4(sp)
    sw   s3,  8(sp)
    sw   t4, 12(sp)
    mv   a0, t3
    mv   a1, t4
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x00884400       # laranja escuro = danificado
    jal  ra, desenha_rect
    lw   s9,  0(sp)
    lw   s1,  4(sp)
    lw   s3,  8(sp)
    lw   t4, 12(sp)
    addi sp, sp, 16

bl_empurra:
    # empurra bola para fora do bloco (evita colisão dupla)
    li   t6, 0
    bgt  s7, t6, bl_empurra_baixo

    # vel_y < 0 → bola vai subir → empurra pra cima do bloco
    addi t5, t4, -4
    la   t6, bola_y
    sw   t5, 0(t6)
    j    bl_fim

bl_empurra_baixo:
    # vel_y > 0 → bola vai descer → empurra pra baixo do bloco
    li   t5, BLOCO_H
    add  t5, t4, t5
    addi t5, t5, 1
    la   t6, bola_y
    sw   t5, 0(t6)
    j    bl_fim

bl_prox:
    addi s9, s9, 1
    j    bl_loop

bl_fim:
    lw   ra,  0(sp)
    lw   s8,  4(sp)
    lw   s9,  8(sp)
    lw   s10, 12(sp)
    lw   s11, 16(sp)
    addi sp, sp, 20
    ret


# ════════════════════════════════════════
# desenha_bola
# ════════════════════════════════════════
desenha_bola:
    addi sp, sp, -4
    sw   ra, 0(sp)

    la   a0, bola_x
    lw   a0, 0(a0)
    la   a1, bola_y
    lw   a1, 0(a1)
    li   a2, TAM_BOLA
    li   a3, TAM_BOLA
    li   a4, 0x00FF0000
    jal  ra, desenha_rect

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


# ════════════════════════════════════════
# limpar_tela
# ════════════════════════════════════════
limpar_tela:
    li   t0, BASE_ADDR
    li   t1, 128
    mul  t1, t1, t1
    slli t1, t1, 2
    add  t1, t0, t1

lt_loop:
    bge  t0, t1, lt_fim
    sw   zero, 0(t0)
    addi t0, t0, 4
    j    lt_loop

lt_fim:
    ret


# ════════════════════════════════════════
# desenha_rect
# a0=x, a1=y, a2=largura, a3=altura, a4=cor
# ════════════════════════════════════════
desenha_rect:
    addi sp, sp, -28
    sw   ra,  0(sp)
    sw   s0,  4(sp)
    sw   s1,  8(sp)
    sw   s2, 12(sp)
    sw   s3, 16(sp)
    sw   s4, 20(sp)
    sw   s5, 24(sp)

    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    mv   s3, a3
    mv   s4, a4
    li   s5, 0

dr_outer:
    bge  s5, s3, dr_fim

    add  t0, s1, s5
    li   t1, 0
    blt  t0, t1, dr_next
    li   t1, 128
    bge  t0, t1, dr_next

    li   t6, 0

dr_inner:
    bge  t6, s2, dr_next

    add  t2, s0, t6
    li   t3, 0
    blt  t2, t3, dr_skip
    li   t3, 128
    bge  t2, t3, dr_skip

    add  t0, s1, s5
    li   t1, 128
    mul  t0, t0, t1
    add  t1, s0, t6
    add  t0, t0, t1
    slli t0, t0, 2
    li   t1, BASE_ADDR
    add  t0, t0, t1
    sw   s4, 0(t0)

dr_skip:
    addi t6, t6, 1
    j    dr_inner

dr_next:
    addi s5, s5, 1
    j    dr_outer

dr_fim:
    lw   ra,  0(sp)
    lw   s0,  4(sp)
    lw   s1,  8(sp)
    lw   s2, 12(sp)
    lw   s3, 16(sp)
    lw   s4, 20(sp)
    lw   s5, 24(sp)
    addi sp, sp, 28
    ret


# ════════════════════════════════════════
# desenha_blocos — 5 fileiras
# fileiras 0,1,3 normais | 2,4 resistentes (laranja brilhante)
# ════════════════════════════════════════
desenha_blocos:
    addi sp, sp, -12
    sw   ra, 0(sp)
    sw   s6, 4(sp)
    sw   s7, 8(sp)

    li   s7, 8               # 8 blocos por fileira

    # fileira 0 — vermelho normal
    li   s6, 0
db_f1:
    bge  s6, s7, db_f2_init
    li   t1, 14
    mul  t1, t1, s6
    addi a0, t1, 4
    li   a1, BLOCO_Y1
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x00FF2222
    jal  ra, desenha_rect
    addi s6, s6, 1
    j    db_f1

    # fileira 1 — azul normal
db_f2_init:
    li   s6, 0
db_f2:
    bge  s6, s7, db_f3_init
    li   t1, 14
    mul  t1, t1, s6
    addi a0, t1, 4
    li   a1, BLOCO_Y2
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x0022AAFF
    jal  ra, desenha_rect
    addi s6, s6, 1
    j    db_f2

    # fileira 2 — laranja brilhante, resistente (2 pancadas)
db_f3_init:
    li   s6, 0
db_f3:
    bge  s6, s7, db_f4_init
    li   t1, 14
    mul  t1, t1, s6
    addi a0, t1, 4
    li   a1, BLOCO_Y3
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x00FF8800      # laranja brilhante
    jal  ra, desenha_rect
    addi s6, s6, 1
    j    db_f3

    # fileira 3 — verde normal
db_f4_init:
    li   s6, 0
db_f4:
    bge  s6, s7, db_f5_init
    li   t1, 14
    mul  t1, t1, s6
    addi a0, t1, 4
    li   a1, BLOCO_Y4
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x0022CC44      # verde
    jal  ra, desenha_rect
    addi s6, s6, 1
    j    db_f4

    # fileira 4 — laranja brilhante, resistente (2 pancadas)
db_f5_init:
    li   s6, 0
db_f5:
    bge  s6, s7, db_fim
    li   t1, 14
    mul  t1, t1, s6
    addi a0, t1, 4
    li   a1, BLOCO_Y5
    li   a2, BLOCO_W
    li   a3, BLOCO_H
    li   a4, 0x00FF8800      # laranja brilhante
    jal  ra, desenha_rect
    addi s6, s6, 1
    j    db_f5

db_fim:
    lw   ra, 0(sp)
    lw   s6, 4(sp)
    lw   s7, 8(sp)
    addi sp, sp, 12
    ret


# ════════════════════════════════════════
# desenha_paddle
# ════════════════════════════════════════
desenha_paddle:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li   a0, 0
    li   a1, PADDLE_Y
    li   a2, LARGURA
    li   a3, PADDLE_H
    li   a4, 0x00000000
    jal  ra, desenha_rect

    la   t0, paddle_x
    lw   a0, 0(t0)
    li   a1, PADDLE_Y
    li   a2, PADDLE_W
    li   a3, PADDLE_H
    li   a4, 0x00FFFFFF
    jal  ra, desenha_rect

    lw   ra, 0(sp)
    addi sp, sp, 4
    ret


# ════════════════════════════════════════
# ler_teclado
# ════════════════════════════════════════
ler_teclado:
    addi sp, sp, -4
    sw   ra, 0(sp)

    li   t0, KEY_READY
    lw   t1, 0(t0)
    andi t1, t1, 1
    beq  t1, zero, lt_fim2

    li   t0, KEY_DATA
    lw   t2, 0(t0)

    la   t3, paddle_x
    lw   t4, 0(t3)

    li   t5, TECLA_A
    bne  t2, t5, lt_d

    addi t4, t4, -3
    li   t5, 0
    bge  t4, t5, lt_salva
    li   t4, 0
    j    lt_salva

lt_d:
    li   t5, TECLA_D
    bne  t2, t5, lt_q

    addi t4, t4, 3
    li   t5, 108
    ble  t4, t5, lt_salva
    li   t4, 108
    j    lt_salva

lt_q:
    li   t5, TECLA_Q
    bne  t2, t5, lt_fim2
    li   a7, 10
    ecall

lt_salva:
    sw   t4, 0(t3)
    jal  ra, desenha_paddle

lt_fim2:
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret