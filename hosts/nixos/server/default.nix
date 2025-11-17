{ pkgs, ... }:

let
	user = "david";
	keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
	lib = pkgs.lib;
in
{
	imports = [
		../../../modules/disko-mbr.nix
		../../../modules/hardware.nix
		../../../modules
	];

	boot = {
		loader = {
			systemd-boot = {
				enable = true;
				configurationLimit = 10;
			};
			efi.canTouchEfiVariables = true;
			timeout = 1;
		};
		initrd.availableKernelModules = [
			"xhci_pci"
			"ahci"
			"nvme"
			"usbhid"
			"usb_storage"
			"sd_mod"
			"virtio_blk"
			"virtio_pci"
			"virtio_scsi"
		];
		initrd.kernelModules = [
			"virtio_blk"
			"virtio_console"
			"virtio_pci"
			"virtio_scsi"
		];
		kernelModules = [ "uinput" "virtio_balloon" "virtio_net" "virtio_rng" ];
	};

	networking = {
		hostName = "server"; # token replaced by apply script
		useDHCP = true;
		firewall = {
			enable = true;
			allowedTCPPorts = [ 22 80 443 ];
		};
		# If static IP token replaced, we can switch off DHCP via tokening later.
	};

	services.openssh = {
		enable = true;
		settings = {
			PasswordAuthentication = true;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = "prohibit-password";
		};
	};

	services.qemuGuest.enable = lib.mkDefault true;

  users.users = {
    ${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
			openssh.authorizedKeys.keys = keys;
			initialPassword = "6!y2c87T"; # rotate post-install
		};
		root = {
			openssh.authorizedKeys.keys = keys;
			initialPassword = "6!y2c87T";
		};
	};

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # sops/sopswarden secret management removed for now.

	systemd.tmpfiles.rules = [
		"d /home/${user}/.ssh 0700 ${user} users -"
	];

	services.getty.autologinUser = null;
	system.stateVersion = "23.11";
}
