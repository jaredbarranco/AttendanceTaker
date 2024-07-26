module attendance-taker/server

go 1.22.5

require github.com/lib/pq v1.10.9

replace attendance-taker/db => ../db

require attendance-taker/db v0.0.0
