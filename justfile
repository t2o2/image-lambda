default:
    @just --list

appname := "testapp"
aws_acc := "123456789"
aws_region := "eu-west-2"
lambda_timeout := "10"
trust_policy := "trust-policy.json"
role_name := "lambda-execute"

# build create repo role push create
create: create-repo create-role build-image push-image create-lambda

# build push update
up: build-image push-image update-lambda

# Cleanup: combines all delete actions
cleanup: delete-lambda delete-role delete-repo

# Trigger your lambda
invoke:
    aws lambda invoke --function-name {{appname}} output.txt
# Create IAM role with trust policy
create-role:
    aws iam create-role --role-name {{role_name}} --assume-role-policy-document file://{{trust_policy}}
    aws iam attach-role-policy --role-name {{role_name}} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Delete IAM role
delete-role:
    aws iam detach-role-policy --role-name {{role_name}} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole  || true
    aws iam delete-role --role-name {{role_name}}  || true

# Building application to an image locally
build-image:
    docker build . -t {{appname}}:latest
    docker tag docker.io/library/{{appname}}:latest {{appname}}:latest || 1

# Create ECR repo to host images built
create-repo:
    aws ecr describe-repositories --repository-names {{appname}}  --region {{aws_region}} || aws ecr create-repository --repository-name {{appname}}  --region {{aws_region}}

# Delete ECR repository
delete-repo:
    aws ecr delete-repository --repository-name {{appname}} --force || true
    
# Pushing local image to ECR
push-image:
    aws ecr get-login-password --region {{aws_region}} | docker login --username AWS --password-stdin {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com
    docker tag {{appname}}:latest {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}
    docker push {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

# Update lambda with the latest image in ECR
update-lambda:
    aws lambda update-function-code --function-name {{appname}} \
        --region {{aws_region}} \
        --image-uri {{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest

# Delete Lambda function
delete-lambda:
    aws lambda delete-function --function-name {{appname}} || true

# Create lambda using the image in ECR
create-lambda:
    aws lambda create-function --function-name {{appname}} \
        --package-type Image \
        --code ImageUri={{aws_acc}}.dkr.ecr.{{aws_region}}.amazonaws.com/{{appname}}:latest \
        --role arn:aws:iam::{{aws_acc}}:role/{{role_name}} \
        --timeout {{lambda_timeout}}
