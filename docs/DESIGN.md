# Just do it — decisões da entrevista

Nome definitivo: **Just do it**. Alvo: WoW Retail 12.x / Midnight. Lua.

## Princípios

- Foco exclusivamente no personagem que usa o addon. Sem soma de benefícios de grupo, protocolos entre usuários ou requisitos de instalação para outros jogadores.
- Estado real do jogo e descoberta pela API; sem catálogo manual de conteúdo. IDs de enumeração/dificuldade e parâmetros de comportamento não são catálogo de missões/itens.
- Uma atividade principal, com uma secundária de mundo aberto na bússola. Fila/formação de grupo pode ser atividade em paralelo.
- Painel no minimapa, sem popup surpresa e sem entrada automática em fila.
- Semi-auto inicia ativo ao entrar no jogo. Auto depende de consentimento.

## Nivelamento

- Campanha é prioritária, mesmo que conceda pouco ou nenhum XP.
- Considerar campanhas aceitas, iniciadas e disponíveis para começar. Escolher pela próxima ação mais próxima; missão aceita desempata.
- Próxima ação pode ser cumprir objetivo, entregar ou aceitar missão; não confundir a recompensa final de capítulo com a próxima etapa.
- Sem identificação confiável da campanha/próxima etapa, usar missões do mapa atual como heurística e identificar a incerteza.
- Campanha distante permanece no painel e na bússola. Não sugerir arbitrariamente uma nova zona.
- Secundárias entram num corredor entre jogador e destino da campanha.
- Uma secundária incompleta pode assumir o principal se estiver no corredor, dentro de raio curto e muito mais perto que a campanha.
- Uma entrega com essa proximidade excepcional pode assumir o principal fora do corredor.
- Reavaliar continuamente, mas trocar somente por vantagem clara mantida durante alguns segundos.
- Grupo de dois ou mais pode receber masmorra aleatória como ação secundária. Qualquer bônus de XP ativo permite que ela substitua a campanha como principal.
- Se aleatória estiver indisponível, escolher masmorra específica pela maior recompensa de XP confirmada; menor exigência de nível desempata. A descoberta de disponibilidade precisa de validação na 12.x.

## Equipamento no nível máximo

- Nicho PvE no MVP. Percorrer slots do mais fraco ao mais forte até encontrar melhoria disponível.
- Especialização ativa, independentemente da seleção de saque.
- Compatibilidade com especialização e ilvl são os critérios do MVP; sem pesos de atributos, efeitos ou conjuntos.
- Melhoria exige **mais de +3 ilvl**, não +3 inclusivo.
- Comparar com o ilvl alcançável do item equipado usando recursos realmente disponíveis; o máximo teórico da trilha não equivale a upgrade financiado.
- Ler loot pelo Encounter Journal e recompensas reais do jogo. Ilvl por dificuldade exige validação; não inventar valores quando ausentes.
- Entre atividades que melhorem o mesmo slot, escolher a mais rápida; ganho de ilvl desempata. Esta decisão final dá precedência à duração sobre o ganho esperado discutido anteriormente.
- Sem histórico, mundo aberto vence instância quando ambos melhoram o slot. Entre opções do mesmo tipo, maior ganho de ilvl.
- Crests podem motivar conteúdo que viabilize upgrade; não sugerir ir gastar as crests no NPC.
- Ler lockouts, atividades semanais e Great Vault. Por boss e dificuldade quando essa distinção for necessária.
- Vault é alternativa após esgotar melhoria direta. Preferir opção com maior ilvl dentro da progressão permitida; menor esforço desempata.

## Tipo de conteúdo e dificuldade

