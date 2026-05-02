1. Lint
    - Always run fix `rubocop` before commit
    - Always run `rails test` bef

2. Write Code Ruby/Rails code following these rules:
    - Use early return instead of nested if
    - Do not combine assignment inside conditions
    - Extract duplicated logic into small private methods
    - Handle exceptions explicitly (no silent crash)
    - Keep methods short (max ~10 lines)
    - Use clear naming, no abbreviations
    - Follow Rails conventions (current_user, before_action, etc.)
    - Avoid one-liners if they reduce readability
    - Prefer readability over clevernessore commit
