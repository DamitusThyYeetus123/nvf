{
  lib,
  stdenvNoCC,
  # build inputs
  nixos-render-docs,
  documentation-highlighter,
  dart-sass,
  path,
  # nrd configuration
  release,
  optionsJSON,
} @ args: let
  manual-release = args.release or "unstable";
in
  stdenvNoCC.mkDerivation {
    name = "nvf-manual";
    src = builtins.path {
      name = "nvf-manual-${manual-release}";
      path = lib.sourceFilesBySuffices ./manual [".md" ".md.in"];
    };

    strictDependencies = true;
    nativeBuildInputs = [nixos-render-docs];
    buildInputs = [dart-sass];

    postPatch = ''
      ln -s ${optionsJSON}/share/doc/nixos/options.json ./config-options.json
    '';

    buildPhase = ''
      dest="$out/share/doc/nvf"
      mkdir -p "$(dirname "$dest")"
      mkdir -p $dest/{highlightjs,script}

      # Copy highlight scripts to /highlights in document root.
      cp -vt $dest/highlightjs \
        ${documentation-highlighter}/highlight.pack.js \
        ${documentation-highlighter}/LICENSE \
        ${documentation-highlighter}/mono-blue.css \
        ${documentation-highlighter}/loader.js

      # Copy anchor scripts to the script directory in document root.
      cp -vt $dest/script \
        ${./static/script}/anchor-min.js \
        ${./static/script}/anchor-use.js

      substituteInPlace ./options.md \
        --subst-var-by OPTIONS_JSON ./config-options.json

      substituteInPlace ./manual.md \
        --subst-var-by NVF_VERSION ${manual-release}

      substituteInPlace ./hacking/additional-plugins.md \
        --subst-var-by NVF_REPO "https://github.com/notashelf/nvf/blob/${manual-release}"

      # Compile and copy stylesheet to the project root.
      sass ${./static/style.css} "$dest/style.css"

      # Move release notes
      cp -vr ${./release-notes} release-notes

      # Generate final manual from a set of parameters. Explanation of the CLI flags are
      # as follows:
      #
      #  1. --manpage-urls will allow you to use manual pages as they are defined in
      #  the nixpkgs documentation.
      #  2. --revision is the project revision as it is defined in 'release.json' in the
      #  repository root
      #  3. --script will inject a given Javascript file into the resulting pages inside
      #  the <script> tag.
      #  4. --toc-depth will determine the depth of the initial Table of Contents while
      #  --section-toc-depth will determine the depth of per-section Table of Contents
      #  sections.
      nixos-render-docs manual html \
        --manpage-urls ${path + "/doc/manpage-urls.json"} \
        --revision ${lib.trivial.revisionWithDefault manual-release} \
        --stylesheet style.css \
        --script highlightjs/highlight.pack.js \
        --script highlightjs/loader.js \
        --script script/anchor-use.js \
        --script script/anchor-min.js \
        --toc-depth 2 \
        --section-toc-depth 1 \
        manual.md \
        "$dest/index.xhtml"

        # Hydra support. Probably not necessary.
        mkdir -p $out/nix-support/
        echo "doc manual $dest index.html" >> $out/nix-support/hydra-build-products
    '';
  }
