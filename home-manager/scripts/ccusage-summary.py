#!/usr/bin/env python3
"""Render per-agent ccusage totals as a bordered terminal table."""

from __future__ import annotations

import json
import subprocess
import sys
from collections import defaultdict
from datetime import date, timedelta


FIELDS = (
    "inputTokens",
    "outputTokens",
    "cacheCreationTokens",
    "cacheReadTokens",
    "totalTokens",
    "totalCost",
)


def report_range(period: str) -> tuple[str, str, str]:
    today = date.today()
    if period == "today":
        start = today
        command = "daily"
    elif period == "week":
        start = today - timedelta(days=6)
        command = "weekly"
    elif period == "month":
        start = today.replace(day=1)
        command = "monthly"
    else:
        raise ValueError(f"unsupported period: {period}")
    return command, start.isoformat(), today.isoformat()


def load_report(period: str) -> tuple[str, dict]:
    command, start, end = report_range(period)
    result = subprocess.run(
        [
            "ccusage",
            command,
            "--since",
            start,
            "--until",
            end,
            "--by-agent",
            "--json",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.stderr:
        print(result.stderr, end="", file=sys.stderr)
    if result.returncode != 0:
        raise RuntimeError(f"ccusage exited with status {result.returncode}")
    return command, json.loads(result.stdout)


def aggregate(command: str, report: dict) -> list[dict]:
    totals: dict[str, dict[str, float]] = defaultdict(
        lambda: {field: 0 for field in FIELDS}
    )
    for period in report.get(command, []):
        for agent in period.get("agents") or []:
            name = agent.get("agent", "unknown")
            for field in FIELDS:
                totals[name][field] += agent.get(field) or 0

    rows = []
    for name in sorted(totals):
        rows.append({"agent": name, **totals[name]})
    return rows


def format_table(rows: list[dict]) -> str:
    headers = (
        "Agent",
        "Input",
        "Output",
        "Cache Create",
        "Cache Read",
        "Total Tokens",
        "Cost (USD)",
    )

    def display(row: dict, label: str | None = None) -> tuple[str, ...]:
        return (
            label or str(row["agent"]),
            f'{int(row["inputTokens"]):,}',
            f'{int(row["outputTokens"]):,}',
            f'{int(row["cacheCreationTokens"]):,}',
            f'{int(row["cacheReadTokens"]):,}',
            f'{int(row["totalTokens"]):,}',
            f'${row["totalCost"]:.2f}',
        )

    total = {"agent": "TOTAL", **{field: 0 for field in FIELDS}}
    for row in rows:
        for field in FIELDS:
            total[field] += row[field]

    body = [display(row) for row in rows]
    body.append(display(total, "Total"))
    widths = [
        max(len(headers[index]), *(len(row[index]) for row in body))
        for index in range(len(headers))
    ]

    def border(left: str, middle: str, right: str) -> str:
        return left + middle.join("─" * (width + 2) for width in widths) + right

    def line(values: tuple[str, ...]) -> str:
        cells = []
        for index, value in enumerate(values):
            aligned = value.ljust(widths[index]) if index == 0 else value.rjust(widths[index])
            cells.append(f" {aligned} ")
        return "│" + "│".join(cells) + "│"

    output = [border("┌", "┬", "┐"), line(headers), border("├", "┼", "┤")]
    for index, row in enumerate(body):
        output.append(line(row))
        if index != len(body) - 1:
            output.append(border("├", "┼", "┤"))
    output.append(border("└", "┴", "┘"))
    return "\n".join(output)


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"today", "week", "month"}:
        print("usage: ccusage-summary.py {today|week|month}", file=sys.stderr)
        return 2

    try:
        command, report = load_report(sys.argv[1])
        rows = aggregate(command, report)
    except (OSError, ValueError, RuntimeError, json.JSONDecodeError) as error:
        print(f"ccusage summary: {error}", file=sys.stderr)
        return 1

    if not rows:
        print("No usage data found.")
        return 0

    print(format_table(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
