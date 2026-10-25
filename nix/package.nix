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
  version = "0.12.1";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0+3pqxl9rJGkO5TnSg/5GfJqKO2qYD2ew+SD5zkVDwM=";
  };

  vendorHash = "sha256-RU0ZSkwGk8bL4mkhnMDveNIW7JGwYwudT+ywmncuT2k=";

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
