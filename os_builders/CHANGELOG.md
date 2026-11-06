# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased:

### Added:
- Added the testing_os_images.yml playbook and run_test role. [#239](https://github.com/stfc/cloud-image-builders/pull/239)
- Added the Ubuntu 26 and Rocky 10 images to the builders. [#191](https://github.com/stfc/cloud-image-builders/pull/191)
- Added auditd to VMs to increase coverage for security monitoring with Wazuh [#255][https://github.com/stfc/cloud-image-builders/pull/255]

### Fixed:
- Various CI fixes, including making sure Ubuntu 26 and RL10 gets tested, the regression tests run, and resolving warnings flagged by ansible-lint or the CI pipeline. [#241](https://github.com/stfc/cloud-image-builders/pull/241)

### Changed:
- Changed default root user, for qemu-guest-agent, to cloud. [#248](https://github.com/stfc/cloud-image-builders/pull/248)
- Added client buffer tuning to the wazuh agent to handle larger log loads [#255][https://github.com/stfc/cloud-image-builders/pull/255]

### Removed:
- Removed the Azimuth builds as these images aren't being used currently. [#243](https://github.com/stfc/cloud-image-builders/pull/243)


## [0.3.2] - 2026-10-06

### Added:
- Added the UK eScienceRoot-2026 and eScienceCA-3B CA certs [#208](https://github.com/stfc/cloud-image-builders/pull/208)
- Added the bash-completion package to the Rocky images.[#214](https://github.com/stfc/cloud-image-builders/pull/214)

### Fixed:

- Removes double quotes from Virtual machine UUID reporting to Pakiti. [#199](https://github.com/stfc/cloud-image-builders/pull/199)
- Install missing ncm services for "-aq" images. [#212](https://github.com/stfc/cloud-image-builders/pull/212)
- "quattor-fetch" and "quattor-configure" will no longer error the first time it is run on a virtual machine. [#230https://github.com/stfc/cloud-image-builders/pull/230]()

### Changed:
- Changed the aq domain from prod_cloud to prod. [#215](https://github.com/stfc/cloud-image-builders/pull/215)
- Updated Azimuth base images to v0.36.2 [#206](https://github.com/stfc/cloud-image-builders/pull/206)
- The version pins of the requirements files has been removed to pick up the latest package versions containing security patches. This has been re-tested for support on OpenStack Yoga still. [#229](https://github.com/stfc/cloud-image-builders/pull/229)

## [0.3.1] - 2026-08-25

### Changed:
- Virtual machines now report to Pakiti with their UUID rather than hostname. [#194](https://github.com/stfc/cloud-image-builders/pull/194)

### Fixed:
- Typo in the hostname for VMs fixed. [#194](https://github.com/stfc/cloud-image-builders/pull/194)

## [0.3.0] - 2026-08-20

### Added:
- Install epel-release to provide EPEL repositories. [#181](https://github.com/stfc/cloud-image-builders/pull/181)

### Changed:
- Switched from Pakiti 2 to Pakiti 3. Virtual machines will now report to Pakiti correctly. [#180](https://github.com/stfc/cloud-image-builders/pull/180)
- Image build flavor changed to l3.imagecreate. This flavor is on dev and prod and has a disk size of 20GB. [#176](https://github.com/stfc/cloud-image-builders/pull/176)
- nubes-bootcontext.sh script renamed to nubes-boot.sh to match the service name. [#172](https://github.com/stfc/cloud-image-builders/pull/172)

### Fixed:
- update_keys.sh hangs indefinitely. Added a retry limit to the wget command to error and exit. [#179](https://github.com/stfc/cloud-image-builders/pull/179)
- Hostname does not get set permanently. Switch to using hostnamectl. [#172](https://github.com/stfc/cloud-image-builders/pull/172)

### Removed:
- Revert Ubuntu 22 back to mainstream kernel 5.15.0 as it is now patched. [#182](https://github.com/stfc/cloud-image-builders/pull/182)

## [0.2.1] - 2026-08-13

### Changed:
- Ubuntu 22.04 now uses the HWE 6.8 Kernel to mitigate CVE-2026-43499. [#175](https://github.com/stfc/cloud-image-builders/pull/175)

## [0.2.0] - 2026-07-15

### Added:
- Added new builders for Rocky 8 and 9 AQ images. [#148](https://github.com/stfc/cloud-image-builders/pull/148)

### Changed:
- Updated Ansible version for building. [#144](https://github.com/stfc/cloud-image-builders/pull/144)
- Created separate requirements file for RL8 image builds. [#153](https://github.com/stfc/cloud-image-builders/pull/153)

### Fixed:
- Ubuntu 22 stuck at reboot when building image. [#153](https://github.com/stfc/cloud-image-builders/pull/153)

## [0.1.0] - 2026-05-05

### Added:

- Added this CHANGELOG file to track changes to the images.
- Image metadata value "image_builder_version" to track the version of the image builders used when making the image [#135](https://github.com/stfc/cloud-image-builders/pull/135)

### Changed:
- Changed image build flavor to l6.c2 to enable images to be used on VMs with less than 50GB disk [#130](https://github.com/stfc/cloud-image-builders/issues/130)
- Changed update_cloud_users.sh to use the new username service. This script is more reslient to failures. [#138](https://github.com/stfc/cloud-image-builders/pull/138)

### Fixed:
- Fix user creation on VMs with 10.10 or 192.168 IP address [#126](https://github.com/stfc/cloud-image-builders/issues/126)
- Fix cleaning up users after image creation [#125](https://github.com/stfc/cloud-image-builders/issues/125)
