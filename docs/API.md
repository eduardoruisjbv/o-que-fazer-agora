# Referências e limites de validação

As assinaturas foram consultadas em 2026-10-05 na documentação e no código da interface Blizzard extraídos do cliente, espelhados no branch `live` de [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source). O branch pode mudar; o relatório do addon registra a build do cliente em que ele realmente rodou.

## Campanha e mapa

- [WarCampaignDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WarCampaignDocumentation.lua): `C_CampaignInfo.GetAvailableCampaigns`, `GetCampaignInfo`, `GetCurrentChapterID`, `GetCampaignChapterInfo`, `GetState`, `GetFailureReason`, `IsCampaignQuest`. `rewardQuestID` identifica recompensa de capítulo, não uma API de próximo objetivo.
- [QuestLogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua): log, `GetQuestsOnMap`, `GetNextWaypoint`, `ReadyForTurnIn`, títulos e conclusão.
- [QuestLineInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua): `C_QuestLine.GetAvailableQuestLines`, `RequestQuestLinesForMap`, `QuestLineInfo.isCampaign`, `GetForceVisibleQuests`, `GetQuestLineInfo`, `x`, `y`. Os pontos usam o mapa solicitado, como no provider nativo; `startMapID` identifica a origem, que pode estar em um mapa filho.
- [QuestTaskInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestTaskInfoDocumentation.lua): world quests/objetivos de mapa via `C_TaskQuest.GetQuestsOnMap`.
- [MapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua): posição do jogador e conversão para coordenadas de mundo. A conversão pode não retornar posição em determinados mapas.
- [ExpansionDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ExpansionDocumentation.lua): funções **globais** `GetClientDisplayExpansionLevel` e `GetMaxLevelForExpansionLevel`, sem namespace `C_Expansion`.

## Loot

- [EncounterJournalDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncounterJournalDocumentation.lua): `C_EncounterJournal.GetLootInfoByIndex`, campos do item e filtro de slot.
- [Blizzard_EncounterJournal.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EncounterJournal/Mainline/Blizzard_EncounterJournal.lua): descoberta por `EJ_GetInstanceByIndex`, seleção de tier/instância/dificuldade e filtro de especialização.
- [ItemDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua): `C_Item.GetDetailedItemLevelInfo` e carregamento assíncrono do item.

O ilvl exibido é o valor retornado para o hyperlink recebido do Journal. Comparar em jogo com a mesma dificuldade e especialização antes de usar esse dado para recomendações. Sem hyperlink/ilvl, o protótipo mantém **pendente**, sem substituição por tabela inventada.

## Dependências da etapa 2

- [ItemUpgradeDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemUpgradeDocumentation.lua): custos por nível para o item no contexto de upgrade. `C_Item.GetItemUpgradeInfo.maxItemLevel` isoladamente é teto de trilha, não capacidade financiada com crests atuais.
- [WeeklyRewardsDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/WeeklyRewardsDocumentation.lua): atividades, thresholds e hyperlinks de recompensa.
- [SuperTrackManagerDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SuperTrackManagerDocumentation.lua): seleção de quest/user waypoint. Utilizada automaticamente pelo Auto para a sugestão principal quando não há pin manual; hooks devolvem controle após ação manual.
- [UnitAuraDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua): acesso auras com restrições de segredo; não usar buff desconhecido como XP bônus comprovado.

Compilação LuaJIT e testes de geometria não validam frames, coordenadas reais, disponibilidade de conteúdo, taint ou restrições protegidas do cliente. A etapa 1 somente passa após comparar os resultados no WoW.

## Ícone e máscara do minimapa

O [listfile extraído do WoW](https://github.com/wowdev/wow-listfile/blob/master/parts/interface.csv) identifica `4635196` como `INV_10_DungeonJewelry_Explorer_Trinket_1Compass_Color1`, `3528314` como `Interface/Masks/CircleMask.BLP` e `136477` como o highlight do botão do minimapa. O ícone foi inspecionado visualmente antes de ser selecionado. São arquivos nativos do jogo; não é necessário distribuir uma imagem externa.

## Modo Auto (0.2.0)

As operações de NPC seguem as funções usadas em [QuestFrame.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua) e [QuestInfo.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua): `AcceptQuest`, `CompleteQuest`, `GetQuestReward`, contagem e hyperlinks de escolhas. A compatibilidade de recompensa usa `C_Item.GetItemSpecInfo` da especialização ativa; sem dados completos, o jogador escolhe. Escolhas de moeda e a confirmação de entrega com custo permanecem nativas.

`C_QuestLog.AddQuestWatch` / `AddWorldQuestWatch` e as remoções são acompanhadas por propriedade persistida das marcações. Hooks seguros tratam intervenções externas como escolhas do jogador e suspendem controle da seta. Isso deve ser confirmado com o tracker nativo, addons de tracker instalados, mudanças manuais, combate e reload no cliente real.

## Missões disponíveis (0.2.1)

A leitura acompanha `QUESTLINE_UPDATE`, incluindo a solicitação de atualização quando o payload é verdadeiro. Inclui ofertas forçadas além das questlines, seguindo [QuestOfferDataProvider.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua). Missões de campanha triviais continuam elegíveis. A classificação consulta tanto a campanha quanto `C_QuestInfoSystem.GetQuestClassification`; uma resposta negativa da primeira fonte não bloqueia a segunda. Marcadores da bússola aparecem sem exigir Seguir; desde a 0.2.2, o Auto também autoriza a navegação nativa automática, preservando pins manuais.

## Navegação automática (0.2.2)

O Auto coloca o destino principal com `C_Map.SetUserWaypoint` e ativa `C_SuperTrack.SetSuperTrackedUserWaypoint(true)` após confirmação de sucesso. Atualiza somente quando as coordenadas mudam; alterações em combate aguardam o fim do combate. Um pin existente ao iniciar/recarregar ou definido manualmente suspende a navegação nativa automática, mantendo a bússola; Seguir sugestão permite retomá-la.

## Missão aceita e etapas instanciadas (0.2.3)

Missões não aceitas usam waypoint; missões aceitas de mundo aberto usam `C_SuperTrack.SetSuperTrackedQuestID`, com confirmação por `GetSuperTrackedQuestID`. O waypoint pertencente ao addon é removido ao trocar para a missão. A propriedade do waypoint é persistida para retomada após reload; pins manuais continuam preservados. Etapas instanciadas detectadas pelos tags disponíveis recebem texto discreto abaixo da bússola; dentro de instâncias os marcadores externos ficam ocultos. A classificação depende dos dados expostos pela API, e precisa de confirmação no cliente.

## Passagens e busca de grupo (0.2.4)

`GetNextWaypointText` fornece a instrução de passagem; `GetNextWaypointForMap` permite usar a etapa local da rota quando o destino está em outro mapa. Sem dados, não são inventadas posições de portais. A busca usa a associação real de `C_LFGList.GetActivityIDForQuestID` e `LFGListUtil_FindQuestGroup`, documentadas pelo [LFGList.lua da Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GroupFinder/Mainline/LFGList.lua). Sem associação ou com anúncio ativo, abre apenas o painel; não remove anúncios nem entra em filas.