- 1–2 jogadores: missões e Delves.
- 3–5 jogadores: masmorras e Míticas.
- 6 ou mais: raids.
- As faixas são limites obrigatórios. Usar Group Finder para completar equipe em conteúdo organizado com três ou mais jogadores.
- Masmorra Normal/Heroica usa fila automática quando disponível. Raid Finder é a dificuldade de raid com fila; Normal/Heroica/Mítica exigem grupo organizado.
- Histórico orienta dificuldade. Sem histórico, começar na dificuldade de entrada: Normal, LFR ou primeiro tier disponível de Delve.
- Avançar quando a atual já tiver sido concluída e não oferecer melhoria elegível em nenhum slot, incluindo drops/crests.
- Reaproveitar histórico em novas temporadas, restrito aos conteúdos/dificuldades disponíveis. Não tratar conclusão antiga como disponibilidade atual.

## Paralelismo e histórico

- Medir duração total desde aceitar a sugestão até concluir: deslocamento, fila, formação de grupo e execução.
- Fila pode correr enquanto o personagem faz mundo aberto. Registrar atividades em paralelo, sem tratar uma como abandono da outra.
- Enquanto espera, orientar campanha. No máximo, concluir as etapas disponíveis da campanha da expansão atual que possam ser feitas no mundo aberto.
- Depois dessas etapas, priorizar missões que melhorem equipamento; depois as demais por proximidade.
- Missão de mundo aberto fica em destaque no painel, instância como indicação menor de **em fila**.
- Entrar na instância pausa bússola de mundo aberto; sair retoma com reavaliação.
- Sem melhoria direta nem progresso útil no Vault, sugerir entretenimento repetível e sinalizar que não há melhoria prevista. Proximidade/duração vêm primeiro; frequência de realização desempata.

## Rastreamento, seta e consentimento

- Bússola horizontal, principal azul acinzentado e secundária bronze suave. P/S também distinguem papéis sem depender só de cor.
- Modo auto adiciona as duas sugestões ao tracker, preservando todas as escolhas manuais. Sem espaço, orientar apenas pela bússola.
- Ao trocar sugestões, remover somente marcações antigas pertencentes ao addon. Se o jogador assumir a marcação, preservá-la.
- No modo Auto, o pin e o indicador nativo complementam a bússola e apontam automaticamente para a sugestão principal. Ponto próprio pode identificar o addon no mapa; capacidade de modificar nome/ícone da seta nativa precisa ser verificada.
- Não substituir ponto manual antes de **Seguir sugestão**. Novo ponto manual devolve controle da seta ao jogador; seguir novamente permite retomada.
- Semi-auto escolhe/atualiza automaticamente os objetivos, mas não altera tracker nem seta.
- Auto também aceita todas as missões oferecidas pelo NPC com quem o jogador conversar e entrega missões concluídas. Não iniciar conversa automaticamente.
- Recompensa automática exige permissão adicional, desativada por padrão. Quando ativa, maior ilvl compatível com especialização atual, mesmo sem melhoria; empate permanece manual.
- **Outra sugestão** ignora apenas atividade exata/dificuldade por 45 minutos.
- Configuração entra no MVP com ambos os modos. Opções futuras aparecem quando suas funções forem implementadas.

## Prova de viabilidade

1. Ler campanha atual; listar missões do mapa com coordenadas; consultar loot de uma masmorra.
2. Depois de confirmar em cliente real, validar bússola, automações e dados de equipamento/progressão antes de concluir o MVP.

Investigar alternativas para funções restringidas pela API; não afirmar funcionamento com base apenas em compilação ou mocks.

Parâmetros iniciais ajustáveis do protótipo: corredor 180 m, raio curto 150 m, proximidade relativa 35%, margem de troca 15%, persistência 4 s. São valores de calibração escolhidos para a primeira execução, não dados de conteúdo nem decisões fechadas pelo usuário.

## Fora do MVP

- PvP e Misto configuráveis; slot mais fraco primeiro, eventos como desempate em PvP.
- Ouro direto quando não houver ganho de ilvl; recompensa confirmada acima do limite configurável, inicialmente 800 gold. Sem estimar Auction House.
- Reputação, conquistas e colecionáveis como fallback de progresso longo.
