## Configuring Fastly Backends

You cannot configure backends in VCL, therefore we need a way to
set up those backends so we can write VCL that depends on them.

`.backends` files give you the ability to configure a set of backends.

Each file contains one or more blocks of backend variables. The variables
are defined in the Fastly documentation: https://docs.fastly.com/api/config#backend

**Note that each of the pairs in this file must be URL safe!**

Example `.backends` file:

```
BACKEND
  name=origin_0
  hostname=httpbin.org
  address=httpbin.org
  port=80

BACKEND
  name=origin_1
  hostname=fastly.com
  address=fastly.com
  port=80
```
