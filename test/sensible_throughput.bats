#!/usr/bin/env bats
# Test if mkmimo shows reasonable throughput on corner cases
load test_helpers

@test "a single slow consumer should not hurt overall throughput (takes 5s)" {
    expected_throughput=100000000  # 100MB/s
    nsecs=5
    nbytes=$(
        mkmimo_throughput \
            timeout=${nsecs}s \
            num_producer_fast=10 num_producer_slow=0 \
            num_consumer_fast=0 num_consumer_slow=1 \
            producer_slow_throughput=ignored \
            consumer_slow_throughput=${expected_throughput} \
            2>&1 | grep ' bytes' | awk '{print $1}' | tr '\n' +
        echo 0
    )
    throughput=$(bc <<<"$nbytes / $nsecs")
    throughputSatisfactionPercentExpr="100 * $throughput / $expected_throughput"
    echo $throughputSatisfactionPercentExpr
    throughputSatisfactionPercent=$(bc <<<"$throughputSatisfactionPercentExpr")
    [[ $throughputSatisfactionPercent -ge 80 ]]
}

@test "slow consumer should not hurt fast consumer's throughput (takes 5-20s)" {
    expected_throughput=1000000000  # 1GB/s
    slow_throughput=4k
    nsecs=5
    let nbytes=$(
        timeout $(($nsecs * 4)) \
        mkmimo_throughput \
            timeout=${nsecs}s \
            num_producer_fast=10 num_producer_slow=0 \
            num_consumer_fast=1 num_consumer_slow=1 \
            producer_slow_throughput=ignored \
            consumer_fast_throughput=${expected_throughput} \
            consumer_slow_throughput=${slow_throughput} \
            2>&1 | grep ' bytes' | awk '{print $1}' | tr '\n' +
        echo 0
    )
    throughput=$(bc <<<"$nbytes / $nsecs")
    throughputSatisfactionPercentExpr="100 * $throughput / $expected_throughput"
    echo $throughputSatisfactionPercentExpr
    throughputSatisfactionPercent=$(bc <<<"$throughputSatisfactionPercentExpr")
    [[ $throughputSatisfactionPercent -ge 80 ]]
}