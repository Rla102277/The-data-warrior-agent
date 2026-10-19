"""Azure Data Factory discovery and IR generation."""

from discovery.adf.parser import AdfPipelineParser, CanonicalPipelineIR

__all__ = ["AdfPipelineParser", "CanonicalPipelineIR"]
