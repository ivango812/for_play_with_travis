# ivango812_infra
ivango812 Infra repository

# Lesson 5

Two VM were created in GCE:

```
bastion_IP = 34.68.245.185
someinternalhost_IP = 10.128.0.3
```

To get to the GCP local VM trough bastion host by one command:

`ssh -tt -i ~/.ssh/appuser -A appuser@34.68.245.185 ssh 10.128.0.3`

or for ssh version 7.3 and above:

`ssh -i ~/.ssh/appuser -J appuser@34.68.245.185 appuser@10.128.0.3`

or create ~/.ssh/config file:
```
Host bastion
    HostName 34.68.245.185
    User appuser

Host someinternalhost
    HostName 10.128.0.3
    User appuser
    ProxyCommand ssh -W %h:%p bastion
```

and connect to someinternalhost by:

`ssh someinternalhost`

VPN Server Pritunl installed on bastion host and configured at https://vpn.newbusinesslogic.com
"Let's Enctypt" SSL certificate was configured on the domain.

# Lesson 6

```
testapp_IP = 35.198.173.140
testapp_port = 9292
```

Several script were created:

`install_ruby.sh` - to install ruby environment

`install_mongodb.sh` - to install mongodb

`deploy.sh` - to deploy ruby application "puma"

`startup_script.sh` - to install ruby, mongodb and run application "puma" during instance creation

gcloud command to create instance with launched application:

```
gcloud compute instances create reddit-app\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh
```

# Lesson 7

Studying Packer https://www.packer.io

Two images was created:

