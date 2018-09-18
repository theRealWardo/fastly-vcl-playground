// assert is called by each check to validate the result.
//
// After assert is called the following must be set:
//  - req.http.name = human readable name of the test.
//  - req.http.result = the string "pass" if the assert succeeds.
//  - req.http.message = message explaining the failed assertion.
sub assert {
  declare local var.origin STRING;
  declare local var.expected STRING;

  set var.origin = regsub(req.backend, "^.+--", "");
  set var.expected = regsub(req.http.expected, "^.+--", "");

  set req.http.name = req.url;
  if (req.http.expected == req.backend) {
    set req.http.result = "pass";
    set req.http.message = req.url + " went to " var.origin;
  } else {
    set req.http.result = "fail";
    set req.http.message = req.url + " went to " + var.origin + " instead of " + var.expected;
  }
}

// test contains blocks of tests to run, where the general pattern is something like:
//  1. set up req to fake an incoming scenario for testing.
//  2. call a function that handles req.
//  3. set assertion values.
//  4. call check which will in turn call assert.
sub test {
  set req.backend = F_origin_0;
  set req.http.origin0 = req.backend;
  set req.backend = F_origin_1;
  set req.http.origin1 = req.backend;
  set req.backend = F_origin_2;
  set req.http.origin2 = req.backend;

  set req.url = "/";
  call route_origin;
  set req.http.expected = req.http.origin1;
  call check;

  set req.url = "/status/200";
  call route_origin;
  set req.http.expected = req.http.origin0;
  call check;

  set req.url = "/status/404";
  call route_origin;
  set req.http.expected = req.http.origin0;
  call check;

  set req.url = "/blog/";
  call route_origin;
  set req.http.expected = req.http.origin2;
  call check;
}
