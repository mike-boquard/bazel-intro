"""Demonstrate hermetic Python builds with Bazel and rules_python."""

from rich.console import Console
from rich.table import Table


def main() -> None:
    console = Console()

    table = Table(title="Hermetic Python with Bazel")
    table.add_column("Property", style="cyan", no_wrap=True)
    table.add_column("Value", style="green")

    table.add_row("Python interpreter", "3.12 — downloaded and pinned by Bazel")
    table.add_row("Package manager", "rules_python pip.parse — no virtualenv needed")
    table.add_row("rich version", "14.0.0 — locked with SHA-256 hash in requirements_lock.txt")
    table.add_row("Reproducible?", "Yes — same inputs → same outputs, always")

    console.print(table)
    console.print(
        "\n[bold]No [italic]pip install[/italic] needed.  "
        "No system Python used.  "
        "Works identically on every machine.[/bold]"
    )


if __name__ == "__main__":
    main()
