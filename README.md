RouteHub Database Schema
========================

This repository contains the RouteHub application's database schema. It defines the structure of the database, including tables, fields, relationships, and constraints.

The purpose of this repository is to provide a clear and organized representation of the database schema, allowing developers to understand the data model and make informed decisions when interacting with the database.

## Tooling

* [DBML](https://dbml.dbdiagram.io/docs): Simple, readable DSL language designed to define database structures.
* [dbml-lsp](https://github.com/kamal-hamza/dbml-language-server): Standalone Language Server Protocol (LSP) implementation for DBML.
* [dbml2sql](https://github.com/holistics/dbml): Official application to convert DBML to SQL.
* [dbml_sqlite](https://github.com/dvanderweele/DBML_SQLite): Python application to convert DBML to SQLite.
* [atlas](https://github.com/ariga/atlas): A language-agnostic tool for managing and migrating database schemas.

## Conventions

For our database table naming convention, we have opted for 'singular'. The primary reason is explained in [stackoverflow](https://stackoverflow.com/a/5841297):

> Objects can have irregular plurals or not plural at all, but will always have a singular one (with few exceptions like News).

## From DBML to SQL

### PostgreSQL

We're going to use the official CLI application to export our DBML schema to PostgreSQL. To use it, we need to ensure we have [Node.js](https://nodejs.org/en) >= 20.19 (obtained using the command `npx ls-engines --dev`) and [NPM](https://www.npmjs.com) >= 10.

To install the application's dependencies, run the following command:

```bash
npm install
```

Then, use the following command to create the SQL file for PostgreSQL:

```bash
npm run 2pg
```

### SQLite

The official CLI application doesn't support exporting the DBML schema to SQLite ([for now](https://github.com/holistics/dbml/issues/286)). To address this limitation, you can use the [`dbml_sqlite`](https://github.com/dvanderweele/DBML_SQLite) script. To run it, [Python](https://www.python.org) 3.7 or higher is required.

#### Virtual Environment

Before running the script, you need to install all its dependencies. Start by creating a virtual environment using the following command:

```bash
python -m venv .venv --prompt "db"
```

Then, activate it:

```bash
source .venv/bin/activate
```

It is recommended to upgrade the `pip` package manager:

```bash
python -m pip install --upgrade pip
```

Now, install the Python dependencies from the `requirements.txt` file:

```bash
pip install -r requirements.txt
```

Once you are finished, deactivate the virtual environment with:

```bash
deactivate
```

#### Schema Conversion

After the setup is complete, we can run the following command to convert the DBML schema to SQLite SQL. It's worth mentioning that the `sed` command will change some data types that are not supported. If you are already running the virtual environment, omit the first and last lines (`source` and `deactivate`).

```bash
source .venv/bin/activate && \
sed -e 's/JSON/text/g' -e 's/special_handling\[\]/special_handling/g' schema.dbml > tmp.dbml && \
dbml_sqlite --no-print --half --if-table-exists --if-index-exists --write schema.sqlite.sql tmp.dbml && \
rm tmp.dbml && \
deactivate
```

## Database Migration

We will be using **Atlas** to manage all changes and updates to our database. Atlas is a modern tool that helps us efficiently organize and evolve the structure of our database. Specifically, we're adopting its **Versioned** approach: this means we simply define exactly how we want our database to look, and Atlas will then intelligently figure out the necessary steps and apply those changes for us. This process greatly simplifies how we update our database over time, making it more reliable and easier to maintain.

### Schema Inspect

The Atlas `schema inspect` command connects to your database and automatically maps out its current structure. It then displays this layout on your screen (formatted in Atlas DDL). You can save this output to a file, which you can then edit and use to plan and safely apply "migrations" to your database.

#### SQLite

```bash
atlas schema inspect \
  --url "file://schema.sqlite.sql" \
  --dev-url "sqlite://file?mode=memory"
```

#### PostgreSQL

```bash
atlas schema inspect \
  --url "postgres://user:pass@server:port/database?sslmode=disable"
```

The standard output is an HCL file. If you want a different format, you can use the `--format '{{ FORMAT . }}'` parameter. Simply replace `FORMAT` with one of these options: `json`, `sql`, or `mermaid`.

### Create Migration

The Atlas `migrate diff` command helps you automatically write database update scripts. It looks at your existing database setup (`--dir`), compares it to how you want it to be (`--to`), and then creates a new file (like `MIGRATION_DESCRIPTION`) with the SQL commands needed to make those changes. It uses a temporary 'dev-database' to figure out your current setup.

#### SQLite

```bash
atlas migrate diff MIGRATION_DESCRIPTION \
  --dir file://migrations_sqlite \
  --to file://schema.sqlite.sql \
  --dev-url "sqlite://file?mode=memory"
```

#### PostgreSQL

```bash
atlas migrate diff MIGRATION_DESCRIPTION \
  --to file://schema.postgresql.sql \
  --dev-url "postgres://user:pass@server:port/database?sslmode=disable"
```

### Apply Migrations

Atlas's `migrate apply` command updates your database by first checking its current state (`--url`) and then identifying any pending changes defined in your migration files (`--dir`). It applies these changes to your database in the correct order. You can use the `--dry-run` parameter to preview exactly what changes would be made without actually modifying the database.

#### SQLite

```bash
atlas migrate apply \
  --url "sqlite://database.sqlite.db" \
  --dir file://migrations_sqlite \
  --dry-run
```

#### PostgreSQL

```bash
atlas migrate apply \
  --url "postgres://user:pass@server:port/database?sslmode=disable" \
  --dry-run
```
