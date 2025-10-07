###############################
# EC2 role and instance profile
###############################

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "allow_ccm_csi_ecr" {
  name               = format("%s-allow_ccm_csi_ecr", local.vcluster_name)
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_instance_profile" "allow_ccm_csi_ecr" {
  name = format("%s-allow_ccm_csi_ecr", local.vcluster_name)
  role = aws_iam_role.allow_ccm_csi_ecr.name
}

###############################
# CCM policy
###############################

data "aws_iam_policy_document" "ccm" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeRouteTables",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:ModifyInstanceAttribute",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "ec2:DescribeInstanceTopology",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ccm" {
  name        = format("%s-ccm", local.vcluster_name)
  description = "Permissions for CCM"
  policy      = data.aws_iam_policy_document.ccm.json
}

resource "aws_iam_user" "ccm" {
  name = format("%s-ccm", local.vcluster_name)
}

resource "aws_iam_user_policy_attachment" "ccm" {
  user       = aws_iam_user.ccm.name
  policy_arn = aws_iam_policy.ccm.arn
}

resource "aws_iam_access_key" "ccm" {
  user = aws_iam_user.ccm.name
}

resource "aws_secretsmanager_secret" "ccm" {
  name = format("%s-ccm", local.vcluster_name)
}

resource "aws_secretsmanager_secret_version" "ccm" {
  secret_id     = aws_secretsmanager_secret.ccm.id
  secret_string = jsonencode({
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.ccm.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.ccm.secret
  })
}

###############################
# ECR policy
###############################

data "aws_iam_policy_document" "ecr" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr" {
  name        = format("%s-ecr", local.vcluster_name)
  description = "Permissions for ECR"
  policy      = data.aws_iam_policy_document.ecr.json
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.allow_ccm_csi_ecr.name
  policy_arn = aws_iam_policy.ecr.arn
}

###############################
# EBS CSI policy
###############################

data "aws_iam_policy_document" "ebs_csi" {
  # Describe permissions
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumeStatus",
    ]
    resources = ["*"]
  }

  # Create snapshot / modify volume on any volume
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:ModifyVolume",
    ]
    resources = ["arn:aws:ec2:*:*:volume/*"]
  }

  # Attach/Detach needs both volume and instance ARNs
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:instance/*",
    ]
  }

  # CreateVolume / EnableFastSnapshotRestores on snapshots
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:EnableFastSnapshotRestores",
    ]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
  }

  # CreateTags only when creating volume/snapshot
  statement {
    effect = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["CreateVolume", "CreateSnapshot"]
    }
  }

  # Allow DeleteTags on volumes/snapshots
  statement {
    effect = "Allow"
    actions = ["ec2:DeleteTags"]
    resources = [
      "arn:aws:ec2:*:*:volume/*",
      "arn:aws:ec2:*:*:snapshot/*",
    ]
  }

  # CreateVolume when request has CSI cluster tag
  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateVolume"]
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  # CreateVolume when request has CSIVolumeName
  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateVolume"]
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  # DeleteVolume when resource tagged with CSI cluster tag
  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteVolume"]
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  # DeleteVolume when resource tagged with CSIVolumeName
  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteVolume"]
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values   = ["*"]
    }
  }

  # DeleteVolume when resource tagged for PVC name
  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteVolume"]
    resources = ["arn:aws:ec2:*:*:volume/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values   = ["*"]
    }
  }

  # CreateSnapshot when request has CSIVolumeSnapshotName
  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateSnapshot"]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  # CreateSnapshot when request has CSI cluster tag
  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateSnapshot"]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  # DeleteSnapshot when resource tagged with CSIVolumeSnapshotName
  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values   = ["*"]
    }
  }

  # DeleteSnapshot when resource tagged with CSI cluster tag
  statement {
    effect    = "Allow"
    actions   = ["ec2:DeleteSnapshot"]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "ebs_csi" {
  name        = format("%s-ebs", local.vcluster_name)
  description = "Permissions for EBS CSI driver"
  policy      = data.aws_iam_policy_document.ebs_csi.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.allow_ccm_csi_ecr.name
  policy_arn = aws_iam_policy.ebs_csi.arn
}
