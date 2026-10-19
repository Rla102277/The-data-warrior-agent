# Orders CDC fixture

Use this fixture to test a candidate pipeline implementation against duplicate delivery, late old versions, tombstones and failure before checkpoint. The executable reference behavior and tests are in `tests/test_pipeline_fixture.py`. This SQLite reference is a local fixture. It is not a claim about any warehouse or lakehouse engine. An evaluated agent must independently implement and execute its own solution; merely reading this test is not a behavioral pass.
