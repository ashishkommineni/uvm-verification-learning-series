#!/usr/bin/env bash
set -euo pipefail

required=(
  README.md REQUIREMENTS.md Makefile
  docs/topic_index.md docs/verification_plan.md docs/verification_report.md
  scripts/lint_uvm_examples.sh scripts/run_uvm_verilator.sh
  rtl/mini_bus_memory.sv tb/interfaces/mini_bus_if.sv
  tb/assertions/mini_bus_sva.sv tb/pkg/mini_bus_uvm_pkg.sv
  tb/top/tb_top.sv tb/smoke/mini_bus_smoke.sv
  lessons/15_interview_practice/questions_and_answers.md
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

lesson_count=$(find lessons -mindepth 2 -maxdepth 2 -name README.md | wc -l)
[[ "$lesson_count" -eq 16 ]] || {
  echo "Expected 16 lesson README files, found $lesson_count" >&2
  exit 1
}

question_count=$(grep -Ec '^### [0-9]+\.' lessons/15_interview_practice/questions_and_answers.md)
[[ "$question_count" -ge 60 ]] || {
  echo "Expected at least 60 interview questions, found $question_count" >&2
  exit 1
}

if rg -n 'run_test\("' tb/top/tb_top.sv >/dev/null; then
  echo "run_test() must remain command-line selectable" >&2
  exit 1
fi

echo "Repository structure: PASS ($lesson_count lessons, $question_count interview Q&A)"
