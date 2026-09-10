# language: pt
Funcionalidade: Motor de Cancelamento e Estorno de Assinatura SaaS
  Como um assinante do serviço
  Quero solicitar o cancelamento de minha assinatura
  Para que minha subscrição seja encerrada e eu receba o reembolso proporcional conforme regras de negócio

  Contexto:
    Dado que o sistema calcula datas e períodos em dias corridos reais do mês vigente
    E que a precedência normativa (CDC / Direito de Arrependimento) sobrescreve qualquer validação de limite operacional
    E que o mês vigente pode ter 28, 29, 30 ou 31 dias de acordo com o calendar.monthrange()
    E que o valor do reembolso líquido = (reembolso bruto - multas aplicáveis)

  # ============================================================================
  # CENÁRIOS: PERÍODO DE DIREITO DE ARREPENDIMENTO (PRIMEIROS 7 DIAS)
  # Precedência Normativa CDC - Reembolso 100% e Cancelamento Imediato
  # ============================================================================

  Cenário: Cancelamento dentro do direito de arrependimento (7 dias corridos)
    Dado que um assinante iniciou sua assinatura há 5 dias corridos
    E que a assinatura está no status "ACTIVE"
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 99,00
    E que o assinante consumiu 75GB de tráfego de dados (acima do limite de 50GB)
    E que existem infrações pendentes nos termos de uso
    Quando o assinante solicita cancelamento imediato da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITH_REFUND"
    E o reembolso bruto aprovado deve ser de R$ 99,00 (100% do valor pago)
    E nenhuma multa deve ser incidida (CDC - Direito de Arrependimento)
    E o reembolso líquido deve ser R$ 99,00
    E o sistema deve retornar os dados: { status: "CANCELLED_WITH_REFUND", refundBrute: 99.00, penalties: 0.00, refundNet: 99.00 }

  Cenário: Cancelamento exatamente no 7º dia corrido (limite do direito de arrependimento)
    Dado que um assinante iniciou sua assinatura exatamente há 7 dias corridos
    E que a assinatura está no status "ACTIVE"
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 199,00
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITH_REFUND"
    E o reembolso bruto aprovado deve ser de R$ 199,00 (100%)
    E o reembolso líquido deve ser R$ 199,00
    E nenhuma validação de limite ou infração deve ser aplicada

  Cenário: Cancelamento no 8º dia corrido (fora do período de arrependimento)
    Dado que um assinante iniciou sua assinatura há 8 dias corridos
    E que a assinatura está no status "ACTIVE"
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 99,00
    E que o assinante consumiu 45GB de tráfego de dados (dentro do limite de 50GB)
    E que não existem infrações pendentes
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITH_REFUND"
    E o reembolso deve ser calculado proporcionalmente aos dias restantes do mês
    E nenhuma multa deve ser incidida (plano mensal)

  # ============================================================================
  # CENÁRIOS: CÁLCULO PROPORCIONAL DE REEMBOLSO (PLANO MENSAL)
  # Regra: Fora do direito de arrependimento, sem infrações, sem limite de dados excedido
  # ============================================================================

  Cenário: Cálculo proporcional correto para fevereiro de ano bissexto (29 dias)
    Dado que estamos em fevereiro de um ano bissexto (29 dias corridos)
    E que um assinante solicitou cancelamento no dia 15 de fevereiro
    E que a assinatura iniciou no dia 1º de fevereiro
    E que o plano contratado é do tipo "MENSAL" com valor mensal de R$ 300,00
    E que o assinante não excedeu o limite de 50GB
    E que não existem infrações
    Quando o sistema calcula o reembolso proporcional
    Então os dias utilizados devem ser 15 dias
    E os dias restantes devem ser 14 dias (29 - 15 = 14)
    E o reembolso bruto deve ser: (300,00 / 29) * 14 = R$ 144,83
    E o status da assinatura deve ser "CANCELLED_WITH_REFUND"

  Cenário: Cálculo proporcional para março com 31 dias
    Dado que estamos em março (31 dias corridos)
    E que um assinante solicitou cancelamento no dia 21 de março
    E que a assinatura iniciou no dia 1º de março
    E que o plano contratado é do tipo "MENSAL" com valor mensal de R$ 250,00
    E que o assinante não excedeu o limite de 50GB
    E que não existem infrações
    Quando o sistema calcula o reembolso proporcional
    Então os dias utilizados devem ser 21 dias
    E os dias restantes devem ser 10 dias (31 - 21 = 10)
    E o reembolso bruto deve ser: (250,00 / 31) * 10 = R$ 80,65
    E o status da assinatura deve ser "CANCELLED_WITH_REFUND"

  Cenário: Cálculo proporcional para abril com 30 dias
    Dado que estamos em abril (30 dias corridos)
    E que um assinante solicitou cancelamento no dia 10 de abril
    E que a assinatura iniciou no dia 5 de abril
    E que o plano contratado é do tipo "MENSAL" com valor mensal de R$ 150,00
    E que o assinante não excedeu o limite de 50GB
    E que não existem infrações
    Quando o sistema calcula o reembolso proporcional
    Então os dias utilizados devem ser 6 dias (10 - 5 = 6)
    E os dias restantes devem ser 20 dias (30 - 10 = 20)
    E o reembolso bruto deve ser: (150,00 / 30) * 20 = R$ 100,00
    E o status da assinatura deve ser "CANCELLED_WITH_REFUND"

  Cenário: Cancelamento no último dia do mês (prorrogação total dos dias utilizados)
    Dado que estamos em junho (30 dias corridos)
    E que um assinante solicitou cancelamento no dia 30 de junho
    E que a assinatura iniciou no dia 1º de junho
    E que o plano contratado é do tipo "MENSAL" com valor mensal de R$ 200,00
    E que o assinante não excedeu o limite de 50GB
    E que não existem infrações
    Quando o sistema calcula o reembolso proporcional
    Então os dias utilizados devem ser 30 dias
    E os dias restantes devem ser 0 dias (30 - 30 = 0)
    E o reembolso bruto deve ser: (200,00 / 30) * 0 = R$ 0,00
    E o status da assinatura deve ser "CANCELLED_WITHOUT_REFUND"

  # ============================================================================
  # CENÁRIOS: NEGAÇÃO DE REEMBOLSO POR LIMITE DE DADOS EXCEDIDO
  # Regra: Após 7 dias + Consumo > 50GB = Reembolso negado (exceto CDC)
  # ============================================================================

  Cenário: Negação de reembolso por excesso de tráfego de dados (50GB+)
    Dado que um assinante está fora do período de direito de arrependimento (10 dias)
    E que a assinatura está no status "ACTIVE"
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 99,00
    E que o assinante consumiu 65GB de tráfego de dados (acima do limite de 50GB)
    E que não existem infrações pendentes
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITHOUT_REFUND"
    E o reembolso bruto deve ser zerado em R$ 0,00
    E nenhuma multa deve ser incidida
    E o reembolso líquido deve ser R$ 0,00
    E o sistema deve retornar os dados: { status: "CANCELLED_WITHOUT_REFUND", refundBrute: 0.00, penalties: 0.00, refundNet: 0.00 }

  Cenário: Negação de reembolso por limite exato de 50GB (não-inclusivo)
    Dado que um assinante está fora do período de direito de arrependimento (12 dias)
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 150,00
    E que o assinante consumiu exatamente 50GB de tráfego de dados
    Quando o assinante solicita cancelamento da assinatura
    Então o reembolso deve ser calculado normalmente (limite não foi ultrapassado)
    E a assinatura deve ser atualizada para o status "CANCELLED_WITH_REFUND"

  Cenário: Negação de reembolso por limite ligeiramente superior a 50GB
    Dado que um assinante está fora do período de direito de arrependimento (14 dias)
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 200,00
    E que o assinante consumiu 50.5GB de tráfego de dados (ultrapassa limite)
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITHOUT_REFUND"
    E o reembolso bruto deve ser zerado em R$ 0,00
    E o reembolso líquido deve ser R$ 0,00

  # ============================================================================
  # CENÁRIOS: NEGAÇÃO DE REEMBOLSO POR INFRAÇÕES NOS TERMOS DE USO
  # Regra: Após 7 dias + Qualquer infração pendente = Reembolso negado
  # ============================================================================

  Cenário: Negação de reembolso por infração única pendente
    Dado que um assinante está fora do período de direito de arrependimento (15 dias)
    E que a assinatura está no status "ACTIVE"
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 120,00
    E que o assinante consumiu 30GB de tráfego de dados (dentro do limite)
    E que existe uma infração pendente nos termos de uso (ex: spam detected)
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITHOUT_REFUND"
    E o reembolso bruto deve ser zerado em R$ 0,00
    E nenhuma multa deve ser incidida
    E o reembolso líquido deve ser R$ 0,00

  Cenário: Negação de reembolso por múltiplas infrações pendentes
    Dado que um assinante está fora do período de direito de arrependimento (20 dias)
    E que o plano contratado é do tipo "MENSAL" com valor de R$ 180,00
    E que o assinante consumiu 40GB de tráfego de dados
    E que existem 3 infrações pendentes nos termos de uso
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITHOUT_REFUND"
    E o reembolso bruto deve ser zerado em R$ 0,00
    E o reembolso líquido deve ser R$ 0,00
    E o sistema deve retornar os dados: { status: "CANCELLED_WITHOUT_REFUND", refundBrute: 0.00, violations: 3 }

  # ============================================================================
  # CENÁRIOS: MULTA RESCISÓRIA PARA PLANO ANUAL (10% DO SALDO RESTANTE)
  # Regra: Cancelamento de Plano Anual implica multa de 10% sobre saldo bruto restante
  # ============================================================================

  Cenário: Multa rescisória em plano anual - cancelamento sem infrações
    Dado que um assinante contratou um plano "ANUAL" por R$ 1.200,00 (100 meses futuros inteiros)
    E que a assinatura iniciou em 1º de janeiro
    E que estamos em 15 de abril (104 dias passados, 261 dias restantes)
    E que o assinante não excedeu o limite de 50GB
    E que não existem infrações pendentes
    Quando o assinante solicita cancelamento da assinatura
    Então os meses futuros inteiros restantes devem ser 8 meses (maio a dezembro)
    E o saldo bruto dos meses futuros deve ser: (1.200,00 / 12) * 8 = R$ 800,00
    E a fração pró-rata do mês atual (abril) deve ser calculada proporcionalmente
    E o saldo bruto total restante deve incluir fração pró-rata + meses inteiros
    E a multa rescisória deve ser 10% do saldo bruto total restante
    E o reembolso líquido deve ser: (saldo bruto total - multa de 10%)

  Cenário: Multa rescisória em plano anual - cancelamento durante primeiros 7 dias
    Dado que um assinante contratou um plano "ANUAL" por R$ 1.200,00
    E que a assinatura iniciou há 3 dias corridos
    E que o assinante possui consumo elevado ou infrações
    Quando o assinante solicita cancelamento dentro do direito de arrependimento
    Então a precedência normativa (CDC) deve ser aplicada
    E nenhuma multa deve ser incidida
    E o reembolso bruto deve ser de R$ 1.200,00 (100%)
    E o reembolso líquido deve ser R$ 1.200,00

  Cenário: Cálculo de multa com fração pró-rata no meio do mês
    Dado que um assinante contratou um plano "ANUAL" por R$ 1.200,00 (R$ 100,00 por mês)
    E que a assinatura iniciou em 1º de maio (data base para ciclo anual)
    E que estamos em 20 de julho (dia 20 do segundo mês do contrato, com 31 dias em julho)
    E que o assinante não tem infrações
    Quando o assinante solicita cancelamento da assinatura
    Então os dias utilizados em julho devem ser 20 dias
    E os dias restantes em julho devem ser 11 dias (31 - 20 = 11)
    E a fração pró-rata de julho deve ser: (100,00 / 31) * 11 = R$ 35,48
    E os meses inteiros restantes após julho devem ser 10 meses (agosto a maio próximo)
    E o saldo bruto total restante deve ser: 35,48 + (100,00 * 10) = R$ 1.035,48
    E a multa rescisória deve ser: 1.035,48 * 0.10 = R$ 103,55
    E o reembolso bruto deve ser R$ 1.035,48
    E o reembolso líquido deve ser: 1.035,48 - 103,55 = R$ 931,93

  Cenário: Multa anual com infrações e dados excedidos (reembolso negado)
    Dado que um assinante contratou um plano "ANUAL" por R$ 1.200,00
    E que está fora do período de direito de arrependimento
    E que consumiu mais de 50GB de tráfego
    E que existem infrações pendentes
    Quando o assinante solicita cancelamento da assinatura
    Então a assinatura deve ser atualizada para o status "CANCELLED_WITHOUT_REFUND"
    E o reembolso bruto deve ser zerado em R$ 0,00
    E a multa rescisória não deve ser incidida (pois não há reembolso a descontar)
    E o reembolso líquido deve ser R$ 0,00

  # ============================================================================
  # CENÁRIOS: SITUAÇÕES CRÍTICAS E EDGE CASES
  # ============================================================================

  Cenário: Cancelamento solicitado após encerramento automático (status encerrado)
    Dado que uma assinatura já foi encerrada automaticamente pelo sistema
    E que o status atual é "EXPIRED" ou "SYSTEM_CANCELLED"
    Quando o assinante tenta solicitar cancelamento
    Então o sistema deve retornar erro "SUBSCRIPTION_ALREADY_CLOSED"
    E nenhuma ação de cancelamento deve ser processada

  Cenário: Cancelamento com assinatura em status de suspensão temporária
    Dado que uma assinatura está no status "SUSPENDED" (devido a pagamento pendente)
    E que o assinante não está dentro do direito de arrependimento
    Quando o assinante solicita cancelamento
    Então o sistema deve permitir o cancelamento
    E o cálculo de reembolso deve considerar o status anterior
    E a assinatura deve transicionar para "CANCELLED_WITH_REFUND" ou "CANCELLED_WITHOUT_REFUND"

  Cenário: Reembolso zero para assinante que utilizou todo o mês
    Dado que um assinante solicitou cancelamento no dia 1º do mês seguinte (ao término do ciclo)
    E que o período de cobrança já foi encerrado
    Quando o sistema calcula o reembolso proporcional
    Então não deve haver dias restantes a reembolsar
    E o reembolso deve ser R$ 0,00
    E a assinatura deve transicionar para "CANCELLED_WITHOUT_REFUND"

  Cenário: Cancelamento com valor de reembolso negativo (não permitido)
    Dado que por algum motivo o cálculo resulta em valor negativo
    Quando o sistema processa o cancelamento
    Então o reembolso deve ser normalizado para R$ 0,00 (piso de zero)
    E o sistema deve registrar um log de alerta sobre o cálculo anômalo

  # ============================================================================
  # CENÁRIOS: VALIDAÇÃO DE DADOS DE SAÍDA
  # Estrutura esperada: { status, refundBrute, refundNet, penalties, daysUsed, daysRemaining, violations }
  # ============================================================================

  Cenário: Resposta do sistema contém todos os campos obrigatórios
    Dado que um cancelamento foi solicitado e processado com sucesso
    Quando o sistema retorna a resposta
    Então a resposta deve conter os seguintes campos obrigatórios:
      | Campo              | Tipo      | Descrição                                |
      | status             | STRING    | CANCELLED_WITH_REFUND, CANCELLED_WITHOUT_REFUND ou CANCELLED |
      | refundBrute        | DECIMAL   | Valor bruto do reembolso (sem multas)   |
      | refundNet          | DECIMAL   | Valor líquido do reembolso (com multas descontadas) |
      | penalties          | DECIMAL   | Multa rescisória aplicada (plano anual) |
      | daysUsed           | INTEGER   | Dias consumidos no período              |
      | daysRemaining      | INTEGER   | Dias restantes a reembolsar             |
      | violations         | INTEGER   | Quantidade de infrações pendentes       |
      | subscriptionType   | STRING    | MONTHLY ou ANNUAL                       |

  Cenário: Validação de precisão decimal para reembolsos
    Dado que um reembolso foi calculado com fração de centavos
    Quando o sistema retorna o valor
    Então o reembolso deve ser arredondado para 2 casas decimais (padrão monetário)
    E o arredondamento deve seguir a regra bancária (half-up)

  # ============================================================================
  # CENÁRIOS: TRANSIÇÕES DE ESTADO
  # ============================================================================

  Cenário: Transição de estado de ACTIVE para CANCELLED_WITH_REFUND
    Dado que uma assinatura está no estado "ACTIVE"
    Quando um cancelamento com reembolso é aprovado
    Então a assinatura deve transicionar diretamente para "CANCELLED_WITH_REFUND"
    E a data de cancelamento deve ser registrada com timestamp UTC
    E um evento de auditoria deve ser criado com todos os detalhes do cálculo

  Cenário: Transição de estado de ACTIVE para CANCELLED_WITHOUT_REFUND
    Dado que uma assinatura está no estado "ACTIVE"
    Quando um cancelamento sem reembolso é aplicado
    Então a assinatura deve transicionar diretamente para "CANCELLED_WITHOUT_REFUND"
    E a data de cancelamento deve ser registrada com timestamp UTC
    E um evento de auditoria deve ser criado

  Cenário: Impossibilidade de transição reversa (cancelamento é irreversível)
    Dado que uma assinatura foi cancelada com status "CANCELLED_WITH_REFUND"
    Quando o assinante tenta reativar a assinatura
    Então o sistema deve rejeitar a operação
    E retornar erro "SUBSCRIPTION_CANCELLATION_IRREVERSIBLE"
    E o status deve permanecer "CANCELLED_WITH_REFUND"

  # ============================================================================
  # CENÁRIOS: INTEGRAÇÃO COM MEIOS DE PAGAMENTO
  # ============================================================================

  Cenário: Reembolso creditado como Saldo na Plataforma
    Dado que um cancelamento com reembolso foi aprovado no valor de R$ 85,50
    E que o assinante optou por crédito em conta na plataforma
    Quando o sistema processa o reembolso
    Então um saldo de R$ 85,50 deve ser creditado à conta do assinante
    E o saldo deve ser registrado como "Platform Credit"
    E esse crédito pode ser utilizado em futuras contratações

  Cenário: Reembolso estornado via PIX
    Dado que um cancelamento com reembolso foi aprovado no valor de R$ 150,00
    E que o assinante optou por estorno via PIX
    Quando o sistema entra em fila de processamento de reembolsos
    Então uma transação de PIX deve ser iniciada com os dados bancários do assinante
    E o status do reembolso deve ficar "PENDING_PIX_TRANSFER"
    E após confirmação do PIX, o status deve transicionar para "REFUND_COMPLETED"

  Cenário: Reembolso mínimo não processável (< R$ 1,00)
    Dado que o cálculo resultou em reembolso de R$ 0,50
    Quando o sistema valida o valor mínimo de processamento
    Então o sistema deve considerar o reembolso como R$ 0,00
    E não deve iniciar nenhuma transação de PIX
    E um notificação deve ser enviada ao assinante informando a impossibilidade de processamento
