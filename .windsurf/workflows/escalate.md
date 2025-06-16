---
description: Cause the current model to output a prompt to give to a more capable model to help solve the current problem
---

# `/escalate` Prompt

Copy **everything** below (between the two delimiter lines) and send it as *your next reply* **without adding or omitting anything else**.  
It is a set of instructions you must follow **now** in order to prepare a briefing that will be handed to a more–capable model that is about to take over this task.

```
You are entering ESCALATION MODE.

Your sole job right now is to write a clear, complete briefing for a stronger model that will soon replace you.  
Think of it as a hand-off note you leave on your keyboard before you go home.

INSTRUCTIONS – produce exactly one Markdown document containing the sections listed below, using the same headings.  Be factual, concise, and self-contained; assume the new model has seen **none** of the prior conversation and has **no** hidden context other than what you write here.

Do **not** solve the problem or continue working on it; only report.

–––––  START YOUR BRIEFING  –––––

## 1. Big-Picture Goal
Explain in 2-4 sentences **why** the user is doing this work.  What ultimate outcome are they aiming for?

## 2. Current Specific Objective
Describe the concrete sub-goal the conversation is focused on right now (e.g., “reproduce the official tarball hash by tweaking the build pipeline”).

## 3. Context & Constraints
• Project/repo name and tech stack (languages, frameworks, major tools)  
• Hard requirements (performance, security, style guides, deadlines, platform restrictions, licensing, etc.)  
• Anything that must **not** be changed or violated

## 4. Progress So Far
Brief chronological list (newest first) of what has been tried, including:  
• key code changes or commands run  
• important outputs, logs, or error messages (include only the relevant fragments)  
• what each attempt taught us (successes as well as failures)

## 5. Current Roadblock(s)
For each blocking issue, explain:  
• the symptoms/error  
• suspected root cause (if any hypothesis exists)  
• why previous fixes failed

## 6. Open Questions & Unknowns
Bullet list of unanswered questions, uncertainties, or decisions the next model should address.

## 7. Environment Snapshot
• OS, language & toolchain versions  
• Important file paths or configuration locations  
• Any running services or external dependencies

## 8. Resources
Links or filenames for:  
• specs, docs, tickets, design docs  
• earlier conversation snippets if critical  
• any other artefacts the next model should inspect

## 9. Next Recommended Step
If you were going to try one more thing, what would it be and why?  Keep it short; this is optional guidance, not a solution.

–––––   END YOUR BRIEFING    –––––

Remember: *do not continue working on the task itself*.  Your entire output must be the briefing above, filled out.
```
