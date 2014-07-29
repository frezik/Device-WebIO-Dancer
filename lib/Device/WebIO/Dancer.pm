package Device::WebIO::Dancer;

# ABSTRACT: REST interface for Device::WebIO using Dancer
use v5.12;
use Dancer2;


my ($webio);

sub init
{
    my ($webio_ext) = @_;
    $webio = $webio_ext;
    return 1;
}


get '/' => sub {
    "Hello, world!";
};

get '/devices/:name/count' => sub {
    my $name  = params->{name};
    my $count = $webio->digital_input_pin_count( $name );
    return $count;
};

get qr{/devices/:name/\*/integer} => sub {
    my ($name) = params->{name};
    my $int = $webio->digital_input_port( $name );
    return $int;
};

get '/devices/:name/:pin/value' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};

    my $in;
    if( $pin eq '*' ) {
        my $int = $webio->digital_input_port( $name );
        my @values = map {
            ($int >> $_) & 1
        } reverse (0 .. ($webio->digital_input_pin_count($name) - 1));
        $in = join ',', @values;
    }
    else {
        $in = $webio->digital_input( $name, $pin );
    }
    return $in;
};

get '/devices/:name/:pin/function' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    # TODO get i/o type
    return 'BAD';
};

post '/devices/:name/:pin/function/:func' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $func = params->{func};

    if( 'IN' eq $func ) {
        $webio->set_as_input( $name, $pin );
    }
    elsif( 'OUT' eq $func ) {
        $webio->set_as_output( $name, $pin );
    }
    else {
        # TODO
    }

    return '';
};

get qr{/devices/:name/\*} => sub {
    # TODO
};


1;
__END__
