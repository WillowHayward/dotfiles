# General instructions

## Git

- Follow the repository's established commit conventions. If none are evident, use Conventional Commits.
- Do not add AI attribution or accreditation, including `Co-authored-by` trailers naming an AI tool or similar AI-credit metadata.
- Do not push unless explicitly requested. Treat permission to push as applying only to that specific request, unless explicitly told otherwise.

## Robots Department

The user queues work for agents, and takes questions from them, through the Robots Department: the `robots` MCP server (see `ai/tasks/Robots Department Trays.md` in the Obsidian vault for the detail). It replaces asking in chat when the user may not be watching.

### Your project
- Work in one project at a time: the one you were started in. Look for a `.whc` file in the working directory or a parent (its `project` line names the project; the format is still being defined). If there is none, match the directory or repository name to a project from `list_projects`. If you cannot tell which, ask once.
- Stay inside that project. "Action all items" (or "do the queue", or similar), said to you directly, means every open item in your own project's queue that is assigned to you or to nobody. It does not mean other projects' items, and it does not mean items assigned to another robot.

### Working the queue
1. `list_items` with `kind: queue`, your `project` and your own `robot` name (`claude` or `codex`). It is in priority order (urgent, bug, task, research, chore). Skip held and blocked items. Never action ideas or plans.
2. Starting an item: set it to `actioning`, so nobody edits it under you (the user adds a linked item if they want more). Finishing: set it to `done`. For a bug or research item, give a short `report` (a few lines; for a bug, the cause and the fix). Reports are optional for ordinary tasks.
3. If you need information, a decision, or something only the user can do, do not stop to ask in chat. Create an In Tray item (`kind: in`, with a `type`), and list the queue items you cannot continue without it in `blocks`. Write each question as its own list item that ends in `?` (that is what gives it an answer box; put any note before the question and its options after it as nested `- [ ]` checkboxes). A blocked task starts again by itself once the user answers.
4. Routine reporting goes in the session log (`log_session`, a short overview), not the In Tray. An `outcome` In Tray item describes an event that is not research or a diagnosis. The result of research or a fixed bug is a `report`: final and unambiguous, with anything the user wants to do about it a new follow-up task, never a reply. Planning goes through the plan review process, never reports: when `list_items` `kind: queue` shows a plan with `attention: true`, read it in full, then `submit_planning` one `planning` In Tray item per round with only new questions (options as nested checkboxes after each question; never re-ask an answered question), and `complete_plan` only after the user presses Implement. Create nothing else while reviewing (use the `robots-planning` tool set). Details: `ai/tasks/Robots Department Trays.md`.
5. When running headless or unattended, don't write a final chat summary nobody will read. The trays and the session log are the record.
