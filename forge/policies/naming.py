"""D0 / D13 naming rules as machine-checkable helpers."""

from __future__ import annotations

import re

BANNED_NAME_RE = re.compile(
    r"(?<![A-Za-z0-9])(EDW_[A-Za-z0-9_]+|(?:dim|fact|vw)_[A-Za-z0-9_]+)",
    re.IGNORECASE,
)
MEDALLION_RE = re.compile(
    r"(?<![A-Za-z0-9])(?:bronze|silver|gold)_[A-Za-z0-9_]+|"
    r"[A-Za-z0-9]+_(?:bronze|silver|gold)(?![A-Za-z0-9])",
    re.IGNORECASE,
)
DBO_DDL_RE = re.compile(
    r"\bcreate\s+(?:or\s+alter\s+)?(?:table|view|procedure|proc|function)\s+\[?dbo\]?\.",
    re.IGNORECASE,
)

BUSINESS_OBJECT_KINDS = frozenset(
    {
        "table",
        "view",
        "procedure",
        "proc",
        "function",
        "warehouse_table",
        "lakehouse_table",
    }
)


def lint_naming_text(text: str) -> list[str]:
    findings: list[str] = []
    if not text:
        return findings
    for match in BANNED_NAME_RE.finditer(text):
        findings.append(f"banned name token: {match.group(0)}")
    for match in MEDALLION_RE.finditer(text):
        findings.append(f"medallion term in object name: {match.group(0)}")
    if DBO_DDL_RE.search(text):
        findings.append("business object created in dbo schema")
    return findings


def is_dbo_business_object(schema: str, name: str, item_type: str = "") -> bool:
    if schema.lower() != "dbo":
        return False
    kind = item_type.lower()
    if kind in BUSINESS_OBJECT_KINDS or kind == "":
        # Empty kind treated as business object when schema is dbo and name is present.
        return bool(name.strip())
    return False
