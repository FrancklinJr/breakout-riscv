# Breakout em RISC-V Assembly

Projeto da disciplina de Arquitetura de Computadores  
Universidade Católica de Santos — Prof. Walter S. Oliveira

## Sobre o projeto
Implementação do jogo clássico Breakout em linguagem Assembly RISC-V,
executável no simulador RARS. O jogo conta com paddle controlado pelo jogador,
bola com física de reflexão, dois andares de blocos coloridos que são destruídos
ao contato e reset automático da bola ao cair no fundo.

## Como rodar
1. Baixe o [RARS](https://github.com/TheThirdOne/rars/releases)
2. Abra o arquivo `breakout.asm` no RARS
3. Vá em **Tools → Bitmap Display → Connect to MIPS**
   - Unit Width/Height: 4
   - Display Width/Height: 512
   - Base Address: 0x10010000 (static data)
4. Vá em **Tools → Keyboard and Display MMIO Simulator → Connect to MIPS**
5. Monte com **F3** e rode com **F5**
6. Clique na janela do MMIO Simulator antes de digitar

## Controles
| Tecla | Ação |
|-------|------|
| `a` | Mover paddle para a esquerda |
| `d` | Mover paddle para a direita |
| `q` | Sair do jogo |

## Estrutura do código
| Função | Descrição |
|--------|-----------|
| `main` | Inicializa a tela e entra no game loop |
| `mover_bola` | Apaga, move e redesenha a bola a cada frame |
| `checa_colisoes` | Verifica colisão com paredes, teto, blocos e paddle |
| `checa_colisao_blocos` | AABB entre bola e os 16 blocos ativos |
| `desenha_rect` | Primitiva gráfica: pinta um retângulo colorido no Bitmap Display |
| `desenha_blocos` | Renderiza as duas fileiras de blocos |
| `desenha_paddle` | Apaga e redesenha o paddle na posição atual |
| `desenha_bola` | Renderiza a bola na posição atual |
| `ler_teclado` | Lê input via MMIO e atualiza posição do paddle |
| `delay` | Controla a velocidade do jogo |

## Conceitos de Arquitetura aplicados
- **Conjunto de instruções RISC-V**: aritméticas (`add`, `sub`, `mul`), lógicas (`neg`, `andi`), desvios (`beq`, `bne`, `blt`, `bge`) e acesso à memória (`lw`, `sw`)
- **Convenção de chamada**: registradores salvos (`s0`–`s11`) preservados na pilha, temporários (`t0`–`t6`) usados livremente, argumentos (`a0`–`a7`) para passagem de parâmetros
- **Gerenciamento de pilha**: todas as funções abrem e fecham corretamente o frame com `addi sp`
- **Chamadas de sistema (ecalls)**: encerramento do programa via `ecall 10`
- **Memória de vídeo**: escrita direta no Bitmap Display via endereço base `0x10010000`
- **MMIO**: leitura de teclado em tempo real via endereços `0xFFFF0000` e `0xFFFF0004`

## Progresso
- [x] Etapa 1 — Bitmap Display: blocos, paddle e bola na tela
- [x] Etapa 2 — Movimento do paddle pelo teclado
- [x] Etapa 3 — Física da bola (reflexão nas paredes e teto)
- [x] Etapa 4 — Detecção de colisão com paddle (AABB)
- [x] Etapa 5 — Destruição dos blocos com reflexão da bola
- [ ] Etapa 6 — Pontuação e estados do jogo
- [ ] Etapa 7 — Polimento e relatório final
