locals {
  vcluster_name      = nonsensitive(var.vcluster.instance.metadata.name)
  vcluster_namespace = nonsensitive(var.vcluster.instance.metadata.namespace)

  subnet_id         = var.vcluster.nodeEnvironment.outputs["private_subnet_ids"][random_integer.subnet_index.result]
  instance_type     = var.vcluster.nodeType.spec.properties["instance-type"]
  user_data         = var.vcluster.userData
  security_group_id = var.vcluster.nodeEnvironment.outputs["security_group_id"]
  instance_profile_name = var.vcluster.nodeEnvironment.outputs["instance_profile_name"]
}
