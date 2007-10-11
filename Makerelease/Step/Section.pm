package Makerelease::Step::Section;

use strict;
use Makerelease::Step;

our @ISA=qw(Makerelease::Step);

# sub-sections don't skip on the dry-runs...  only executing steps do.
sub possibly_skip_dryrun {
    my ($self, $step, $parentstep, $counter) = @_;
    return 0;
}

sub step {
    my ($self, $step, $parentstep, $counter) = @_;

    # XXX: should we call this on the parent module instead of our
    # own?  Probably...
    $self->output("-- starting substeps in: $parentstep$counter\n");
    $self->{'master'}->process_steps($step, "$parentstep$counter.");
    $self->output("-- ending substeps in: $parentstep$counter\n");
    # step does nothing other than print things already handled by the parent
    return;
}

1;

