## Instalando Docker e ativando o cluster swarm

[![Build Status](https://github.com/diogoab/devopstools/graphs/contributors)]

Atualizar o sistema e instalar o Ansible com os seguintes comandos:

```console
$ sudo apt-get update
$ sudo apt-get install software-properties-common
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt-get update
$ sudo apt-get install ansible
```

Criar diretórios do projeto
```console
$ mkdir -p /home/cluster_docker/roles; mkdir /home/cluster_docker/group_vars
$ cd /home/cluster_docker
$ touch /home/cluster_docker/hosts; touch /home/cluster_docker/main.yml
```
Configurar os servidores que receberão as instalações, podendo usar uma key para autenticar ou sua senha.
>vim /home/cluster_docker/hosts

```
[docker_swarm_manager]
MANAGER1 ansible_ssh_host=10.0.0.4 ansible_ssh_port=22 ansible_ssh_user=root ansible_ssh_private_key_file=keys/key_master.pem
[docker_swarm_worker]
WORKER1 ansible_ssh_host=10.0.0.5 ansible_ssh_port=22 ansible_ssh_user=root ansible_ssh_pass=yourpass
```

Instalação do Docker
 
 >/home/cluster_docker/roles/docker/tasks/main.yml:

```
---
  - name: Realizando apt-get update
    apt:
     update_cache: yes
  - name: Modificando hostname
    shell: hostname {{ inventory_hostname }}

  - name: Instalando a versão mais recente do Docker
    shell: curl -sS https://get.docker.com | sh

  - name: Reiniciar serviço do Docker
    systemd:
     state: restarted
     enabled: yes
     daemon_reload: yes
     name: docker
```


Configuração do Manager
>/home/cluster_docker/roles/manager/tasks/main.yml:

```
---
  - name: Verifica se o Docker Swarm está habilitado
    shell: docker info
    changed_when: False
    register: docker_info

  - name: Cria o cluster no primeiro servidor
    shell: docker swarm init --advertise-addr {{ docker_swarm_manager_ip }}:{{ docker_swarm_manager_port }}
    when: "docker_info.stdout.find('Swarm: active') == -1 and inventory_hostname == groups['docker_swarm_manager'][0]"

  - name: Armazena o token de manager
    shell: docker swarm join-token -q manager
    changed_when: False
    register: docker_manager_token
    delegate_to: "{{ groups['docker_swarm_manager'][0] }}"
    when: "docker_info.stdout.find('Swarm: active') == -1"
 
  - name: Adiciona os outros swarms Managers no cluster.
    shell: docker swarm join --token "{{ docker_manager_token.stdout }}" {{ docker_swarm_manager_ip}}:{{ docker_swarm_manager_port }} 
    changed_when: False
    when: "docker_info.stdout.find('Swarm: active') == -1
     and docker_info.stdout.find('Swarm: pending') == -1
     and 'docker_swarm_manager' in group_names
     and inventory_hostname != groups['docker_swarm_manager'][0]"
```

Configuração do Worker
>/home/cluster_docker/roles/worker/tasks/main.yml:

```
---
  - name: Verifica se o Docker Swarm está habilitado.
    shell: docker info
    changed_when: False
    register: docker_info

  - name: Pega o token do worker.
    shell: docker swarm join-token -q worker
    changed_when: False
    register: docker_worker_token
    delegate_to: "{{ groups['docker_swarm_manager'][0] }}"
    when: "docker_info.stdout.find('Swarm: active') == -1"

  - name: Adiciona o servidor de Worker no cluster.
    shell: docker swarm join --token "{{ docker_worker_token.stdout }}" {{ docker_swarm_manager_ip}}:{{ docker_swarm_manager_port }}
    changed_when: False
    when: "docker_info.stdout.find('Swarm: active') == -1
           and docker_info.stdout.find('Swarm: pending') == -1"
```

Configuração do Manager
>/home/cluster_docker/group_vars/all
```
---
  docker_swarm_manager_ip: "10.0.0.2"
  docker_swarm_manager_port: "2377"
```

Playbook principal
>/home/cluster_docker/main.yml

```
---
 - name: Configurando Managers
   hosts: docker_swarm_manager

   roles:
     - docker
     - manager

 - name: Configurando Workers
   hosts: docker_swarm_worker
   roles:
    - docker
    - worker

```

Instalação do Cluster
```
 ansible-playbook -i hosts main.yml
```
