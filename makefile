.DEFAULT_GOAL := help

appname := "testapp"
aws_acc := "123456789"
aws_region := "eu-west-2"
lambda_timeout := "10"

.PHONY: help
help:
	@echo "Available targets:"
	@echo " - build-image: Building application to an image locally"
	@echo " - create-repo: Create ECR repo to host images built"
	@echo " - push-image: Pushing local image to ECR"
	@echo " - update-lambda: Update lambda with the latest image in ECR"
	@echo " - create-lambda: Create lambda using the image in ECR"
	@echo " - up: build push update"
	@echo " - create: build create-repo push create"
	@echo " - invoke: Trigger your lambda"

.PHONY: build-image
build-image:
	docker build . -t $(appname):latest
	docker tag docker.io/library/$(appname):latest $(appname):latest || true

.PHONY: create-repo
create-repo:
	aws ecr describe-repositories --repository-names $(appname) || aws ecr create-repository --repository-name $(appname)

.PHONY: push-image
push-image:
	aws ecr get-login-password --region $(aws_region) | docker login --username AWS --password-stdin $(aws_acc).dkr.ecr.$(aws_region).amazonaws.com
	docker tag $(appname):latest $(aws_acc).dkr.ecr.$(aws_region).amazonaws.com/$(appname)
	docker push $(aws_acc).dkr.ecr.$(aws_region).amazonaws.com/$(appname):latest

.PHONY: update-lambda
update-lambda:
	aws lambda update-function-code --function-name $(appname) \
		--image-uri $(aws_acc).dkr.ecr.$(aws_region).amazonaws.com/$(appname):latest

.PHONY: create-lambda
create-lambda:
	aws lambda create-function --function-name $(appname) \
		--package-type Image \
		--code ImageUri=$(aws_acc).dkr.ecr.$(aws_region).amazonaws.com/$(appname):latest \
		--role arn:aws:iam::$(aws_acc):role/vscode-execute \
		--timeout $(lambda_timeout)

.PHONY: up
up: build-image push-image update-lambda

.PHONY: create
create: build-image create-repo push-image create-lambda

.PHONY: invoke
invoke:
	aws lambda invoke --function-name $(appname) output.txt
