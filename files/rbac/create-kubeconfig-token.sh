#!/bin/bash

# Thiết lập chế độ nghiêm ngặt và thoát nếu có lỗi
set -euo pipefail

# --- KHỞI TẠO BIẾN VÀ HỎI THÔNG TIN ---
read -p "Nhập tên Service Account: " SA_NAME
read -p "Nhập tên Namespace để phân quyền: " NAMESPACE
read -p "Nhập tên thư mục output (ví dụ: hacker): " OUTPUT_DIR

# Định nghĩa tên Cluster và Server (lấy từ context hiện tại)
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$CURRENT_CONTEXT\")].context.cluster}")
SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
CERT_DATA=$(kubectl config view --raw -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.certificate-authority-data}")
KUBECONFIG_OUT="${OUTPUT_DIR}/${SA_NAME}-kubeconfig-token"
ROLE_NAME="${SA_NAME}-role"
ROLEBINDING_NAME="${SA_NAME}-rolebinding"
SECRET_NAME="${SA_NAME}-sc"

echo "--- Bắt đầu tạo Kubeconfig cho Service Account: ${SA_NAME} trong Namespace: ${NAMESPACE} ---"

# 1. Tạo thư mục output
mkdir -p "${OUTPUT_DIR}"
echo "✅ Tạo thư mục: ${OUTPUT_DIR}"

# 2. Tạo RBAC Definition (Namespace, SA, Secret, Role, RoleBinding)
echo "--- Tạo file RBAC: ${OUTPUT_DIR}/${SA_NAME}-rbac.yaml ---"
cat << EOF > "${OUTPUT_DIR}/${SA_NAME}-rbac.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
secrets:
  - name: ${SECRET_NAME}
---
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SA_NAME}
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${ROLE_NAME}
  namespace: ${NAMESPACE}
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ROLEBINDING_NAME}
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: ${ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f "${OUTPUT_DIR}/${SA_NAME}-rbac.yaml"
echo "✅ Áp dụng RBAC, Namespace và ServiceAccount"

# 3. Lấy Token từ Secret
echo "--- Đợi và lấy Token từ Secret: ${SECRET_NAME} ---"
# Đợi Secret được tạo (thường là tức thì nếu đã khai báo thủ công như trên)
sleep 2

# Lấy giá trị token từ Secret, decode Base64
TOKEN=$(kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" -o jsonpath='{.data.token}' | base64 -d)

if [[ -z "$TOKEN" ]]; then
    echo "❌ Lỗi: Không thể lấy Token từ Secret ${SECRET_NAME}. Hãy kiểm tra lại."
    exit 1
fi
echo "✅ Đã lấy Token thành công."

# 4. Tạo Kubeconfig File
echo "--- Tạo file Kubeconfig: ${KUBECONFIG_OUT} ---"
cat << EOF > "${KUBECONFIG_OUT}"
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $CERT_DATA
    server: $SERVER
  name: k8s-${SA_NAME}
users:
- name: ${SA_NAME}-user
  user:
    token: $TOKEN
contexts:
- context:
    cluster: k8s-${SA_NAME}
    namespace: ${NAMESPACE}
    user: ${SA_NAME}-user
  name: ${SA_NAME}-context
current-context: ${SA_NAME}-context
preferences: {}
EOF
chmod 600 "${KUBECONFIG_OUT}"
echo "✅ Kubeconfig đã tạo thành công tại: ${KUBECONFIG_OUT}"
echo ""

# 5. Dọn dẹp các tệp tin trung gian
echo "--- Dọn dẹp tệp tin trung gian ---"
rm -f "${OUTPUT_DIR}/${SA_NAME}-rbac.yaml"
echo "✅ Đã xóa file định nghĩa RBAC gốc."

# 6. Gợi ý kiểm tra quyền hạn (KHÔNG thực thi)
echo "--- Gợi ý kiểm tra quyền hạn ---"
echo "Để kiểm tra: Dùng file ${KUBECONFIG_OUT}."
echo "1. Thử truy cập tài nguyên trong Namespace ${NAMESPACE} (ví dụ: kubectl --kubeconfig=${KUBECONFIG_OUT} get pods). Kết quả: **THÀNH CÔNG**."
echo "2. Thử truy cập tài nguyên ngoài Namespace (ví dụ: kubectl --kubeconfig=${KUBECONFIG_OUT} get node). Kết quả: **BỊ TỪ CHỐI** (Forbidden)."
