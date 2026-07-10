# Practice · Design System da Franquia

Contrato de design compartilhado pelos apps da franquia Practice
(**practice-br**, **practice-fr**, e os que vierem). Este arquivo é **portável**:
copie-o tal qual para cada app da franquia.

## Filosofia: um design system, N marcas

Um componente é **estrutura + tokens**:

- A **estrutura** (anatomia dos cards, hierarquia dos botões, tipografia,
  espaçamentos, tom das mensagens) pertence à *franquia* — é igual em todos os apps.
- Os **tokens** (as cores concretas) pertencem à *marca* — cada app preenche
  os mesmos nomes com a sua paleta.

Na prática: uma view escrita para o practice-br funciona no practice-fr sem
mudar uma linha — só a paleta do `_tokens.scss` muda.

## As 3 camadas

| Camada | Onde vive | Muda entre apps? |
|---|---|---|
| 1. Fundamentos (tipografia, raios, sombras, anatomia, regras) | este documento + `docs/design_system.html` | ❌ nunca |
| 2. Tokens de marca (paleta) | `app/assets/stylesheets/_tokens.scss` | ✅ só os **valores** |
| 3. Componentes (partials, views) | `app/views/**` | ❌ referenciam só tokens |

## Regras de ouro

1. **Nunca escreva um hex numa view, helper ou JS.** Sempre `var(--token)`.
   Se precisar de uma cor que não existe, é uma conversa de design system
   (adicionar token), não um hex avulso.
2. **Exceções documentadas** (hex permitido, espelhando a tabela de tokens):
   - Views de **mailer** (`app/views/*mailer*`) — clientes de email não suportam `var()`.
   - `<meta name="theme-color">` no layout — a meta tag não aceita `var()`.
   - O tema DaisyUI em `config/tailwind.config.js` — o build exige literais.
3. **Botões têm 3 papéis** (consultar antes de criar qualquer botão):
   - **CTA de rodapé** → `--brand` (hover: `--brand-deep`) — grande, convite principal da página.
   - **Compacto** → `--brand-deep` — ações pequenas no meio do conteúdo (editar, voltar).
   - **Submit de formulário** → `--action` (hover: `--action-hover`) — fecha formulários.
4. **Contraste com coragem.** Lição aprendida no BR: página toda branca fica
   "sem graça". Alternar `--paper` → `--surface` → `--surface-2`, e usar
   `--brand-deep` cheio nos blocos que merecem peso.
5. **Texto sempre na escala ink** (`--ink`, `--ink-soft`, `--ink-faint`).
   Nada de cinza puro (`#333`, `#666`) — a escala é quente de propósito.
6. **Níveis CEFR têm cor fixa na franquia** (aluno reconhece o nível em
   qualquer app): A1 = marca, A2 = info, B1 = violet, B2 = warning, C1 = neutro.

## Vocabulário de tokens

Nomes em inglês, por papel (nunca por cor — `--brand`, não `--verde`).
Grupos: **neutros** (`ink`, `paper`, `surface`, `line`, `neutral-*`),
**marca** (`brand*`), **ação** (`action*`), **estados** (`success*`, `error*`,
`warning*`, `info*`), **apoio** (`sky*` = CO, `amber*` = CE, `violet*` = B1/eCPF)
e **véus** (`*-veil`, `*-glow` — sombras tintadas da marca).

A lista completa com os valores do app está em `_tokens.scss`;
a amostra visual, em `docs/design_system.html`.

Sufixos padronizados dentro de cada grupo:

| Sufixo | Papel |
|---|---|
| *(sem sufixo)* | a cor de trabalho do grupo |
| `-deep` | variação escura (texto sobre tint, hover de peso) |
| `-bright` / `-soft` | variações claras de realce |
| `-border` | borda da família |
| `-tint` / `-tint-2` / `-mist` | fundos, do mais presente ao mais sutil |
| `-ink` | texto escuro da família sobre fundo tintado |

## Tipografia (franquia)

| Papel | Fonte | Uso |
|---|---|---|
| Display | Raleway 600–800 | títulos h1–h3 |
| Corpo | Plus Jakarta Sans 400–700 | texto, formulários, botões |
| Mono | DM Mono | badges técnicos, contadores, códigos |

Raios de borda: 8px (controles), 12px (cards), 18px (blocos), 24px (heros).

## Como adotar num novo app da franquia (ex.: practice-fr)

1. Copie `docs/DESIGN_SYSTEM.md` (este arquivo) e `docs/design_system.html`.
2. Copie `app/assets/stylesheets/_tokens.scss` e **troque só os valores**
   (a paleta da nova marca). Os nomes ficam idênticos.
3. Atualize o bloco `:root` do `design_system.html` com a nova paleta e abra
   no navegador — é o teste visual da marca inteira de uma vez.
4. Nas views, troque hex por `var(--token)`. O script
   `scripts/tokenize_colors.rb` automatiza: ajuste o mapa hex→token para a
   paleta local, rode sem argumentos (dry-run) e depois com `--apply`.
5. Espelhe a paleta no tema DaisyUI do `tailwind.config.js`
   (`practice-fr` em vez de `practice-br`).

## Histórico

- **2026-07-10** — Sprint 1 da franquia: criado `_tokens.scss`, 2.233 hex
  substituídos por tokens em 67 arquivos do practice-br (views, helpers, JS,
  SCSS). Tailwind `extend.colors` passou a ler os tokens. Estilos inline
  continuam existindo (viram classes gradualmente, conforme as views forem
  retrabalhadas) — mas as **cores** já são 100% tematizáveis.
