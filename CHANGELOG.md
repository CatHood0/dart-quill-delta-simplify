# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 10.9.0

### Added

* `contains` method to check if a part of text or an embed exist [#4](https://github.com/CatHood0/dart-quill-delta-simplify/pull/3).

## 10.8.8

### Added

* `replaceAllMapped` to allow create operations dynamically based on the matched `Operation` [#3](https://github.com/CatHood0/dart-quill-delta-simplify/pull/3).

### Fixed

* Bad behavior of `insert()` method [#2](https://github.com/CatHood0/dart-quill-delta-simplify/pull/2).

## 10.8.7

### Added

* Support for get operations into a specified range using `getRange()`.

### Changed

* Updated some parts of code examples documentation.

### Fixed

* Removed `flutter_quill` dependency for conflicts with major versions.

## 10.8.6

### Fixed

* Diff matching by @CatHood0 in https://github.com/CatHood0/dart-quill-delta-simplify/pull/1

## New Contributors

* @CatHood0 made their first contribution in https://github.com/CatHood0/dart-quill-delta-simplify/pull/1

## 10.8.5

### Added

* Extras documentation. 
* Alternative checking to avoid unexpected behavior in `simpleInsert`.

### Changed

* Update outdated documentation. 

### Fixed

* Contributing guide.

### Fixed

* Missing `predicate` param on match methods for `DeltaExt`.
* If we insert a list of operations at last, them are not inserted as expected.
* Bad url to documentation. 
* Typo in documentation about `ObjectToOperation` extension. 

## 10.8.4

### Added

* `predicate` function to `match` methods.
* `getAllEmbeds` and `getFirstEmbed` to `QueryDelta` and Delta `classes`.
* Checks to avoid unexpected behaviors with `simpleInsert`.
* Checks to avoid add or remove unnecessary newlines with `InsertCondition`.

### Changed

* Removed assert that checks if the `Delta` is not empty.

### Fixed

* Renamed `insertion` param to `replace` in tests.
* `insertAtLastOperation` didn't work as expected.

## 10.8.3

* First version
