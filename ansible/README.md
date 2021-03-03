# Ansible playbooks to deploy service that receives `JSON` object and return a string decorated with emoji in the following manner:

```sh
curl -XPOST -d'{"word":"evilmartian", "count": 3}' http://myvm.localhost/
💀evilmartian💀evilmartian💀evilmartian💀

curl -XPOST -d'{"word":"mice", "count": 5}' http://myvm.localhost/
🐘mice🐘mice🐘mice🐘mice🐘mice🐘
```

## Requirements
First of all you should have `Python 3` and `Ansible` installed on your *Ansible automation platform*, and ssh access to remote machine which would be managed with `Python 3` installed.
To provide the ability to generate and distribute an ssh key to a remote machine, `sshpass`, `ssh-keygen` and `ssh-copy-id` must also be installed on localhost.
In my case I used Virtualbox VM with ssh access for `root` user with password (*qwer*) authentication (at start) as remote machine and my localhost as Ansible automation platform.

To be able connect to the remote machine I configured VM network adapter as attached to "Bridget Adapter".
<br/>![vm_net_setup](https://user-images.githubusercontent.com/63558838/109476250-b7ef0280-7a87-11eb-87d2-5ef1a917e6e6.png)<br/>
An example of my node access configuration at this point is the `inventory` file. You must replace the `ansible_host` IP address in the `[ssh_setup_group]` and `[servers]` groups according to the settings of your remote machine.

**NOTE:** To be able connect to remote machine using hostname instead IP address if you have sudo access, you could add entry in `/etc/hosts`.

## How it works
The environment is deployed by executing Ansible's playbooks (*.yml files in `tasks/` directory):
* ***ssh_access.yml***
The first step is create `admin` user on remote machine, create ssh-key pair on localhost and store public part of this key in `admin's` `authorized_keys` on remote machine to get ssh access for that user using ssh-key authorization instead password.
Also in this step disable root login and disable password authentication.
* ***firewall.yml***
The second step is setup firewall rules. Remote machine should allow connections only to the ports 22, 80, 443.
* ***openssl.yml***
Install pyOpenSSL and generate self signed certificate with private key.
* ***flask.yml***
Install Flask and emoji modules, copy to server application files, configure systemd so that the application starts after reboot, launch service.
* ***nginx.yml***
Install nginx web server, configure it as reverse-proxy to Flask app.
Setup redirection from unsecure (http:) connection on port 80 to secured (https:) on port 443.
* ***deploy_emoji_app.yml***
Launch all playbooks described above in the same order.

## Usage
To launch deploy process in the directory with inventory and .yml run:
```sh
$ ansible-playbook --vault-password-file vault_pass deploy_emoji_app.yml
```

**NOTE:** The vault password file (like all other sensitive data files) **should not** be added to source control! The `vault_pass` file was only added because this is a training repository.
<br/>Encrypted passwords (including the *root* user for initial access) are stored in `group_vars/all`.
<br/>More details here: [https://docs.ansible.com/ansible/2.8/user_guide/playbooks_vault.html](https://docs.ansible.com/ansible/2.8/user_guide/playbooks_vault.html)<br/>
<br/>After the deployment is complete, you can try running something like this:
```sh
$ curl -XPOST --insecure -d'{"word":"turtle", "count": 8}' https://myvm.localhost/
```
or this:
```sh
$ curl -XPOST -d'{"word":"elephant", "count": 3}' http://192.168.1.246/
```
<br/>![output_sample](https://user-images.githubusercontent.com/63558838/109478943-e91d0200-7a8a-11eb-9447-42538f578e95.png)<br/>
**NOTE:** The `--insecure` flag added to allow `curl` connect to the server using an *untrusted* selfsigned certificate when connected via https.
<br/>More details here: [https://curl.se/docs/sslcerts.html](https://curl.se/docs/sslcerts.html)
## GET method
To test http `GET` request method, you can enter the IP address of the remote machine in the address bar of your preferred browser.
After accepting the risks of using an untrusted certificate, the index page is displayed.
<br/>![index](https://user-images.githubusercontent.com/63558838/109476239-b58ca880-7a87-11eb-86ce-217dd7fa1f68.png)<br/>
By adding the name of an emoji to the address, you can see its preview.
<br/>![thumbs_up](https://user-images.githubusercontent.com/63558838/109476248-b7566c00-7a87-11eb-8627-334547434e3d.png)
<br/>![cat](https://user-images.githubusercontent.com/63558838/109476242-b6bdd580-7a87-11eb-855d-3f7c82f72549.png)