- one "base" image by [`packer/ubuntu16.json`](https://github.com/Otus-DevOps-2019-08/ivango812_infra/blob/packer-base/packer/ubuntu16.json) file
- second one "full" image with ruby, mongo, puma by [`packer/immutable.json`](https://github.com/Otus-DevOps-2019-08/ivango812_infra/blob/packer-base/packer/immutable.json) file based on the "base" image

Script for GCE-instance creation based on "full" image placed here: [`config-scripts/create-reddit-vm.sh`](https://github.com/Otus-DevOps-2019-08/ivango812_infra/blob/packer-base/config-scripts/create-reddit-vm.sh)

- Instance on "base" image: http://34.76.44.118:9292
- Instance on "full" image: http://34.77.196.237:9292

!Notes:

1. If you want debug packer image creation use:

- add ` -x` to scripts shebang `#!/bin/bash -x`
- `PACKER_LOG=1 packer ...` run to see packer logs

2. If the provisioning user (generally not root) 
cannot write to this directory, you will receive a "Permission Denied" error.
Then put file to the user home directory and then copy file with inline command using `sudo`

Example:
```
        {
            "type": "file",
            "source": "files/puma.service",
            "destination": "/home/appuser/puma.service"
        },
        {
            "type": "shell",
            "inline": [
                "sudo cp /home/appuser/puma.service /lib/systemd/system/",
                "sudo systemctl enable puma"
            ]
        }
```

3. During working with packer I faced with the next issue - image creation process crashed with next error:

```
==> googlecompute: + apt update
==> googlecompute:
==> googlecompute: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> googlecompute:
    googlecompute: Hit:1 http://europe-west1.gce.archive.ubuntu.com/ubuntu xenial InRelease
    googlecompute: Get:2 http://europe-west1.gce.archive.ubuntu.com/ubuntu xenial-updates InRelease [109 kB]
    googlecompute: Get:3 http://europe-west1.gce.archive.ubuntu.com/ubuntu xenial-backports InRelease [107 kB]
    googlecompute: Get:4 http://security.ubuntu.com/ubuntu xenial-security InRelease [109 kB]
    googlecompute: Ign:5 http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 InRelease
    googlecompute: Hit:6 http://archive.canonical.com/ubuntu xenial InRelease
    googlecompute: Hit:7 http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 Release
    googlecompute: Get:8 http://europe-west1.gce.archive.ubuntu.com/ubuntu xenial-updates/main amd64 Packages [1,033 kB]
    googlecompute: Get:9 http://europe-west1.gce.archive.ubuntu.com/ubuntu xenial-updates/universe amd64 Packages [764 kB]
    googlecompute: Get:10 http://security.ubuntu.com/ubuntu xenial-security/main amd64 Packages [748 kB]
    googlecompute: Get:11 http://security.ubuntu.com/ubuntu xenial-security/universe amd64 Packages [458 kB]
    googlecompute: Fetched 3,328 kB in 2s (1,275 kB/s)
    googlecompute: Reading package lists...
==> googlecompute: + sleep 30
    googlecompute: Building dependency tree...
    googlecompute: Reading state information...
    googlecompute: 4 packages can be upgraded. Run 'apt list --upgradable' to see them.
==> googlecompute: + apt install -y ruby-full ruby-bundler build-essential
==> googlecompute:
==> googlecompute: WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
==> googlecompute:
==> googlecompute: E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)
==> googlecompute: E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
```

It's unsolved issue so far.

Run command for build an image:
`PACKER_LOG=1 packer build -var 'project_id=titanium-deck-253210' -var 'source_image=reddit-base-1569316717' packer-config.json`

packer-config.json

```
{
    "variables": {
        "project_id": null,
        "source_image": null,
        "machine_type": "f1-micro"
    },
    "builders": [
        {
            "type": "googlecompute",
            "project_id": "{{ user `project_id`}}",
            "image_name": "reddit-full-{{timestamp}}",
            "source_image": "{{ user `source_image`}}",
            "zone": "europe-west1-b",
            "ssh_username": "appuser",
            "machine_type": "{{ user `machine_type`}}",
            "image_description": "Puma preinstalled image",
            "disk_size": 10,
            "disk_type": "pd-standard",
            "network": "default",
            "tags": ["puma-server"]
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```

`install_ruby.sh`:

```
#!/bin/bash -x
apt update
sleep 30 # added trying to figure out the issue
apt install -y ruby-full ruby-bundler build-essential
```

# Lesson 8

Studying Terraform http://terraform.io/

Terraform files for instance "reddit-app" launch were created:
```
main.tf
variables.tf
terraform.tfvars
output.tf
```

Also was created `.gitignore`:

```
*.tfstate
*.tfstate.*.backup
*.tfstate.backup
*.tfvars
.terraform/
```

I tried to add second user `appuser2` with existing ssh-key, and faced with log in problem: 
`Permission denied (publickey).`

Cleaning ~/.ssh/know_hosts helps.

Load balancer was added to [`lb.tf`]() file for instance "reddit-app".

Then second instance "reddit-app2" was added to the instances group in load balancer.
It was inconvenient cause of duplicating a lot of code.

So, the best way - to use `count` argument in the `resource` body.
It was implemented in the final version of [`lb.tf`]()

# Lesson 9

Learning modules, provisioners and other small features...

If we already have some infrastructure or some resources in our cloud we should load it  into terraform state file by using `import` command
```
terraform import
```
Before you run it - create empty resources in `*.tf` file

Resource dependency:
- explicit dependency (depends_on = "*resource link*")
- implicit dependency (if resource has link to other resource or its attribute) In this case terraform will wait until the required resource is created

I splitted `main.tf` with the single project instance onto two instances in two files `app.tf` and `db.tf` 

**Modules**

After that I put the general functionality into separate modules: `app`, `db` and `vpc`

At the same time I parameterized the modules so that they can be reused by setting different input variables.

A GCP bucket was created for `.tfstate` storing and reconfigured my project for storing state into this bucket.
`storage-bucket.tf` for creating bucket
`prod/backend.tf`, `stage/backend.tf` - for using this bucket


Added provisioners for configuring and launching our applications:
- `puma` server at `app` instance 
- and `mongodb` at `db` instance

I used three types of provisioners:
- `file` - for copying `puma.service` and `mongod.conf` files
- `remote-exec` (inline, script) - see it bellow
- `local-exec` (by trigger `when = "destroy"`)

**Mongo configuring**

As we put mongodb server as separate instance we need to forward mongo ip address and port to the instance with the app. It was implemented by using module 'db' output variables as input for module 'app'

Ruby application is waiting an `DATABASE_URL`, so I collected `mongo_ip` and `mongo_port` in one string `DATABASE_URL`:
```
  database_url     = "${module.db.mongo_ip}:${module.db.mongo_port}"
```

then I created `mongod.conf` to force mongo listen external ip address.
See: 

As our modules were parameterized now I can create two environment `stage` and `prod` using the same modules.

After destroy/apply inctances ip could be different and we can't login through SSH because we have an ssh-key in ~/.ssh/known_hosts file from the old deleted instance with the same ip. So, to prevent it we need to delete ssh-key manually from `known_hosts` or by
```
ssh-keygen -R <ip_address>
```
We can add this command to the `local-exec `provisioner like that:

```
  provisioner "local-exec" {
    when = "destroy"
    command= "ssh-keygen -R ${self.network_interface[0].access_config[0].nat_ip}"
  }
```

# Lesson 10

Learning Ansible

Requirements: Python >=2.7

Install Ansible `pip install ansible>=2.4` or `pip install -r requirements.txt`

**Inventory**

Created `invetory` file

Up instances `app` and `db` from the previous lesson *Terraform*

Playing with ansible modules - option ` -m <module>`

Create `ansible.cfg` and clear up `invetory` all default settings

Add groups to the `inventory`: `[app]` and `db`

Dublicate `invenory` into `inventory.yml` and check it

Playing with `shell`, `command`, `service` modules

Conclusion - use more specific modules pather then common: 
- `service` instead of `command -a 'systemctl ...`
- `git` instead of `command -a 'git ...`
- `file -a 'state=absent path=~/reddit'` instead `command -a 'rm -rf ~/reddit'` - doesn't show the state correctly
- etc.

`ansible app -m ` missed for short.

Also - more specific module works properly when you run the command again

**Playbook**

`ansible-playbook clone.yml`

Playbook runs git clone command (use module `git`)

**inventory.json and Dynamic inventory**

Static `inventory.json` is the direct reflection of the `inventory.yml`

Dynamic `inventory.json` that produces by script (in our case by `inventory.py` (python 2.7 require) has additional section "_meta" that contains variables.

Example:

```
{
    "app": {
        "hosts": [
            "appserver"
        ]
    }, 
    "all": {
        "children": [
            "app", 
            "db"
        ]
    }, 
    "db": {
        "hosts": [
            "dbserver"
        ]
    }, 
    "_meta": {
        "hostvars": {
            "appserver": {
                "ansible_host": "146.148.8.111"
            }, 
            "dbserver": {
                "ansible_host": "35.187.177.167"
            }
        }
    }
}
```

`inventory.py` reads hosts ip from the `terraform output`. I created `terraform.tfstate.test_for_ansible` file in the `./terraform` directory for Travis test.

I put it into `./terraform`, not into `./terraform/stage` because it has local state file configuration, `./terraform/stage` storing state at the GCP Storate bucket.


# Lesson 11

Up infrastructure without running provisioners:

```
$ cd terraform/stage
$ terraform apply -var 'enable_provisioner=false' --auto-approve
$ cd ../..
```

For `ansible --check` works - install `python-apt` first:
```
$ ansible -i inventory.gcp.yml all -m "apt name=python-apt state=latest" --become
```

Recreate images with packer:
```bash
$ packer build -var-file=packer/variables.json packer/db.json
$ packer build -var-file=packer/variables.json packer/app.json
```

Then run:

```
cd ansible
ansible-playbook -i inventory.gcp.yml site.yml
```

In `inventory.gcp.yml`:
- to group hosts use `groups`
- to filter hosts use `filters`
- to get external ip from GCP inventory use `compose`

```
plugin: gcp_compute
projects:
  - titanium-deck-253210
hostnames:
  - name
compose:
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
filters: 
  - name = reddit*
groups:
  app: "'reddit-app' in name"  
  db: "'reddit-db' in name"  
auth_kind: serviceaccount
service_account_file: titanium-deck-253210-b60e30301bcf.json
```

To add internal ip of mongodb in app playbook:
```
  vars:
    db_host: "{{ hostvars['reddit-db-stage'].networkInterfaces[0].networkIP }}"
```

Destory all instances at the end:
```
$ cd terraform/stage
$ terraform destroy --auto-approve
```
