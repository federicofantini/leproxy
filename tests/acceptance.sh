#!/bin/bash

# test against first argument or search first file matching "leproxy*.php"
bin=${1:-$(ls -1 leproxy*.php | head -n1 || echo leproxy.php)}
echo "Testing $bin"

TEST_PORT=8180
TEST_PORT_CHAIN_1=8181
TEST_PORT_CHAIN_2=8182

test_number=0

# test command line arguments
((test_number++)); echo -n "$test_number - "; out=$(php $bin --version) && echo -n "OK (" && echo -n $out && echo ")" || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin --help) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin -h) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin --unknown 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(php $bin --unknown 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin invalid 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin 8080 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin user:pass@[::] --allow-unprotected 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin --block=http:// 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin --proxy= 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(php $bin --proxy=tcp://host/ 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

killall php 2>&- 1>&- || true
php $bin "127.0.0.1:$TEST_PORT" --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail "http://localhost:$TEST_PORT/pac" 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" "http://127.0.0.1:$TEST_PORT"/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://localhost:$TEST_PORT" "http://localhost:$TEST_PORT/pac" 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" --location http://github.com 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks4a://127.0.0.1:$TEST_PORT" --location http://github.com  2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# ensure we can receive multiple "Set-Cookie" headers
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" "http://httpbin.org/cookies/set?k2=v2&k1=v1" 2>&1)
if [ $? -eq 0 ]; then
  if echo "$out" | grep -q "Set-Cookie: k2=v2;"; then
    echo "OK"
  else
    if echo "$out" | grep -q "HTTP/1.1 503 Service Temporarily Unavailable"; then
      echo "OK"
    else
      echo "FAIL: $out" && exit 1
    fi
  fi
fi

# unneeded authentication should work
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://user:pass@127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://user:pass@127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# invalid URIs should return error
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks://127.0.0.1:$TEST_PORT" http://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

# restart LeProxy with really short timeout to ensure timeout error
killall php 2>&- 1>&- || true
php -d default_socket_timeout=0.001 $bin 127.0.0.1:$TEST_PORT --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "504 Gateway Time-out" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy on IPv6 address
killall php 2>&- 1>&- || true
php $bin "[::1]:$TEST_PORT" --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://[::1]:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://[::1]:$TEST_PORT" "http://[::1]:$TEST_PORT/pac" 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks://[::1]:$TEST_PORT" -6 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5://[::1]:$TEST_PORT" "http://[::1]:$TEST_PORT/pac" 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy with hosts and plain HTTP port blocked
killall php 2>&- 1>&- || true
php $bin "127.0.0.1:$TEST_PORT" --block=youtube.com --block=*.google.com --block=*:80 --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" https://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" http://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://google.de 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" http://www.google.de 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy with hosts file and plain HTTP port blocked
killall php 2>&- 1>&- || true
php $bin "127.0.0.1:$TEST_PORT" --block-hosts=tests/hosts-google --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://google.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://maps.google.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy on Unix domain socket path and another LeProxy instance for chaining
killall php 2>&- 1>&- || true
php $bin ./leproxy.tmp.socket --no-log &
pid=$!
php $bin :$TEST_PORT --proxy ./leproxy.tmp.socket --no-log &
sleep 2

((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
kill $pid && rm leproxy.tmp.socket && echo . || (echo "FAIL" && exit 1) || exit 1

# restart LeProxy with authentication required
killall php 2>&- 1>&- || true
php $bin "user:pass@127.0.0.1:$TEST_PORT" --no-log &
sleep 2

# authentication should work
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://user:pass@127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://user:pass@127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# invalid authentication should return error
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT" http://reactphp.org 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

# start another LeProxy instance for HTTP proxy chaining / nesting
php $bin "127.0.0.1:$TEST_PORT_CHAIN_1" --proxy="http://user:pass@127.0.0.1:$TEST_PORT" --no-log &
sleep 2

# client does not need authentication because first chain passes to next via HTTP
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT_CHAIN_1" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:TEST_PORT_CHAIN_1" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# start another LeProxy instance for SOCKS proxy chaining / nesting
php $bin "127.0.0.1:$TEST_PORT_CHAIN_2" --proxy="socks://user:pass@127.0.0.1:$TEST_PORT" --no-log &
sleep 2

# client does not need authentication because first chain passes to next via SOCKS
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "http://127.0.0.1:$TEST_PORT_CHAIN_2" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy "socks5h://127.0.0.1:$TEST_PORT_CHAIN_2" http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# start another LeProxy instance for invalid HTTP proxy chaining / nesting
php $bin 127.0.0.1:8183 --proxy="http://user:invalid@127.0.0.1:$TEST_PORT" --no-log &
sleep 2

# client does not need authentication because first chain passes to next via HTTP
((test_number++)); echo -n "$test_number - "; out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8183 https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1

killall php 2>&- 1>&- || true
echo DONE
