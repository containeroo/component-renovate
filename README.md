# Commodore Component: renovate

This is a [Commodore][commodore] Component for renovate.

This repository is part of Project Syn.
For documentation on Project Syn and this component, see [syn.tools](https://syn.tools).

## Documentation

The rendered documentation for this component is available on the [Commodore Components Hub](https://hub.syn.tools/renovate).

Documentation for this component is written using [Asciidoc][asciidoc] and [Antora][antora].
It can be found in the [`docs`](docs) folder.
We use the [Divio documentation structure](https://documentation.divio.com/) to organize our documentation.

Run the `make docs-serve` command in the root of the project, and then browse to http://localhost:2020 to see a preview of the current state of the documentation.

After writing the documentation, please use the `make docs-vale` command and correct any warnings raised by the tool.

## Testing with custom CA certificates

If dependency fetching fails during `make test` with TLS trust errors, provide your CA bundle:

```bash
make test -e instance=defaults CA_CERT_FILE=/path/to/ca-bundle.pem
```

This mounts the certificate into the Commodore container and exports:
- `SSL_CERT_FILE`
- `REQUESTS_CA_BUNDLE`
- `CURL_CA_BUNDLE`

## Contributing and license

This library is licensed under [BSD-3-Clause](LICENSE).
For information about how to contribute, see [CONTRIBUTING](CONTRIBUTING.md).

[commodore]: https://syn.tools/commodore/
[asciidoc]: https://asciidoctor.org/
[antora]: https://antora.org/
