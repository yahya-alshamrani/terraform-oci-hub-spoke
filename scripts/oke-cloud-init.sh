#!/bin/bash
curl --fail -H "Authorization: Bearer Oracle" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh
bash /var/run/oke-init.sh
## Configure the disk
bash /var/run/oke-init.sh
sudo growpart /dev/sda 3
sudo pvresize /dev/sda3
sudo lvextend -r -l +100%FREE /dev/mapper/ocivolume-root 
sudo systemctl restart kubelet.service
## disable short_name
sudo sed -i '/crio.image/s@$@\n    short_name_mode = "disabled"@' /etc/crio/crio.conf.d/00-default.conf
sudo systemctl restart crio.service