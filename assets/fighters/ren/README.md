# Ren — visual aprovado

`poses.png`: atlas RGBA gerado com a ferramenta integrada ImageGen a partir de
`assets/concepts/ren-approved.png`, aprovado pelo usuário antes da implementação.
As regiões e os pivôs estão em `scripts/ren_visual.gd`.

Prompt final: preservar exatamente o samurai aprovado, roupa creme, faixas azul-petróleo,
cabelo preto volumoso e katana; oito poses em pixel art com transparência: guarda inicial,
passo, preparação, ataque, defesa, salto, agachamento e dano; manter identidade e proporções,
com espadas completas e margem entre poses. Atlas de 1536 x 1024.

Implementação: poses discretas sincronizadas com os tempos existentes, respiração sutil,
espelhamento e reação visual a dano. As regras de combate permanecem em fighter.gd.

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
