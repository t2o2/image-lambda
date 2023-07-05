default:
    @just --list

appname := "testapp"
aws_acc := "123456789"
aws_region := "eu-west-2"
lambda_timeout := "10"

# Building application to an image locally
build-image:
    docker build . -t {{appname}}:latest
    docker tag docker.io/library/{{appname}}:latest {{appname}}:latest || 1

# Create ECR repo to host images built
create-repo:
    aws ecr describe-repositories --repository-names {{appname}} || aws ecr create-repository --repository-name {{appname}}

# Pushing local image to ECR
push-image:
    aws ecr get-login-password --region {{aws_region}} | docker login --username AWS --password-stdin {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com
    docker tag {{appname}}:latest {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}
    docker push {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

# Update lambda with the latest image in ECR
update-lambda:
    aws lambda update-function-code --function-name {{appname}} \
        --image-uri {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

# Create lambda using the image in ECR
create-lambda:
    aws lambda create-function --function-name {{appname}} \
        --package-type Image \
        --code ImageUri={{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest \
        --role arn:aws:iam::{{aws_acc}}:role/vscode-execute \
        --timeout {{lambda_timeout}}

# build push update
up: build-image push-image update-lambda

# build create-repo push create
create: create-repo build-image push-image create-lambda

# Trigger your lambda
invoke:
    aws lambda invoke --function-name {{appname}} output.txt