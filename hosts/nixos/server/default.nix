{ pkgs, ... }:

let
	user = "david";
	keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
	lib = pkgs.lib;
	sopsFile = "/var/lib/sopswarden/secrets.yaml";
in
{
	imports = [
		../../../modules/nixos/disk-config.nix
		../../../modules/nixos/hardware.nix
		../../../modules/shared
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

	fileSystems."/" = lib.mkForce {
		device = "/dev/disk/by-label/NIXOS_ROOT";
		fsType = "ext4";
	};

	fileSystems."/boot" = lib.mkForce {
		device = "/dev/disk/by-label/NIXOS_BOOT";
		fsType = "vfat";
	};

	networking = {
	hostName = "%HOST%"; # Replaced by apply script
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

	# Ensure 'nix-command' and 'flakes' are enabled for root and all users
	# nix settings (nix-command + flakes) are enabled globally via modules/shared

	# Bring in the shared package set for convenience on servers,
	# but filter out GUI apps. Keep shells, CLI tools, fonts, etc.
	environment.systemPackages =
	  let
	    sharedPkgs = import ../../../modules/shared/packages.nix { inherit pkgs; };
	  in builtins.filter (p: !(p == pkgs.kitty || p == pkgs.synergy)) sharedPkgs;

	# Enable zsh and set it as the user's shell
	programs.zsh.enable = true;

  users.users = {
    ${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
			openssh.authorizedKeys.keys = keys;
			shell = pkgs.zsh;
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

	# sopswarden disabled in full-SOPS mode; secrets come from per-host SOPS files.

	sops.secrets = {
	    "github-token" = {
      owner = "${user}";
      group = "users";
      mode = "0400";
      path = "/run/secrets/github-token";
    };
    # SSH private key managed declaratively via SOPS
    ssh_private_key = {
      owner = "${user}";
      group = "users";
      mode = "0600";
      path = "/home/${user}/.ssh/id_ed25519";
    };
  };

	sops = {
		defaultSopsFile = ../../../secrets/common.yaml;
		age.keyFile = "/etc/sops/age/keys.txt";
		validateSopsFiles = true;
	};

	systemd.tmpfiles.rules = [
		"d /home/${user}/.ssh 0700 ${user} users -"
	];

	services.getty.autologinUser = null;
	system.stateVersion = "23.11";
}
