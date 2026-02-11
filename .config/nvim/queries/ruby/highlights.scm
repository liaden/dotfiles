; extends

; Spell-check identifiers — Ruby's snake_case convention means
; method/variable names are real words (e.g., calculate_totl → flags "totl")
(identifier) @spell
(constant) @spell

; Spell-check string contents and symbols
(string_content) @spell
(simple_symbol) @spell
(delimited_symbol) @spell
(heredoc_content) @spell
(comment) @spell
