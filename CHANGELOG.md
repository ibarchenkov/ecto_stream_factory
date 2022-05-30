# Changelog

## v0.2.2 (2022-05-30)

### Enhancements

  * Improve documentation
  * Add more tests

### Bug fix

  * Convert `t:EctoStreamFactory.overwrites/0` to a map to prevent bugs

## v0.2.1 (2022-05-28)

### Enhancements

  * Improve documentation
  * Update dependencies

## v0.2.0 (2021-04-24)

### Enhancements

  * Add `build!/2`
  * Add `build_list!/3`
  * Add `insert!/3`
  * Add `insert_list!/4`

All the new functions raise `EctoStreamFactory.MissingKeyError` error if a generated struct, map or keyword list cannot be fully merged with the provided attributes.
