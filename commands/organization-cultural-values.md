# Cultural Values Reference

Display the organization's cultural values stored in the `$CULTURAL_VALUES` environment variable.

Run `printf '%s\n' "$CULTURAL_VALUES"` to read the current values, then display them to the user.

If `$CULTURAL_VALUES` is not set or empty, inform the user that no cultural values have been configured (set `CULTURAL_VALUES` in `~/.nocommit_profile`).
