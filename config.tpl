Host bastion
  HostName ${bastion_ip}
  User ubuntu
  IdentityFile ~/.ssh/epam.pem
  host_key_checking = False

Host ${web_ip}
  HostName ${web_ip}
  ProxyJump  bastion
  User ubuntu
  IdentityFile ~/.ssh/epam.pem
