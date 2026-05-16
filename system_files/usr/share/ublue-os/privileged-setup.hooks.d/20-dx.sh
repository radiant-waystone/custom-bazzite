#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script dx-usergroups privileged 1 || exit 0

# Function to append a group entry to /etc/group
append_group() {
	local group_name="$1"
	if ! grep -q "^$group_name:" /etc/group; then
		echo "Appending $group_name to /etc/group"
		grep "^$group_name:" /usr/lib/group | tee -a /etc/group >/dev/null
	fi
}

# Setup Groups
append_group docker

# We dont have incus on the image yet
# append_group incus-admin
# usermod -aG incus-admin $user

# docker group intentionally not auto-assigned: docker group = root-equivalent.
# Run `usermod -aG docker $USER` manually after first login if needed.