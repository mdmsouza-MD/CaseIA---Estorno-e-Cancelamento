# Diagrama 2: Entidades e Relacionamentos (ERD)

## Modelo de Dados – Motor de Cancelamento SaaS

```mermaid
erDiagram
    SUBSCRIPTION ||--o{ CANCELLATION_REQUEST : initiates
    SUBSCRIPTION ||--o{ DATA_USAGE : tracks
    SUBSCRIPTION ||--o{ VIOLATION : has
    SUBSCRIPTION ||--o{ REFUND_TRANSACTION : generates
    SUBSCRIPTION ||--o{ AUDIT_LOG : produces
    
    CANCELLATION_REQUEST ||--|| REFUND_CALCULATION : triggers
    REFUND_CALCULATION ||--o{ REFUND_TRANSACTION : creates
    
    SUBSCRIBER ||--o{ SUBSCRIPTION : owns
    REFUND_TRANSACTION ||--|| PAYMENT_METHOD : uses

    %% Entidade: SUBSCRIBER
    SUBSCRIBER {
        string subscriber_id PK
        string email UK
        string name
        timestamp created_at
        string payment_method_type "PIX, CARD, BANK_TRANSFER"
        timestamp updated_at
    }

    %% Entidade: SUBSCRIPTION
    SUBSCRIPTION {
        string subscription_id PK
        string subscriber_id FK
        string status "ACTIVE, SUSPENDED, CANCELLED_WITH_REFUND, CANCELLED_WITHOUT_REFUND, EXPIRED"
        string plan_type "MONTHLY, ANNUAL"
        decimal monthly_price
        decimal annual_price
        timestamp created_at "Data de início da assinatura"
        timestamp cancelled_at
        int days_in_cycle "28-31, calculado dinamicamente"
        timestamp updated_at
    }

    %% Entidade: DATA_USAGE
    DATA_USAGE {
        string data_usage_id PK
        string subscription_id FK
        int year_month "YYYYMM"
        decimal total_gb_consumed
        decimal limit_gb "50.0"
        boolean exceeded "total_gb_consumed > 50.0"
        timestamp recorded_at
    }

    %% Entidade: VIOLATION
    VIOLATION {
        string violation_id PK
        string subscription_id FK
        string violation_type "SPAM_DETECTED, TERMS_ABUSE, PAYMENT_FRAUD, etc"
        string status "PENDING, RESOLVED, DISMISSED"
        timestamp created_at
        timestamp resolved_at
    }

    %% Entidade: CANCELLATION_REQUEST
    CANCELLATION_REQUEST {
        string request_id PK
        string subscription_id FK
        string reason "USER_CHOICE, SERVICE_ISSUE, COMPETITOR, etc"
        timestamp requested_at "UTC"
        string requested_by "subscriber_id ou admin_id"
        string status "PENDING, APPROVED, REJECTED, PROCESSING"
    }

    %% Entidade: REFUND_CALCULATION
    REFUND_CALCULATION {
        string calc_id PK
        string cancellation_request_id FK
        string subscription_id FK
        
        int days_used
        int days_total_in_month
        int days_remaining
        
        decimal monthly_fee
        decimal refund_brute "reembolso bruto (100% ou proporcional)"
        decimal penalty_rescissory "10% do saldo restante (plano anual)"
        decimal refund_net "refund_brute - penalty"
        
        string cdc_eligible "YES se dentro de 7 dias"
        string violation_reason "null se aprovado; OVERAGE_DATA, VIOLATION_PENDING se negado"
        
        timestamp calculated_at
        string calculated_by "MOTOR_AUTOMATICO ou MANUAL"
    }

    %% Entidade: REFUND_TRANSACTION
    REFUND_TRANSACTION {
        string transaction_id PK
        string subscription_id FK
        string refund_calc_id FK
        decimal amount
        string type "PIX, PLATFORM_CREDIT, BANK_TRANSFER"
        string status "PENDING_PIX_TRANSFER, PROCESSING, COMPLETED, FAILED, CANCELLED"
        string pix_key
        string bank_account
        timestamp initiated_at
        timestamp completed_at
        string failure_reason
        timestamp updated_at
    }

    %% Entidade: PAYMENT_METHOD
    PAYMENT_METHOD {
        string payment_method_id PK
        string subscriber_id FK
        string method_type "PIX, CREDIT_CARD, BANK_ACCOUNT"
        string pix_key "CPF@pix, email@pix, aleatoria@pix, telefone@pix"
        string account_holder_name
        string account_number
        string bank_code
        boolean is_default
        timestamp created_at
        timestamp updated_at
    }

    %% Entidade: AUDIT_LOG
    AUDIT_LOG {
        string audit_id PK
        string subscription_id FK
        string event_type "CANCELLATION_REQUESTED, REFUND_APPROVED, REFUND_DENIED, STATE_TRANSITION, etc"
        string actor "subscriber_id, system, admin_id"
        string old_state
        string new_state
        text details_json "Snapshot completo do cálculo e decisão"
        timestamp event_at "UTC"
        string ip_address
    }
```

