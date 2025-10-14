#!/bin/bash

PYTHON_VERSION="3.12.0"

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to check if pyenv is installed
pyenv_installed() {
  [ -d "$HOME/.pyenv" ] && command_exists pyenv
}

# Function to check if pyenv-virtualenv is installed
pyenv_virtualenv_installed() {
  command_exists pyenv-virtualenv
}

# Function to check if a Python version is installed
python_version_installed() {
  pyenv versions 2>/dev/null | grep -q "$1"
}

# Function to check if a virtualenv exists
virtualenv_exists() {
  pyenv virtualenvs 2>/dev/null | grep -q "$1"
}

# Function to check if ansible is installed in current env
ansible_installed() {
  pip list 2>/dev/null | grep -q "^ansible[[:space:]]"
}

# Step 1: Install pyenv, Python, and Ansible (isolated to this directory)
install_all() {
  echo "Installing pyenv, Python $PYTHON_VERSION, and Ansible (isolated to this directory only)..."

  # Install pyenv dependencies if needed
  if ! command_exists make || ! command_exists curl; then
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
      libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev \
      libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
  fi

  # Install pyenv if not installed
  if ! pyenv_installed; then
    curl https://pyenv.run | bash
    if ! grep -q "PYENV_ROOT" ~/.bashrc; then
      echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
      echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
      echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
      echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
    fi
    source ~/.bashrc
  fi

  # Install pyenv-virtualenv if not installed
  if ! pyenv_virtualenv_installed; then
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)/plugins/pyenv-virtualenv"
    if ! grep -q "pyenv virtualenv-init" ~/.bashrc; then
      echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
    fi
    source ~/.bashrc
  fi

  # Install fixed Python version
  if ! python_version_installed "$PYTHON_VERSION"; then
    pyenv install "$PYTHON_VERSION"
  fi

  # Create virtualenv if not exists
  if ! virtualenv_exists "ansible-env"; then
    pyenv virtualenv "$PYTHON_VERSION" ansible-env
  fi

  # Uninstall global Ansible if it exists
  if command_exists ansible; then
    echo "Global Ansible detected. Uninstalling to ensure isolation..."
    sudo apt remove --purge ansible ansible-core -y 2>/dev/null
    sudo apt autoremove -y 2>/dev/null
    pip uninstall -y ansible ansible-core ansible-base 2>/dev/null
    if command_exists ansible; then
      echo "Warning: Could not fully uninstall global Ansible. Manually remove it if needed."
    else
      echo "Global Ansible removed."
    fi
  fi

  # Activate virtualenv, install Ansible, and verify
  pyenv activate ansible-env
  if ! ansible_installed; then
    pip install --upgrade pip
    pip install ansible pywinrm pyvmomi ansible[azure] || {
      echo "Error: Failed to install Ansible."
      pyenv deactivate
      return 1
    }
  fi
  ansible --version && echo "Ansible installed in virtualenv." || {
    echo "Error: Ansible not found after installation."
    pyenv deactivate
    return 1
  }
  pyenv deactivate

  # Set local virtualenv for auto-activation in this directory
  pyenv local ansible-env

  echo "Installation completed. Ansible is only available when 'cd' into this directory (auto-activated by pyenv). Run 'source ~/.bashrc' or restart terminal if needed."
}

# Step 2: Uninstall Ansible and delete the virtualenv
uninstall_ansible() {
  echo "Uninstalling Ansible and deleting virtualenv ansible-env..."
  if virtualenv_exists "ansible-env"; then
    pyenv activate ansible-env 2>/dev/null
    pip uninstall -y ansible pywinrm pyvmomi ansible-core ansible-base 2>/dev/null
    pyenv deactivate 2>/dev/null
    pyenv virtualenv-delete -f ansible-env 2>/dev/null && echo "Virtualenv deleted." || echo "Error: Failed to delete virtualenv."
    rm -f .python-version
  else
    echo "Virtualenv not found. Nothing to uninstall."
  fi
}

# Display menu
show_menu() {
  echo "════════════════════════════════════"
  echo "1. Cài đặt Pyenv + Python + Ansible"
  echo "2. Gỡ Ansible và hủy môi trường ảo"
  echo "3. Thoát"
  echo "════════════════════════════════════"
  echo -n "Chọn (1-3): "
}

# Main script logic
while true; do
  show_menu
  read choice
  case "$choice" in
    1)
      install_all
      ;;
    2)
      uninstall_ansible
      ;;
    3)
      echo "Thoát."
      exit 0
      ;;
    *)
      echo "Lựa chọn không hợp lệ."
      ;;
  esac
  echo
done
