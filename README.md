# Just do it

Addon individual de WoW Retail 12.x para sugerir a próxima atividade do personagem.

## Estado da entrega

**0.2.4 — protótipo com modos Semi-auto e Auto.** Implementa as três leituras combinadas, orientação por missões e automações com consentimento. A recomendação completa PvE por equipamento continua pendente.

- Painel aberto pelo minimapa ou `/jdi`, sem popup de login. Seletor **Modo: Semi-auto / Auto** no topo e controles na aba Configuração. Botão circular compacto com ícone nativo de bússola (FileDataID 4635196).
- Leitura de campanhas disponíveis e presentes no log, capítulo atual e impedimentos.
- Leitura das missões do log, POIs do mapa, questlines disponíveis e world quests, com as coordenadas que o jogo expuser.
- Descoberta de masmorras pelo Encounter Journal, consulta de loot em Normal/Heroica/Mítica e filtro da especialização ativa.
- Links e ilvl retornados pelo jogo, sem inventar níveis quando os dados não estiverem carregados.
- Bússola horizontal semi-auto transparente, sem fundo/borda, no topo. Principal azul acinzentado e secundária bronze suave; letras P/S também distinguem os marcadores. A animação acompanha metade do FPS do jogo (mínimo alvo de 30 Hz), com suavização angular; a posição é consultada separadamente a 10 Hz.
- Pontos próprios P/S no mapa, com identificação em tooltip. Semi-auto preserva o tracker e a seta; Auto adiciona as sugestões ao tracker, preservando marcações manuais. No Auto, missões disponíveis recebem um pin, e missões aceitas usam o rastreamento nativo da própria missão; um ponto manual tem prioridade. **Seguir sugestão** permite retomar o controle.
- Regras de proximidade/corredor, estabilidade de troca e exclusão da atividade exata por 45 minutos.
- Relatório copiável, também persistido em `JustDoItDB.lastReport` ao sair do jogo.

O addon funciona individualmente, sem comunicação entre jogadores. A consulta ao Encounter Journal é manual, fora de combate e com a janela nativa fechada. Os filtros e a seleção visual anterior do Journal são restaurados em cada leitura. Dados secretos da 12.x não são comparados nem serializados.

## Instalação

Copie a pasta **JustDoIt** (a que contém `JustDoIt.toc`) para `_retail_/Interface/AddOns/`. O título exibido no jogo é **Just do it**; o nome técnico da pasta não tem espaços.

Interface declarada: **120100**, correspondente aos addons Retail presentes nesta máquina. Se instalar em outro patch, confira a versão real do cliente.

## Validação da primeira etapa

1. Reinicie o WoW se a pasta foi adicionada enquanto ele estava aberto. Habilite **Just do it** na lista de addons.
2. Entre em um personagem que tenha campanha em andamento, numa zona com missões. Abra `/jdi` e confira a identificação das próximas ações.
3. Execute `/jdi probe`, fora de combate e com o Encounter Journal fechado.
4. Na aba **Leituras**, confira campanha/capítulo, missões/POIs e coordenadas. Compare com o mapa e o log nativos; zero missões/campanhas em uma zona vazia não significa falha da API.
5. Confira a masmorra descoberta e sua loot table. Use `<` e `>` para trocar de masmorra e os botões para mudar a dificuldade. Compare itens e ilvl com o Encounter Journal nativo, usando a mesma especialização.
6. Ande e gire o personagem. Confira orientação P/S, distâncias e ocultação dos marcadores externos dentro de instância. A próxima missão de campanha disponível aparece na bússola e no mapa antes de ser aceita; no Auto, o indicador nativo acompanha automaticamente a sugestão principal quando não houver pin manual.
7. Execute `/jdi report`, copie o texto com Ctrl+A/Ctrl+C e preserve o resultado. Ele inclui erros, dados pendentes e a build real do cliente.

O relatório expõe dados do jogo consultados, não certifica sozinho que a sugestão corresponde à próxima etapa correta. A validação requer comparação no cliente.

## Comandos

| Comando | Ação |
| --- | --- |
| `/jdi` ou `/justdoit` | Abrir/fechar painel |
| `/jdi probe` | Abrir leituras e executar as três consultas |
| `/jdi report` | Abrir relatório copiável |
| `/jdi config` | Abrir configuração da prévia |
| `/jdi bussola` | Mostrar/ocultar bússola |
| `/jdi seguir` | Iniciar orientação pela bússola |
| `/jdi outra` | Ignorar sugestão exata por 45 minutos |

Shift + arrastar move a bússola; arrastar o botão move sua posição no minimapa.

## Próxima etapa acordada

Após validar as três leituras no cliente, investigar custos reais de upgrade/crests, ilvl por dificuldade, loot de Delves, lockouts por boss, atividades semanais, Great Vault, histórico de dificuldade, filas e bônus de XP. As automações disponíveis na 0.2.0 devem ser exercitadas no cliente: alternar modos, preservar marcações/pontos manuais e conversar com NPCs com múltiplas missões. O consentimento do modo Auto e a permissão adicional de recompensa são separados.

O resumo completo das regras está em [docs/DESIGN.md](docs/DESIGN.md). As referências de API estão em [docs/API.md](docs/API.md).

O modo Auto aceita/entrega missões no NPC com quem o jogador conversar. Escolha de recompensa é uma permissão separada, desativada inicialmente: escolhe o maior ilvl compatível com a especialização ativa, deixando empates, dados incompletos e escolhas de moeda para o jogador. Entregas que cobram gold preservam a confirmação nativa. Não entra em filas nem recomenda upgrades fictícios a partir do loot lido. No nível máximo, a interface identifica sua sugestão como **prévia de mundo aberto**, enquanto o motor de equipamento aguarda a etapa 2.

## Usar o seletor de modo

1. Execute `/jdi` e abra **Modo: Semi-auto** no topo, ou clique com o botão direito no minimapa para abrir Configuração.
2. Selecione **Auto**. Na primeira ativação deste personagem, o consentimento descreve rastreamento, aceitação e entrega de missões. Cancelar mantém o modo anterior.
3. Para escolher itens automaticamente, ative a permissão **Escolher recompensa automaticamente** na Configuração e confirme seu próprio consentimento. Ela é desativada por padrão.
4. Voltar a **Semi-auto** interrompe as automações e remove somente rastreamentos ainda pertencentes ao addon.

As verificações locais de consentimento, propriedade das marcações e escolha de recompensa não substituem testes no cliente 12.x.

Na 0.2.3, etapas instanciadas disponíveis na leitura aparecem como uma linha discreta abaixo da bússola, com prioridade para campanha. Não recebem direção externa; entregas no mundo aberto voltam à seleção normal. A sugestão completa de masmorra por equipamento permanece pendente.

Na 0.2.4, instruções de passagem retornadas pela Blizzard aparecem na bússola e no painel. Para esses trechos, o Auto usa um waypoint, preferindo a etapa local da rota quando o jogo a expõe; missões aceitas sem passagem continuam com o rastreamento nativo da missão. A indicação instanciada do painel é clicável e abre a busca correspondente quando disponível, ou o localizador de grupos como alternativa.
