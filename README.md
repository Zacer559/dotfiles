
![Dotfiles Logo](https://dotfiles.github.io/images/dotfiles-logo.png)

# Dotfiles Configuration

Welcome to my dotfiles configuration! This repository provides a fully automated development environment inspired by the work of [TechDufus](https://github.com/TechDufus/dotfiles) and [ALT-F4-LLC](https://github.com/ALT-F4-LLC/dotfiles). Below you'll find all the necessary information to set up and maintain your development environment using Ansible.

## Goals

Provide a fully automated `Arch` development environment that is easy to set up and maintain.

### Why Ansible?

Ansible replicates the manual steps we would take to set up a development environment. Among various automation solutions, Ansible is chosen for its simplicity and effectiveness.

## Requirements

### Operating System

This Ansible playbook supports `Arch` distributions to ensure a consistent development experience across hosts.

### System Upgrade

Ensure your `Arch` installation has the latest packages installed before running the playbook.

```sh
# Arch
sudo pacman -Syu
```

> NOTE: This process will take some time.

## Setup

### all.yaml values file

The `all.yaml` file allows you to personalize your setup. This file will be created at `~/.dotfiles/group_vars/all.yaml` after you [install the dotfiles](#install) and include your desired settings.

Below is a list of available values. All are required, but incorrect values will break the playbook if not properly set.

| Name                  | Type                                | Required |
| --------------------- | ----------------------------------- | -------- |
| git_user_email        | string                              | yes      |
| git_user_name         | string                              | yes      |
| git_token             | string                              | yes      |
| ssh_key               | dict `(see SSH Keys below)`         | yes      |
| veracrypt_pim         | int                                 | yes      | 

### SSH Keys

Manage SSH keys by setting the `ssh_key` value in `values.yaml`.

```yaml
---
ssh_key:
  <filename>: !vault |
    $ANSIBLE_VAULT;1.1;AES256
    <encrypted content>
```

> NOTE: All SSH keys will be stored at `$HOME/.ssh/<filename>`.

### Examples

Below are minimal and advanced configuration examples. For a more real-world example, refer to [my public configuration](https://github.com/Zacer559/dotfiles-erikreinert).

#### Minimal

```yaml
---
git_user_email: foo@bar.com
git_user_name: Foo Bar
```

#### Advanced

```yaml
---
git_user_email: foo@bar.com
git_user_name: Foo Bar
exclude_roles:
  - slack
ssh_key: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  <encrypted content>
system_host:
  127.0.0.1: foobar.localhost
bash_public:
  MY_PUBLIC_VAR: foobar
bash_private:
  MY_SECRET_VAR: !vault |
    $ANSIBLE_VAULT;1.1;AES256
    <encrypted content>
```

### vault.secret

The `vault.secret` file allows you to encrypt values with `Ansible vault` and store them securely in source control. Create a file located at `~/.config/dotfiles/vault.secret` with a secure password.

```sh
vim ~/.ansible-vault/vault.secret
```

To encrypt values with your vault password, use the following:

```sh
ansible-vault encrypt_string --vault-password-file ~/.ansible-vault/vault.secret "mynewsecret" --name "MY_SECRET_VAR"
cat myfile.conf | ansible-vault encrypt_string --vault-password-file ~/.ansible-vault/vault.secret --stdin-name "myfile"
```

> NOTE: This file will automatically be detected by the playbook when running the `dotfiles` command to decrypt values. Read more on Ansible Vault [here](https://docs.ansible.com/ansible/latest/user_guide/vault.html).

## Installation

This playbook includes a custom shell script located at `bin/dotfiles`. 

### Install

Run the installation script:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Zacer559/dotfiles/main/bin/dotfiles)"
```

### Script Usage

The `dotfiles` script supports several arguments to customize its behavior. Below are the available options:

```
Usage: ./dotfiles [-r role1,role2,...] [--roles role1,role2,...] [-h] [--help]

Options:
  -r, --roles    Specify the roles to run, separated by commas
  -h, --help     Display this help message
```

#### Examples

1. Run the script with specified roles:
   ```sh
   ./dotfiles -r role1,role2
   ```

2. Display help message:
   ```sh
   ./dotfiles -h
   ```

### Update

To update your environment, run the `dotfiles` command in your shell:

```sh
~/.dotfiles/bin/dotfiles
```

This command will:

- Verify Ansible is up-to-date
- Generate SSH keys and add to `~/.ssh/authorized_keys`
- Clone this repository locally to `~/.dotfiles`
- Verify any `ansible-galaxy` plugins are updated
- Run the playbook with the values in `~/.config/dotfiles/group_vars/all.yaml`

## Contributing

Feel free to submit issues or pull requests if you find any bugs or have suggestions for improvements. Contributions are always welcome!

## License

This project is licensed under the MIT License.

---

Enjoy your customized development environment! If you have any questions or need further assistance, please don't hesitate to reach out.
