use Dancer2;
use Device::WebIO::Dancer;
use Plack::Builder;
 
builder {
    enable 'Deflater';
    enable 'Session', store => 'File';
    enable 'Debug', panels => [ qw<DBITrace Memory Timer> ];
    dance;
};
