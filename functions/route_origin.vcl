sub route_origin {
  if (req.url ~ "^/status/\d+$") {
    # Requests for /status/ => origin 0
    # (query strings allowed)
    set req.backend = F_origin_0;
  } else if (req.url == "/") {
    # Requests for exactly / => origin 1
    # (query strings not allowed)
    set req.backend = F_origin_1;
  } else if (req.url == "/blog/") {
    # Requests for exactly /blog/ => origin 2
    # (query strings not allowed)
    set req.backend = F_origin_2;
  }
}
