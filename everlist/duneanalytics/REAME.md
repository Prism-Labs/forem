# Dune Analytics Client Script
======================================================

Dune Analytics client script that is using unofficial python client library [github.com/itzmestar/duneanalytics](https://github.com/itzmestar/duneanalytics).

## Installation

  1. Install Pyenv
  ```sh
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv

    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n eval "$(pyenv init -)"\nfi' >> ~/.bashrc
  ```

  2. Install appropriate python version and dependencies
  ```sh
    pyenv install $(cat .python-version)
    pyenv local $(cat .python-version)

    pip install -r requirements.txt
  ```
