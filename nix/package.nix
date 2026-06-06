{ lib
, buildGo126Module
, fetchFromGitHub
, fetchurl
, installShellFiles
, git
, go_1_26
, stdenv
, writableTmpDirAsHomeHook
,
}:

let
  goVersion = "1.26.4";
  goSrcHash = "sha256-T2aKMvv8ETLmqIH7lowvHa2mMUkqM5IRc1+7JVpCYC0=";

  pinnedGo = go_1_26.overrideAttrs (_: {
    version = goVersion;
    src = fetchurl {
      url = "https://go.dev/dl/go${goVersion}.src.tar.gz";
      hash = goSrcHash;
    };
  });

  buildGoModule = buildGo126Module.override { go = pinnedGo; };
in
buildGoModule (finalAttrs: {
  pname = "entire";
  version = "0.7.5";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bCfXaFag3eS2bp+qlOWkYJpsx67b4To5AABtimeiYzg=";
  };

  vendorHash = "sha256-31GHWH7KdjpspNauJz3jpICf20OhtbnwXgcOjBpTL1Q=";

  subPackages = [ "cmd/entire" ];

  ldflags = [
    "-s"
    "-X=github.com/entireio/cli/cmd/entire/cli/versioninfo.Version=${finalAttrs.version}"
    "-X=github.com/entireio/cli/cmd/entire/cli/versioninfo.Commit=${finalAttrs.src.rev}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [
    git
    writableTmpDirAsHomeHook
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd entire \
      --bash <($out/bin/entire completion bash) \
      --fish <($out/bin/entire completion fish) \
      --zsh <($out/bin/entire completion zsh)
  '';

  meta = {
    description = "CLI tool that captures AI agent sessions alongside git commits";
    longDescription = ''
      Entire hooks into your git workflow to capture AI agent sessions on every
      push. Sessions are indexed alongside commits, creating a searchable record
      of how code was written in your repo.
    '';
    homepage = "https://github.com/entireio/cli";
    changelog = "https://github.com/entireio/cli/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "entire";
  };
})
