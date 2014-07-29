package Device::WebIO::Dancer;

# ABSTRACT: REST interface for Device::WebIO using Dancer
use v5.12;
use Dancer2;


get '/' => sub {
    "Hello, world!";
};


#dance;
1;
__END__
