"""Foundation control plane.

Decision (Confirmed from existing SQL): do not create a second parallel control
database. Authoritative operational metadata remains in Fabric warehouse
`warehouse_stage` schema `control` (see automation/sql/stage_load_config.sql).

This package provides typed models, seed parsing, and an in-memory repository
for offline engineering and tests.
"""
