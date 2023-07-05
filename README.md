# AWS Image-based Lambda Template

This repository provides an image-based AWS Lambda template that gives you an efficient method to bootstrap your AWS Lambda projects. It's designed to help you overcome the AWS Lambda's 250MB size limit, enabling the use of larger libraries such as pandas.

## Prerequisites

Before you can use this template, make sure to install the following on your local machine:

- **justfile**: A modern, user-friendly alternative to Makefile. You can install it from [here](https://github.com/casey/just).
- **aws cli**: The Amazon Web Services command line interface. It's used to create and update Lambda functions, as well as manage ECR repositories. You can install it from [here](https://aws.amazon.com/cli/).

## Getting Started

1. **Replace AWS Info**: Modify the AWS-related information in the `justfile` to match your own AWS configuration.
2. **Create Lambda**: Execute `just create` command in your terminal to create the Lambda function.
3. **Trigger Lambda**: Use `just invoke` to trigger your Lambda function and check the `output.txt` for results.
4. **Code**: Start coding in `main.py` and manage your dependencies using `requirements.txt`.

## Advantage

This template provides a workaround for AWS Lambda's 250MB size limit, which allows you to use larger libraries, such as pandas, in your AWS Lambda projects.

## Contributions

Contributions are always welcome! Feel free to improve this template and submit a pull request.

Happy coding!
