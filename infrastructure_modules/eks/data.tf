locals {
  ## Key Pair ##
  key_pair_name = "eks-workers-keypair-${var.region_tag[var.region]}-${var.env}-${var.app_name}"
  # run "ssh-keygen" then copy public key content to public_key
  public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCbUWxOqk4nHxChj3BSYKeVHr1iTi1kKyshi0lMRwCmYt1y9EcWlUN+Vuk5sitV7F4oTwuKKuJLxpH1w7CwmCma9/4Hs1p+FdmqR/3DycyioAEUYv5WDGQiCz7gIc0cm6KuxLHryjsUg9O/tF4sH/wFLLY8QRUsCky0CtPnEc8we3jwPQNwbXIBedgF4Yte6CgofVdKa4PvAD5zSI4N24IFCoPYVh5wCj3u0iT6DogQDXkJtVIPzGjktE71yJN9Sx8LiYNzzIuBJdSBOGrWs9ummKKXzJOECioglO1kSb+9vCKNtn4Iznk/WiZ4K/ndjTVrE49Fn5cgCUuVHHIZ0DZABgRdMIpVWyl65StycubvxJSe7E89yRQqyUUp0E/B4r2fBFcGR93Hs7US1jJUhCptgC7uMDd+/W5qEwVOjCKzuKyZqSWR5GrweIOzix8YdVYRba2F03rNo7vvvS2qYBBRptC/jkuEjRrYG9Fj3IaLb2z54mx3TERSn+jgLS9GKE0= ant\\jojiv@JFK-1800267858"

  ########################################
  ##  KMS for K8s secret's DEK (data encryption key) encryption
  ########################################
  k8s_secret_kms_key_name                    = "alias/cmk-${var.region_tag[var.region]}-${var.env}-k8s-secret-dek"
  k8s_secret_kms_key_description             = "Kms key used for encrypting K8s secret DEK (data encryption key)"
  k8s_secret_kms_key_deletion_window_in_days = "30"
  k8s_secret_kms_key_tags = merge(
    var.tags,
    tomap({
        "Name" = local.k8s_secret_kms_key_name
    })
  )
}

# current account ID
data "aws_caller_identity" "this" {}

data "aws_iam_policy_document" "k8s_api_server_decryption" {
  # Copy of default KMS policy that lets you manage it
  statement {
    sid    = "Allow access for Key Administrators"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this.account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  # Required for EKS
  statement {
    sid    = "Allow service-linked role use of the CMK"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        module.eks_cluster.cluster_iam_role_arn, # required for the cluster / persistentvolume-controller
        "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root", 
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        module.eks_cluster.cluster_iam_role_arn,                                                                                                 # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    actions = [
      "kms:CreateGrant"
    ]

    resources = ["*"]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}