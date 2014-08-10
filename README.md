awkfunge
========

Befunge 93 interpreter in AWK.

Running the examples
--------------------

```bash

$ awk -f befunge.awk examples/helloworld.bf

```

Debug mode
----------

To enable the debug mode set *DEBUG* to *1*:

```bash

$ awk -v DEBUG=1 -f befunge.awk examples/helloworld.bf

```
