fluent-plugin-postgres-bulk
=====

[Fluentd](https://www.fluentd.org/) output plugin to postgres.

# Usage

```
<match **>
  @type postgres_bulk
  host my-host-name.local
  port 5432
  username ksss
  password password
  table any
  column_names id,col1,col2,col3
</match>
```

Plugin build and exec query to postgres like this

```sql
INSERT INTO #{@table} (#{column_names}) VALUES (...),(...),(...);
```

# Configuration

* See also: [Output Plugin Overview](https://docs.fluentd.org/v1.0/articles/output-plugin-overview)

## Fluent::Plugin::PostgresBulkOutput

### host (string) (optional)

Database host.

Default value: `127.0.0.1`.

### port (integer) (optional)

Database port.

Default value: `5432`.

### database (string) (required)

Database name.

### username (string) (required)

Database user.

### password (string) (optional) (secret)

Database password.

Default value: ``.

### table (string) (required)

Bulk insert table.

### column_names (array) (required)

Bulk insert column.

# Install

In case of using Bundler,
you can install this plugin by writing to Gemfile.

```
gem "fluent-plugin-postgres-bulk"
```

or use gem command

```
$ gem install fluent-plugin-postgres-bulk
```

# Require

- libpq(build pg gem)

# Contributing

I need your help.

# Copyright

Copyright (c) 2018 Yuki Kurihara.

# LISENCE

MIT
