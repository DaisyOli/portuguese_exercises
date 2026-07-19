# 📚 Guia de estudo: o bug do GoodJob que derrubou nossa produção

*Documento de estudo para a Daisy — escrito em 2026-07-18, sobre o incidente de 2026-07-09.*
*Companheiro do issue publicado no repositório do GoodJob (rascunho em `goodjob_issue_draft.md`).*

---

## Parte 1 — Os conceitos, um por um

Antes da história do bug, os cinco conceitos que ele envolve. Se você dominar
estes cinco, o bug inteiro vira uma consequência lógica.

### 1.1 Processo e fork

Um **processo** é um programa rodando, com sua própria memória. O **fork** é
uma operação do sistema em que um processo cria uma cópia de si mesmo: o
"pai" (master) e o "filho" (worker) seguem vidas separadas, mas o filho nasce
com uma **fotografia da memória do pai** naquele instante.

> 🧑‍🏫 Analogia de professora: é como tirar xerox do seu caderno de
> planejamento e dar para um estagiário. No momento da cópia, os dois cadernos
> são idênticos — mas o que você escrever no seu depois não aparece no dele, e
> vice-versa. E se uma anotação do seu caderno dizia "a chave do armário está
> na minha bolsa", no caderno do estagiário essa frase aponta para uma bolsa
> que ele não tem.

Esse último detalhe é literalmente o nosso bug. Guarde essa analogia.

### 1.2 Puma, workers e `preload_app!`

O **Puma** é o servidor web do Rails. Em produção nós rodamos com
`workers 2`: um processo master que faz fork de 2 workers, e são os workers
que atendem as requisições.

`preload_app!` diz ao Puma: "carregue o Rails inteiro **no master, antes** de
fazer o fork". Vantagem: o código carregado é compartilhado na memória entre
os workers (economiza RAM — importante no nosso dyno de 512 MB). Desvantagem:
**tudo o que acontecer no master antes do fork é fotografado para dentro dos
workers** — inclusive coisas que não deviam ser compartilhadas.

### 1.3 Pool de conexões (connection pool)

Abrir uma conexão com o Postgres é caro. Por isso o Rails mantém um **pool**:
um "armário" com algumas conexões prontas, que as threads pegam emprestado e
devolvem. Regra de ouro: **conexões de banco não sobrevivem ao fork**. Por
isso o ActiveRecord tem um vigia chamado `ForkTracker`: quando detecta que
houve fork, ele descarta no filho as conexões herdadas do pai (elas seriam
perigosas — pai e filho falando no mesmo cano com o banco).

### 1.4 Memoização (`||=`)

Padrão comuníssimo em Ruby:

```ruby
def adapter_class
  @_adapter_class ||= calcular_algo_caro
end
```

O `||=` significa: "se `@_adapter_class` ainda não tem valor, calcule e
guarde; senão, devolva o que já está guardado". É um cache. O perigo: o valor
guardado pode **envelhecer** — o mundo muda e o cache continua apontando para
o mundo antigo. Com fork, isso é traiçoeiro: o memo preenchido no master é
fotografado para dentro do worker.

### 1.5 Closure (o bloco que "lembra" das variáveis)

Em Ruby, um bloco/lambda **captura as variáveis do lugar onde foi criado** e
carrega essas referências para sempre:

```ruby
pool = connection_pool          # pega o pool DE AGORA
meu_bloco = -> { pool.with_connection { ... } }
# mesmo que exista um pool novo no futuro, meu_bloco usa o `pool` capturado
```

Isso se chama **closure**. Não é bug de Ruby — é um recurso. Mas closure +
memoização + fork é a receita exata do nosso incidente.

---

## Parte 2 — A história do bug, em ordem

Agora é só juntar as peças:

1. **Deploy de 2026-07-09.** Colocamos o `AiGradingJob` no ar com GoodJob em
   modo `:async` (os jobs rodam em threads dentro dos próprios workers do
   Puma — escolha feita para não pagar dyno extra).

