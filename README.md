## First of all

Run script here:

```bash
git clone https://github.com/nulldoot2k/cluster-k8s-ansible.git
cd cluster-k8s-ansible
chmod +x setup-and-run.sh
bash setup-and-run.sh
```

## Deploy K8s

Reference: [https://datvu2k-blog.netlify.app/devsecops/kubernetes/kubernetes-playbooks](https://datvu2k-blog.netlify.app/devsecops/kubernetes/kubernetes-playbooks)

## Install Minio on CS,VM

Edit variable:

```
minio:
  minio_image: "minio/minio"
  minio_image_bucket: "minio/mc"
  minio_region_name: "vietnam"
  minio_bucket_name: "bucket"
  minio_root_user: "admin"
  minio_root_passwd: "password"
  minio_access_key: "username"
  minio_secret_key: "password"
  minio_path_opt: "/opt/minio"
```

Run playbook:

```bash
ansible-playbook playbook.yml --tags minio
enter host> minio
```

Test bucket:

```bash
cd roles/minio/files
python client-minio.py
```
