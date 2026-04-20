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
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    rev = "90bb1c503f8fdaaecc49c181e1c68a2f63bdb441";
    hash = "sha256-3sFQix4tabTs5imJCRh28azQdaUMGdVyfFxdGGqKJCg=";
  };

  vendorHash = "sha256-PkSN+ynGo6xW9IDoc+rX4NMt7R/d5Who0N56QyQxzl8=";

  postPatch = ''
    substituteInPlace go.mod --replace-fail "go 1.26.2" "go 1.26.1"
  '';

  subPackages = [ "cmd/entire" ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/entireio/cli/cmd/entire/cli/buildinfo.Version=${finalAttrs.version}"
    "-X=github.com/entireio/cli/cmd/entire/cli/buildinfo.Commit=${finalAttrs.src.rev}"
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
