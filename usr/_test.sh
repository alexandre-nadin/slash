## Test arrays of positive && negative statements
# Syntax idea:
mfunc() {
} && tsh__add_func mfunc <PREFIX> <POS_ARRAYNAME> <NEG_ARRAY_NAME>

# Executes ${PREFIX:-test__}${mfunc} 
#  and/or
#  map POS_ARRAYNAME/NEG_ARRAY_NAME content to  $mfunc
PREFIX__mfunc() {
  local _test_count=0
  ## Positive tests separately
  for _test in "${TEST_FUNCTIONS_CORRECT[@]}"; do
    _test_count=$(( _test_count + 1 ))
    $_func "$_test" || return $_test_count
  done
  
  ## Negative tests separately
  for _test in "${TEST_FUNCTIONS_WRONG[@]}"; do
    _test_count=$(( _test_count + 1 ))
    ! $_func "$_test" || return $_test_count
  done

  ## Negative and Positive tests together in elegant way
  ## Surely requires a key dictionary
  local _truefalse_tests=(true false)
  for _tf_test in "${_test_type[@]}"; do
    for _test in 
    _test_count=$(( _test_count + 1 ))
    
  done
}
 true || \ 
  { # Fail 
   true -> KO
   false -> OK

true \
&& {
    $tt \
    && echo OK \
    || echo KO
   } \
|| {
     $tt \
     && echo KO \
     || echo OK
   }

## Example of positive/negative data sets
TEST_FUNCTIONS_CORRECT=(
  " function hello() {
    echo 1 
    echo 2
   }"

  " hello() {
    echo 1 
    echo 2
   }  "

  " -_hel-02lo(){
    echo 1 
    echo 2
   }  "

  " o(){
    echo 1 
    echo 2
   }  "
)

TEST_FUNCTIONS_WRONG=(
  " function h ello() {
    echo 1 
    echo 2
   }"

  " func hello() {
    echo 1 
    echo 2
   }  "

  " (){
    echo 1 
    echo 2
   }  "

  " (){
    echo 1 
    echo 2
   }  "

  " hello ( ){
    echo 1 
    echo 2
   }  "

  " hello () 
    echo 1 
    echo 2
   }  "
)

## 2 types of tests:
#   - On return value (int/ $?)
#   - On stdout
# For testing stdout, we need to map each test to expected stoud, as a string.



###
# Incrementing functions
+=() {
  local _inputs=(_varname _value)
  local ${_inputs[@]}
  _varname="$1"
  _value="$2"
  eval "$_varname=$(( ${!_varname} + $_value ))"
  printf "${!_varname}\n"
}
# Should we put result in stdout? I think so
