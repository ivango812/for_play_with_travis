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
