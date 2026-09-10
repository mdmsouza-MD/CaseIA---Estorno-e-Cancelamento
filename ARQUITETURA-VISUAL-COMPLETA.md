# 🏛️ Motor de Cancelamento SaaS – Arquitetura Visual Completa

## Índice de Diagramas (Mermaid.js)

Conjunto de 6 diagramas arquiteturais em Diagram-as-Code para o sistema de **Cancelamento e Estorno de Assinatura SaaS**, baseado na especificação BDD completa em `motor-cancelamento-estorno.feature`.

---

## 📋 Lista de Arquivos

### 1️⃣ **Diagrama de Máquina de Estados**
**Arquivo:** `arquitetura-visual-01-maquina-estados.md`  
**Tamanho:** 2.5 KB  
**Descrição:** Ciclo de vida da assinatura com transições, precedência normativa CDC e irreversibilidade  
**Uso:** Product, Design, QA — entender fluxos de status  
**Mermaid Type:** `stateDiagram-v2`  

**Principais Estados:**
- `ACTIVE` → Assinatura ativa, elegível para cancelamento
- `CANCELLED_WITH_REFUND` → Reembolso aprovado, irreversível
- `CANCELLED_WITHOUT_REFUND` → Reembolso negado, irreversível
- `SUSPENDED` → Bloqueada temporariamente (pagamento)
- `EXPIRED` → Encerrada automaticamente

---

### 2️⃣ **Diagrama Entidade-Relacionamento (ERD)**
**Arquivo:** `arquitetura-visual-02-erd.md`  
**Tamanho:** 6.8 KB  
**Descrição:** Schema completo de banco de dados com 8 entidades, relacionamentos 1:N, constraints e índices  
**Uso:** Arquitetos, Desenvolvedores Backend — implementar BD PostgreSQL  
**Mermaid Type:** `erDiagram`  

**Entidades Principais:**
- `SUBSCRIPTION` — Assinatura (plano MENSAL/ANUAL, valor, status)
- `REFUND_CALCULATION` — Cálculo de reembolso (refund_brute, penalty, refund_net)
- `REFUND_TRANSACTION` — Transação PIX/Platform Credit
- `DATA_USAGE` — Consumo mensal GB
- `VIOLATION` — Infrações pendentes
- `AUDIT_LOG` — Rastreabilidade legal

---

### 3️⃣ **Diagrama de Fluxo de Decisão (Swimlanes)**
**Arquivo:** `arquitetura-visual-03-fluxo-decisao.md`  
**Tamanho:** 8.1 KB  
**Descrição:** Algoritmo completo de cancelamento com 4 caminhos principais (CDC, Dados, Infrações, Pagamento)  
**Uso:** Desenvolvedores — implementar lógica de negócio  
**Mermaid Type:** `flowchart TD`  

**Paths Principais:**
1. **CDC (7 dias)** → 100% refund + bypass validações
2. **Dados > 50GB** → Refund negado (R$ 0,00)
3. **Infrações PENDING** → Refund negado (R$ 0,00)
4. **Aprovado** → Calcular proporcional + multa anual + pagamento

---

### 4️⃣ **Diagrama de Sequência**
**Arquivo:** `arquitetura-visual-04-sequencia.md`  
**Tamanho:** 9.6 KB  
**Descrição:** 4 cenários críticos (CDC, Dados, Proporcional, Anual) + 1 exceção, com interações entre componentes  
**Uso:** QA, Arquitetos — entender fluxo de interação entre serviços  
**Mermaid Type:** `sequenceDiagram`  

**Cenários:**
- **A:** CDC (7 dias) → 100% refund automático
- **B:** Dados excedidos → Refund negado
- **C:** Proporcional mensal → Cálculo exato
- **D:** Anual com multa rescisória (10%)
- **Exceção:** Assinatura já cancelada (erro 409)

---

### 5️⃣ **Diagrama de Arquitetura de Componentes**
**Arquivo:** `arquitetura-visual-05-componentes.md`  
**Tamanho:** 11.7 KB  
**Descrição:** Arquitetura em camadas (Presentation, API, Business Logic, Services, Persistence, Payment, Async)  
**Uso:** Arquitetos, Tech Leads — design review, deployment topology  
**Mermaid Type:** `graph TB` (subgraphs)  

**Camadas:**
1. **Presentation** — Web, Mobile, Admin
2. **API Gateway** — Auth, Rate Limiting
3. **Motor Cancelamento** — CDC Validator, Operational Validator, Refund Calculator, State Transitioner
4. **Services** — DataUsageService, ViolationService, AuditService, CalendarService
5. **Persistence** — PostgreSQL, Redis Cache
6. **Payment** — PIX STP, Platform Credit
7. **Async** — Message Queue (RabbitMQ/Kafka), Workers
8. **External** — Banking API, Notifications, Logging

