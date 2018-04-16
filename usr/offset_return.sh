manual() {
  cat << eol

  DESCRIPTION
    Finds the pattern '$RET_PATTERN' and puts it at the specified offset.
    Default offset is '$RET_OFFSET'. 
    If the pattern is farther than the offset, doesn't change it.
    Makes a backup of the file as <FILE>.bak.

  USAGE:
    $ ${BASH_SOURCE[0]} FILE [OFFSET]
eol
}

# -----
RET_PATTERN='(\|\||&&) (return|retexit|exit) '
RET_OFFSET=65

! [ $# -ge 1 ] && manual && exit 1 || :

FILE="$1" && shift
RET_OFFSET=${1:-$RET_OFFSET}

echo "FILE: '$FILE'; OFFSET: '$RET_OFFSET'" >&2

lines=($(grep -En "$RET_PATTERN" "$FILE" \
          | cut -d':' -f1))

## Backup
cp "$FILE" "${FILE}.bak"
for _l in "${lines[@]}"; do
  col=$(sed -n ${_l}p "$FILE" \
         | grep -Eaob "$RET_PATTERN" \
         | cut -d':' -f1 \
         | head -n1)
  
  offset=$(( RET_OFFSET - col - 1 ))
  if [ $offset -gt 0 ]; then
    echo "adding offset of $offset to pattern from line $_l" >&2 \
    && sed -i -E \
        "${_l}s/(.*)($RET_PATTERN)(.*)?/\1$(printf ' %.0s' $(seq 1 ${offset}))\2\5/" \
        "$FILE" \
    || : 
  fi
done
