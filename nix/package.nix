{ lib
, buildGo127Module
, fetchFromGitHub
, fetchurl
, go_1_27
, installShellFiles
, git
, stdenv
, writableTmpDirAsHomeHook
,
}:

let
  goVersion = "1.27.3";
  goSrcHash = "sha256-bndJA1zzYPBrJXXRYup535/ajvZxiJ5cN1+OUHd/Jrs=";

  # Keep patch updates independent of the consumer's Nixpkgs revision.
  pinnedGo = go_1_27.overrideAttrs (_: {
    version = goVersion;
    src = fetchurl {
      url = "https://go.dev/dl/go${goVersion}.src.tar.gz";
      hash = goSrcHash;
    };
  });
  buildGoModule = buildGo127Module.override { go = pinnedGo; };
in
buildGoModule (finalAttrs: {
  pname = "entire";
  version = "0.13.2";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-basmrDcFJe5tfn1xDWO71THHV8oIKWDXK5vF4gYoZXw=";
  };

  vendorHash = "sha256-p5d1SU5vCuPf1ETFFy4znU3PVGsdvoUFyM8O74ZChR4=";

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
