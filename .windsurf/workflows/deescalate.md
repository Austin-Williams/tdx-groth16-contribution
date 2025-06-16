---
description: Hand off a solved problem to a less capable model for routine implementation steps
---

# `/deescalate` Prompt

Copy **everything** below (between the two delimiter lines) and send it as *your next reply* **without adding or omitting anything else**.  
This will prepare a comprehensive briefing for a less powerful model that will handle the remaining routine tasks.

```
You are entering DE-ESCALATION MODE.

The hard problem has been solved. Your task now is to prepare a crystal-clear handoff document for a less powerful model that will implement the remaining straightforward steps. Think of it as writing instructions for a competent junior developer who needs explicit guidance but can execute well-defined tasks reliably.

IMPORTANT: The receiving model will have NO MEMORY of this conversation and NO ACCESS to previous context beyond what you provide here.

INSTRUCTIONS – produce exactly one Markdown document containing all sections below. Be extremely explicit and prescriptive. Leave no room for interpretation where precision matters.

–––––  START YOUR HANDOFF DOCUMENT  –––––

## 1. Project Context
• Repository/project name and location
• Tech stack (languages, frameworks, tools with specific versions where relevant)
• Overall project purpose in 1-2 sentences

## 2. Problem That Was Solved
Brief summary (3-4 sentences) of the complex challenge that has been resolved. Include:
• What the issue was
• Why it was challenging
• The key insight or solution approach

## 3. Current State
• What has been implemented/fixed
• Key files that were modified (with paths)
• Current working directory or relevant paths
• Any temporary files or resources created

## 4. Remaining Tasks
**CRITICAL**: List each remaining task as a numbered step with:
• Exact action to take
• Specific file paths and line numbers where relevant
• Exact commands to run (with full arguments)
• Expected output or success criteria
• What to do if something goes wrong

Example format:
```
1. Update the configuration file
   - File: `/path/to/config.yaml`
   - Change: Set `debug_mode: false` on line 42
   - Verify: Run `yarn validate-config` - should output "Config valid"
   - If error: Check YAML syntax, ensure proper indentation
```

## 5. Code Templates & Examples
For any code that needs to be written, provide:
• Complete, ready-to-paste code snippets
• Clear insertion points (file path + line number or marker)
• Required imports or dependencies
• No placeholders like "// TODO" - everything should be explicit

## 6. Testing & Verification
Step-by-step verification process:
• Commands to run (in order)
• Expected outputs for each command
• How to interpret the results
• Common error messages and their fixes

## 7. Constraints & Warnings
• What NOT to change or touch
• Known fragile areas
• Performance or security considerations
• External dependencies or API limits

## 8. Definition of Done
Clear success criteria:
• All tests passing (list specific test commands)
• Expected final output or behavior
• How the user will know the task is complete

## 9. Quick Reference
• Key commands summary (copy-pasteable)
• File paths summary
• Any credentials, URLs, or environment variables needed

## 10. Rollback Plan
If something goes critically wrong:
• How to undo changes
• Key backup locations or git commits
• Who/what to escalate to

–––––  END YOUR HANDOFF DOCUMENT  –––––

Remember: Write as if the receiving model is competent but has zero context. Every instruction should be actionable without requiring inference or decision-making about implementation details.