2. **Boot no Heroku.** O master do Puma carrega o Rails (`preload_app!`). O
   GoodJob começa a se preparar; uma parte dele (o **Notifier**, que fica
   escutando avisos de "chegou job novo") toca no método `adapter_class`
   **ainda no master, antes do fork**.

3. **O código do GoodJob** (só existe em Rails < 7.2 — é um "shim", um
   remendo de compatibilidade) faz isto:

   ```ruby
   @_adapter_class ||= begin
     pool = connection_pool     # ⬅ captura o pool DO MASTER na closure
     proxy = Object.new
     proxy.define_singleton_method(:quote_table_name) { |name|
       pool.with_connection { |c| c.quote_table_name(name) }  # ⬅ usa o pool capturado
     }
     proxy
   end
   ```

   Ou seja: memoizou um objeto cujos métodos carregam, via closure, uma
   referência ao **pool de conexões do processo master**.

4. **Fork.** Os 2 workers nascem com a fotografia da memória do master —
   incluindo `@_adapter_class` já preenchido, apontando para o pool do master.

5. **ForkTracker age** (corretamente!): dentro de cada worker, as conexões
   herdadas daquele pool são descartadas. O pool capturado vira um armário
   condenado: o objeto existe, mas suas estruturas internas foram anuladas.

