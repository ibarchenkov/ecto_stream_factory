## v0.2.0 (2021-04-24)

### Enhancements

  * Add `build!/2`
  * Add `build_list!/3`
  * Add `insert!/3`
  * Add `insert_list!/4`

All the new functions raise `EctoStreamFactory.MissingKeyError` error if a generated struct, map or keyword list cannot be fully merged with the provided attributes.
