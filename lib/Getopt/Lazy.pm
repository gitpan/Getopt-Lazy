package Getopt::Lazy;

use version; our $VERSION = qv('0.0.3');

use strict;
use warnings;

=head1 NAME

Getopt::Lazy - Yet another lazy, minimal way of using Getopt::Long

=head1 SYNOPSIS

    use Getopt::Lazy
	'help|h' => 'Show this help screen',
	'verbose|v' => 'Show verbose output',
	'output|o=s' => ["[FILE] Send the output to FILE", 'getopt.out'],
	'output-encoding=s' => ['[ENCODING] Specify the output encoding', 'utf8'],
	-summary => 'a simple example usage of Getopt::Lazy',
	-usage => '%c %o file1 [file2 ..]',
	;

    getopt;
    print usage and exit 1 unless @ARGV;

=head1 DESCRIPTION

Getting tired of the digging the same tedious "getopt" things for every script
that you write?  This module works for you!

=head2 Without Getopt::Lazy

Normally we started a script this way:

    use File::Basename;
    use Getopt::Long;

    sub usage {
	my $msg = shift;
	my $cmd = basename $0;
	print $msg, "\n" if defined $msg;
	print <<__USAGE__;
    $cmd - Yet another tool for whatever you like
    Usage:  $cmd [options...] file [more-file]
    Options:
	    --boolean,-b			Turn on the function A
	    --string, -s STRING			Specify the name of blahblah (defaults 'blahblah')
	    --another-string, -as STRING	Specify an alias for blahblah (defaults 'blahblah')
	    ...
    __USAGE__
    }

    my $boolean = 0;
    my $string = 'blahblah';
    my $another_string = 'blahblah';
    ...

    GetOptions(
	'boolean|b' => \$boolean,
	'string|s=s' => \$string,
	'another-string|as=s' => \$string,
	...
    );

    usage and exit unless @ARGV;

=head2 With Getopt::Lazy

...or, being a little bit "lazier" than usual:

    use Getopt::Lazy
	'boolean|b' => 'Turn on the function A',
	'string|s=s' => ['[STRING] Specify the name of blahblah' => 'blahblah'],
	'another-string|as=s' => ['[STRING] Specify an alias for blahblah' => 'blahblah'],
	-summary => 'Yet another tool for whatever you like',
	-usage => '%c %o file1 [more-file]',
	;

    getopt;
    print usage and exit 1 unless @ARGV;

=head2 What We've Got?

The usage() will display the following help screen for you:

    $ lazy
    lazy - Yet another tool for whatever you like
    Usage:  lazy [options..] file1 [more-file]
    Options:
	    --another-string, -as STRING    Specify an alias for blahblah (default: blahblah)
	    --boolean                       Turn on the function A
	    --string, -s STRING             Specify the name of blahblah (default: blahblah)


=head2 Detail Usage

Basically the Getopt::Lazy does two things for you: 1) spawning a variable for
every given option, and 2) generating GNU-style help message.  (Guess I was too
lazy to put this down in details.  See for yourself!) If you have other even
lazier ways of doing the same thing, be sure to let me know!

=head1 INTERFACE 

=cut

use Carp;

our @ISA = qw/Exporter/;
our @EXPORT = qw/usage getopt/;
our %OPT = ();
our %USAGE = ();
our %CONFIG = ();

sub import {
    my $pkg = shift;
    my %o = @_;

    for (keys %o) {
	m/^-(\w+)$/ and do {
	    $CONFIG{$1} = $o{$_};
	    next;
	};

	my ($type, $spec, $name) = m/^([\@\%\$])?((.+?)(?:\|.*)?(?:\=.*)?)$/;
	my $guess = undef;
	(my $var = $name) =~ s/-/_/g;
	push @EXPORT, ($type || $guess || '$') . $var;

	my $item = "--$name"; 
	my ($desc, @def) = ref $o{$_} eq 'ARRAY' ? @{$o{$_}}: $o{$_};
	$spec =~ /\|(\w+)=/ and $item .= ", -$1";
	$desc =~ s/^\[([A-Z_-]+)\]\s*// and $item .= " $1";
	$USAGE{$item} = $desc;

        no strict 'refs';
        not (defined $type and $type eq '$') and do {
            $USAGE{$item} .= " (default: $def[0])" if $def[0];
            ${"$var"} = pop @def;
            $OPT{$spec} = *{"$var"}{SCALAR};
        } or $type eq '@' and do {
            $USAGE{$item} .= " (default: ".join(',', @def).")" if @def > 0;
            @{"$var"} = (@def);
            $OPT{$spec} = *{"$var"}{ARRAY};
        } or $type eq '%' and do {
            %{"$var"} = (@def);
            $OPT{$spec} = *{"$var"}{HASH};
        };

    }

    $pkg->export_to_level(1, undef, @EXPORT);
}

=over 2

=item usage

Show the GNU-style help screen 

=back

=cut

sub usage {
    use File::Basename;
    use Text::Wrap;

    my $msg = shift;
    my $cmd = $CONFIG{cmd} || basename $0;
    my $summary = $CONFIG{summary}; 
    my $usage = $CONFIG{usage} || '%c %o';
    $usage =~ s/\%c\b/$cmd/g;
    $usage =~ s/\%o\b/[options..]/g;

    print $msg, "\n" if defined $msg;
    print $cmd, ($summary? " - $summary\n": "\n");
    print "Usage:  $usage\n" if defined $usage;
    return unless keys %USAGE;

    print "Options:\n";
    my $size = 8 * int (((reverse sort { $a <=> $b } map length $_, keys %USAGE)[0] + 8) / 8);
    for (sort keys %USAGE) {
	printf "\t%-${size}s%s\n", $_, $USAGE{$_};
    }

    1;
}

=over 2

=item getopt

Make Getopt::Long work!

=back

=cut

sub getopt {
    use Getopt::Long;
    GetOptions %OPT;
}


1; # Magic true value required at end of module
__END__

=head1 CONFIGURATION AND ENVIRONMENT

Getopt::Lazy requires no configuration files or environment variables.

=head1 DEPENDENCIES

Getopt::Lazy depends on Getopt::Long.

=head1 INCOMPATIBILITIES

None reported (so far so good.)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-getopt-lazy@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Ruey-Cheng Chen  C<< <rueycheng@gmail.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Ruey-Cheng Chen C<< <rueycheng@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.