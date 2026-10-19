"""Structured Foundation exceptions."""

from __future__ import annotations


class FoundationError(Exception):
    """Base error for Foundation platform code."""

    def __init__(self, message: str, *, code: str = "FOUNDATION_ERROR") -> None:
        super().__init__(message)
        self.message = message
        self.code = code


class ConfigurationError(FoundationError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="CONFIGURATION_ERROR")


class ValidationError(FoundationError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="VALIDATION_ERROR")


class PolicyDeniedError(FoundationError):
    def __init__(self, message: str, *, decision: str = "DENY") -> None:
        super().__init__(message, code="POLICY_DENIED")
        self.decision = decision


class DiscoveryError(FoundationError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="DISCOVERY_ERROR")


class NotImplementedCapabilityError(FoundationError):
    def __init__(self, message: str) -> None:
        super().__init__(message, code="NOT_IMPLEMENTED")
