# Contribution guide
Contributions are very welcome. These could be typos, bug reports, feature requests, speed optimization, better code, and better documentation.
You are very welcome to raise issues and start pull requests.

## Issues
If you notice any bugs, such as crashing code, incorrect results or speed issues, please raise a GitHub issue. 

Before filing an issue please
- check that there are no similar existing issues already
- check that your versions are up to date

If you want to report a bug, include your version and system information, as well as stack traces with all relevant information.
If possible, condense your bug into the shortest example possible that the maintainers can replicate, a so called "minimal working example" or MWE.

If you want to suggest a new feature, for example functionality that other plotting packages offer already, include supplementary material such as example images if possible, so it's clear what you are asking for.

## Code contributions (Pull requests)
When opening a pull request, please add a short but meaningful description of the changes/features you implemented. Moreover, please add tests (where appropriate) to ensure that your code is working as expected.

For each feature you want to contribute, please file a separate PR to keep the complexity down and time to merge short.
Add PRs in draft mode if you want to discuss your approach first.


## Adding documentation
1. We recommend to write a Literate.jl document and place it in `docs/literate/FOLDER/FILENAME.jl` with `FOLDER` being `HowTo`, `Explanations`, `Tutorials` or `Intro` ([recommended reading on the 4 categories](https://documentation.divio.com/)).
2. Literate.jl converts the `.jl` file to a `.md` automatically and places it in `docs/src/generated/FOLDER/FILENAME.md`.
3. Edit [make.jl](https://github.com/unfoldtoolbox/Unfold.jl/blob/main/docs/make.jl) with a reference to `docs/src/generated/FOLDER/FILENAME.md`.

## Formatting (Beware of reviewdog :dog:)
We use the [julia-format](https://github.com/julia-actions/julia-format) Github action to ensure that the code follows the formatting rules defined by [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl).
When opening a pull request [reviewdog](https://github.com/reviewdog/reviewdog) will automatically make formatting suggestions for your code.

## Seeking Help

If you get stuck, here are some options to seek help:

- Use the REPL `?` help mode.
- Check the Documentation. 