# Creating migrations

`SQLiteMigrationManager` handles the migration process.

## SQL File migrations

To create new migration, you need to generate new SQL file in this folder, use the following script to generate one:

```bash
$ touch "`ruby -e "puts Time.now.strftime('%Y%m%d%H%M%S').to_i"`"_name.sql
```

## Swift based migrations

Just conform to `Migration` protocol, something like the following:

```swift
import Foundation
import SQLiteMigrationManager
import SQLite

struct SwiftMigration: Migration {
  var version: Int64 = 2016_01_19_13_12_06

  func migrateDatabase(_ db: Connection) throws {
    // perform the migration here
  }
}
```

Read more here: https://github.com/garriguv/SQLiteMigrationManager.swift