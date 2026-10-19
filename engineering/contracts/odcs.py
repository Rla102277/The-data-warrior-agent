"""Open Data Contract Standard oriented operations (YAML-friendly)."""

from __future__ import annotations

from typing import Any

import yaml
from pydantic import ValidationError

from forge.contracts.models import CompatibilityClass, DataContract, SchemaField


def create_contract(**kwargs: Any) -> DataContract:
    return DataContract(**kwargs)


def validate_contract(contract: DataContract | dict[str, Any] | str) -> tuple[bool, list[str]]:
    errors: list[str] = []
    try:
        if isinstance(contract, str):
            payload = yaml.safe_load(contract)
            model = DataContract.model_validate(payload)
        elif isinstance(contract, dict):
            model = DataContract.model_validate(contract)
        else:
            model = contract
    except (ValidationError, yaml.YAMLError) as exc:
        return False, [str(exc)]

    if not model.contract_id:
        errors.append("contract_id required")
    if not model.schema_fields:
        errors.append("schema_fields required")
    if not model.keys:
        errors.append("keys required for reconciliation")
    if model.version == "":
        errors.append("version required")
    return len(errors) == 0, errors


def compare_contract_versions(older: DataContract, newer: DataContract) -> CompatibilityClass:
    return older.compare_schema(newer)


def assess_schema_change(older: DataContract, newer: DataContract) -> dict[str, Any]:
    klass = compare_contract_versions(older, newer)
    return {
        "compatibility": klass.value,
        "accepted": klass != CompatibilityClass.BREAKING,
        "older_version": older.version,
        "newer_version": newer.version,
        "blocking": klass == CompatibilityClass.BREAKING,
    }


def generate_contract_tests(contract: DataContract) -> list[dict[str, Any]]:
    tests: list[dict[str, Any]] = []
    for field in contract.schema_fields:
        tests.append(
            {
                "id": f"schema.{field.name}",
                "type": "column_exists",
                "column": field.name,
                "nullable": field.nullable,
            }
        )
    for key in contract.keys:
        tests.append({"id": f"unique.{key}", "type": "uniqueness", "column": key})
    for rule in contract.quality_requirements:
        tests.append({"id": f"rule.{rule}", "type": "quality_rule", "rule": rule})
    return tests


def evaluate_contract_compliance(
    contract: DataContract,
    *,
    actual_columns: list[str],
    row_count: int,
    duplicate_count: int = 0,
) -> dict[str, Any]:
    expected = [f.name for f in contract.schema_fields]
    missing = sorted(set(expected) - set(actual_columns))
    failures: list[str] = []
    if missing:
        failures.append(f"missing columns: {missing}")
    if duplicate_count > 0:
        failures.append(f"duplicates: {duplicate_count}")
    if row_count < 1:
        failures.append("empty dataset")
    return {
        "compliant": not failures,
        "failures": failures,
        "tests": generate_contract_tests(contract),
        "contract_id": contract.contract_id,
        "version": contract.version,
    }


def contract_to_yaml(contract: DataContract) -> str:
    return yaml.safe_dump(contract.model_dump(mode="json"), sort_keys=False)


def field(name: str, data_type: str, nullable: bool = True) -> SchemaField:
    return SchemaField(name=name, data_type=data_type, nullable=nullable)
