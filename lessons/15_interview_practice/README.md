# 15 — UVM interview practice

The [question bank](questions_and_answers.md) contains 80 practical questions.
Do not memorize paragraphs. Build each answer in this order:

1. State **what** the construct is.
2. Explain **why** verification needs it.
3. Trace **how** handles, data, or control move internally.
4. Give one concrete mini-bus, FIFO, or AXI example.
5. End with one trap or edge case.

Practice in five rounds: definitions, exact syntax, execution flow, debugging a
broken snippet, and extending the project. Record 60–90 second answers. If an
answer depends on “the code above,” rewrite it until it is self-contained and
speakable.

The strongest project explanation follows one transaction from sequence to
scoreboard, then names what assertions and coverage add, how the test ends, and
which simulator results were actually executed.

## Three study modes

### 1. Concept round

Answer in 60–90 seconds using **WHAT → WHY → HOW → WHERE → TRAP**. Example:

> “A monitor is a passive component that converts accepted pin activity into
> transactions. It provides independent evidence for scoreboards and coverage.
> In this project it samples through a clocking block, queues accepted requests,
> adds response data one cycle later, and broadcasts a fresh completed item. A
> common bug is publishing too early or reusing the same object handle.”

### 2. Exact-syntax round

Write from memory: factory registration/construction, config-db set/get,
start-item handshake, driver handshake, analysis connection, covergroup sample,
one SVA property, phase objection, and a RAL frontdoor access. Compile the answer;
syntax confidence should come from tools, not visual familiarity.

### 3. Debug round

Given a hang or mismatch, state what evidence you inspect first. Trace
sequence → driver → interface → DUT → monitor → scoreboard, and distinguish DUT,
testbench, tool, and infrastructure failures.

## Mock-interview rubric

Score each answer from 0–2 in five categories:

| Category | 0 | 1 | 2 |
|---|---|---|---|
| Definition | Wrong/missing | Partly correct | Precise |
| Purpose | None | Generic | Verification reason |
| Internal flow | None | Names APIs | Correct data/control path |
| Example | None | Abstract | Concrete project example |
| Edge case | None | Vague | Specific failure/debug point |

A strong answer scores at least 8/10 without relying on memorized wording.

## Project walkthrough checklist

Be ready to explain:

1. DUT protocol and reset contract.
2. Component topology and why the monitor is the evidence source.
3. Transaction fields/constraints and factory override.
4. Driver/monitor clocking and request-response latency.
5. Reference-model algorithm and false-pass prevention.
6. Assertions and functional-coverage plan.
7. Test lifetime, drain, timeout, and result criteria.
8. One failure you could inject and how the bench detects it.
9. Which simulator runs were actually executed versus only documented.

## Follow-up practice prompts

- Convert the in-order scoreboard to out-of-order matching by ID.
- Make the agent passive without changing the monitor stream.
- Explain why a factory override set after build has no effect.
- Diagnose a sequence stuck at `finish_item()`.
- Explain a coverpoint at 100% while a cross remains incomplete.
- Describe RAL mirror drift when another bus master writes a register.
- Handle reset while a driver owns a sequence item.
- Separate an Xcelium license failure from a design regression failure.

## Honest-answer rule

Never claim a simulator, coverage target, or protocol feature was executed unless
a retained log/result proves it. Say “supported script, not run here” when that
is the truth, then describe how you would validate it. This is stronger than an
unverifiable green claim.

## Revision summary

The full [question bank](questions_and_answers.md) is organized for concept,
syntax, execution, debug, and extension practice. Explain mechanisms in your own
words, anchor them to code, and always finish with a real edge case.
