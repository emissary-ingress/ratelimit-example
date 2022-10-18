
# re-generate protos...this only needs to run if you want to make changes to proto since these are
# currently checked into the repository, which is subject to change
proto-gen:
	rm -rf gen
	buf generate buf.build/googleapis/googleapis
	buf generate buf.build/cncf/xds
	buf generate buf.build/envoyproxy/protoc-gen-validate
	buf generate buf.build/envoyproxy/envoy

## builds locally and copies into distroless container server runs on port 8080
build-image:
	GOOS=linux GOARCH=amd64 go build -o ratelimit-example server/main.go 
	docker build -t ratelimit-example:latest .

## build, re-tag as #v3 and push container
docker-push:
	docker tag ratelimit-example:latest emissaryingress/ratelimit-example:v3
	docker push emissaryingress/ratelimit-example:v3

## applies the necessary yaml to setup ratelimit service
apply-yaml:
	kubectl apply -f ./k8s/ratelimit-example.yaml
	kubectl apply -f ./k8s/emissary-ratelimit-service.yaml
	kubectl apply -f ./k8s/quote-mapping-ratelimited.yaml
