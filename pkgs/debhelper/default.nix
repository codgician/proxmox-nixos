{ lib
, stdenv
, gettext
, dpkg
, perlPackages
, fetchFromGitLab
}:

let
  inherit (perlPackages) perl;
  dh-autoreconf = fetchFromGitLab {
    domain = "salsa.debian.org";
    owner = "debian";
    repo = "dh-autoreconf";
    rev = "20";
    hash = "sha256-I1dMWBNWx2mWXwSHYRR3FsFcOlnJ/MOVWdWeNPRaOek=";
  };
in stdenv.mkDerivation rec {
  pname = "debhelper";
  version = "13.20";

  src = fetchFromGitLab {
    domain = "salsa.debian.org";
    owner = "debian";
    repo = "debhelper";
    rev = "debian/${version}";
    hash = "sha256-+6HRksDo+D7rsONHd6G1m6XGaVNWLIp0tsXC4t+7h/8=";
  };

  patchPhase = ''
    patchShebangs .
  '';

  nativeBuildInputs = [
    gettext
  ] ++ (with perlPackages; [
    perl
    Po4a
  ]);

  propagatedBuildInputs = [
    dpkg
  ];

  makeFlags = [
    "PREFIX=$(out)"
    "PERLLIBDIR=$(out)/${perl.libPrefix}/Debian/Debhelper"
  ];

  postInstall = ''
    # Install dh-autoreconf extension
    cp ${dh-autoreconf}/autoreconf.pm $out/${perl.libPrefix}/Debian/Debhelper/Sequence/
    cp ${dh-autoreconf}/dh_autoreconf $out/bin
    cp ${dh-autoreconf}/dh_autoreconf_clean $out/bin

    PERL5LIB="$PERL5LIB''${PERL5LIB:+:}$out/${perl.libPrefix}"

    perlFlags=
    for i in $(IFS=:; echo $PERL5LIB); do
      perlFlags="$perlFlags -I$i"
    done

    find $out/bin | while read fn; do
        if test -f "$fn"; then
            first=$(dd if="$fn" count=2 bs=1 2> /dev/null)
            if test "$first" = "#!"; then
                echo "patching $fn..."
                sed -i "$fn" -e "s|^#\!\(.*\bperl\b.*\)$|#\!\1$perlFlags|"
            fi
        fi
    done
  '';

  meta = with lib; {
    description = "";
    homepage = "https://salsa.debian.org/debian/debhelper.git";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ];
    mainProgram = "dh";
    platforms = platforms.all;
  };
}