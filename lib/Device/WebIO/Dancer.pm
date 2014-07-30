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

get qr{\A /devices/:name/\*/integer \z}x => sub {
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
        my @values = _int_to_array( $int,
            $webio->digital_input_pin_count( $name ) );
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

    my $type = _get_io_type( $name, $pin );
    return $type;
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

get qr{\A /devices/:name/\* \z}x => sub {
    my $name = params->{name};
    my $pin_count = $webio->digital_input_pin_count( $name );

    my $int = $webio->digital_input_port( $name );
    my @values = _int_to_array( $int, $pin_count );

    my @type_values = map {
        _get_io_type( $name, $_ );
    } 0 .. ($pin_count - 1);

    my $combined_types = join ',', map {
        $values[$_] . ':' . $type_values[$_]
    } 0 .. ($pin_count - 1);
    return $combined_types;
};


sub _int_to_array
{
    my ($int, $len) = @_;
    my @values = map {
        ($int >> $_) & 1
    } reverse (0 .. ($len - 1));
    return @values;
}

sub _get_io_type
{
    my ($name, $pin) = @_;
    # Ignore exceptions
    my $type = eval { $webio->is_set_input( $name, $pin ) } ? 'IN'
        : eval { $webio->is_set_output( $name, $pin ) }     ? 'OUT'
        : 'UNSET';
    return $type;
}

1;
__END__
