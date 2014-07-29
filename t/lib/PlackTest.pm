package PlackTest;
use v5.12;
use Dancer2;
use Plack::Test;
use Device::WebIO::Dancer;


sub get_plack_test
{
    my ($class, $webio) = @_;
    Device::WebIO::Dancer::init( $webio );
    my $app = Dancer2->psgi_app;
    my $test = Plack::Test->create( $app );
    return $test;
}


1;
__END__

