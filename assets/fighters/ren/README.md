# Ren — visual aprovado

`poses.png`: atlas RGBA gerado com a ferramenta integrada ImageGen a partir de
`assets/concepts/ren-approved.png`, aprovado pelo usuário antes da implementação.
As regiões e os pivôs estão em `scripts/ren_visual.gd`.

Prompt final: preservar exatamente o samurai aprovado, roupa creme, faixas azul-petróleo,
cabelo preto volumoso e katana; oito poses em pixel art com transparência: guarda inicial,
passo, preparação, ataque, defesa, salto, agachamento e dano; manter identidade e proporções,
com espadas completas e margem entre poses. Atlas de 1536 x 1024.

Implementação: poses de combate sincronizadas com os tempos existentes, caminhada
articulada sobre a arte original, respiração sutil, espelhamento e reação visual a dano.
As regras de combate permanecem em fighter.gd.

## Caminhada ativa — malha 2D sobre o sprite aprovado

### Estado parado aprovado

`scripts/ren_idle_rig.gd` integra o movimento aprovado na prévia 04
(`artifacts/ren-idle-v4-preview/ren-idle-120-quadros.gif`). O ciclo de 3.6 segundos
reproduz a mesma função usada nos 120 quadros do GIF, avaliada continuamente no jogo:
respiração mais marcada, inclinação do tronco, oscilação do punho/katana e movimento
secundário do cabelo/faixas. A arte original é usada na escala habitual 0.58; a
prévia era ampliada a 0.92. Os pés permanecem apoiados, sem escalar o corpo inteiro.

A entrada/saída da caminhada mistura as deformações. Ataque, defesa, salto e dano
mantêm prioridade; o retorno ao repouso suaviza em 0.16 s. Pausa e hitstop congelam
o ciclo. Testes dedicados: `tests/ren_idle_test.gd`; captura com `-- --capture-idle`.
As regras e os sprites originais do combate permanecem intactos.

O usuário autorizou escolher a técnica para melhorar a fluidez, preservando o corpo.
A caminhada usa **somente a região idle de poses.png**, na mesma escala 0.58 da pose
parada. Não utiliza os atlas experimentais de caminhada, não altera a imagem original
e não exige Blender. `scripts/ren_walk_rig.gd` define 12 poses de uma malha 2D e
interpola os vértices continuamente entre elas. É deformação 2D da arte existente,
não uma nova sequência desenhada quadro a quadro nem um personagem 3D.

Cabeça, braços, mãos, espada e tronco mantêm as mesmas coordenadas horizontais e as
mesmas distâncias internas. A parte superior só recebe uma pequena translação vertical.
Abaixo da faixa, os pesos da malha articulam pernas e pés; o balanço dos pés tem uma
fase baixa de recuperação e uma fase de apoio. A fonte e a escala não mudam ao andar.

O ciclo acompanha o deslocamento efetivo após colisões, com 128 pixels por ciclo;
o recuo percorre a sequência ao contrário. Entrada em 0.10 s e saída em 0.12 s evitam
trocas bruscas ao começar/parar. Pausa e hitstop congelam o estado. Ataques, dano,
agachamento e salto assumem prioridade imediata. Reiniciar o round limpa a animação.
Ataques, alcance, dano, velocidade e demais regras de `fighter.gd` não foram alterados.

Limite artístico: a técnica preserva a silhueta original e melhora a continuidade,
mas continua sendo um passo curto de combate. Não redesenha volumes ocultos nem
substitui uma animação completa de corrida/ataque feita quadro a quadro.

Para revisão: `Testar-Ren.cmd` abre uma comparação ampliada entre original e animação.
Espaço pausa; setas percorrem as 12 poses; Esc sai. O ciclo automático mostra avanço,
recuo e parada. `Jogar.cmd` abre a arena com a nova caminhada integrada.

Validação: `tests/ren_animation_test.gd` verifica anatomia rígida da parte superior,
solas, ausência de inversão de triângulos em 120 amostras, fechamento do ciclo,
atualizações a 30/60/144 Hz, recuo, espelhamento, interrupções, pausa, hitstop e reset.
`tests/ren_arena_render.gd` captura avanço/recuo/parada na arena. Testes existentes
de combate e rounds permanecem em `tests/combat_test.gd`.
Vídeo renderizado pelo Godot: `artifacts/ren-rig-demo.avi` (7.5 s, 60 fps).
Backup dos scripts anteriores à integração: `artifacts/ren-rig-backup/`.

Referência técnica: [ArrayMesh na documentação do Godot](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html).

## Caminhada — 24/09/2026

**Rejeitada pelo usuário após teste:** a sequência de 12 quadros altera a espessura
e as proporções do Ren ao entrar em caminhada. A integração foi retirada e o visual
anterior restaurado. `walk.png` permanece apenas como experimento sem uso no jogo.
Os detalhes abaixo descrevem esse experimento, não a implementação ativa.

Referência corporal indicada pelo usuário: a proposta de **8 quadros**, preservada em
`assets/concepts/ren-walk-8-body-reference.png`. Uma futura caminhada deve manter
o volume do tronco, largura dos ombros/braços, cabeça e proporções do Ren habitual.
Antes de nova integração, comparar parado/andando na mesma escala, conferir cada
quadro e a transição em movimento. Mais quadros não compensam mudança de anatomia.
Os testes técnicos anteriores não verificavam essa consistência artística.
Script e teste retirados foram preservados como texto em `artifacts/ren-walk-rejected/`.

`walk.png`: atlas RGBA de 1536 x 1024, com 12 poses da segunda proposta aprovada
para implementação. Gerado e convertido para transparência pela ferramenta integrada
ImageGen. As três faixas começam em y=0, 360 e 692; não são células quadradas.
Escala 0.74 e pivôs de sola explícitos preservam aproximadamente a altura do atlas antigo.

O ciclo percorre 12 quadros a cada 150 pixels de deslocamento real, em sentido inverso
no recuo. Sem deslocamento, o ciclo não avança. Parar, atacar, saltar, agachar ou receber
dano seleciona a pose correspondente. O recuo continua defendendo pelas regras existentes.
O visual tem estado próprio por instância e não modifica o modelo de combate.

Prompt da proposta: preservar Ren, roupa creme, faixas azul-petróleo, cabelo e guarda;
12 momentos consecutivos de avanço em combate, passos baixos, transferência de peso,
joelhos flexionados, tronco estável e movimento discreto de cabelo e tecido; quatro
colunas e três linhas, sem textos, sem cruzar os pés e sem mudar a katana.

Prompt final de transparência (ImageGen integrado):
"Background extraction only. Edit this exact twelve-frame Ren sprite sheet to remove
the blue background and produce true transparent RGBA alpha. Preserve every character
pixel, all twelve poses, exact canvas 1536x1024, positions, scale and 4-column 3-row
arrangement unchanged. Do not redraw or redesign. All empty space transparent including
between legs and sword and body. No checkerboard baked in, no shadows, no labels.
Keep clean hard pixel-art edges."

Validação: `tests/ren_walk_test.gd` verifica deslocamento, recuo, espelhamento,
prioridade dos estados e transparência. Com `-- --capture-walk`, renderiza avanço e
recuo na arena em `artifacts/ren-walk-25.png` e `artifacts/ren-walk-70.png`.
Combate e rounds: `tests/combat_test.gd`. Backup dos dois scripts antes da mudança:
`artifacts/ren-walk-backup/`. A fluidez artística deve ser avaliada jogando; as poses
geradas ainda têm pequenas variações de desenho entre quadros.
