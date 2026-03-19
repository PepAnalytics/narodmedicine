from django.core.management.base import BaseCommand

from core.services.regional_importer import RegionalContentImporter


class Command(BaseCommand):
    help = "Import structured regional folk medicine content from JSON."

    def add_arguments(self, parser) -> None:  # noqa: ANN001
        parser.add_argument(
            "--path",
            type=str,
            default=None,
            help="Path to JSON dataset. Uses bundled dataset by default.",
        )
        parser.add_argument(
            "--reset",
            action="store_true",
            help=(
                "Delete previously imported regional remedies "
                "and sources before import."
            ),
        )

    def handle(self, *args, **options) -> None:  # noqa: ANN002, ANN003
        importer = RegionalContentImporter(dataset_path=options["path"])
        result = importer.import_dataset(reset=options["reset"])
        self.stdout.write(
            self.style.SUCCESS(
                "Regional content imported: "
                f"{result['sources']} sources, "
                f"{result['ingredients']} ingredients, "
                f"{result['remedies']} remedies."
            )
        )
