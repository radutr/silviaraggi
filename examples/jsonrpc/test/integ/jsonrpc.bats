#!/usr/bin/env bats

# Simple and non exhaustive test suite using bats:
# https://github.com/sstephenson/bats

PIDFILE=run/jsonrpc.pid
CONFFILE=conf/jsonrpc.conf

# Start and stop have to be tweaked before being used
stop_app() {
	if [ -f "$PIDFILE" ]; then
		kill -QUIT `cat "$PIDFILE"`
		sleep 3
	fi
	if [ -f "$PIDFILE" ]; then
		kill -KILL `cat "$PIDFILE"`
		sleep 2
	fi
}

start_app() {
	stop_app
	kore -nrc "$CONFFILE"
}

query_with_content_type() {
	curl -q \
	    -H "Content-Type: $1" \
	    -X POST \
            --raw \
            -d "$2" \
            -s -S \
            --insecure \
            "https://127.0.0.1:8888/v1"
}

query() {
	query_with_content_type "application/json" "$1"
}

grepstr() {
	declare result=$1
	shift
	printf "%s" "$result" | grep "$@" >/dev/null
}

printrep() {
	declare query=$1
    	declare result=$2
    	printf "Sent:\n"
    	printf "%s\n" "$query"
    	printf "Received:\n"
    	printf "%s\n" "$result"
}

@test "requests with no protocol raise errors" {
    	query='{"method":"foo"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}
@test "requests with invalid protocol (1) raise errors" {
	query='{"jsonrpc":"1.0","method":"foo"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}
@test "requests with invalid protocol (2) raise errors" {
    	query='{"jsonrpc":2.0,"method":"foo"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}

@test "requests with no method raise errors" {
	query='{"jsonrpc":"2.0"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}
@test "requests with invalid method raise errors" {
	query='{"jsonrpc":"2.0","method":1}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}
@test "requests with unknown method raise errors" {
    	query='{"jsonrpc":"2.0","method":"foobar"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
}

@test "error responses give back the string request id" {
	query='{"jsonrpc":"2.0","id":"foo"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
    	grepstr "$result" '"id"[ \t\n]*:[ \t\n]*"foo"'
}
@test "error responses give back the integer request id" {
    	query='{"jsonrpc":"2.0","id":1}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"error"[ \t\n]*:[ \t\n]*{[ \t\n]*"code"'
    	grepstr "$result" '"id"[ \t\n]*:[ \t\n]*1'
}
@test "result responses give back the string request" {
	query='{"jsonrpc":"2.0","method":"echo","params":"foobar","id":"tau"}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"result"[ \t\n]*:[ \t\n]*"foobar"'
    	grepstr "$result" '"id"[ \t\n]*:[ \t\n]*"tau"'
}
@test "result responses give back the integer request id" {
	query='{"jsonrpc":"2.0","method":"echo","params":"foobar","id":6}'
    	result=`query "$query"`
    	printrep "$query" "$result"
    	grepstr "$result" '"result"[ \t\n]*:[ \t\n]*"foobar"'
    	grepstr "$result" '"id"[ \t\n]*:[ \t\n]*6'
}