**Padrões Implementados:**
- Strategy Pattern (RefundCalculator)
- Chain of Responsibility (Validators)
- Event Sourcing (Auditoria)
- Asynchronous Processing (Fila)

---

### 6️⃣ **Matriz de Decisão (Heatmap)**
**Arquivo:** `arquitetura-visual-06-matriz-decisao.md`  
**Tamanho:** 9.0 KB  
**Descrição:** Cobertura exaustiva de combinações CDC × Dados × Infrações → Resultado, com 14 linhas de test matrix  
**Uso:** QA, Testes — garantir cobertura 100% de paths  
**Mermaid Type:** `graph LR` + Tabelas markdown  

**Combinações Cobertas:**
- CDC=SIM (qualquer Dados/Infrações) → 100% refund
- CDC=NÃO + Dados ≤ 50GB + Sem Infrações → Proporcional
- CDC=NÃO + Dados > 50GB → Refund negado
- CDC=NÃO + Infrações PENDING → Refund negado
- ANUAL com/sem multa rescisória (10%)
- Edge cases (expirada, suspensa, zero, negativo)

**Cobertura BDD:** 29 cenários determinísticos = 100% de paths

---

## 🎯 Guia de Uso Rápido

### Para Começar (Onboarding)
```
1. Leia: arquitetura-visual-01-maquina-estados.md
   ↓ Entender ciclo de vida
2. Leia: arquitetura-visual-06-matriz-decisao.md
   ↓ Ver todas as combinações
3. Leia: arquitetura-visual-03-fluxo-decisao.md
   ↓ Entender lógica de decisão
```

### Para Implementar Backend
```
1. Leia: arquitetura-visual-02-erd.md
   ↓ Criar schema PostgreSQL
2. Leia: arquitetura-visual-03-fluxo-decisao.md
   ↓ Implementar motores de cálculo
3. Leia: arquitetura-visual-04-sequencia.md
   ↓ Implementar orquestração
```

### Para Testar (QA/Testes)
```
1. Leia: arquitetura-visual-06-matriz-decisao.md
   ↓ Validar cobertura de cenários
2. Leia: arquitetura-visual-04-sequencia.md
   ↓ Criar testes de integração
3. Leia: motor-cancelamento-estorno.feature
   ↓ Executar testes BDD
```

### Para Validar Arquitetura
```
1. Leia: arquitetura-visual-05-componentes.md
   ↓ Design review com time
2. Leia: arquitetura-visual-01-maquina-estados.md
   ↓ Validar transições
3. Leia: arquitetura-visual-02-erd.md
   ↓ Validar model relationships
```

---

## 📊 Estatísticas dos Diagramas

| Aspecto | Quantidade |
|---|---|
| **Total de Arquivos** | 6 diagrams + 1 feature + 1 índice |
| **Total de Diagramas Mermaid** | 15+ (múltiplos por arquivo) |
| **Linhas de Código Total** | ~2,500 linhas |
| **Tamanho Total** | ~48 KB |
| **Cenários BDD Cobertos** | 29 (motor-cancelamento-estorno.feature) |
| **Combinações Testadas** | 14+ (matriz-decisao) |
| **Camadas Arquiteturais** | 8 (componentes) |
| **Entidades BD** | 8 (ERD) |
| **Estados de Assinatura** | 5 (máquina-estados) |
| **Validators** | 3 (CDCValidator, OperationalValidator, RefundCalculator) |

---

## 🔄 Rastreabilidade: Diagramas ↔ BDD ↔ Código

### Exemplo: Cenário "Cancelamento dentro de 7 dias"

**BDD Spec** (`motor-cancelamento-estorno.feature`):
```gherkin
Cenário: Cancelamento dentro do direito de arrependimento (7 dias corridos)
  Dado que um assinante iniciou sua assinatura há 5 dias corridos
  E que a assinatura está no status "ACTIVE"
  ...
  Quando o assinante solicita cancelamento imediato da assinatura
  Então a assinatura deve ser atualizada para o status "CANCELLED_WITH_REFUND"
  E o reembolso bruto aprovado deve ser de R$ 99,00 (100% do valor pago)
```

↓ **Mapped to Diagram 1 (States):**
```mermaid
ACTIVE --> CANCELLED_WITH_REFUND: Cancelamento Aprovado\n(CDC ou Sem Infrações/Dados)
```

↓ **Mapped to Diagram 3 (Flow):**
```mermaid
CDC_Check -->|SIM dias ≤ 7| CDC_Path["✅ CDC APLICÁVEL"]
CDC_Path --> CDC_Refund["💰 Reembolso = 100%"]
```

