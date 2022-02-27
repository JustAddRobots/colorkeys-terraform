# colorkeys-terraform
Terraform modules to build, test, and deploy colorkeys

## About

This repository contains tools to build, test and deploy
[colorkeys](https://github.com/JustAddRobots/colorkeys) to AWS via Terraform.

It is part of my exploration of color palette analysis in film and art. It is 
part-exercise and part-foundational project for building data analysis and machine 
learning tools for content creation.

There is **no support** for this project.

## Requirements

* Local AWS CLI and configured credentials (~/.aws/credentials)
* Remote state table (./environment/stage/backends.tf)
* Local image samples (./infrastructure/service/pipeline/pipeline_vars.tf)

## Installing

```
Update AWS region in ./global/vars.tf

❯ cd ./environment/stage
❯ terraform plan --out /tmp/myplan.tf
❯ terraform apply /tmp/myplan.tf
```
## The Plan

![Concept](./readme/JustAddRobots-colorkeys-terraform-v4.svg)

## In Action

### 01 - Apply, Build

* terraform apply AWS resources
* CodePipeline starts Build, Run, Load stages
* CodeBuild builds from git commit

<P align="center">
	<IMG src="https://user-images.githubusercontent.com/59129905/155896581-6e917dbd-eed1-4ba4-a5a3-4f522cd8cc4a.mp4" />
</P>

### 02 - Run, Load

* Run colorkeys as Lambda Fargate ECS task
* Load colorkeys data into DynamoDB

<P align="center">
	<IMG src="https://user-images.githubusercontent.com/59129905/155896595-3ee4a5a5-5d56-4447-9396-f03dc9cd79ca.mp4" />
</P>

### 03 - Check, Destroy

* Check DynamoDB for results
* terraform destroy AWS resources

<P align="center">
	![Destroy](https://user-images.githubusercontent.com/59129905/155896606-ebe66472-66fe-4cbe-8554-14edd8a0ca38.mp4)
</P>

## Todo

* Finish PASS/FAIL analytics for histogram comparision.
* Clean up dependencies, make more modular

