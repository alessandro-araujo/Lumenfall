# Lumenfall — Lâminas do Amanhecer

Protótipo jogável de luta 2D com espadas para **Godot 4.7.2**, inspirado no ritmo de duelos clássicos como Samurai Shodown: posicionamento, golpes fortes com recuperação longa e punição de erros. Ren e o cenário usam arte raster aprovada; Akane e os sons são desenhados ou sintetizados pelo código. Não usa recursos da SNK.

## Jogar

Abra `project.godot` no Godot e pressione **F5**, ou abra `Jogar.cmd` no Windows. A cópia local do motor fica em `tools/godot/` e não entra no Git. Em outro computador, use o Godot instalado ou defina `GODOT_BIN`.

- **Enter / 1:** enfrentar a CPU.
- **2:** dois jogadores no mesmo teclado.
- **Esc:** pausar/continuar. Na pausa, **Q** volta ao menu.
- **R:** reiniciar a partida. **F1:** ligar/desligar os efeitos sonoros.

| Ação | Jogador 1 — Ren | Jogador 2 — Akane |
| --- | --- | --- |
| Mover | A / D | Setas esquerda / direita |
| Pular | W | Seta para cima |
| Agachar | S | Seta para baixo |
| Corte leve | J | B ou numérico 1 |
| Corte forte | K | N ou numérico 2 |
| Defender | L ou mover para trás | M ou numérico 3 ou mover para trás |
| Golpe de fúria | U | H ou numérico 0 |

Defesa funciona no chão e reduz o dano a 8%. Fúria aumenta ao acertar ou receber golpes; o especial exige e consome 100%. O corte forte demora mais para sair e deixa o atacante vulnerável por mais tempo. Primeiro a vencer dois rounds ganha. Cada round dura 60 segundos; no limite, vence quem tem mais vida. Empates repetem o duelo sem conceder pontos. Pulos permitem cruzar o adversário. Alguns teclados limitam combinações simultâneas de teclas.

## Escopo desta versão

Uma arena, dois lutadores com aparências distintas e o mesmo conjunto de golpes, CPU, versus local, dano, defesa, pulo, agachamento visual, colisão, fúria, cronômetro, rounds, pausa, revanche, partículas, hitstop e sons sintetizados. Ainda não há elenco selecionável, campanha, rede, suporte a controles, música ou sprites desenhados quadro a quadro. Agachar ainda não distingue golpes altos e baixos.

A cena anterior `boas_vindas.tscn` e seu script foram preservados. A cena principal agora é `scenes/arena.tscn`.

## Arena: Templo ao Luar

O cenário usa o fundo em pixel art aprovado, com templo japonês, lanternas,
cerejeiras e montanhas ao luar. É uma imagem única, sem camadas animadas;
o chão e os limites do combate foram preservados. O arquivo e sua origem
estão em `assets/arenas/templo-ao-luar/`.

## Visual do Ren

O jogador 1 usa o visual em pixel art aprovado: roupa creme, faixas azul-petróleo,
cabelo preto volumoso e katana. O atlas possui oito poses ligadas aos estados do combate,
com respiração, passos, espelhamento e efeitos de corte. É uma primeira animação por poses;
uma sequência completa desenhada quadro a quadro ainda pode ser refinada.
A arte e o prompt estão documentados em `assets/fighters/ren/README.md`.

## Organização

- `scripts/fighter.gd`: regras e estado do lutador; tabela de alcance, dano e tempos.
- `scripts/arena.gd`: partida, CPU, entrada, desenho, interface e áudio.
- `tests/combat_test.gd`: testes de combate e ciclo de rounds.
- `tools/godot_mcp.py`: servidor MCP local, sem dependências externas (Python 3.12+).
- `tests/test_mcp.py`: teste real de inicialização e ferramentas via stdio.

## MCP local

O servidor usa JSON-RPC por stdio e fornece quatro ferramentas:

| Ferramenta | Função |
| --- | --- |
| `project_info` | Versão do motor, configuração e arquivos do projeto |
| `read_source` | Ler fonte por caminho relativo, limitado ao projeto |
| `validate_project` | Executar a cena principal sem janela e relatar erros |
| `test_combat` | Executar os testes de combate e rounds |

É uma integração com os arquivos e a execução do Godot, não um plugin de controle ao vivo do editor. Não abre porta de rede, não executa comandos arbitrários e não expõe `.git`, `.codex` ou caminhos externos. As ferramentas de validação executam os scripts do projeto.

A configuração desta máquina fica em `.codex/config.toml`, ignorada pelo Git. Para configurar outro computador, copie o exemplo `tools/codex-mcp.toml` para esse caminho e ajuste os caminhos do projeto, Python e Godot. O Codex aceita a configuração por projeto para projetos confiáveis. Reinicie a conexão MCP ou reabra o Codex para carregar as ferramentas.

Referências: [configuração oficial MCP do Codex](https://developers.openai.com/codex/mcp), [transporte stdio MCP](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports), [linha de comando do Godot](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

## Verificação

```powershell
& .\tools\godot\Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/combat_test.gd
& .\tools\godot\Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/blood_test.gd
python tests/test_mcp.py
```

Para capturar a arena (requer renderização gráfica):

```powershell
New-Item -ItemType Directory -Force artifacts
& .\tools\godot\Godot_v4.7.2-stable_win64.exe --path . -- --preview
```

A captura é salva em `artifacts/arena-preview.png`. Esse modo configura uma pose de inspeção e sai automaticamente.

## Fluxo de branches

- `master`: versão de produção estável.
- `develop`: versão integrada para desenvolvimento.
- `release`: preparação da próxima entrega.
