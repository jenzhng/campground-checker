# campground-checker
Command line Ruby app that checks reservation.gov for campsite vacancies. App takes input such as camp type, number of nights, and park id. 

## Testing 
- [x] retrieve park name

## Example Usage
```
ruby campground-checker.rb --start_date 2022-05-01 --parks 232508
{:start_date=>"2022-05-01", :parks=>"232508"}
BLACKWOODS CAMPGROUND
```

```
ruby campground-checker.rb --start_date 2022-05-01 --end_date 2022-05-31 --parks 10149034 --campsite_type 'CABIN ELECTRIC' --nights 5
{:parks=>["10149034"], :campsite_ids=>[], :start_date=>"2022-05-01", :end_date=>"2022-05-31", :campsite_type=>"CABIN ELECTRIC", :nights=>"5"}
there are campsites open from 2022-05-01 to 2022-05-31!!!
The Bayberry Dunes Beachview House (10149034): 1 site(s) open out of 1 site(s)
```
