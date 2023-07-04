# AWS Image based lambda template

This repository offers a image-based AWS Lambda template that provides you with a simple and efficient method to bootstrap your Lambda projects.

# Prerequisites

Before you begin, ensure you have installed the following on your machine:

[justfile](https://github.com/casey/just): A modern, user-friendly alternative to Makefile

[aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html): Used to create/update Lambda functions and manage ECR repositories

# Getting Started

* Replace AWS info in justfile
* Create lambda with `just create`
* Trigger lambda with `just invoke` & check output.txt
* Happy coding from `main.py` with `requirements.txt`

# Advantage

Helps you get away with the 250M limit with AWS Lambda, e.g. pandas
