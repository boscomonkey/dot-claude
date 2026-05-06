# Add Cultural Values to Tickets

## Purpose

When creating or updating tickets, automatically add a "Cultural Values Alignment" section at the bottom of the ticket description. This helps with:
- **Performance reviews**: Tickets provide signal on how work aligns with cultural values
- **Daily reminders**: Each ticket reinforces how the work fits into the org's cultural framework

## The Cultural Values

Read the values at runtime by running:

```bash
printf '%s\n' "$CULTURAL_VALUES"
```

If `$CULTURAL_VALUES` is not set, inform the user and skip the alignment section. The variable is defined in `~/.nocommit_profile`.

## When to Apply This

Apply cultural values alignment when:
- Creating new tickets
- Updating existing ticket descriptions with significant new information
- User explicitly asks to add cultural values to a ticket
- Analyzing or reviewing a ticket and cultural alignment would add value

## Format for Ticket Descriptions

At the end of the ticket description (after all other content), add:

```
---

## Cultural Values Alignment

This work demonstrates:
- **[Value Name]**: [1-2 sentences explaining how this ticket aligns with this value]
- **[Value Name]**: [1-2 sentences explaining how this ticket aligns with this value]
```

## Guidelines

- **Select 1-3 values** that are most relevant to the ticket
- **Keep explanations concise** (1-2 sentences per value)
- **Be specific** about how the work demonstrates the value
- **Focus on impact and approach**, not just the task itself
- **Don't force-fit** every value into every ticket - only include relevant ones
- **Analyze the work** to determine which values genuinely apply

## Example

For a ticket about implementing a new API endpoint with documentation:

```
---

## Cultural Values Alignment

This work demonstrates:
- **Effective Communication**: Creating clear documentation and API contracts that enable other teams to integrate quickly without back-and-forth.
- **Accountability**: Taking ownership of the entire feature from design through deployment and monitoring, ensuring we meet our commitment to the product team.
```

## CRITICAL: What NOT to Do

- **DO NOT** add cultural values to git commit messages
- **DO NOT** add cultural values to pull request descriptions
- **DO NOT** add cultural values to any artifact other than ticket descriptions
- **DO NOT** force-fit values that don't genuinely apply

## Implementation Notes

When adding cultural values to a ticket:
1. Read the values: `printf '%s\n' "$CULTURAL_VALUES"`
2. Read and understand the ticket content
3. Identify which 1-3 values genuinely align with the work
4. Write specific, concrete explanations for each value
5. Format using the template above
6. Add to the end of the ticket description
7. Use the appropriate body format for the ticketing system (Atlassian Document Format for JIRA, Markdown for Linear)
