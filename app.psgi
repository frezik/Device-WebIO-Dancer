use Dancer;
use Device::WebIO::Dancer;
use Device::WebIO;
use Plack::Builder;

my $webio = Device::WebIO->new;
Device::WebIO::Dancer::init( $webio );

 
builder {
    do 'default_enable.pl';
    dance;
};
