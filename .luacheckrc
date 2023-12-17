std = "luajit"
codes = true
max_line_length = 120
max_comment_line_length = false

self = false


-- special files {{{
files["spec/*_spec.lua"].std = "+busted"
-- special files }}}

-- vim: set ft=lua ts=2 sw=2 et
