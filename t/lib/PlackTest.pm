package PlackTest;
use v5.12;
use Dancer;
use Dancer::Handler::PSGI;
use Plack::Test;
use Device::WebIO::Dancer;
use Plack::Builder;


sub get_plack_test
{
    my ($class, $webio) = @_;

    Device::WebIO::Dancer::init( $webio );

    my $app = Dancer::Handler->psgi_app;
    my $test = Plack::Test->create( $app );

    return $test;
}


1;
__END__

