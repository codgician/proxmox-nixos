{
  lib, 
  autoreconfHook,
  debhelper,
  python3,
  python3Packages,
  pkgs, 
  stdenv, 
  fetchgit,
  ... 
}:

stdenv.mkDerivation rec {
  pname = "pve-edk2-firmware";
  version = "4.2023.08-4";

  src = fetchgit {
    url = "git://git.proxmox.com/git/${pname}.git";
    rev = "17443032f78eaf9ae276f8df9d10c64beec2e048";
    sha256 = "sha256-19frOpnL8xLWIDw58u1zcICU9Qefp936LteyfnSIMCw=";
    fetchSubmodules = true;
  };

  buildInputs = [ ];

  nativeBuildInputs = with pkgs; [
    autoreconfHook pkgconf 
    dpkg fakeroot debhelper
    bc dosfstools acpica-tools mtools nasm 
    qemu-utils libisoburn
    python3 python3Packages.distutils-extra python3Packages.pexpect 
  ];

  buildPhase = 
  let
    mainVersion = builtins.head (lib.splitString "-" version);
  in
  ''
    # Patch paths
    substituteInPlace ./Makefile --replace-warn /usr/share/dpkg ${pkgs.dpkg}/share/dpkg
    substituteInPlace ./debian/rules --replace-warn /usr/share/dpkg ${pkgs.dpkg}/share/dpkg
    substituteInPlace ./debian/rules --replace-warn /usr/bin/make ${pkgs.gnumake}/bin/make
    substituteInPlace ./debian/rules --replace-warn /bin/bash ${pkgs.bash}/bin/bash
    substituteInPlace ./**/*.sh --replace-warn /bin/bash ${pkgs.bash}/bin/bash

    # Set up build directory
    make ${pname}_${mainVersion}.orig.tar.gz
    pushd ${pname}-${mainVersion}

    # Use dpkg to apply patches
    dpkg-buildpackage -d -b -uc -us

    # Build targets defined in override_dh_auto_build
    # build-qemu-efi-aarch64

    # build-ovmf
    
    # build-ovmf32

    # build-qemu-efi-risv64

    popd
    echo $(pwd)
    ls $(pwd)
    mkdir -p $out
    exit 1
  '';

  installPhase = ''
    # TARGET=$out/usr/share/pve-edk2-firmware
    # mkdir -p $TARGET
    # cp -r usr/share/OVMF/* $TARGET
  '';

  meta = {
    description = "edk2 based UEFI firmware modules for virtual machines";
    homepage = "git://git.proxmox.com/git/${pname}.git";
    maintainers = with lib.maintainers; [ ];
  };
 }