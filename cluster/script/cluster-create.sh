#!/bin/bash

redis-cli --cluster create rm1:6379 rm2:6379 rm3:6379 rr1:6379 rr2:6379 rr3:6379 --cluster-replicas 1 -a redis
