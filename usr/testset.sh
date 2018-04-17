mfun() {
#set +euf
(set -euf; echo hi; true; echo ho; false; echo hu)
return $?
}

mfun
echo "mfun ret: $?"
