{ lib
, buildGoModule
, fetchFromGitHub
, fetchpatch
, pkg-config
, libheif
, libde265
, cmake
, libwebp
}:
let
  # libheif must match the version requested in go.mod
  # this is basically just https://github.com/NixOS/nixpkgs/pull/254708
  libheif' = libheif.overrideAttrs (old: rec {
    version = "1.17.1";
    src = fetchFromGitHub {
      owner = "strukturag";
      repo = "libheif";
      rev = "v${version}";
      sha256 = "sha256-PI55VdNsJUpomdFlVOzD9ha1b+0MoxOPnM0KASRH2rI=";
    };
    nativeBuildInputs = builtins.filter (p: p.name != "autoreconf-hook") old.nativeBuildInputs ++ [ cmake ];
    buildInputs = old.buildInputs ++ [ libwebp ];
  });
in
buildGoModule rec {
  pname = "matrix-media-repo";
  version = "1.3.3";

  src = fetchFromGitHub {
    owner = "turt2live";
    repo = "matrix-media-repo";
    rev = "v${version}";
    hash = "sha256-RiTYJ2M8n0VdfUtfIv/FXn6F81adx16C3RDU43pU08E=";
  };
  patches = [
    (fetchpatch {
      url = "https://github.com/turt2live/matrix-media-repo/pull/490.patch";
      hash = "sha256-e8pbNLvkIfRqWvA/gh6OYhKNs0shftv7YtnMLXC/ZYI=";
    })
  ];

  vendorHash = "sha256-UCzYvi8aI+SBHd7UVN21EYVDhXGMlT9bQQrbwiKyK/o=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libheif'
    libde265
  ];

  ldflags = [ "-X github.com/turt2live/matrix-media-repo/common/version.Version=${version}" ];

  excludedPackages = [
    "cmd/compile_assets" # compiled in preBuild to be able to correctly compile assets
    "cmd/media_repo" # compiled in postBuild to allow for pgo
  ];
  preBuild = ''
    go install -v ./cmd/compile_assets
    $GOPATH/bin/compile_assets
  '';
  postBuild = ''
    (
      . $TMPDIR/buildFlagsArray
      buildFlagsArray+=('-pgo=pgo_media_repo.pprof')
      declare -p buildFlagsArray > $TMPDIR/buildFlagsArray
    )
    buildGoDir install ./cmd/media_repo
  '';

  doCheck = false;

  meta = with lib; {
    description = "Matrix media repository with multi-domain in mind";
    homepage = "https://github.com/turt2live/matrix-media-repo";
    license = licenses.mit;
    maintainers = with maintainers; [ _999eagle ];
    mainProgram = "media_repo";
  };
}
