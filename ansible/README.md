# Ansible playbooks to deploy service that receives `JSON` object and return a string decorated with emoji in the following manner:

```sh
curl -XPOST -d'{"word":"evilmartian", "count": 3}' http://myvm.localhost/
💀evilmartian💀evilmartian💀evilmartian💀

curl -XPOST -d'{"word":"mice", "count": 5}' http://myvm.localhost/
🐘mice🐘mice🐘mice🐘mice🐘mice🐘
```

## Requirements
First of all you should have `Python 3` and `Ansible` installed on your *Ansible automation platform*, and ssh access to remote machine which would be managed with `Python 3` installed.
In my case I used Virtualbox VM with ssh access for `root` user with password authentication (at start) as remote machine and my localhost as Ansible automation platform.

To be able connect to the remote machine I configured VM network adapter as attached to "Bridget Adapter".
<br/>![vm_net_setup](https://user-images.githubusercontent.com/63558838/109376759-d57d6a00-78d7-11eb-8367-683589d1b6a2.png)<br/>
Example of my access-configuration to nodes at this stage presented inventory `inventory` file. You should replace `ansible_host` IP address in `[ssh_setup_group]` and `[servers]` groups accordingly your remote machine setup.

**NOTE:** to be able connect to remote machine using hostname instead IP address if you have sudo access, you could add entry in `/etc/hosts`.   

## How it works
The environment is deployed by executing Ansible's playbooks (.yml files):
* ***_ssh_access.yml***
The first step is create `admin` user on remote machine, create ssh-key pair on localhost and store public part of this key in `admin's` `authorized_keys` on remote machine to get ssh access for that user using ssh-key authorization instead password.
Also in this step disable root login and disable password authentication.
* ***_firewall.yml***
The second step is setup firewall rules. Remote machine should allow connections only to the ports 22, 80, 443.
* ***_openssl.yml***
Install pyOpenSSL and generate selfsigned certificate with private key.
* ***_flask.yml***
Install Flask and and emoji modules, copy to server application files, configure systemd so that the application starts after reboot, launch service. 
* ***_nginx.yml***
Install nginx webserver, configure it as reverse-proxy to Flask app.
Setup redirection from unsecure (http:) connection on port 80 to secured (https:) on port 443.
* ***_deploy_emoji_app.yml***
Launch all playbooks described above in the same order.

## Usage
To launch deploy proccess in the directory with inventory and .yml:
```sh
$ ansible-playbook _deploy_emoji_app.yml
```
After the deployment is complete, you can try running something like this:
```sh
$ curl -XPOST --insecure -d'{"word":"turtle", "count": 8}' https://myvm.localhost/
```
<br/>![output_sample](https://user-images.githubusercontent.com/63558838/109376760-d6160080-78d7-11eb-95b5-f66861e917f0.png)<br/>
**NOTE:** `--insecure` flag added to allow `curl` connect to the server using an *untrusted* selfsigned certificate.
More details here: [https://curl.se/docs/sslcerts.html](https://curl.se/docs/sslcerts.html)
## GET method
To test http `GET` request method, you can enter the IP address of the remote machine in the address bar of your preferred browser.
After accepting the risks of using an untrusted certificate, the index page is displayed.
<br/>![index](https://user-images.githubusercontent.com/63558838/109381613-72e29900-78ec-11eb-89a9-83a38ea0544e.png)<br/>
By adding the name of an emoji to the address, you can see its preview. 
<br/>![thumbs_up](https://user-images.githubusercontent.com/63558838/109376897-8f74d600-78d8-11eb-83c1-ea932c4d19c2.png)<br/>
<br/>![cat](https://user-images.githubusercontent.com/63558838/109376896-8edc3f80-78d8-11eb-94c3-f80546445fdf.png)<br/>
