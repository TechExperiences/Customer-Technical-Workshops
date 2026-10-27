"""Regression tests for local knowledge-base preflight behavior."""
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "create_knowledge_base.py"
SPEC = importlib.util.spec_from_file_location("create_knowledge_base", MODULE_PATH)
assert SPEC and SPEC.loader
knowledge_base = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(knowledge_base)


class FakePath:
    def __init__(self, name: str, is_directory: bool = False) -> None:
        self.name = name
        self.is_directory = is_directory


class FakeFileSystem:
    def __init__(self, paths: list[FakePath]) -> None:
        self.paths = paths

    def get_paths(self, recursive: bool):
        self.recursive = recursive
        return self.paths


class FakeService:
    def __init__(self, containers: dict[str, FakeFileSystem]) -> None:
        self.containers = containers

    def get_file_system_client(self, container: str) -> FakeFileSystem:
        return self.containers[container]


class CollectDocumentsTests(unittest.TestCase):
    def test_orders_azure_path_properties_by_name(self) -> None:
        service = FakeService(
            {
                "data": FakeFileSystem([FakePath("zeta.docx"), FakePath("alpha.docx")]),
                "sharepoint": FakeFileSystem([FakePath("context.docx")]),
            }
        )

        documents = knowledge_base.collect_documents(service)

        self.assertEqual(
            [(container, source_path, upload_name) for container, _, source_path, upload_name in documents],
            [
                ("data", "alpha.docx", "data__alpha.docx"),
                ("data", "zeta.docx", "data__zeta.docx"),
                ("sharepoint", "context.docx", "sharepoint__context.docx"),
            ],
        )

    def test_rejects_unsupported_source_before_vector_store_creation(self) -> None:
        service = FakeService(
            {
                "data": FakeFileSystem([FakePath("input.csv")]),
                "sharepoint": FakeFileSystem([FakePath("context.docx")]),
            }
        )

        with self.assertRaisesRegex(RuntimeError, "not supported"):
            knowledge_base.collect_documents(service)


if __name__ == "__main__":
    unittest.main()
