# Emulates bahaviour of echo, but more efficiently. 
# The difference can be seen by comparing print and echo for large arrays of strings.
if [ "$#" -gt 0 ]; then
  printf %s "$1"
  shift
fi
if [ "$#" -gt 0 ]; then
  printf ' %s' "$@"
fi
printf '\n'
