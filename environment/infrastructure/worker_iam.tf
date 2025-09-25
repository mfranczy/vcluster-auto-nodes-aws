# Control plane policy
data "aws_iam_policy_document" "control_plane" {
  statement {
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
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

resource "aws_iam_policy" "control_plane" {
  name        = format("%s-control_plane_policy", local.vcluster_name)
  description = "Permissions for CCM and CSI"
  policy      = data.aws_iam_policy_document.control_plane.json
}

# Worker node
data "aws_iam_policy_document" "worker_node" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
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

resource "aws_iam_policy" "worker_node" {
  name        = format("%s-worker_node", local.vcluster_name)
  description = "Permissions for ECR and EC2 region"
  policy      = data.aws_iam_policy_document.worker_node.json
}

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
  description = "IAM policy for AWS EBS CSI driver"
  policy      = data.aws_iam_policy_document.ebs_csi.json
}

# Attach policies to role
resource "aws_iam_role" "allow_ccm_csi_ecr" {
  name               = format("%s-allow_ccm_csi_ecr", local.vcluster_name)
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "control_plane" {
  role       = aws_iam_role.allow_ccm_csi_ecr.name
  policy_arn = aws_iam_policy.control_plane.arn
}

resource "aws_iam_role_policy_attachment" "worker" {
  role       = aws_iam_role.allow_ccm_csi_ecr.name
  policy_arn = aws_iam_policy.worker_node.arn
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.allow_ccm_csi_ecr.name
  policy_arn = aws_iam_policy.ebs_csi.arn
}

resource "aws_iam_instance_profile" "allow_ccm_csi_ecr" {
  name = format("%s-allow_ccm_csi_ecr", local.vcluster_name)
  role = aws_iam_role.allow_ccm_csi_ecr.name
}
