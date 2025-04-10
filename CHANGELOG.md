# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2025-04-10

### Changed

- Add deprecation warning - this gem will be renamed to ruby-anthropic in the next release, to make way for the new official Anthropic SDK (currently at https://github.com/anthropics/anthropic-sdk-ruby).
- The gem name 'anthropic' will soon refer to the official Anthropic SDK. You'll need to update your Gemfile to 'ruby-anthropic' if you want to keep using this gem.

## [0.4.0] - 2025-03-25

### Added

- Add Batches API! Thanks to [@ignacio-chiazzo](https://github.com/ignacio-chiazzo) for previous work on this.
- Thanks to [@seuros](https://github.com/seuros) for helpful README notes on Batch usage.

## [0.3.2] - 2024-10-09

### Fixed

- Fix for use with older versions of Faraday pre-v2.5.0. Thanks to [@geeosh](https://github.com/geeosh) for the PR!

## [0.3.1] - 2024-10-09

### Fixed

- Fix for Tool streaming. Thanks to [@Leteyski](https://github.com/Leteyski) for this fix!

## [0.3.0] - 2024-06-10

### Added

- Add chat streaming! Thank you to the inimitable [@swombat](https://github.com/swombat) for adding this vital functionality!

## [0.2.0] - 2024-04-25

### Added

- Add new Messages endpoint - thanks [@svs](https://github.com/svs) for the PR, [@obie](https://github.com/obie) for the first pass, and many others for requesting and contributions!

## [0.1.0] - 2023-07-18

### Changed

- Got the gem working with the API. MVP

## [0.0.0] - 2023-07-12

### Added

- Initialise repository.
