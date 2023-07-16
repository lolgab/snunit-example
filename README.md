# Example HTTP application using SNUnit + Http4s

This example application show how a SNUnit application look like.

The server uses the http4s API and Mill as the build tool.

## Getting started

To run the application you need to first [install NGINX Unit](https://unit.nginx.org/installation/).

Then you can run:

```
./mill runUnit
```

to run it.

If you want to build your application on every change you can run a separate terminal with the following command:

```
./mill -w nativeLink
```

And to restart the app you need to kill the first process and run `./mill runUnit` again in your first terminal.

### Docker image

To build a Docker image you can run:

```
docker build -t snunit-example .
```

Then you can run the application with:

```
docker run --rm -p 8080:8080 snunit-example
```

The NGINX Unit configuration is stored in the [conf.json](./conf.json) file.
The `conf.json` file can be stored in the `statedir` directory when launching NGINX Unit.
All of this is already taken care by the `runUnit` command in the Mill build and by the
`Dockerfile`. The `executable` path `out` is relative to the directory where you run
NGINX Unit. You can change the port where the application is exposed by changing the
`listeners` section. Refer to the [NGINX Unit documentation](https://unit.nginx.org/configuration/) for more advanced configurations.