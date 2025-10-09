{
  lib,
  stdenv,
  fetchFromGitHub,
  buildNpmPackage,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "claude-code-acp";
  version = "0.5.4";

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = "claude-code-acp";
    rev = "v${finalAttrs.version}";
    hash = "sha256-va98a1P6az1p5FkJylhSHommF7C4qsFbbigW/Id4WRU=";
  };

  npmDepsHash = "sha256-93qDUanqHiUwvGq2t9BvzpY8isPg5X3XVvGCNySveWA=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Use Claude Code from any ACP client such as Zed";
    homepage = "https://github.com/zed-industries/claude-code-acp";
    changelog = "https://github.com/zed-industries/claude-code-acp/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ poelzi ];
    mainProgram = "claude-code-acp";
    platforms = lib.platforms.all;
  };
})
