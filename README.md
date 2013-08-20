1. Run the following tasks to setup the project:
```cp proxy.example.yml proxy.yml```
```cp database.example.yml database.yml```
```cp gcs.example.yml gcs.yml```
```rake db:create```
```rake db:migrate```

2. Run the scraper script:
```ruby run.rb```

Read about Google Custom Search on https://developers.google.com/custom-search/v1/using_rest.
