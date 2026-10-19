# Decision register (rebuild mirror)

Authoritative register remains:

[`knowledge/decisions/README.md`](../../knowledge/decisions/README.md)

This file is a navigation mirror for the rebuild docs tree. Do not invent new D-numbers here. Do not close open decisions (D2, D3, D11) without an approved decision record.

## Machine enforcement

Binding decisions are enforced in code by:

- `forge.policies.engine.PolicyEngine`
- `forge.policies.naming`
- tests in `tests/unit/test_policies.py`
