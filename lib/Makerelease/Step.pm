package Makerelease::Step;

use strict;
use Makerelease;

our $VERSION = '0.1';

our @ISA=qw(Makerelease);

sub start_step {
    my ($self, $step) = @_;
}

sub possibly_skip_yn {
    my ($self, $step, $parentstep, $counter) = @_;

    if ($self->{'opts'}{'n'}) {
	if ($self->{'opts'}{'i'} || $step->{'interactive'}) {
	    $self->output("(Pause here to ensure the operator wishes to perform the step)");
	}
	return 1;
    }
    if ($self->{'opts'}{'i'} || $step->{'interactive'}) {
	my $info = $self->getinput("Do step $parentstep$counter (y,n,q)?");
	if ($info eq 'q') {
	    $self->output("... quitting as requested\n");
	    exit;
	}
	if ($info eq 'n') {
	    $self->output("... skipping step $parentstep$counter\n");
	    return 1;
	}
    }
    return 0;
}

sub possibly_skip_test {
    my ($self, $step, $parentstep, $counter) = @_;
    my ($result, $test);

    if ($step->{'skipif'}) {
	# Check if test matches
        $test = $self->expand_text( $step->{'skipif'} );
	$self->DEBUG("SkipIf: >$test<\n");
        $result = eval $test;
	$self->DEBUG("skipIf returns $result.\n");
        return $result;
    }

    if ($step->{'skipunless'}) {
	# Check if test matches
        $test = $self->expand_text( $step->{'skipunless'} );
	$self->DEBUG("SkipUnless: >$test<\n");
        $result = eval $test;
	$self->DEBUG("skipUnless returns $result.\n");
        return 1-$result;
    }
    return 0;
}

sub possibly_skip_dryrun {
    my ($self, $step, $parentstep, $counter) = @_;
    if ($self->{'opts'}{'n'}) {
	$self->document_step($step, $parentstep, $counter);
	return 1;
    }
    return 0;
}

# return 1 to skip, 0 to do it
sub possibly_skip {
    my $self = shift;

    my ($step, $parentstep, $counter) = @_;

    # handle -n
    return 1 if ($self->possibly_skip_dryrun(@_));

    # handle mandatory steps
    return 0 if ($step->{'mandatory'});

    # handle skip tests
    return $self->possibly_skip_test(@_);

    # handle -i
    return $self->possibly_skip_yn(@_);

    return 0;
}

sub print_description {
    my ($self, $step) = @_;
    my $text = $self->expand_text($step->{'text'});
    $text =~ s/\n\s*$//g;
    $self->output($text, "\n\n") if ($text);
}

sub finish_step {
    my ($self, $step, $parentstep, $counter) = @_;

    # do nothing on a dry-run
    return if ($self->{'opts'}{'n'});

    # maybe sleep if we're not pausing
    if (!$step->{'pause'}) {
	sleep($self->{'opts'}{'S'}) if ($self->{'opts'}{'S'});
	return;
    }

    # pause display
    my $info = $self->getinput("---- PRESS ENTER TO CONTINUE (q=quit) ----");
    if ($info eq 'q') {
	$self->output("Quitting...\n");
	exit;
    }
}

sub document_step {
}

sub expand_parameters {
    my ($self, $string) = @_;

    return $string if ($self->{'opts'}{'n'});
    # ignore {} sets with a leading $
    $string =~ s/([^\$]){([^\}]+)}/$1 . (exists($self->{'parameters'}{$2}) ? $self->{'parameters'}{$2} : "{$2}")/eg;

    # get the initial one too with no leading data
    $string =~ s/^{([^\}]+)}/(exists($self->{'parameters'}{$1}) ? $self->{'parameters'}{$1} : "{$1}")/eg;
    return $string;
}

# also tries to clean up newline->spaces blocks
sub expand_text {
    my ($self, $string) = @_;

    $string = $self->expand_parameters($string);
    $string =~ s/^\s*//;
    $string =~ s/([^\n\r])\r*\n[ \t]+/$1 /gm;
    $string =~ s/\r*\n\r*\n[ \t]+/\n\n/gm;
    $string =~ s/\s*$//;
    return $string;
}

sub test {
    my ($self) = @_;
    return 0;
}

sub WARN {
    my ($self, @args) = @_;
    use Data::Dumper;;
    print STDERR "WARNING: step: '$self->{'title'}'\n";
    print STDERR "WARNING: " . join("",@args) . "\n\n";
    return 1;
}

sub require_piece {
    my ($self, $step, $parentstep, $counter, $nametop, $namebot) = @_;
    return $self->WARN($step, "No '$nametop' element in this step")
      if (!exists($step->{$nametop}) ||
	  ref($step->{$nametop}) ne 'ARRAY' ||
	  $#{$step->{$nametop}} == -1);
    return 0 if (!$namebot);
    return $self->WARN($step, "No '$namebot' element inside '${nametop}' in this step")
      if (!exists($step->{$nametop}[0]{$namebot}) ||
	  ref($step->{$nametop}[0]{$namebot}) ne 'ARRAY' ||
	  $#{$step->{$nametop}[0]{$namebot}} == -1);
    return 0;
}

sub require_attribute {
    my ($self, $step, $parentstep, $counter, $nametop, $namebot) = @_;
    return $self->WARN($step, "No '$nametop' attribute in this step")
      if (!exists($step->{$nametop}) ||
	  ref($step->{$nametop}) eq 'ARRAY');
    return 0;
}

1;

