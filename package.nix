{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  git,
  makeWrapper,
  stdenv,
  writableTmpDirAsHomeHook,
}:

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

  # Nixpkgs currently ships Go 1.26.1, but upstream's go.mod requires 1.26.2.
  # Patch the module directive so buildGoModule can build this release cleanly.
  postPatch = ''
    substituteInPlace go.mod --replace-fail "go 1.26.2" "go 1.26.1"
  '';

  subPackages = [ "cmd/entire" ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/entireio/cli/cmd/entire/cli/versioninfo.Version=${finalAttrs.version}"
    "-X=github.com/entireio/cli/cmd/entire/cli/versioninfo.Commit=${finalAttrs.src.rev}"
  ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

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

  postFixup = ''
    wrapProgram $out/bin/entire \
      --prefix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta = {
    description = "CLI tool that captures AI agent sessions alongside git commits";
    longDescription = ''
      Entire hooks into your git workflow to capture AI agent sessions on every
      push. Sessions are indexed alongside commits, creating a searchable record
      of how code was written in your repo.
    '';
    homepage = "https://github.com/entireio/cli";
    changelog = "https://github.com/entireio/cli/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "entire";
  };
})