## Relacionamentos Críticos

### 1️⃣ **SUBSCRIPTION** ↔ **DATA_USAGE**
- 1 assinatura pode ter múltiplos registros de consumo (1 por mês)
- Campo `exceeded` é **booleano calculado** (total_gb_consumed > 50.0)
- Índice: `(subscription_id, year_month)`

### 2️⃣ **SUBSCRIPTION** ↔ **VIOLATION**
- 1 assinatura pode ter múltiplas violações pendentes
- Status `PENDING` é critério de negação de refund
- Qualquer `PENDING` implica refund = R$ 0,00 (fora do CDC)

### 3️⃣ **CANCELLATION_REQUEST** → **REFUND_CALCULATION**
- 1:1 Obrigatório (toda solicitação gera cálculo)
- Cálculo inclui **todas as variáveis** necessárias para auditoria
- `cdc_eligible` é determinístico: `datetime.now() - subscription.created_at ≤ 7 dias`

### 4️⃣ **REFUND_CALCULATION** → **REFUND_TRANSACTION**
- 1:1 se refund aprovado (refund_net > 0.01)
- 1:0 se refund negado (refund_net = 0.00) → não cria transação

### 5️⃣ **REFUND_TRANSACTION** ↔ **PAYMENT_METHOD**
- Múltiplas transações podem usar mesma payment_method
- Índice: `(subscriber_id, is_default=true)`

### 6️⃣ **AUDIT_LOG** (Rastreabilidade)
- **Requisito legal:** Todas as operações devem ser auditadas
- `details_json` = snapshot completo do cálculo (refund_brute, penalty, cdc_eligible, violation_reason)
- Garantir **imutabilidade** de audit_log (apenas INSERT, nunca UPDATE/DELETE)

## Constraints Críticos

```sql
-- CDC Precedence Constraint
CONSTRAINT chk_cdc_precedence:
  IF (days_since_creation <= 7 AND subscription.status IN ('ACTIVE', 'SUSPENDED'))
  THEN refund_calculation.refund_brute = subscription.monthly_price
  AND refund_calculation.penalty_rescissory = 0
  
-- Refund Denial Logic
CONSTRAINT chk_refund_denial:
  IF (days_since_creation > 7)
    AND (data_usage.total_gb_consumed > 50.0 OR violation.status = 'PENDING')
  THEN refund_calculation.refund_net = 0.00

-- Irreversibility
CONSTRAINT chk_irreversible_cancellation:
  IF subscription.status IN ('CANCELLED_WITH_REFUND', 'CANCELLED_WITHOUT_REFUND')
  THEN NO UPDATE TO status, NO transition back to ACTIVE

-- Decimal Precision
CONSTRAINT chk_decimal_precision:
  ALL monetary fields (price, refund, penalty) = DECIMAL(10,2)
  Rounding rule: ROUND_HALF_UP (banker's rounding)
```
