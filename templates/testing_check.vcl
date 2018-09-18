# check is called by test functions.
sub check {
  declare local var.TAP-Test INTEGER;
  set var.TAP-Test = std.atoi(req.http.TAP-Test);
  set var.TAP-Test += 1;
  set req.http.TAP-Test = var.TAP-Test;

  call assert;

  if (req.http.result != "pass") {
    declare local var.TAP-Failures INTEGER;
    set var.TAP-Failures = std.atoi(req.http.TAP-Failures);
    set var.TAP-Failures += 1;
    set req.http.TAP-Failures = var.TAP-Failures;

    set req.http.TAP-Log = req.http.TAP-Log + "__FILE__ - " + req.http.name + " - FAILED" + LF + "  " + req.http.message + LF + LF;
    set req.http.TAP-Result = "fail";
  }
}
