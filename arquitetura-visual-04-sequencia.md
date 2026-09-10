# Diagrama 4: Sequência – Cenários Críticos

## Cenário A: CDC (7 dias) – Reembolso 100% Imediato

```mermaid
sequenceDiagram
    participant Assinante
    participant Frontend
    participant Motor as Motor de<br/>Cancelamento
    participant Banco as Banco de Dados<br/>Assinatura
    participant Calc as Calculadora<br/>Refund
    participant Audit as Auditoria
    participant Payment as Payment<br/>Gateway (PIX)
    
    Assinante ->> Frontend: Clica "Cancelar Assinatura"
    Frontend ->> Motor: POST /api/subscriptions/{id}/cancel<br/>{reason: "..."}
    
    Motor ->> Banco: GET subscription WHERE id=...
    Banco -->> Motor: {id, created_at, monthly_price,<br/>status: ACTIVE, plan_type: MENSAL}
    
    Motor ->> Calc: ValidateCDC(created_at, now)
    Calc ->> Calc: dias_elapsed = (now - created_at).days
    Calc -->> Motor: ✅ CDC_ELIGIBLE (dias_elapsed=5)
    
    Note over Motor, Calc: 🔴 BYPASS de todas as<br/>validações (CDC override)
    
    Motor ->> Calc: CalculateRefund(subscription)<br/>cdc_eligible=TRUE
    Calc ->> Calc: refund_brute = monthly_price<br/>(100% CDC)<br/>penalties = 0<br/>refund_net = 100%
    Calc -->> Motor: {refund_brute: 99.00,<br/>penalties: 0, refund_net: 99.00}
    
    Motor ->> Banco: UPDATE subscription<br/>status='CANCELLED_WITH_REFUND'<br/>cancelled_at=NOW
    Banco -->> Motor: ✅ Updated
    
    Motor ->> Audit: LogEvent(subscription_id,<br/>event: CDC_REFUND_APPROVED)<br/>details: {refund_brute, penalties,<br/>cdc_eligible: true}
    Audit -->> Motor: ✅ Logged
    
    Motor ->> Payment: CreateRefundTransaction<br/>(subscription_id, 99.00, PIX)
    Payment -->> Motor: {transaction_id, status:<br/>PENDING_PIX_TRANSFER}
    
    Note over Payment: PIX STP Processing
    Payment ->> Payment: Enfileirar para processamento
    
    Motor ->> Frontend: {status: 200,<br/>subscription_status: CANCELLED_WITH_REFUND,<br/>refund_net: 99.00,<br/>transaction_id, method: PIX}
    
    Frontend -->> Assinante: ✅ Cancelamento Processado<br/>Reembolso de R$ 99,00<br/>será transferido via PIX<br/>em até 2 horas
    
    Note over Payment: (Async) PIX é confirmado pelo banco
    Payment ->> Banco: UPDATE refund_transaction<br/>status=COMPLETED
    Banco -->> Payment: ✅
    
    Payment -->> Assinante: 📧 Email: Reembolso<br/>transferido com sucesso
```

---

## Cenário B: Pós-CDC com Dados Excedidos – Refund Negado

