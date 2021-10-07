Step 1: Replicate Remote TF modules for EKS in local Resource Modules
https://github.com/terraform-aws-modules/terraform-aws-eks

Step 2: Create Infrastructure Modules for EKS and Consume Resource Modules

- using https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/complete
- infrastructure_modules/eks/main.tf, module eks will act as facade to sub-components as EKS cluster, EKS worker nodes, IAM roles, worker launch template, security groups, auto scaling groups, etc.


![](https://gblobscdn.gitbook.com/assets%2F-LMqIrDmky_20pK6TFJ3%2F-LMsEyvFSkhI7U5bXYr0%2F-LMsFSH4bEnNaV2UP-K6%2FComposition%201.png?alt=media&token=bf8b7677-4ba6-4001-a176-3916587f4250)

Simple infrastructure composition
