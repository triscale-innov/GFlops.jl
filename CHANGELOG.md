# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).



## [UNRELEASED]

### Changed

- Quality Assurance:
  - CI: finish the switch from Travis to GitHub Actions

- Display memory allocs in `@gflops` output (#5)

- Estimate GFlops based on the minimum time measurement provided by `@btime` (#15)



## [0.1.2] - 2020-12-20

### Added

- Support for ternary operators: fma (#12)

### Changed

- Quality Assurance:
  - switch to GitHub Actions for CI



## [0.1.1] - 2020-04-21

This is the first version compatible with Julia 1.4

### Added

- Quality Assurance:
  - more tests (#11)
  - TagBot support (#7)
  - CompatHelper support
  
## Changed

- Update dependency compat bounds to restore compatibility with Julia 1.4 (#6, #10)
  - Cassette (#8)
  - BenchmarkTools (#9)



## [0.1.0] - 2019-11-13

Initial release

### Added

- Support for 32-bit and 64-bit FP formats
- Support for binary operators: +, -, *, /
- Support for unary operator: sqrt
