.DEFAULT_GOAL := help

appname := "testapp"
aws_acc := "123456789"
aws_region := "eu-west-2"
lambda_timeout := "10"
trust_policy := "trust-policy.json"
api_name := "testfastapi-gateway"

.PHONY: help
help:
	@echo "Available targets:"
	@echo " - create-role: Create IAM role with trust policy"
	@echo " - delete-role: Delete IAM role"
	@echo " - build-image: Building application to an image locally"
	@echo " - create-repo: Create ECR repo to host images built"
	@echo " - delete-repo: Delete ECR repo"
	@echo " - push-image: Pushing local image to ECR"
	@echo " - update-lambda: Update lambda with the latest image in ECR"
	@echo " - create-lambda: Create lambda using the image in ECR"
	@echo " - delete-lambda: Delete Lambda function"
	@echo " - up: build push update"
	@echo " - create: build create-repo push create"
	@echo " - cleanup: combines all delete actions"
	@echo " - invoke: Trigger your lambda"

create-role:
	aws iam create-role --role-name $(role_name) --assume-role-policy-document file://$(trust_policy)
	aws iam attach-role-policy --role-name $(role_name) --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

delete-role:
	-aws iam detach-role-policy --role-name $(role_name) --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
	-aws iam delete-role --role-name $(role_name)

.PHONY: build-image
build-image:
	docker build . -t $(appname):latest
	docker tag docker.io/library/$(appname):latest $(appname):latest || true

.PHONY: create-repo
create-repo:
	aws ecr describe-repositories --repository-names $(appname) || aws ecr create-repository --repository-name $(appname)

.PHONY: delete-repo
delete-repo:
	-aws ecr delete-repository --repository-name $(appname) --force

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

delete-lambda:
	-aws lambda delete-function --function-name $(appname)

.PHONY: up
up: build-image push-image update-lambda

.PHONY: create
create: create-repo create-role build-image push-image create-lambda

.PHONY: cleanup
cleanup: delete-lambda delete-role delete-repo

.PHONY: invoke
invoke:
	aws lambda invoke --function-name $(appname) output.txt
