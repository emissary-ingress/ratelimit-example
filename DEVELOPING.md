# Ratelimit Example Service

This implements the bare-bones plumbing for a demo RateLimit Service. The implementation is not production ready and only for demo and documentation purposes. It is based on the Emissary-ingress docs found here: <https://www.getambassador.io/docs/emissary/latest/howtos/rate-limiting-tutorial/>

- [Development](#development)
  - [Dependencies](#dependencies)
  - [Regenerate Protobufs](#regenerate-protobufs)
  - [Build and Run Locally](#build-and-run-locally)
  - [Build Server Image](#build-server-image)
  - [Push Image](#push-image)
  - [Deploy RateLimit Service](#deploy-ratelimit-service)

## Development

Here are instructions for hacking on it locally.

### Dependencies

Here are a list of dependency for developemnt:

- golang
- [buf cli](https://docs.buf.build/installation)
- Docker
- Make
- kubectl
- K8s cluster

### Regenerate Protobufs

The project requires generated code from protobufs that are pulled from the Buf Service Registry (BSR). The deps can be found in the `buf.yaml` file which references the latest commits from these projecst.

> Note: Emissary-ingress uses a custom build of Envoy, the custom instance is used to generate code that is checked into the `emissary.git` repository. As of writing this example service the RateLimit protos are a 1-to-1 with upstream which makes it safe to use Buf Schema Registery. However, that is subject to change so it is recommended that the generated code in `emissary.git` be used since it is tested against the custom build of Envoy.

The `buf-cli` regenerate the Golang code from the remote deps as outlined in `buf.yaml`. The code is generated in `gen/proto/go` folder which is configured in the `buf.gen.yaml` file. We also use the "managed" feature of buf-cli to ensure the golang imports in the
generated code are based on the `go.mod` so that imports are relative to go module.

```shell
# regenerate code from protobuf files
make proto-gen
```

### Build and Run Locally

This project consists of the server and a test client that are gRPC implementations of the Envoy RateLimit protos. The server is the only thing required and the client is for local testing.

The server can be started calling:

```shell
go run server/main.go
```

Open a second terminal and a test client that connects to the RateLimit server and makes simple ShouldRateLimit request every 2 seconds can be run by calling:

```shell
go run client/main.go
```

### Build Server Image

To build a server image the following command can be run:

```shell
make build-image
```

This will build the Golang binary locally, compiling for `linux` and `amd64` and then copying it into a base distroless container. This container can be run locally or pushed to a K8s cluster (*see below*)

### Push Image

After building the image it needs to be pushed to a container registry like DockerHub.

For example, Emissary-ingress Maintainers can run the following Make target to update the image in the `emissaryingress` organization on DockerHub:

```shell
make docker-push
```

> Note: if you are not a maintainer you will need to update the `Makefile` to point at your own registry that you have push permissions on or just make direct `docker tag`, `docker push` commands

### Deploy RateLimit Service

Now that you have a basic RateLimitService available you can deploy it and use it with Emissary-ingress.

First, if you don't have a cluster go and follow the [Emissary-ingress Quickstart guide](https://www.getambassador.io/docs/emissary/latest/tutorials/getting-started/) to setup Emissary-ingress in a cluster.

Second, assuming you have `kubectl` configured for your cluster you can now run the following command:

```shell
make apply-yaml
```

This will Kubectl apply the sample yaml files found in the `k8s` folder:

- ratelimit-example.yaml - *K8s Deployment and Service for the RateLimit Server container*
- emissary-ratelimit-service.yaml - *RateLimitService configured for the ratelimit-example and `emissary` domain*
- quote-mapping-ratelimited.yaml - *updated mapping which includes RateLimit labels*

Once it is done deploying you can test that it is working:

```shell
## You should receive a 429 response
curl -i -H "x-emissary-test-allow: probably"  http://$LB_ENDPOINT/backend/

## You should receive a 200 response
curl -i -H "x-emissary-test-allow: true"  http://$LB_ENDPOINT/backend/
```

If you receive a `500` error code this means Envoy was unable to talk to the RateLimit-Example service. Be sure to check your deployment was successful and whether you can connect to it yourself.

