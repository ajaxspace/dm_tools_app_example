# pr-6: ci: point the machine loop at the ajaxspace forks on main

## Description

Issues-assigned and issue-comment events run workflows from the DEFAULT branch - main must carry the fork-wired stubs and the comment-resume trigger for the needs-input flow. Content identical to ai/gh-2's workflow wiring (fork refs @main + issue_comment trigger).

Co-Authored-By: Claude Code <noreply@anthropic.com>
