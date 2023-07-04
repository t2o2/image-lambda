default:
    @just --list

appname := "testapp"
aws_acc := "123456789"
aws_region := "eu-west-2"
lambda_timeout := 10

build-image:
    docker build . -t {{appname}}:latest
    docker tag docker.io/library/{{appname}}:latest {{appname}}:latest || 1

create-repo:
    aws ecr describe-repositories --repository-names {{appname}} || aws ecr create-repository --repository-name {{appname}}

push-image:
    aws ecr get-login-password --region {{aws_region}} | docker login --username AWS --password-stdin {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com
    docker tag {{appname}}:latest {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}
    docker push {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

update-lambda:
    aws lambda update-function-code --function-name {{appname}} \
        --image-uri {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

create-lambda:
    aws lambda create-function --function-name {{appname}} \
        --package-type Image \
        --code ImageUri={{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest \
        --role arn:aws:iam::{{aws_acc}}:role/vscode-execute \
        --timeout {{lambda_timeout}}

# build push update
up: build-image push-image update-lambda

# build create-repo push create
create: build-image create-repo push-image create-lambda

invoke:
    aws lambda invoke --function-name {{appname}} output.txt