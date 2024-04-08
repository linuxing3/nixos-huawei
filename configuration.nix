{
  config,
  pkgs,
  lib,
  ...
}: {
  # 我用的一些内核参数
  boot.kernelParams = [
    # 关闭内核的操作审计功能
    "audit=0"
    # 不要根据 PCIe 地址生成网卡名（例如 enp1s0，对 VPS 没用），而是直接根据顺序生成（例如 eth0）
    "net.ifnames=0"
  ];

  # 我用的 Initrd 配置，开启 ZSTD 压缩和基于 systemd 的第一阶段启动
  boot.initrd = {
    compressor = "zstd";
    compressorArgs = ["-19" "-T0"];
    systemd.enable = true;
  };

  # 安装 Grub
  boot.loader.grub = {
    enable = !config.boot.isContainer;
    default = "saved";
    devices = ["/dev/vda"];
  };

  # 时区，根据你的所在地修改
  time.timeZone = "Asia/Singapore";

  # Root 用户的密码和 SSH 密钥。如果网络配置有误，可以用此处的密码在控制台上登录进去手动调整网络配置。
  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = "$y$j9T$QpZqryGfgl.tLSmEO4hUL1$ctlcnaERAFllXtK7iPP8JAI5TqRNdiJS7btuGXaTPA7";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP6a5gTP+YgaKywr7XOEKhHrmmfZs0AETcarxOLelADo"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChJJ2V3vRglmuY/ITRciJ5oU+f7VBA7ix/e+V5UfXbzsNOoT2BsUCYhLzBHYH9nAvunErXXrUvNsOeHcj+U8B0E2vXSa4TfsuQc0l/nXC4KvwASUTLUWRVYfgv3Ha0mIeg6k4UOewds/S+oEYfxaRlteNgxZMPfwpKrmoHA9x0yRDqd917agnwcod9ZUv3CR6I698mk0z6FUp4sc0rCbqIYIX3hAEBDxtsiprWc6Ykq6+L9V3hB8QMlDmrUCpGiKXUfJu3hV6+26sKshrvEjy1WoWiVn2H59drFeIY9q6ho/v8gBN21CDNPYgt8EKC7RS4cc9HzWY6VmFdlwwwCsNUcBLT74CnPkrzQtNoQmVsyplQLNK1s2dnLXGESqLhJ/2kLmlx3OvMwz0gOX/ZC71HEHxRI4nmUMcPAqlITi45Cy+Uv0cCQa36LWdnFPM/sLpX19bUfzWnJeVF0q1vHlASp/urKO/ANmzj7t+l6BREAtGUp9hzK1B/plKNVaQI1D0= vagrant@nixos"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDuZZ1mwqhRKEfLoqt75VLFGXMbapDAu37lU9SaxWgz/dO9hwN3MQN6n9xpyguhxVCqNgI5WYIx6SdoQ+0gnkkmylNfkB8VV16pitiuADIEqx57unTuDZVERHFWIDTpixcouelzZkb6pd35jMCx/ON3UlTZIgZuy90TCEfXxc6mRS753FBWe9zV1CM5Q41WTiKMx7P4vHRxF6eOsGCbLyqG7zruRPMAdHApHmBenyWARLWhiOPhz2EEk1tPz2vUNMWpTyh4h1nx3v4YW9JxTlnESob7Zia0+23ZES46AIL0EYJlpqsDoJJAwoAUGhnRWWvlnC6k1FMEnCzLKbtwXP7O85Wj65t9RgO3yOFvIWWDMUteIPH7iRFTzwSuuX8wQ2uslpOHSCeRiVnnF6NPlnge0eBI8hGz98N9qVY0Q4Mt4Uvl3yvQn1N7R5sLDtWbgvzUyr5Brf8FQHtyh2qBvQGTfjJCW+TQD85zv7UtFGtoDaeTYqjj3MSrX7DGTwrv2NE= administrator@miluna"
    ];
  };

  # 使用 systemd-networkd 管理网络
  systemd.network.enable = true;
  services.resolved.enable = false;

  # 配置网络 IP 和 DNS
  systemd.network.networks.eth0 = {
    address = ["192.168.1.101/24"];
    gateway = ["192.168.1.1"];
    matchConfig.Name = "eth0";
  };
  networking.nameservers = [
    "8.8.8.8"
  ];

  # 开启 SSH 服务端，监听 2222 端口
  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
    };
  };

  # 关闭 NixOS 自带的防火墙
  networking.firewall.enable = false;

  # 关闭 DHCP，手动配置 IP
  networking.useDHCP = false;

  # 主机名，随意设置即可
  networking.hostName = "bootstrap";

  # 首次安装系统时 NixOS 的最新版本，用于在大版本升级时避免发生向前不兼容的情况
  system.stateVersion = "23.11";

  # QEMU（KVM）虚拟机需要使用的内核模块
  boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
    # Set the system time from the hardware clock to work around a
    # bug in qemu-kvm > 1.5.2 (where the VM clock is initialised
    # to the *boot time* of the host).
    hwclock -s
  '';

  boot.initrd.availableKernelModules = [
    "virtio_net"
    "virtio_pci"
    "virtio_mmio"
    "virtio_blk"
    "virtio_scsi"
  ];
  boot.initrd.kernelModules = [
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

  disko = {
    # 不要让 Disko 直接管理 NixOS 的 fileSystems.* 配置。
    # 原因是 Disko 默认通过 GPT 分区表的分区名挂载分区，但分区名很容易被 fdisk 等工具覆盖掉。
    # 导致一旦新配置部署失败，磁盘镜像自带的旧配置也无法正常启动。
    enableConfig = false;

    devices = {
      # 定义一个磁盘
      disk.main = {
        # 要生成的磁盘镜像的大小，2GB 足够我使用，可以按需调整
        imageSize = "2G";
        # 磁盘路径。Disko 生成磁盘镜像时，实际上是启动一个 QEMU 虚拟机走一遍安装流程。
        # 因此无论你的 VPS 上的硬盘识别成 sda 还是 vda，这里都以 Disko 的虚拟机为准，指定 vda。
        device = "/dev/vda";
        type = "disk";
        # 定义这块磁盘上的分区表
        content = {
          # 使用 GPT 类型分区表。Disko 对 MBR 格式分区的支持似乎有点问题。
          type = "gpt";
          # 分区列表
          partitions = {
            # GPT 分区表不存在 MBR 格式分区表预留给 MBR 主启动记录的空间，因此这里需要预留
            # 硬盘开头的 1MB 空间给 MBR 主启动记录，以便后续 Grub 启动器安装到这块空间。
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              # 优先级设置为最高，保证这块空间在硬盘开头
              priority = 0;
            };

            # ESP 分区，或者说是 boot 分区。这套配置理论上同时支持 EFI 模式和 BIOS 模式启动的 VPS。
            ESP = {
              name = "ESP";
              # 根据我个人的需求预留 512MB 空间。如果你的 boot 分区占用更大/更小，可以按需调整。
              size = "512M";
              type = "EF00";
              # 优先级设置成第二高，保证在剩余空间的前面
              priority = 1;
              # 格式化成 FAT32 格式
              content = {
                type = "filesystem";
                format = "vfat";
                # 用作 Boot 分区，Disko 生成磁盘镜像时根据此处配置挂载分区，需要和 fileSystems.* 一致
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };

            # 存放 NixOS 系统的分区，使用剩下的所有空间。
            nix = {
              size = "100%";
              # 格式化成 Btrfs，可以按需修改
              content = {
                type = "filesystem";
                format = "btrfs";
                # 用作 Nix 分区，Disko 生成磁盘镜像时根据此处配置挂载分区，需要和 fileSystems.* 一致
                mountpoint = "/nix";
                mountOptions = ["compress-force=zstd" "nosuid" "nodev"];
              };
            };
          };
        };
      };

      # 由于我开了 Impermanence，需要声明一下根分区是 tmpfs，以便 Disko 生成磁盘镜像时挂载分区
      nodev."/" = {
        fsType = "tmpfs";
        mountOptions = ["relatime" "mode=755" "nosuid" "nodev"];
      };
    };
  };

  # 由于我们没有让 Disko 管理 fileSystems.* 配置，我们需要手动配置
  # 根分区，由于我开了 Impermanence，所以这里是 tmpfs
  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["relatime" "mode=755" "nosuid" "nodev"];
  };

  # /nix 分区，是磁盘镜像上的第三个分区。由于我的 VPS 将硬盘识别为 sda，因此这里用 sda3。如果你的 VPS 识别结果不同请按需修改
  fileSystems."/nix" = {
    device = "/dev/vda3";
    fsType = "btrfs";
    options = ["compress-force=zstd" "nosuid" "nodev"];
  };

  # /boot 分区，是磁盘镜像上的第二个分区。由于我的 VPS 将硬盘识别为 sda，因此这里用 sda2。如果你的 VPS 识别结果不同请按需修改
  fileSystems."/boot" = {
    device = "/dev/vda2";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
}
