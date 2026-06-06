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
  go_1_26_4 = go_1_26.overrideAttrs (_: {
    version = "1.26.4";
    src = fetchurl {
      url = "https://go.dev/dl/go1.26.4.src.tar.gz";
      hash = "sha256-T2aKMvv8ETLmqIH7lowvHa2mMUkqM5IRc1+7JVpCYC0=";
    };
  });

  buildGoModule = buildGo126Module.override { go = go_1_26_4; };
in
buildGoModule (finalAttrs: {
  pname = "entire";
  version = "0.6.1";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-VfuzYSFgH6cW80SYtkhaNeiNYFAOHbcFX9jdr/rDqSw=";
  };

  vendorHash = "sha256-GhFH/y781RIRZ7+r79Wsw8x0/ZmTnv0g9GHtESn5zSA=";

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
