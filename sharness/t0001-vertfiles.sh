#!/bin/sh

test_description="Check for duplicate source files in compiled .vert files"

. ./lib/sharness/sharness.sh

SHARNESS_TEST_SRCDIR=".."
VERTFILES="../../cormani-brut-nko.vert ../../cormani-brut-lat.vert"

test_expect_success "Vert files exist and are accessible" "
    echo $PWD &&
    stat $VERTFILES
"

test_expect_success "No duplicate documents in .vert corpora" "
    test "$(awk '$1 ~ /<doc/ { print $2 }' $VERTFILES | sort | uniq -c | awk '{ count[$1]++} END{for (i in count) {printf "%s", i}}')" = 1
"

test_done
