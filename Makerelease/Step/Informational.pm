package Makerelease::Step::Informational;

use strict;
use Makerelease::Step;

our @ISA=qw(Makerelease::Step);

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    # step does nothing other than print things already handled by the parent
    return;
}

1;

