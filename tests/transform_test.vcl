# assert is called by each check to validate the result.
#
# After assert is called the following must be set:
#  - req.http.name = human readable name of the test.
#  - req.http.result = the string "pass" if the assert succeeds or "fail" if the assert fails.
#  - req.http.message = message explaining the failed assertion if the assert fails.
sub assert {
  set req.http.name = req.http.input;
  if (req.http.output == req.http.expected) {
    set req.http.result = "pass";
  } else {
    set req.http.result = "fail";
    set req.http.message = "expected " + req.http.expected + " but got " + req.http.output;
  }
}

# test contains blocks of tests to run, where the general pattern is something like:
#  1. set up req to fake an incoming scenario for testing.
#  2. call a function that handles req.
#  3. set assertion values.
#  4. call check which will call assert.
sub test {
  set req.http.input = "/";
  set req.http.expected = "/";
  call transform;
  call check;

  set req.http.input = "//";
  set req.http.expected = "/";
  call transform;
  call check;

  set req.http.input = "////photos////animals///pets///";
  set req.http.expected = "/photos/animals/pets";
  call transform;
  call check;
}
