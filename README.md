# Breakout em RISC-V Assembly

Projeto da disciplina de Arquitetura de Computadores  
Universidade Católica de Santos — Prof. Walter S. Oliveira

## Sobre o projeto
Implementação do jogo clássico Breakout em linguagem Assembly RISC-V,
executável no simulador RARS.

## Como rodar
1. Baixe o [RARS](https://github.com/TheThirdOne/rars/releases)
2. Abra o arquivo `breakout.asm` no RARS
3. Vá em Tools → Bitmap Display → Connect to MIPS
4. Vá em Tools → Keyboard and Display MMIO Simulator → Connect to MIPS
5. Monte com F3 e rode com F5
6. Use `a` e `d` para mover o paddle, `q` para sair

## Progresso
- [x] Etapa 1 — Bitmap Display: blocos, paddle e bola na tela
- [x] Etapa 2 — Movimento do paddle pelo teclado
- [ ] Etapa 3 — Física da bola
- [ ] Etapa 4 — Detecção de colisão
- [ ] Etapa 5 — Destruição dos blocos
- [ ] Etapa 6 — Pontuação e estados do jogo
- [ ] Etapa 7 — Polimento e relatório final
