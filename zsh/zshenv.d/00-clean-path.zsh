# Ensure no duplicates in path-like variables. First entry wins,
# so prepending moves an existing entry to the front.
typeset -U PATH path FPATH fpath MANPATH manpath