6. **Primeiro uso no worker.** O Notifier chama `quote_table_name` → a
   closure chama `pool.with_connection` no pool condenado → dentro do Rails,
   uma estrutura interna que deveria ser um Hash é `nil` →

   ```
   NoMethodError: undefined method '[]' for nil
     .../connection_pool.rb:223:in `with_connection'
   ```

7. **O crash-loop.** O Notifier tem uma regra: se o erro for de conexão
   (rede caiu etc.), espere um pouco e tente de novo; se for **qualquer outro
   erro**, reagende **imediatamente**. `NoMethodError` não é erro de conexão…
   então ele tentava de novo sem pausa: **~20 erros por segundo** nos logs, e
   nenhum job rodava. As correções por IA dos alunos simplesmente não
   aconteciam.

> 💡 O ponto elegante: cada peça estava "certa". O `preload_app!` economiza
> memória (certo). O ForkTracker descarta conexões herdadas (certo). A
> memoização evita trabalho repetido (certo). A closure captura variáveis
> (certo). O bug mora na **combinação** — e é por isso que ninguém tinha
> reportado: precisa de Rails < 7.2 + Puma com preload + o azar de a primeira
> chamada acontecer no master.

---

## Parte 3 — Como provamos a causa (a parte de detetive)

Isso é o que dá credibilidade ao issue — e é o que você viveu:

1. **Sintoma nos logs:** o `NoMethodError` em `with_connection`, repetido sem
   parar, só nos workers, começando logo após o boot.

2. **Hipótese:** o memo `@_adapter_class` estava sendo preenchido no master e
   herdado "podre" pelos workers. Por que hipótese e não certeza? Porque
   dependia de timing: se a primeira chamada acontecesse **depois** do fork,
   cada worker capturaria o próprio pool e nada quebraria. Bug intermitente é
   o pior tipo — a não ser que você o torne determinístico…

3. **Reprodução determinística:** no `config/puma.rb`, forçamos o memo a ser
   preenchido no master de propósito:

   ```ruby
   before_fork do
     [GoodJob::Job, GoodJob::Process, GoodJob::BatchRecord].each(&:adapter_class)
     GoodJob.shutdown
   end
   ```

   Resultado: o erro aparecia **sempre**. Tiramos a sorte da equação.

4. **Teste A/B:** com a mesma reprodução ativa, limpamos o memo dentro de
   cada worker recém-nascido:

   ```ruby
   on_worker_boot do
     [GoodJob::Job, GoodJob::Process, GoodJob::BatchRecord].each do |klass|
       klass.remove_instance_variable(:@_adapter_class) if klass.instance_variable_defined?(:@_adapter_class)
     end
     GoodJob.restart
   end
   ```

   Com a limpeza: tudo funciona (o worker recalcula o memo e captura o
   próprio pool). Sem a limpeza: crash-loop. Mesmo código, uma variável de
   diferença → causa provada.

5. **Esse A/B virou o nosso workaround de produção**, que está no
   `config/puma.rb` até hoje (commit 36690c2), com um lembrete: remover
   quando o Rails for ≥ 7.2, porque aí o shim nem é instalado.

---

## Parte 4 — O fix que sugerimos ao GoodJob

A correção proposta no issue é pequena e cirúrgica: **continuar memoizando o
proxy, mas parar de memoizar o pool**. Em vez de capturar `pool` na closure,
capturar a **classe** e perguntar o pool na hora de cada chamada:

```ruby
klass = self
proxy.define_singleton_method(:quote_table_name) { |name|
  klass.connection_pool.with_connection { |c| c.quote_table_name(name) }
}
```

Diferença: `klass.connection_pool` é resolvido **a cada chamada**, então
depois do fork ele devolve o pool novo e correto do worker. A classe pode ser
capturada com segurança (ela é a mesma antes e depois do fork); o pool, não.

> 🧑‍🏫 De volta à analogia: em vez de escrever no caderno "a chave está NA
> BOLSA DA DAISY" (referência fixa a um objeto), escrever "pergunte à
> secretaria onde está a chave" (referência ao *procedimento*). A xerox do
> caderno continua válida para qualquer pessoa.

---

## Parte 5 — Perguntas que o mantenedor pode fazer (e as respostas)

Se o Ben Sheldon responder, provavelmente será algo desta lista:

**"Isso acontece em Rails 7.2+?"**
Não. Em 7.2+ o próprio ActiveRecord define `adapter_class`, então o shim do
GoodJob (o `unless respond_to?(:adapter_class)`) nem é instalado. Só afeta
Rails < 7.2.

**"Por que ninguém mais viu isso?"**
Precisa da combinação: Rails < 7.2 + Puma com `preload_app!` e workers > 0 +
a primeira chamada de `adapter_class` acontecendo no master antes do fork
(questão de timing do boot). Sem preload, ou com timing diferente, não ocorre.

**"Você pode reproduzir fora do seu app?"**
A reprodução determinística está no issue (o `before_fork` que força o memo).
Ela funciona em qualquer app Rails 7.1 + Puma preload + GoodJob. Se ele pedir
um app mínimo de reprodução, volte aqui que montamos um esqueleto novo em
alguns minutos.

**"Por que não usar `GoodJob.restart` sozinho no `on_worker_boot`?"**
Testamos (foi nosso teste A/B): o restart sozinho não limpa o memo — a
variável `@_adapter_class` sobrevive e continua apontando para o pool do
master. Só funciona limpando o memo.

**"Aceita abrir um PR?"**
Sim! (Você respondendo isso = a gente prepara o PR juntas: o diff da Parte 4
+ um teste. Seria seu primeiro PR em gem de verdade. 💚)

**"Isso não é um bug do Rails/ForkTracker?"**
Não — o ForkTracker está fazendo o trabalho dele (descartar conexões herdadas
é o comportamento seguro e documentado). O que quebra é guardar uma
referência de longa duração a um pool específico atravessando o fork; a
responsabilidade de não fazer isso é de quem captura (o shim).

---

## Parte 6 — Vocabulário do issue em inglês

| Termo no issue | Tradução no nosso contexto |
|---|---|
| shim | remendo de compatibilidade para versões antigas |
| memoize / memo | cachear em variável (`||=`) / o valor cacheado |
| close over / closure | capturar variável do contexto / bloco que "lembra" |
| forked workers | processos filhos criados pelo fork |
| crash-loop | ciclo de erro que se realimenta sem pausa |
| deterministic reproduction | jeito de fazer o bug acontecer sempre, sem sorte |
| workaround | contorno no nosso lado (não conserta a gem) |
| upstream | o projeto original (GoodJob), "rio acima" de quem usa |

---

*Se quiser treinar: me explique a Parte 2 com suas palavras que eu faço o
papel do mantenedor cético. É o melhor jeito de fixar. 😄*
