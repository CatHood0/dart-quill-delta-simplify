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
