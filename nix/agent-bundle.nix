{
  agentSkillsLib,
  rencireSkills,
}:
let
  sources = {
    shared = {
      path = rencireSkills;
      subdir = "skills";
    };
  };
  bundle =
    pkgs:
    agentSkillsLib.mkBundle {
      inherit pkgs;
      selection = agentSkillsLib.selectSkills {
        catalog = agentSkillsLib.discoverCatalog sources;
        inherit sources;
        allowlist = [
          "dev-loop"
          "doc-table-of-contents"
          "nix-repo"
          "public-repo-readiness"
          "vcs"
        ];
        skills = { };
      };
    };
  targets = {
    agents = agentSkillsLib.defaultLocalTargets.agents // {
      enable = true;
    };
    claude = agentSkillsLib.defaultLocalTargets.claude // {
      enable = false;
    };
  };
in
{
  inherit bundle targets;
}
