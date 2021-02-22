## Ansible playbooks to deploy service that receives `JSON` object and return a string decorated with emoji in the following manner:

```sh
curl -XPOST -d'{"word":"evilmartian", "count": 3}' http://myvm.localhost/
💀evilmartian💀evilmartian💀evilmartian💀

curl -XPOST -d'{"word":"mice", "count": 5}' http://myvm.localhost/
🐘mice🐘mice🐘mice🐘mice🐘mice🐘
```

### Requirements
First of all you should have ssh access to host with Ansible installed, and ssh access to remote machine with `Python 3` installed which would be managed.
In my case I used Virtualbox VM with ssh access for `root` user with password authentication (at start) as remote machine and my localhost with ssh access by ssh-private key as my `Ansible automation platform`.
Since both nodes use the same IP/hostname (127.0.0.1/localhost), to allow ssh connection TCP 2222 port of host system forwarded to port 22 of guest system.

Example of my access-configuration to nodes at this stage presented inventory `inventory` file.

### Usage
The first step is create `admin` user on remote machine, create ssh-key pair on localhost and store public part of this key in `admin's` `authorized_keys` on remote machine to get ssh access for that user using ssh-key authorization instead password.
Also in this step disable root login and disable password authentication.

run:

```bash
ansible-playbook -i inventory _ssh_access.yml
```

The second step is setup firewall rules. Remote machine with our service should allow connections only to the ports 22, 80, 443.

run:

```bash
ansible-playbook -i inventory _firewall.yml
```
