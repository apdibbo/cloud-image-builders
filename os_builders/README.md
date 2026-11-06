# os_builders

## Contents:

- [How to build images](#how-to-build-images)
- [How to update the playbooks](#how-to-update-the-playbooks)
- [How to release a new version](#how-to-release-a-new-verison)

## How to build images

### Setting up the build environment

#### Prerequisites:
- Rocky or Ubuntu VM
- Access to the **packer** project, on dev and prod
- Application credential for **packer** project, admin is not required

#### Steps on VM:

1. Install Python pip and venv modules
   ```shell
   # Ubuntu
   sudo apt install python3-pip python3-venv -y
   # Rocky
   sudo dnf install python3-pip python3-venv -y
   ```

2. Create a virtual environment
   ```shell
   python3 -m venv image_builders
   source image_builders/bin/activate
   ```

3. Clone the repository
   ```shell
   git clone https://github.com/stfc/cloud-image-builders.git

   cd cloud-image-builders/os_builders
   ```

4. Install Python packages
   ```shell
   # Unless you are building Rocky 8 images, use the standard requirements.txt
   pip install -r requirements.txt
   # For Rocky 8 images
   pip install -r requirements-rl8.txt
   ```
  
5. Install Packer and dependencies
   ```shell
   ansible-playbook prep_builder.yml
   ```

6. Create clouds.yaml with application credential
   ```shell
   mkdir -p ~/.config/openstack
   touch ~/.config/openstack/clouds.yaml

   # Using vim or nano, paste your application credential into the clouds.yaml
   ```

### Building the image

The following steps assume you have set up your VM correctly as in the previous steps.

#### Steps on VM:

1. Ensure environment is prepared
   ```shell
   source ~/image_builders/bin/activate
   cd ~/cloud-image-builders/os_builders
   export OS_CLOUD=openstack
   ```
2. Choose from the following steps whether you want to build all, multiple or one image. Also, "env=dev" should match the environment your application credentials were made in.
3. Initiate Packer image build for all images
   ```shell
   packer build --var env=dev build.pkr.hcl
   ```
4. Intiate Packer image build for multiple images
   ```shell
   # Replace image-name with the actual image name. "openstack." is required
   packer build --var env=dev -only <openstack.image-name>,<openstack.image-name>... build.pkr.hcl
   # e.g.
   packer build --var env=dev -only openstack.ubuntu-jammy-22.04-nogui,openstack.rocky-8-nogui build.pkr.hcl
   ```
5. Initiate Packer image build for a single image
   ```shell
   # Replace image-name with the actual image name. "openstack." is required
   packer build --var env=dev -only <openstack.image-name> build.pkr.hcl
   # e.g.
   packer build --var env=dev -only openstack.ubuntu-jammy-22.04-nogui build.pkr.hcl
   ```
6. Once the build completes successfully you should get a UUID of the new image

### Testing the image is working

We need to do some basic verification on the image before releasing it to users.

#### Steps on VM:

1. Ensure environment is prepared
   ```shell
   source ~/image_builders/bin/activate
   cd ~/cloud-image-builders/os_builders
   export OS_CLOUD=openstack
   ```

2. Build a new VM using the new image. This can be done in Horizon or command line from the VM
   ```shell
   openstack server create --wait \
   --flavor l3.nano \
   --network Internal \
   --key-name <openstack-ssh-key-name> \
   --image <new-image-id> \
   <server-name>
   ```

3. SSH to VM with your fed ID, if you are not using an SSH agent you will need to exit this VM first
   ```shell
   ssh <fed-id>@172.16.X.Y
   ```

4. If you get logged in then testing is complete. If not then it needs to be looked into.

5. Delete VM in Horizon or command line from the VM
   ```shell
   openstack server delete <server-name>
   ```

### Releasing an image

The new image needs to be made public and renamed, the old image needs to be deactivated and renamed. This **requires** an admin account.

#### Steps on VM:

1. Ensure environment is prepared
   ```shell
   source ~/image_builders/bin/activate
   cd ~/cloud-image-builders/os_builders
   export OS_CLOUD=openstack
   ```

2. Run the rename_images.sh script to make it public
   ```shell
   ./rename_images.sh <current-image-name> <new-image-id>
   # e.g.
   ./rename_images.sh ubuntu-jammy-22.04-nogui 0b8884fa-111c-4d8f-aa4c-98bed3f521c8
   ```

## How to update the playbooks

The image configuration is based on the Ansible playbooks run by Packer. If we want to make changes, e.g. update a pinned package version, then you need to update or add new roles / tasks. When making any changes you will need to verify they work across all the OS images in the build file.

#### Steps on VM:

1. Ensure environment is prepared
   ```shell
   source ~/image_builders/bin/activate
   cd ~/cloud-image-builders/os_builders
   export OS_CLOUD=openstack
   ```

2. Switch to the next version branch and checkout from there before developing
   ```shell
   git switch 0.3.X
   git checkout -b <new-feature-branch>
   ```

2. Create a VM using the current image for the OS 
  ```shell
  openstack server create --wait \
  --network Internal
  --flavor l3.nano \
  --image <os-image> \
  --key-name <your-openstack-key> \
  <server-name>
  ```

3. Edit `inventory.yml` and add your host's IP
  ```shell
  # Contents of: inventory.yml
  ---
  all:
    hosts:
      test-vm:
        ansible_host: "172.16.255.255"  # Your host's IP
        ansible_user: "ubuntu"  # or rocky
  ```

4. Run the baseline against the VM
  ```shell
  ansible-playbook -i inventory playbooks/configure_os_images.yml
  ```

5. If it is an AQ image, run the quattor playbook
  ```shell
  ansible-playbook -i inventory playbooks/quattor.yml
  ```
6. Repeat steps 5-6 making changes to the playbooks

7. Commit any changes you have made and update the [CHANGELOG](./CHANGELOG.md)

8. Make a pull request to the next version branch adding the relevant labels and linking, if any, the GitHub issue

## How to release a new image builders version

By default we do not put any unreleased changes into the main branch. This allows images to be built without switching branches, preventing mistakes. To release the next version we need to merge the next version branch into main.

This only requires Git and you do not need the environment set up to build images.

#### Steps:

1. Clone and change into the repository directory
   ```shell
   git clone git@github.com:stfc/cloud-image-builders.git
   cd cloud-image-builders/os_builders
   ```

2. Switch to the next version branch
   ```shell
   git switch 0.3.X
   ```
   
3. In [CHANEGLOG.md](./CHANGELOG.md) update the unreleased section to the next version and date it.

4. Add a new unreleased section at the top linking to the next branch name

5. In [RELEASES.md](./RELEASES.md) add the releasing version with the date and summarise **changes that users** using the format of previous releases.

6. Update the [version.txt](./version.txt) if not already done

7. Update the image_builder_version in [build.pkr.hcl](./build.pkr.hcl) if not already done

8. Commit and push the changes as the following, updating where needed:
   ```markdown
   RELEASE: Version 0.3.0

   Brief summary of changes. Including breaking changes or unexpected new beaviour.
   ```

9. In GitHub, create a pull request from the next version branch to main [here](https://github.com/stfc/cloud-image-builders/compare/main...main)

10. Once pull request is merged create a new branch from main with the next version
