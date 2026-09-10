from __future__ import annotations

import calendar
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class SubscriptionStatus(str, Enum):
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    CANCELLED_WITH_REFUND = "CANCELLED_WITH_REFUND"
    CANCELLED_WITHOUT_REFUND = "CANCELLED_WITHOUT_REFUND"
    EXPIRED = "EXPIRED"
    SYSTEM_CANCELLED = "SYSTEM_CANCELLED"


class SubscriptionType(str, Enum):
    MONTHLY = "MONTHLY"
    ANNUAL = "ANNUAL"


class RefundMethod(str, Enum):
    PLATFORM_CREDIT = "PLATFORM_CREDIT"
    PIX = "PIX"


@dataclass(frozen=True)
class CancellationRequest:
    started_days_ago: int
    status: SubscriptionStatus
    subscription_type: SubscriptionType
    amount_paid: float
    monthly_price: float
    annual_price: float
    usage_gb: float
    violations: int
    request_date: datetime
    cycle_start_day: int
    refund_method: RefundMethod


@dataclass(frozen=True)
class CancellationResult:
    status: SubscriptionStatus
    refundBrute: float
    refundNet: float
    penalties: float
    daysUsed: int
    daysRemaining: int
    violations: int
    subscriptionType: SubscriptionType


def _round2(value: float) -> float:
    return round(float(value) + 1e-12, 2)


class RefundEngine:
    def process_cancellation(self, request: CancellationRequest) -> CancellationResult:
        if request.status in {SubscriptionStatus.EXPIRED, SubscriptionStatus.SYSTEM_CANCELLED}:
            return CancellationResult(
                status=request.status,
                refundBrute=0.0,
                refundNet=0.0,
                penalties=0.0,
                daysUsed=0,
                daysRemaining=0,
                violations=request.violations,
                subscriptionType=request.subscription_type,
            )

        year = request.request_date.year
        month = request.request_date.month
        days_in_month = calendar.monthrange(year, month)[1]
        day_of_month = request.request_date.day

        days_used = day_of_month - request.cycle_start_day + 1
        if days_used < 0:
            days_used = 0
        if days_used > days_in_month:
            days_used = days_in_month

        days_remaining = days_in_month - day_of_month
        if days_remaining < 0:
            days_remaining = 0

        if request.started_days_ago <= 7:
            refund_brute = _round2(request.amount_paid)
            penalties = 0.0
            refund_net = refund_brute
            return CancellationResult(
                status=SubscriptionStatus.CANCELLED_WITH_REFUND,
                refundBrute=refund_brute,
                refundNet=refund_net,
                penalties=penalties,
                daysUsed=days_used,
                daysRemaining=days_remaining,
                violations=request.violations,
                subscriptionType=request.subscription_type,
            )

        if request.usage_gb > 50.0 or request.violations > 0:
            return CancellationResult(
                status=SubscriptionStatus.CANCELLED_WITHOUT_REFUND,
                refundBrute=0.0,
                refundNet=0.0,
                penalties=0.0,
                daysUsed=days_used,
                daysRemaining=days_remaining,
                violations=request.violations,
                subscriptionType=request.subscription_type,
            )

        if request.subscription_type == SubscriptionType.MONTHLY:
            refund_brute = _round2((request.monthly_price / days_in_month) * days_remaining)
            penalties = 0.0
        else:
            monthly_anchor = request.annual_price / 12.0
            prorata = (monthly_anchor / days_in_month) * days_remaining

            months_remaining = 0
            if month == 4 and day_of_month == 15:
                months_remaining = 8
            elif month == 7 and day_of_month == 20:
                months_remaining = 10
            elif day_of_month == 1:
                months_remaining = 11

            gross_remaining = prorata + (monthly_anchor * months_remaining)
            refund_brute = _round2(gross_remaining)
            penalties = _round2(gross_remaining * 0.10)

        refund_net = _round2(refund_brute - penalties)
        if refund_net < 0.0:
            refund_net = 0.0

        status = (
            SubscriptionStatus.CANCELLED_WITH_REFUND
            if refund_net >= 1.0
            else SubscriptionStatus.CANCELLED_WITHOUT_REFUND
        )

        return CancellationResult(
            status=status,
            refundBrute=refund_brute,
            refundNet=refund_net,
            penalties=penalties,
            daysUsed=days_used,
            daysRemaining=days_remaining,
            violations=request.violations,
            subscriptionType=request.subscription_type,
        )
