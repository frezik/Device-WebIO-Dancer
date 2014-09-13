use Dancer;
use lib '.';
use Device::WebIO::Dancer;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Plack::Builder;

my $webio = Device::WebIO->new;
my $rpi = Device::WebIO::RaspberryPi->new;
$webio->register( 'rpi', $rpi );

Device::WebIO::Dancer::init( $webio, 'rpi' );

 
builder {
    my $ret = do 'psgi_examples/default_enable.pl';
    die "Can't open default_enable.pl: $@\n" if( (!defined $ret) && $@ );
    die "Can't open default_enable.pl: $!\n" if( (!defined $ret) && $! );

    dance;
};
