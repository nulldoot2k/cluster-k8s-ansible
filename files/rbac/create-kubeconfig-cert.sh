#!/bin/bash

# Thiết lập chế độ nghiêm ngặt và thoát nếu có lỗi
set -euo pipefail

# --- KHỞI TẠO BIẾN VÀ HỎI THÔNG TIN ---
read -p "Nhập tên người dùng (CN trong Certs): " USER_NAME
read -p "Nhập tên Namespace để phân quyền: " NAMESPACE
read -p "Nhập tên thư mục output (ví dụ: hacker): " OUTPUT_DIR

# Định nghĩa tên Cluster (lấy từ context hiện tại)
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
CA_B64=$(kubectl config view --raw --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
KUBECONFIG_OUT="${OUTPUT_DIR}/${USER_NAME}-kubeconfig-cert"
ROLE_NAME="${USER_NAME}-role"
ROLEBINDING_NAME="${USER_NAME}-rolebinding"
CERT_DAYS=365

echo "--- Bắt đầu tạo Kubeconfig cho User: ${USER_NAME} trong Namespace: ${NAMESPACE} ---"

# 1. Tạo thư mục output
mkdir -p "${OUTPUT_DIR}"
echo "✅ Tạo thư mục: ${OUTPUT_DIR}"

# 2. Tạo RBAC Definition (Namespace, Role, RoleBinding)
echo "--- Tạo file RBAC: ${OUTPUT_DIR}/${USER_NAME}-rbac.yaml ---"
cat << EOF > "${OUTPUT_DIR}/${USER_NAME}-rbac.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
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
- kind: User
  name: ${USER_NAME}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f "${OUTPUT_DIR}/${USER_NAME}-rbac.yaml"
echo "✅ Áp dụng RBAC và Namespace"

# 3. Tạo Key và CSR
echo "--- Tạo Key và CSR cho User: ${USER_NAME} ---"
openssl genrsa -out "${OUTPUT_DIR}/${USER_NAME}.key" 2048
openssl req -new -key "${OUTPUT_DIR}/${USER_NAME}.key" -subj "/CN=${USER_NAME}/O=devops" -out "${OUTPUT_DIR}/${USER_NAME}.csr"

CSR_B64=$(base64 -w0 < "${OUTPUT_DIR}/${USER_NAME}.csr")

# 4. Gửi và Phê duyệt CSR
echo "--- Gửi và Phê duyệt CSR ---"
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER_NAME}-client-csr
spec:
  request: ${CSR_B64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: $((CERT_DAYS * 24 * 3600))
  usages:
  - client auth
EOF

echo "Đợi 2 giây và Phê duyệt CSR..."
sleep 2
kubectl certificate approve "${USER_NAME}-client-csr"

# 5. Tải về Chứng chỉ đã ký
echo "--- Tải về Cert đã ký ---"
kubectl get csr "${USER_NAME}-client-csr" -o jsonpath='{.status.certificate}' | base64 --decode > "${OUTPUT_DIR}/${USER_NAME}.crt"
CERT_B64=$(base64 -w0 < "${OUTPUT_DIR}/${USER_NAME}.crt")
KEY_B64=$(base64 -w0 < "${OUTPUT_DIR}/${USER_NAME}.key")

# 6. Tạo Kubeconfig File
echo "--- Tạo file Kubeconfig: ${KUBECONFIG_OUT} ---"
cat > "${KUBECONFIG_OUT}" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: ${CLUSTER_NAME}
  cluster:
    server: ${APISERVER}
    certificate-authority-data: ${CA_B64}
users:
- name: ${USER_NAME}
  user:
    client-certificate-data: ${CERT_B64}
    client-key-data: ${KEY_B64}
contexts:
- name: ${USER_NAME}@${CLUSTER_NAME}
  context:
    cluster: ${CLUSTER_NAME}
    namespace: ${NAMESPACE}
    user: ${USER_NAME}
current-context: ${USER_NAME}@${CLUSTER_NAME}
EOF
chmod 600 "${KUBECONFIG_OUT}"
echo "✅ Kubeconfig đã tạo thành công tại: ${KUBECONFIG_OUT}"
echo ""

# 7. Dọn dẹp các tệp tin nhạy cảm và trung gian
echo "--- Dọn dẹp tệp tin trung gian/nhạy cảm ---"
rm -f "${OUTPUT_DIR}/${USER_NAME}.key"
rm -f "${OUTPUT_DIR}/${USER_NAME}.csr"
rm -f "${OUTPUT_DIR}/${USER_NAME}.crt"
kubectl delete csr "${USER_NAME}-client-csr" &> /dev/null || true
echo "✅ Đã xóa Key, CSR và Cert gốc. Chỉ giữ lại file kubeconfig."

# 8. Gợi ý kiểm tra quyền hạn (KHÔNG thực thi)
echo "--- Gợi ý kiểm tra quyền hạn ---"
echo "Để kiểm tra: Dùng file ${KUBECONFIG_OUT}."
echo "1. Thử truy cập tài nguyên trong Namespace ${NAMESPACE} (ví dụ: kubectl --kubeconfig=${KUBECONFIG_OUT} get pods). Kết quả: **THÀNH CÔNG**."
echo "2. Thử truy cập tài nguyên ngoài Namespace (ví dụ: kubectl --kubeconfig=${KUBECONFIG_OUT} get node). Kết quả: **BỊ TỪ CHỐI** (Forbidden)."