```mermaid
sequenceDiagram
    participant Assinante
    participant Frontend
    participant Motor as Motor de<br/>Cancelamento
    participant Banco as Banco de Dados
    participant DataUsage as Data Usage<br/>Service
    participant Calc as Calculadora<br/>Refund
    participant Audit as Auditoria
    
    Assinante ->> Frontend: Clica "Cancelar Assinatura"
    Frontend ->> Motor: POST /api/subscriptions/{id}/cancel
    
    Motor ->> Banco: GET subscription WHERE id=...
    Banco -->> Motor: {id, created_at (10 dias atrás),<br/>status: ACTIVE}
    
    Motor ->> Calc: ValidateCDC(created_at, now)
    Calc ->> Calc: dias_elapsed = 10
    Calc -->> Motor: ❌ CDC_NOT_ELIGIBLE<br/>(> 7 dias)
    
    Note over Motor: Aplicar validações<br/>operacionais
    
    Motor ->> DataUsage: GetDataUsage(subscription_id,<br/>year_month=202409)
    DataUsage -->> Motor: {total_gb_consumed: 65.2,<br/>limit_gb: 50.0}
    
    Motor ->> Motor: Verificar:<br/>65.2 > 50.0? ✅ SIM
    
    Motor ->> Calc: CalculateRefund(subscription)<br/>cdc_eligible=FALSE<br/>data_overage=TRUE
    Calc ->> Calc: ❌ REFUND DENIED<br/>refund_brute = 0<br/>penalties = 0<br/>refund_net = 0
    Calc -->> Motor: {refund_brute: 0,<br/>penalties: 0, refund_net: 0,<br/>denial_reason: OVERAGE_DATA}
    
    Motor ->> Banco: UPDATE subscription<br/>status='CANCELLED_WITHOUT_REFUND'<br/>cancelled_at=NOW
    Banco -->> Motor: ✅ Updated
    
    Motor ->> Audit: LogEvent(subscription_id,<br/>event: REFUND_DENIED)<br/>details: {reason: OVERAGE_DATA,<br/>consumed_gb: 65.2,<br/>limit_gb: 50.0}
    Audit -->> Motor: ✅ Logged
    
    Note over Motor: ⛔ Sem criação de transação<br/>pois refund_net = 0
    
    Motor ->> Frontend: {status: 200,<br/>subscription_status: CANCELLED_WITHOUT_REFUND,<br/>refund_net: 0.00,<br/>denial_reason: DATA_OVERAGE}
    
    Frontend -->> Assinante: ⚠️ Cancelamento Processado<br/>Sem Reembolso<br/>Motivo: Limite de dados<br/>excedido (65.2GB > 50GB)
    
    Assinante -->> Frontend: 😞 Visualiza histórico<br/>de consumo
```

---

## Cenário C: Pós-CDC sem Violações – Reembolso Proporcional (Mensal)

```mermaid
sequenceDiagram
    participant Assinante
    participant Frontend
    participant Motor
    participant Banco
    participant Violations as Violations<br/>Service
    participant Calendar as Calendar<br/>Service
    participant Calc as Calculadora
    participant Audit
    
    Assinante ->> Frontend: Cancelar Assinatura
    Frontend ->> Motor: POST /api/subscriptions/{id}/cancel
    
    Motor ->> Banco: GET subscription
    Banco -->> Motor: {created_at: 15 dias atrás,<br/>monthly_price: 250.00,<br/>plan_type: MONTHLY,<br/>status: ACTIVE}
    
    Motor ->> Calc: ValidateCDC(created_at, now)
    Calc -->> Motor: ❌ CDC_NOT_ELIGIBLE (15 dias)
    
    Motor ->> Violations: GetViolations(subscription_id,<br/>status=PENDING)
    Violations -->> Motor: [] (empty, sem infrações)
    
    Motor ->> Banco: GetDataUsage(subscription_id,<br/>202409)
    Banco -->> Motor: {total_gb: 45.0} ✅ OK
    
    Motor ->> Calendar: GetMonthInfo(2024, 9)
    Calendar -->> Motor: {days_in_month: 30,<br/>current_day: 21}
    
    Motor ->> Calc: CalculateRefund<br/>(subscription, month_info)
    Calc ->> Calc: dias_utilizados = 21<br/>dias_restantes = 30 - 21 = 9<br/>refund_brute = (250 / 30) × 9<br/>= 8.33 × 9 = 75.00<br/>penalties = 0 (MONTHLY)<br/>refund_net = 75.00
    Calc -->> Motor: {refund_brute: 75.00,<br/>penalties: 0, refund_net: 75.00,<br/>days_used: 21, days_remaining: 9}
    
    Motor ->> Banco: UPDATE subscription<br/>status=CANCELLED_WITH_REFUND
    Banco -->> Motor: ✅
    
    Motor ->> Audit: LogEvent<br/>event: REFUND_APPROVED_PROPORTIONAL<br/>details: {refund_brute: 75.00,<br/>days_used: 21, days_total: 30,<br/>calculation_formula: '(250/30)*9'}
    Audit -->> Motor: ✅
    
    Motor ->> Motor: Verificar refund_net ≥ 1.00?<br/>75.00 >= 1.00? ✅ SIM
    
    Motor ->> Motor: Criar REFUND_TRANSACTION<br/>amount=75.00, method=PIX
    Motor ->> Banco: INSERT refund_transaction<br/>{..., status: PENDING_PIX_TRANSFER}
    Banco -->> Motor: ✅
    
    Motor ->> Frontend: {status: 200,<br/>subscription_status: CANCELLED_WITH_REFUND,<br/>refund_net: 75.00,<br/>days_remaining: 9}
    
    Frontend -->> Assinante: ✅ Cancelamento Processado<br/>Reembolso Proporcional:<br/>R$ 75,00<br/>(21 dias usados de 30 no mês)
```

