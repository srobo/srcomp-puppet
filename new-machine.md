# Setting up a new production host

1. Spin up the VM. It needs to be a supported OS & version; see the
   `Vagrantfile` for the current target.

  **Note**: for TLS configuration to work correctly the hostname of the machine
  must match the public DNS name of the machine. If spinning up a Digtial Ocean
  box, this means the name of the machine you put into DO's UI must be the fully
  qualified name for the machine.

2. Login as root

3. Create a non-root user with `sudo` access:

    ```bash
    useradd --create-home --user-group --groups sudo $USERNAME --shell /bin/bash
    ```

4. Set the password for that account (so it can `sudo`):

    ```bash
    passwd $USERNAME  # and then follow the prompts
    ```

5. Logout and log back in as that user. This is important because our puppet
   configuration removes `ssh` access for the root user.

   **Note**: the remainder of thes instructions require root access, so you
   probably want to `sudo su` at this point.

6. Configure key based SSH access for that user.
   This might look something like:

   ``` bash
   su $USERNAME
   mkdir --parents --mode=700 ~/.ssh
   wget https://github.com/$THEIR_GITHUB_USERNAME.keys -O ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

7. Repeat for another user, so that more than one person has access to
   administer the machine.

8. Bootstrap puppet:

    ```bash
    sudo apt install --yes puppet git
    rm -rf /etc/puppet
    git clone --recurse-submodules https://github.com/PeterJCLaw/srcomp-puppet /etc/puppet
    ```

9. Set up public DNS for the machine.

10. (Optional) If setting up a deployment that will have a different upstream than `srcomp.studentrobotics.org` then you will have to modify `upstreamBase` in `/etc/puppet/modules/compbox/files/comp-services.js`

11. Run the install:

    ```bash
    /etc/puppet/scripts/install
    ```

12. Deploy your compstate using `srcomp deploy` locally. For details on how to
    configure your deployments, see the docs for the [`deploy` command][deploy-docs].

If things change in puppet and you need to re-deploy, you can do so with this command:

```bash
/etc/puppet/scripts/update
```

[deploy-docs]: https://srcomp-cli.readthedocs.io/en/latest/commands/deploy.html
