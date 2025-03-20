## Unreleased

### Fixed 

* When `startPoint` is passed on `insert()` method of `QueryDelta`, `left` value passed is ignored.
* When set `target` param in `insert()` method of `QueryDelta`, sometimes the target is replaced unexpectedly.
* When set `startPoint` is passed, sometimes is ignored and will jump to the part that we want to change.
* wrong behavior and unexpected `Delta` results after `build()` when using complex inserts.

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
