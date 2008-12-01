#!/bin/sh -x
SRCDIR=$1
[ -d "$SRCDIR" ] || exit 1
LINTEL_PO_TEST=first ./program_options --mode=first --test --multi=1 --multi=2 || exit 1
LINTEL_PO_TEST=second ./program_options --sample=a --unknown foo || exit 1
LINTEL_PO_TEST=third ./program_options --help >check-help || exit 1
cmp check-help $SRCDIR/program_options.help.ref || exit 1
LINTEL_PO_TEST=fourth ./program_options -x || exit 1


