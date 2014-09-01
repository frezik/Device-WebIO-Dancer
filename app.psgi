use Dancer;
use Device::WebIO::Dancer;
use Plack::Builder;
use Log::Dispatch;

use constant LOG_DIR   => 'logs';
use constant LOG_FILE  => LOG_DIR . '/plack.log';
use constant LOG_LEVEL => 'debug';

my $logger = Log::Dispatch->new(
    outputs => [
        [
            'File',
            min_level => LOG_LEVEL,
            filename  => LOG_FILE,
            mode      => '>>',
            newline   => 1,
        ],
    ],
);

 
builder {
    enable 'Deflater';
    enable 'Session', store => 'File';
    enable 'Debug', panels => [ qw<DBITrace Memory Timer> ];
    enable 'LogDispatch', logger => $logger;
    dance;
};
