package Net::Proxy::Connector::dummy;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;

use Net::Proxy::Connector;
our @ISA = qw( Net::Proxy::Connector );

# IN
sub listen { }

sub accept_from { }

# READ
sub read_from { return '' }

# WRITE
sub write_data_to { }

# OUT
sub open_connection { }

1;

__END__

=head1 NAME

Net::Proxy::Connector::dummy - Net::Proxy connector for standard tcp proxies

=head1 SYNOPSIS

    use Net::Proxy;

    my $proxy = Net::Proxy->new(
        in  => { type => 'dual', port => '6789' },
        out => { type => 'dummy' }
    );

    $proxy->register();

    Net::Proxy->mainloop();

=head1 DESCRIPTION

=head1 PROXY OPTIONS

=head1 AUTHOR

=head1 COPYRIGHT

=head1 LICENSE

