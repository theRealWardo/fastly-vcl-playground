sub transform {
  # Replace multiple //// in URL paths with a single one
  set req.http.output = regsuball(req.http.input, "/{2,}", "/");
  # Remove trailing slash, but leave /
  set req.http.output = regsub(req.http.output, "(?<=.)/$", "");
}
