{ config, pkgs, lib, inputs, ... }:

let
	user = "david";
	keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];
in
{
	imports = [ ../../shared ../../modules/nixos/disk-config-btrfs.nix ];

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
		};
	};

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

	security.sudo.enable = true;
	security.sudo.extraRules = [{ groups = [ "wheel" ]; commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }]; }];

	environment.systemPackages = with pkgs; [ gitAndTools.gitFull neovim htop btop ];

	programs.zsh.enable = true;

	services.getty.autologinUser = null;
	system.stateVersion = "23.11";
}
