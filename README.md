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

Running command:
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
