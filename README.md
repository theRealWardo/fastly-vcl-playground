# Fastly VCL Playground

**A "framework" for playing with and testing VCL on Fastly.**

Let's be honest, this is just a pile of helpful bash scripts...


## Overview

The general idea is to write as much as possible in functions that you can unit test.

- Put functions in separate VCL files in the `functions` directory.
- Put test files for those function in `tests`.
- The tests run on your configured host at `/tests` by default.

For example, `functions/transform.vcl` has the definition of a VCL function named `transform`.
Unsurprisingly, `tests/transform_test.vcl` has unit tests for that VCL function.

**This framework using custom VCL** so you should be familiar with [Fastly's documentation on Custom VCL](https://docs.fastly.com/vcl/custom-vcl/creating-custom-vcl/) and know that **these scripts configure a single main VCL file NOT SNIPPETS**.

Functions and the test framework are prepended to a "template" VCL which is provided as an argument to `run.sh`.

Service backends can be configured in a `.backends` file, [learn more about that here](https://github.com/theRealWardo/fastly-vcl-playground/tree/master/config).


## Setup

The scripts source a `.env` file from the root of this repository which should have the following:

| Environment Variable | Description                                                                                                      | Example                          |
|----------------------|------------------------------------------------------------------------------------------------------------------|----------------------------------|
| `TOKEN`              | A Fastly API token.                                                                                              | 27ha74ha8cbaa0123c626e3fc5o12no6 |
| `SERVICE_ID`         | The ID of the service that you are modifying. This is under your Fastly service name on the "All Services" page. | 1hahaHTJTAw2Yj0fuJa5WE           |
| `DOMAIN`             | A protocol and domain where we can reach the configured service.                                                 | http://test.mydomain.com         |

Example `.env` file:

```
TOKEN=27ha74ha8cbaa0123c626e3fc5o12no6
SERVICE_ID=1hahaHTJTAw2Yj0fuJa5WE
DOMAIN=http://test.mydomain.com
```

## Getting Started

1. Setup your enviroment by creating the necessary `.env` file.
1. Write some functions, tests, a new template or backend configuration.
1. `./run.sh ${TEMPLATE_PATH} ${BACKENDS_PATH}` will generate your main VCL, upload it, and run the tests. To run the example, try `./run.sh templates/testing.vcl config/testing.backends`.
1. You should see some your test output!

## Other Resources

- https://docs.fastly.com/vcl/ - Fastly's VCL reference.
- https://fiddle.fastlydemo.net - A really great tool for playing with VCL in the browser with autocomplete.
