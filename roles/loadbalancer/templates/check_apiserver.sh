 #!/bin/sh

 errorExit() {
     echo "*** $*" 1>&2
     exit 1
 }

{% if lb.haproxy_vip %}
 curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
 if ip addr | grep -q {{ virtual_ip }}; then
     curl --silent --max-time 2 --insecure https://{{ virtual_ip }}:6443/ -o /dev/null || errorExit "Error GET https://{{ virtual_ip }}:6443/"
 fi
{% else %}
 curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
 if ip addr | grep -q {{ lb.virtual_ip }}; then
     curl --silent --max-time 2 --insecure https://{{ lb.virtual_ip }}:6443/ -o /dev/null || errorExit "Error GET https://{{ lb.virtual_ip }}:6443/"
 fi
{% endif %}
