resource "local_file" "kubespray_config" {
  content = templatefile("template/inventory.tmpl",
    {
    
     node_host_name = module.node.name
     node_host_ip = module.node.nodes_public_ip

    }
  )
  filename = "${var.kubespray_cluster_path}/hosts.yaml"
  
  provisioner "local-exec" {
    command = <<-EOT
      sed -i -e 's/.*container_manager:.*/container_manager: docker/' ${var.kubespray_config_path}/k8s-cluster.yml
      sed -i -e 's/.*supplementary_addresses_in_ssl_keys:.*/supplementary_addresses_in_ssl_keys: [${module.node.nodes_public_ip[0]}]/' ${var.kubespray_config_path}/k8s-cluster.yml
      sed -i -e 's/.*dashboard_enabled:.*/dashboard_enabled: true/' ${var.kubespray_config_path}/addons.yml
      sed -i -e 's/.*metrics_server_enabled:.*/metrics_server_enabled: true/' ${var.kubespray_config_path}/addons.yml
      sed -i -e 's/.*helm_enabled:.*/helm_enabled: true/' ${var.kubespray_config_path}/addons.yml
      sed -i -e 's/.*ingress_nginx_enabled:.*/ingress_nginx_enabled: true/' ${var.kubespray_config_path}/addons.yml
      sed -i -e 's/.*ingress_nginx_host_network:.*/ingress_nginx_host_network: true/' ${var.kubespray_config_path}/addons.yml
    EOT
  }
  depends_on = [
    module.node
  ]
}

resource "null_resource" "wait" {
  provisioner "local-exec" {
    command = "sleep 40"
  }

  depends_on = [
    local_file.kubespray_config
  ]
}

#Install cluster with kubespray
resource "null_resource" "cluster" {
  provisioner "local-exec" {
    command = <<-EOT
    ANSIBLE_FORCE_COLOR=1 ansible-playbook -i ~/kubespray/inventory/mycluster/hosts.yaml  --become ~/kubespray/cluster.yml
    EOT
  }
  depends_on = [
    null_resource.wait
  ]
}

#Copy config from cluster and backup old local config
resource "null_resource" "copy-config" {
  provisioner "local-exec" {
    command = <<-EOT
    BACKUP_NAME='config-'$(date +%Y-%m-%d-%H-%M)
    mv ~/.kube/config ~/.kube/$BACKUP_NAME
    ssh ${module.node.nodes_public_ip[0]} sudo cat /etc/kubernetes/admin.conf >> ~/.kube/config
    sed -i s%127.0.0.1%\${module.node.nodes_public_ip[0]}% ~/.kube/config
    EOT
  }
  depends_on = [
    null_resource.cluster
  ]
}