## Создание кластера kubernetes в YandexCloud с помощью kubespray и terraform

### Quick start

```SHELL
terraform init
terraform workspace new kube
terraform plan
terraform apply -auto-approve
```

### Variables

[variables.tf](./terraform/variables.tf)

- `metadata`               - Путь до файла с метаданными `meta.txt` для создания пользователя в инстансе.
- `yc_token`               - Токен YC (обычно содержится в окружении пользователя)
- `yc_cloud_id`            - ID облака (обычно содержится в окружении пользователя)
- `yc_folder_id`           - ID директории облака (формируется при создании инстанса)
- `yc_region`              - Регион
- `kubespray_cluster_path` - Путь до `kubespray/inventory/mycluster`
- `kubespray_config_path`  - Путь до `kubespray/inventory/mycluster/group_vars/k8s_cluster`

***meta.txt***

```TXT
#cloud-config
users:
  - name: <username>
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - "<your ssh public key>"
```
