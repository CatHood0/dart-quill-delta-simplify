# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## Added

* Added `contains` method to check if a part of text or an embed exist [#4](https://github.com/CatHood0/dart-quill-delta-simplify/pull/3).

## 10.8.8

* Feat: `replaceAllMapped` to allow create operations dynamically based on the matched `Operation` [#3](https://github.com/CatHood0/dart-quill-delta-simplify/pull/3).
* Fix: bad behavior of `insert()` method [#2](https://github.com/CatHood0/dart-quill-delta-simplify/pull/2).

## 10.8.7

* Fix: removed `flutter_quill` dependency for conflicts with major versions.
* Chore(doc): updated some parts of code examples.
* Feat: support for get operations into a specified range using `getRange()`.

## 10.8.6
* Fix: diff matching by @CatHood0 in https://github.com/CatHood0/dart-quill-delta-simplify/pull/1

## New Contributors
* @CatHood0 made their first contribution in https://github.com/CatHood0/dart-quill-delta-simplify/pull/1

## 10.8.5

* Fix: missing `predicate` param on match methods for `DeltaExt`
* Fix: is we insert a list of operations at last, them are not inserted as expected
* Fix: bad url to documentation 
* Fix: typo in documentation about `ObjectToOperation` extension 
* Chore(doc): added extras documentation 
* Chore(doc): update outdated documentation 
* Chore(doc): fix contributing guide
* Chore: added an alternative checking to avoid unexpected behavior in `simpleInsert`

## 10.8.4

* Fix(test): renamed `insertion` param to `replace`
* Fix: `insertAtLastOperation` didn't work as expected
* Fix: added some checks to avoid add or remove unnecessary newlines with `InsertCondition`
* Chore: removed assert that checks if the `Delta` is not empty
* Chore: added checks to avoid unexpected behaviors with `simpleInsert`
* Feat: added `predicate` function to `match` methods
* Feat: added `getAllEmbeds` and `getFirstEmbed` to `QueryDelta` and Delta `classes`

## 10.8.3

* First version
