# Agentic Engineering Patterns (Simon Willison)

Source: https://simonwillison.net/guides/agentic-engineering-patterns/

## Principles

### 1. What is Agentic Engineering
- Developing software WITH coding agents (not just generating code)
- Agent = software that runs tools in a loop to achieve a goal (LLM + system prompt + tools in a loop)
- Code execution is the defining capability — without it, LLM output has limited value
- Human role remains essential: determining WHAT to write, navigating tradeoffs, verifying results
- Differs from "vibe coding" (unreviewed prototype-quality output) — agentic engineering brings code to production-ready standards

### 2. Writing Code is Cheap Now
- Code GENERATION is nearly free; GOOD code still costs effort
- Good code = functional, bug-free, verified, solves the right problem, handles errors, simple, well-tested, future-proof without over-engineering
- Don't reflexively reject ideas as "not worth the time" — experiment asynchronously with agents
- Worst outcome = wasted tokens (minimal cost vs potential gains)
- Quality standards don't drop just because generation is cheaper

### 3. Hoard Things You Know How to Do
- Build a personal repository of working code examples and solutions
- "Knowing something is theoretically possible != having seen it done yourself"
- Powerful pattern: instruct agents to combine two working examples into something new
- Coding agents mean we only need to figure out a useful trick ONCE
- Document solutions with working code — agents can consult them for future projects

### 4. AI Should Help Us Produce Better Code
- Refactoring tasks are ideal for agents (API changes across files, naming fixes, deduplication, modularization)
- Lowered costs enable "zero tolerance" for code smells
- Agents enable rapid prototyping to AVOID poor architectural decisions — build and compare rather than theorize
- Compound Engineering Loop: each project ends with retrospective documenting what succeeded, evolving agent instructions over time

### 5. Anti-patterns: Things to Avoid
- **NEVER file PRs with unreviewed agent-generated code** — this delegates your work to collaborators
- Quality PRs must include: functional code you're confident works, manageable scope, contextual explanation, validated descriptions
- Demonstrate your investment: manual testing notes, implementation rationale, screenshots
- Your responsibility = delivering WORKING code, not delegating validation to peers

## Working with Coding Agents

### 6. How Coding Agents Work
- Architecture: LLM + system prompt + tools in a loop
- LLMs are stateless — entire conversation replayed each prompt (token caching mitigates cost)
- Tool-calling: model generates tool calls, harness executes them, results feed back
- Code execution tools (Bash, Python) are the most powerful capability
- System prompts can be hundreds of lines — they instruct behavior

### 7. Subagents
- Address context window limitations (~200k usable tokens for quality)
- Subagent = fresh context window with dedicated prompt for specific goals
- Use cases: codebase exploration, parallel independent tasks, specialist roles (reviewer, test runner, debugger)
- Preserve root context by offloading token-intensive operations
- Can run in parallel using faster models for independent tasks

## Testing and QA

### 8. Red/Green TDD
- **Red**: Write tests that FAIL
- **Green**: Implement code until tests PASS
- CRITICAL: Confirm tests fail BEFORE implementing — prevents writing non-functional or unnecessary code
- "A comprehensive test suite is by far the most effective way to keep features working"
- Shorthand prompt: "Use red/green TDD"

### 9. First Run the Tests
- Run existing tests IMMEDIATELY when starting work on any project
- "Automated tests are no longer optional when working with coding agents"
- Four-word prompt: "First run the tests"
- Benefits: discovers test suite existence, reveals project complexity, establishes testing-first mindset
- Tests also help agents understand existing codebases

### 10. Agentic Manual Testing
- "Never assume LLM-generated code works until it has been EXECUTED"
- Unit tests passing != real-world functionality
- Python: test with `python -c "..."` and edge cases
- Web: run dev server + curl to explore endpoints
- Write demo files in /tmp to avoid accidental repo commits
- Browser automation: Playwright for interactive UIs
- Document testing with screenshots and command output

## Understanding Code

### 11. Linear Walkthroughs
- Use agents to generate structured documentation of codebases
- Especially valuable for revisiting forgotten projects or understanding vibe-coded output
- Counters concern that AI reduces learning — structured walkthroughs teach you what was built

### 12. Interactive Explanations
- When code is too complex to comprehend, build interactive visualizations
- Reduces "cognitive debt" from agent-written code
- Agents excel at producing animations and interactive interfaces to explain concepts
- If the core of your application becomes a black box you can't reason about, build an explanation tool

## Key Prompts
- "Use red/green TDD" — write failing tests, then implement
- "First run the tests" — establish baseline before changes
- "Explore the codebase" — subagent for understanding before editing
