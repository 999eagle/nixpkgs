{
  lib,
  pythonAtLeast,
  buildPythonPackage,
  fetchpatch,
  fetchPypi,
  mercurial,
}:

buildPythonPackage rec {
  pname = "python-hglib";
  version = "2.6.2";
  format = "setuptools";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-sYvR7VPJDuV9VxTWata7crZOkw1K7KmDCJLAi7KNpgg=";
  };
  patches =
    [
      # this patch removes the nose dependency for testing but isn't yet part of a released version
      (fetchpatch {
        url = "https://repo.mercurial-scm.org/python-hglib/raw-rev/8341f2494b3f";
        excludes = [ "heptapod-ci.yml" ];
        hash = "sha256-WFljjLJ/9BSlkp2MvhZtb0gLYTWFmwYJnpgbiUpBSbU=";
      })
    ]
    ++ lib.optionals (pythonAtLeast "3.12") [
      # most tests currently fail on python3.12 due to `assertEquals` being removed
      ./python312-test-fix.patch
    ];

  nativeCheckInputs = [ mercurial ];

  preCheck = ''
    export HGTMP=$(mktemp -d)
    export HGUSER=test
  '';

  pythonImportsCheck = [ "hglib" ];

  meta = with lib; {
    description = "Library with a fast, convenient interface to Mercurial. It uses Mercurial’s command server for communication with hg";
    homepage = "https://www.mercurial-scm.org/wiki/PythonHglibs";
    license = licenses.mit;
    maintainers = [ ];
  };
}
