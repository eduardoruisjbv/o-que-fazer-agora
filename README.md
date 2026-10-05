# O que fazer agora? (nome provisório)

> Addon de World of Warcraft que sugere **uma** atividade que sempre agrega algo ao personagem (nível, ilvl ou ouro).

**Status:** design fechado, MVP definido, nenhuma linha de código ainda.
**Alvo:** WoW Retail 12.x (Midnight). **Linguagem:** Lua.

## Problema

Muitas vezes entramos no WoW sem propósito do que fazer. O addon sugere uma atividade que sempre agrega algo ao personagem (nível, ilvl ou ouro), com a prioridade definida pelo estado do personagem.

## Princípios

- **Leitura do estado real do jogo, sempre.** Sem catálogo manual de conteúdo.
- **Uma sugestão única por vez**, escolhida por regra de prioridade.
- **Nunca intrusivo.** Nada de popup surpresa nem entrada automática na fila. Tudo parte de uma ação do jogador.
- **Entrega:** botão no minimapa abre o painel. O addon marca o conteúdo no mapa com a **seta nativa da Blizzard**, identificada como sugestão do addon (nome/ícone próprio no ponto). Quando a atividade não tem local no mapa (fila de masmorra), o painel mostra um botão que abre a masmorra no Group Finder.

## Regras de prioridade (MVP)

### Abaixo do nível máximo: upar o mais rápido possível

Modelo mental: **um grafo, como o do Obsidian.**

1. **Campanha em andamento** é a prioridade principal (nós grandes do grafo). O addon sugere a próxima etapa dela, sem recomendar zona nova.
2. **Missões secundárias** vêm em seguida, escolhidas pela proximidade com o objetivo principal e entre si, para maximizar o XP por deslocamento.
3. **Grupo de 2 ou mais jogadores:** masmorra aleatória pelo Group Finder aparece como botão secundário. Ela substitui a campanha como sugestão principal **somente se houver bônus de XP ativo**.
4. **Sem campanha em andamento:** vale a mesma lógica do grafo (missões próximas) e a masmorra em grupo.

### Nível máximo, nicho PvE

- **Fontes lidas:** Great Vault (slots pendentes), lockouts e atividades semanais, ilvl por slot e crests acumuladas.
- **Critério:** o **slot mais fraco** do personagem manda. O addon sugere a atividade que dropa item para ele, lendo a loot table pelo Encounter Journal.
- **Conteúdo por tamanho de grupo:**
  - 1 a 2 jogadores: missões e Delves
  - 3 a 5 jogadores: masmorras e Míticas
  - 6 ou mais: raid

## Fora do MVP (versões futuras)

- **Seletor de nicho no nível máximo:** PvE, PvP ou Misto.
- **PvP:** mesma regra do PvE (slot mais fraco primeiro, evento ativo só desempata). Fontes: eventos de PvP ativos, Conquest/Honor semanal, Great Vault de PvP, ilvl por slot.
- **Misto:** escolhe pela atividade de maior ganho de ilvl pendente, seja PvE ou PvP. Unidade de ganho: ilvl que a atividade pode dropar menos o ilvl equipado no slot mais fraco.
- **Ouro direto:** só sugerido quando a API mostra recompensa em gold direta (missão, evento) acima de um limite configurável (padrão 800), e só quando não houver nenhum ganho de ilvl disponível. **Ilvl sempre vence ouro.** Sem estimativa de preço de Auction House.
- **Fallback de progresso longo** (reputação, conquista, colecionável) quando não há ganho de ilvl nem ouro acima do limite.
- **Tela de configuração** (nicho e limite de ouro).

## Pontos em aberto a validar na construção

- **ilvl por dificuldade:** o Encounter Journal pode não expor o ilvl exato, o que pode exigir uma tabela mínima de ilvl por tipo de conteúdo.
- **XP de missões não aceitas:** a API só mostra bem o XP das que já estão no log.
- **Aparência da seta nativa:** modificar o visual é limitado, então a identificação do addon pode ficar no nome ou ícone do ponto.
- **Bônus de XP ativo:** depende de quais buffs a API do WoW 12.x deixa o addon ler.
- **Restrições da API na 12.x:** confirmar o que ficou protegido ou limitado para addons.

## Primeiro protótipo (prova de viabilidade)

Um protótipo mínimo que só faça **três leituras**:

1. Ler a campanha atual do personagem.
2. Listar as missões do mapa atual com coordenadas.
3. Consultar a loot table de uma masmorra pelo Encounter Journal.

Se essas três leituras funcionarem na 12.x, o resto do desenho se sustenta.

## Licença

MIT (regra para todos os addons de WoW do autor). Veja [LICENSE](LICENSE).
