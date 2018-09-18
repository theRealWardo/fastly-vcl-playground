sub check {
  declare local var.TAP-Test INTEGER;

  set var.TAP-Test = std.atoi(req.http.TAP-Test);
  set var.TAP-Test += 1;
  set req.http.TAP-Test = var.TAP-Test;

  call assert;

  if (req.http.result != "pass") {
    set req.http.TAP-Log = req.http.TAP-Log + req.http.TAP-Test + ". FAIL - " + req.http.message + LF;
    set req.http.TAP-Result = "fail";
  }
}

sub vcl_recv {
#FASTLY recv
  if (req.request != "HEAD" && req.request != "GET" && req.request != "FASTLYPURGE") {
    return(pass);
  }

  if (req.url.path == "/tests") {
    call tests;
    if (req.http.TAP-Result == "fail") {
      error 901;
    }
    error 900;
  }
}

sub vcl_fetch {
#FASTLY fetch
  if ((beresp.status == 500 || beresp.status == 503) && req.restarts < 1 && (req.request == "GET" || req.request == "HEAD")) {
    restart;
  }

  if (req.restarts > 0) {
    set beresp.http.Fastly-Restarts = req.restarts;
  }

  if (beresp.http.Set-Cookie) {
    set req.http.Fastly-Cachetype = "SETCOOKIE";
    return(pass);
  }

  if (beresp.http.Cache-Control ~ "private") {
    set req.http.Fastly-Cachetype = "PRIVATE";
    return(pass);
  }

  if (beresp.status == 500 || beresp.status == 503) {
    set req.http.Fastly-Cachetype = "ERROR";
    set beresp.ttl = 1s;
    set beresp.grace = 5s;
    return(deliver);
  }

  if (beresp.http.Expires || beresp.http.Surrogate-Control ~ "max-age" || beresp.http.Cache-Control ~ "(s-maxage|max-age)") {
    # keep the ttl here
  } else {
    # apply the default ttl
    set beresp.ttl = 1h;
  }

  return(deliver);
}

sub vcl_hit {
#FASTLY hit
  if (!obj.cacheable) {
    return(pass);
  }
  return(deliver);
}

sub vcl_miss {
#FASTLY miss
  return(fetch);
}

sub vcl_deliver {
#FASTLY deliver
  return(deliver);
}

sub vcl_error {
#FASTLY error
  if (obj.status == 900) {
    set obj.http.content-type = "text/plain";
    synthetic "1.." + req.http.TAP-Test + LF + LF + "All tests passed.";
    return (deliver);
  } else if (obj.status == 901) {
    set obj.http.content-type = "text/plain";
    synthetic "1.." + req.http.TAP-Test + LF + LF + "FAILED." + LF + LF + req.http.TAP-Result;
    return (deliver);
  }
}

sub vcl_pass {
#FASTLY pass
}

sub vcl_log {
#FASTLY log
}