↓ **Mapped to Diagram 4 (Sequence):**
```mermaid
Motor ->> Calc: ValidateCDC(created_at, now)
Calc -->> Motor: ✅ CDC_ELIGIBLE (dias_elapsed=5)
Motor ->> Calc: CalculateRefund(subscription) cdc_eligible=TRUE
```

↓ **Mapped to Diagram 6 (Matrix):**
```
| # | CDC | Consumo | Infrações | Resultado | Refund |
|1  | ✅  | 75      | Sim       | ✅ APROV  | 99,00  |
```

↓ **Implementation Code** (Python/Java/TypeScript):
```python
def process_cancellation(subscription_id, requested_at):
    subscription = get_subscription(subscription_id)
    days_elapsed = (requested_at - subscription.created_at).days
    
    if days_elapsed <= 7:  # CDC Check
        refund_brute = subscription.monthly_price  # 100%
        status = "CANCELLED_WITH_REFUND"
        create_refund_transaction(subscription_id, refund_brute, status)
        return status, refund_brute, 0, refund_brute
```

---

## 📁 Estrutura de Diretórios Recomendada

```
CaseAT/
├── motor-cancelamento-estorno.feature          (Especificação BDD)
├── ARQUITETURA-VISUAL-COMPLETA.md              (Este arquivo - Índice)
├── arquitetura-visual-01-maquina-estados.md
├── arquitetura-visual-02-erd.md
├── arquitetura-visual-03-fluxo-decisao.md
├── arquitetura-visual-04-sequencia.md
├── arquitetura-visual-05-componentes.md
├── arquitetura-visual-06-matriz-decisao.md
└── src/
    ├── models/
    │   ├── subscription.py           (← ERD diagram 2)
    │   ├── refund_calculation.py     (← Flow diagram 3)
    │   └── audit_log.py
    ├── services/
    │   ├── cancellation_motor.py     (← Sequence diagram 4)
    │   ├── refund_calculator.py      (← Flow diagram 3)
    │   ├── validators.py             (← Component diagram 5)
    │   └── payment_gateway.py        (← Component diagram 5)
    └── tests/
        ├── test_cdc_validator.py     (← Matrix diagram 6)
        ├── test_refund_calculation.py
        └── test_integration.py       (← Sequence diagram 4)
```

---

## 🚀 Próximas Etapas

### Fase 2: Implementação
- [ ] Gerar **Step Definitions** (Python/Behave, Java/Cucumber, etc.)
- [ ] Criar **Classes de Domínio** a partir da ERD
- [ ] Implementar **Validators** (CDCValidator, OperationalValidator)
- [ ] Implementar **RefundCalculator** com precisão decimal

### Fase 3: Testes
- [ ] Unit Tests para cada validator
- [ ] Integration Tests para fluxo completo
- [ ] E2E Tests baseados em BDD (29 cenários)
- [ ] Performance Tests para cálculos em massa

### Fase 4: Documentação
- [ ] API OpenAPI Spec (Swagger)
- [ ] Arquitetura C4 Model
- [ ] Runbook de operação
- [ ] Disaster recovery plan

### Fase 5: Deployment
- [ ] CI/CD Pipeline
- [ ] Kubernetes manifests
- [ ] Monitoring & Alerting
- [ ] Canary Release

---

## 📞 Suporte e Validação

Todos os 6 diagramas foram gerados como **Diagram-as-Code (Mermaid.js)**, o que permite:

✅ **Versionamento em Git** — Controle de mudanças  
✅ **Rendering automático** — GitHub, GitLab, Notion, Confluence  
✅ **Sincronização com código** — Diagramas = Single Source of Truth  
✅ **Colaboração visual** — Review & feedback sem ferramentas proprietárias  
✅ **Conversão para SVG/PNG** — Exportação para documentação

---

## ✨ Status da Entrega

- [x] Diagrama 1: Máquina de Estados ✅
- [x] Diagrama 2: Entidade-Relacionamento ✅
- [x] Diagrama 3: Fluxo de Decisão ✅
- [x] Diagrama 4: Diagrama de Sequência ✅
- [x] Diagrama 5: Arquitetura de Componentes ✅
- [x] Diagrama 6: Matriz de Decisão ✅
- [x] Índice Mestre (Este arquivo) ✅
- [x] Rastreabilidade BDD → Diagrama → Código ✅

**Arquitetura Visual: 100% Completa e Pronta para Implementação** 🎯

---

**Data de Geração:** 2026-09-09  
**Versão:** 1.0  
**Baseado em:** motor-cancelamento-estorno.feature (29 cenários BDD)  
**Formato:** Mermaid.js Diagram-as-Code  
**Idioma:** Português do Brasil (PT-BR)  

---

*Para mais informações ou sugestões de melhoria, consulte a documentação ou entre em contato com o time de arquitetura.*
