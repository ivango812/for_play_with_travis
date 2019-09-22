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
testapp_IP = 35.246.206.213
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
