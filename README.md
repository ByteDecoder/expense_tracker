# Running the App

```bash
$ bundle exec rackup
```

# Creating development App database
```bash
$ bundle exec sequel -m ./db/migrations sqlite://db/development.db --echo
```
