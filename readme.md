# Tidus

[![Travis Build state](https://api.travis-ci.org/Barzahlen/tidus.svg)](https://travis-ci.org/Barzahlen/tidus)

Tidus is a Ruby Gem which works in conjunction with ActiveRecord to automatically generate database views for every model which is a direct descendent from ActiveRecord::Base. The purpose of the views is to anonymize the contents of select columns to ensure that no confidential information leave the database while still providing access to the data in general.

## Getting started

1. add the Gem to the Gemfile

        gem 'tidus'

2. Require the Gem at any point after ActiveRecord but before loading the models. Rails requires all Gems in the Gemfile by default.
3. Add your anonymization rules
4. Execute `rake db:migrate`. The `db:clear_views` and `db:generate_views` tasks are hooked to automatically run every time before and after execution of `db:migrate` or `db:rollback`.

## Anonymization rules
The rules to ensure anonymization can be defined as follows

        anonymizes :column_name, strategy: <strategy_name>, <additional_options>
- strategy_name: any of the strategies below
- additional_options: additional settings in `key: value`notation

### Strategies
- `:cond`
    - Replaces values by other values of a specific type in case a condition is met. If no condition is met, the current value or a default is used if specified.
    - Options:
        - `:default`  The default value to be used in case no condition is met. If not set the current column value will be used.
        - `:default_strategy` The default strategy to be used in case no condition is met (alternative to `:default`). Strategy options are not supported at the moment.
        - `:result_type`   The type to which the resulting value should be cast. Default is `text`.
        - `:conditions`  Array or hash of one or more condition settings
            -  `:column` Name of the column for the condition
            -  `:value` Value which should be compared to the `:column` value
            -  `:type`  The type to which the column value and the condition value should be cast for comparision. Default is `text`.
            -  `:comparator`  Infix function with which to compare the values. Default is `=`
            -  `:result` Value which should be used as a replacement in case the condition is met.
- `:email`
    -  Replaces the part before the `@` by an MD5 Hash of the value with the given length. A hash function is used to have anonymization while allowing to find out whether two addresses are the same.
    -  Options:
        -  `:length`    Specifies the length of the part which should be kept before the `@`. Default is 15. Maximum with MD5 is 32.
- `:null`
    - Replaces any value with `NULL`
- `:overlay`
    - Adds an overlay to part of the string.
    - Options:
        - `:start`  Defines the starting point in the value string. (required)
        - `:length` Defines the length of the overlay. (required)
        - `:char`   Defines the character which should be used as an overlay. Default is 'X'.
- `:static`
    - Similar to the `:null` strategy, this strategy allows defining a specific value with which to replace the column value.
    - Options:
        - `:value`  The value used as a replacement in the view. (required)
        - `:type`   The type to which the returned value should be cast. Default is `text`
- `:text`
    - It replaces any string by a randomized string of equal length minding capital letters. The replacement function is the same for every value in the view but it is randomly generated each time the view is created.
- `:regex_replace`
    - This strategy allows replacing string matching a pattern with another string.
    - Options:
        - `:pattern`    The regular expression pattern which will be replaced. (required)
        - `:replacement`    The replacement to the pattern. Uses an empty string if none given.
- `:remove_json_keys`
    - This strategy allows removing top-level keys from JSON objects.
    - Options:
        - `:keys`   An array of keys on the top level which should be removed. (required)


Note: to provide your own anonymization strategy you can also provide a class name for the strategy, e.g. `strategy: Tidus::OverlayAnonymizer`. It is expected though that the class is in a submodule. It is recommended to use `Tidus` as module name for better association of the purpose of the class.

## Other options

* `skip_anonymization` - Don't create an anonymized view for the model (by default tidus creates an anonymized view even if no fields are anonymized). Add this to the model instead of using `anonymizes` strategies.

## Database support

|                  | PostgreSQL | SQLite3 | MySQL |
|------------------|------------|---------|-------|
| cond             |      √     |    x    |   x   |
| email            |      √     |    x    |   x   |
| null             |      √     |    √    |   x   |
| overlay          |      √     |    x    |   x   |
| static           |      √     |    x    |   x   |
| text             |      √     |    x    |   x   |
| replace          |      √     |    x    |   x   |
| remove_json_keys |      √     |    x    |   x   |

Currently the Gem only contains strategy implementations for PostgreSQL.

## Backup and Restore

You can use the bash example script located in examples to backup and restore databases prepared with tidus easily. `tidus_backup_restore.sh` can be called with any parameter other than `-d|-r|--dump|--restore` to get help for it's usage. The `tidus_seq_rst.sql` file is necessary for restores since it's will reset all sequences after restore for you - it's not necessary for backups only.

### Basic usage

Before dumping or restoring you have to manually edit the `tidus_backup_restore.sh` file and search for all occurences of PGSERVER, PGPORT, PGUSER and PGPASSWD and set them for your environment. Those parameters are not exposed into the commandline due to security considerations. Also check the `dump_it` and `restore_it` functions and add the databases you want to dump or restore as well as the database names in your staging environment and the staging user which will get the permissions after restore.

- `./tidus_backup_restore.sh -d /path/to/the/dumps/folder`
  - Set the PGSERVER, PGPORT, PGUSER and PGPASSWD parameters in the `dump_db` function first!
  - Add all databases you want to dump from in the `dump_it` function!
- `./tidus_backup_restore.sh -r /path/to/the/dumps/folder <Backup-Set-No>`
  - Set the PGSERVER, PGPORT, PGUSER and PGPASSWD parameters in the `restore_db` function first!
  - Add all databases you want to restore - as well as the destination database names and users - in the `restore_it` function!
  - Be sure to have the `tidus_seq_rst.sql`in the same folder as the script which is required for a successful restore!

## Bugs and Contribution
For bugs and feature requests open an issue on Github. For code contributions fork the repo, make your changes and create a pull request.

## Extending functionality
The number of strategies implemented so far is limited. You can however very easily define your own anonymization strategy. There is actually only one requirement: The class containing the strategy has to have an `anonymize` method. By passing the class name as a strategy value to the `:strategy` key, you are telling the anonymization extension on which class to execute said method.

### License
[LICENSE](LICENSE)
