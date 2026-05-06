# Subsequent Commit Message Format

For second and subsequent commits in a branch, use this concise format:

## Structure

```
TICKET-ID: brief description of change

* succinct bullet point describing specific change
* another bullet if multiple changes were made
* keep bullets short and focused on what changed
```

## Guidelines

- **Title**: `TICKET-ID: ` followed by a brief, lowercase description
- **Bullets**: Optional but recommended for clarity
- **Style**: Concise and direct, focus on what changed rather than why
- **Length**: Keep title under 50 characters when possible
- **Bullets**: Use past tense, be specific about the change

## Examples

### Single change
```
PROJ-123: remove bookworm-specific gcc compilers

* updated from gcc-9 and gcc-10 (bullseye) to gcc-12 (bookworm)
* added comment noting this was done for security reasons
```

### Multiple changes
```
PROJ-456: fix authentication middleware issues

* updated JWT token validation logic
* added error handling for expired tokens
* removed deprecated auth helper methods
```

### Simple change
```
PROJ-789: update README installation steps
```

## Notes

- This format is for commits **after** the first commit in a branch
- First commits should use the full format from `format-commit-pr-message.md`
- Keep bullets itemized and specific to aid code review