---

## Cenário D: Plano ANUAL com Multa Rescisória

```mermaid
sequenceDiagram
    participant Assinante
    participant Motor
    participant Banco
    participant Calc as Calculadora
    participant Audit
    
    Assinante ->> Motor: Solicitar Cancelamento
    
    Motor ->> Banco: GET subscription<br/>plan_type=ANNUAL,<br/>annual_price=1200.00,<br/>created_at=01/mai/2024
    Banco -->> Motor: ✅
    
    Motor ->> Calc: ValidateCDC<br/>dias_elapsed = 120 (4 meses)
    Calc -->> Motor: ❌ CDC_NOT_ELIGIBLE
    
    Motor ->> Motor: Validações OK<br/>(sem infrações, dados OK)
    
    Motor ->> Calc: CalculateRefund<br/>(annual_subscription, requested_at=20/set/2024)
    
    Note over Calc: CÁLCULO ANUAL COMPLETO:<br/>1. Ciclo anual: mai/2024 - abr/2025<br/>2. Hoje: 20 de setembro (dentro do ciclo)<br/>3. Meses inteiros restantes:<br/>&nbsp;&nbsp; out(31), nov(30), dez(31),<br/>&nbsp;&nbsp; jan(31), fev(28), mar(31), abr(30)<br/>&nbsp;&nbsp; = 7 meses<br/>4. Fração pró-rata de setembro:<br/>&nbsp;&nbsp; dias_restantes = 30 - 20 = 10<br/>&nbsp;&nbsp; fração = (1200/12)/30 × 10<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; = (100/30) × 10 = 33.33<br/>5. Saldo total restante:<br/>&nbsp;&nbsp; (100 × 7) + 33.33 = 733.33<br/>6. Multa rescisória 10%:<br/>&nbsp;&nbsp; penalty = 733.33 × 0.10 = 73.33<br/>7. Reembolso Líquido:<br/>&nbsp;&nbsp; refund_net = 733.33 - 73.33<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; = 660.00
    
    Calc -->> Motor: {refund_brute: 733.33,<br/>penalties: 73.33,<br/>refund_net: 660.00,<br/>penalty_reason: ANNUAL_RESCISSORY_10_PERCENT}
    
    Motor ->> Banco: UPDATE subscription<br/>status=CANCELLED_WITH_REFUND
    Banco -->> Motor: ✅
    
    Motor ->> Audit: LogEvent<br/>details: {plan_type: ANNUAL,<br/>remaining_balance: 733.33,<br/>penalty_rate: 0.10,<br/>penalty_amount: 73.33}
    Audit -->> Motor: ✅
    
    Motor ->> Motor: Criar transação: 660.00
    
    Motor ->> Assinante: ✅ Cancelamento Processado<br/>Reembolso Líquido: R$ 660,00<br/>(-) Multa Rescisória 10%: R$ 73,33
```

---

## Fluxo de Exceção: Subscription Já Cancelada

```mermaid
sequenceDiagram
    participant Assinante
    participant Motor
    participant Banco
    
    Assinante ->> Motor: POST /cancel
    
    Motor ->> Banco: GET subscription
    Banco -->> Motor: {status: CANCELLED_WITH_REFUND,<br/>cancelled_at: 2024-09-10}
    
    Motor ->> Motor: ❌ Verificação de Status<br/>Status != ACTIVE?
    
    Motor ->> Assinante: {status: 409 CONFLICT,<br/>error: SUBSCRIPTION_ALREADY_CLOSED,<br/>message: "Assinatura já foi<br/>cancelada em 10 de setembro"}
```
