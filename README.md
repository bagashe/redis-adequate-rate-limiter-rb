Wrapper for a Lua script for Redis that provides **smooth**, **configurable**, **space-efficient** & **blazing fast** rate limiting. 


### Usage:
  
    require 'redis'
    require 'redis/adequate-rate-limiter'
   
    r = Redis.new
    rate_limiter = Redis::AdequateRateLimiter.new(r)
    rate_limiter.configure(r, event_type, max_allowed, over_interval, lockout_interval)
   
    ...
    if rate_limiter.is_allowed?(r, event_type, actor, check_only: false)
       # Count this action and check if it is allowed.
       ...
    end
    ...
   
    # OR
    ...
    if rate_limiter.is_allowed?(r, event_type, actor, check_only: true)
       # Don't count this action and check if it is allowed. 
       ...
    end
   
   
If `is_allowed?` is invoked on an event type that has not been configured, a ConfigNotDefinedError exception will be raised.


                                                                                                     
### Configuration Example
```
event_type = "api-access"                                                                                 
max_allowed = 1000
over_interval = 3600
lockout_interval = 300                                                                   
```
Each `actor` will be rate limited to `1000` `api-access` events per `3600 seconds`. Once the limit   
is reached, the `actor` will be locked out for `300 seconds`. Note that the rate limit applies over  
a rolling window.                                                                                    
                                                                                                     
### Features                                                                                                     
This rate-limiting solution -                                                                        
1. Does not use buckets & does not enumerate events. So it is space-efficient. It stores everything  
in a three-tuple for each `actor`,`event` pair.                                                      
2. Uses a simple linear decay function to compute available quota. So it is blazing fast.            
3. Can be easily configured to rate limit over a few seconds or a few hours or a few days.           
                      
                                                                                                     
### Performance benchmark of the Lua script using redis-benchmark                                                                                         
Processor: Intel® Core™ i7-8550U CPU @ 1.80GHz × 8                                     
Results: **142836.73 requests per second** with **99%** of them being served in under **0.6 ms**                     
_Note that client and server were running on the same machine. Even so, it proves that performance of this Lua script should not be an issue._                                               
