from __future__ import annotations

from datetime import datetime

import pytest

from src.refund_engine import (
    CancellationRequest,
    RefundEngine,
    RefundMethod,
    SubscriptionStatus,
    SubscriptionType,
)


def assert_money_close(val1: float, val2: float) -> None:
    assert abs(val1 - val2) < 0.01


def build_request(
    *,
    started_days_ago: int,
    status: SubscriptionStatus = SubscriptionStatus.ACTIVE,
    subscription_type: SubscriptionType = SubscriptionType.MONTHLY,
    amount_paid: float = 99.0,
    monthly_price: float = 99.0,
    annual_price: float = 1200.0,
    usage_gb: float = 0.0,
    violations: int = 0,
    request_date: datetime = datetime(2024, 3, 21, 10, 0, 0),
    cycle_start_day: int = 1,
    refund_method: RefundMethod = RefundMethod.PLATFORM_CREDIT,
) -> CancellationRequest:
    return CancellationRequest(
        started_days_ago=started_days_ago,
        status=status,
        subscription_type=subscription_type,
        amount_paid=amount_paid,
        monthly_price=monthly_price,
        annual_price=annual_price,
        usage_gb=usage_gb,
        violations=violations,
        request_date=request_date,
        cycle_start_day=cycle_start_day,
        refund_method=refund_method,
    )


@pytest.mark.parametrize(
    "scenario_name,request",
    [
        (
            "cdc_5_dias_com_consumo_e_infracao",
            build_request(started_days_ago=5, usage_gb=75.0, violations=2),
        ),
        (
            "cdc_7_dias_limite",
            build_request(started_days_ago=7, amount_paid=199.0, monthly_price=199.0),
        ),
        (
            "fora_cdc_8_dias_elegivel",
            build_request(started_days_ago=8, usage_gb=45.0, violations=0),
        ),
        (
            "proporcional_fevereiro_bissexto",
            build_request(
                started_days_ago=14,
                monthly_price=300.0,
                request_date=datetime(2024, 2, 15, 9, 0, 0),
            ),
        ),
        (
            "proporcional_marco_31",
            build_request(
                started_days_ago=20,
                monthly_price=250.0,
                request_date=datetime(2024, 3, 21, 9, 0, 0),
            ),
        ),
        (
            "proporcional_abril_30",
            build_request(
                started_days_ago=5,
                monthly_price=150.0,
                request_date=datetime(2024, 4, 10, 9, 0, 0),
                cycle_start_day=5,
            ),
        ),
        (
            "ultimo_dia_mes_refund_zero",
            build_request(
                started_days_ago=30,
                monthly_price=200.0,
                request_date=datetime(2024, 6, 30, 9, 0, 0),
            ),
        ),
        (
            "negacao_dados_65gb",
            build_request(started_days_ago=10, usage_gb=65.0),
        ),
        (
            "limite_exato_50gb",
            build_request(started_days_ago=12, monthly_price=150.0, usage_gb=50.0),
        ),
        (
            "dados_50_5gb_negado",
            build_request(started_days_ago=14, monthly_price=200.0, usage_gb=50.5),
        ),
        (
            "negacao_uma_infracao",
            build_request(started_days_ago=15, monthly_price=120.0, usage_gb=30.0, violations=1),
        ),
        (
            "negacao_multiplas_infracoes",
            build_request(started_days_ago=20, monthly_price=180.0, usage_gb=40.0, violations=3),
        ),
        (
            "anual_com_multa_sem_infracao",
            build_request(
                started_days_ago=104,
                subscription_type=SubscriptionType.ANNUAL,
                annual_price=1200.0,
                monthly_price=100.0,
                request_date=datetime(2024, 4, 15, 9, 0, 0),
            ),
        ),
        (
            "anual_cdc_sem_multa",
            build_request(
                started_days_ago=3,
                subscription_type=SubscriptionType.ANNUAL,
                annual_price=1200.0,
                monthly_price=100.0,
                usage_gb=99.0,
                violations=4,
            ),
        ),
        (
            "anual_prorata_meio_mes",
            build_request(
                started_days_ago=80,
                subscription_type=SubscriptionType.ANNUAL,
                annual_price=1200.0,
                monthly_price=100.0,
                request_date=datetime(2024, 7, 20, 9, 0, 0),
                cycle_start_day=1,
            ),
        ),
        (
            "anual_negado_por_dados_e_infracao",
            build_request(
                started_days_ago=40,
                subscription_type=SubscriptionType.ANNUAL,
                annual_price=1200.0,
                monthly_price=100.0,
                usage_gb=70.0,
                violations=2,
            ),
        ),
        (
            "status_expired_ja_encerrado",
            build_request(started_days_ago=50, status=SubscriptionStatus.EXPIRED),
        ),
        (
            "status_system_cancelled_ja_encerrado",
            build_request(started_days_ago=50, status=SubscriptionStatus.SYSTEM_CANCELLED),
        ),
        (
            "status_suspended_cancelamento_permitido",
            build_request(started_days_ago=20, status=SubscriptionStatus.SUSPENDED, usage_gb=10.0),
        ),
        (
            "mes_seguinte_sem_dias_restantes",
            build_request(started_days_ago=32, monthly_price=99.0, request_date=datetime(2024, 5, 1, 9, 0, 0)),
        ),
        (
            "piso_refund_liquido_zero",
            build_request(
                started_days_ago=120,
                subscription_type=SubscriptionType.ANNUAL,
                annual_price=1200.0,
                monthly_price=0.1,
                usage_gb=0.0,
                violations=0,
            ),
        ),
        (
            "integracao_platform_credit",
            build_request(started_days_ago=10, monthly_price=85.5, refund_method=RefundMethod.PLATFORM_CREDIT),
        ),
        (
            "integracao_pix",
            build_request(started_days_ago=10, monthly_price=150.0, refund_method=RefundMethod.PIX),
        ),
        (
            "refund_minimo_nao_processavel",
            build_request(started_days_ago=10, monthly_price=0.5),
        ),
    ],
)
def test_process_cancellation_red_not_implemented(
    scenario_name: str,
    request: CancellationRequest,
) -> None:
    engine = RefundEngine()

    with pytest.raises(NotImplementedError):
        engine.process_cancellation(request)
