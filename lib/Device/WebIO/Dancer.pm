package Device::WebIO::Dancer;

# ABSTRACT: REST interface for Device::WebIO using Dancer
use v5.12;
use Dancer;

use constant VID_READ_LENGTH => 4096;


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

get '/devices/:name/:pin/integer' => sub {
    my ($name) = params->{name};
    my ($pin)  = params->{pin};
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
            reverse(0 .. $webio->digital_input_pin_count( $name ) - 1) );
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

get '/devices/:name/:pin' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $pin_count = $webio->digital_input_pin_count( $name );
    my @pin_index_list = 0 .. ($pin_count - 1);

    my (@values, @type_values);
    foreach (@pin_index_list) {
        my $type = _get_io_type( $name, $_ );
        push @type_values, $type;

        my $int = ($type eq 'IN') ? $webio->digital_input( $name, $_ ) :
            ($type eq 'OUT') ? 0 :
            0;
        push @values, $int;
    }

    my $combined_types = join ',', reverse map {
        $values[$_] . ':' . $type_values[$_]
    } @pin_index_list;
    return $combined_types;
};

post '/devices/:name/:pin/value/:digit' => sub {
    my $name  = params->{name};
    my $pin   = params->{pin};
    my $digit = params->{digit};

    $webio->digital_output( $name, $pin, $digit );

    return '';
};

post '/devices/:name/:pin/integer/:value' => sub {
    my $name  = params->{name};
    my $pin   = params->{pin};
    my $value = params->{value};

    $webio->digital_output_port( $name, $value );

    return '';
};

get '/devices/:name/video/count' => sub {
    my $name = params->{name};
    my $val  = $webio->vid_channels( $name );
    return $val;
};

get '/devices/:name/video/:channel/resolution' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};

    my $width  = $webio->vid_width( $name, $channel );
    my $height = $webio->vid_height( $name, $channel );
    my $fps    = $webio->vid_fps( $name, $channel );

    return $width . 'x' . $height . 'p' . $fps;
};

post '/devices/:name/video/:channel/resolution/:width/:height/:framerate'
    => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $width   = params->{width};
    my $height  = params->{height};
    my $fps     = params->{framerate};

    $webio->vid_set_width( $name, $channel, $width );
    $webio->vid_set_height( $name, $channel, $height );
    $webio->vid_set_fps( $name, $channel, $fps );

    return '';
};

get '/devices/:name/video/:channel/kbps' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};

    my $bitrate = $webio->vid_kbps( $name, $channel );

    return $bitrate;
};

post '/devices/:name/video/:channel/kbps/:bitrate' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $bitrate = params->{bitrate};
    $webio->vid_set_kbps( $name, $channel, $bitrate );
    return '';
};

get '/devices/:name/video/:channel/allowed-content-types' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $allowed = $webio->vid_allowed_content_types( $name, $channel );
    return join( "\n", @$allowed );
};

get '/devices/:name/video/:channel/stream/:type1/:type2' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $type1   = params->{type1};
    my $type2   = params->{type2};
    my $mime_type = $type1 . '/' . $type2;

    my $in_fh = $webio->vid_stream( $name, $channel, $mime_type );

    return send_file( '/etc/hosts',
        streaming    => 1,
        system_path  => 1,
        content_type => $mime_type,
        callbacks    => {
            around_content => sub {
                my ($writer, $chunk) = @_;

                my $buf;
                while( read( $in_fh, $buf, VID_READ_LENGTH ) ) {
                    $writer->write( $buf );
                }
                close $in_fh;
            }
        },
    );
};

get '/devices/:name/analog/count' => sub {
    my $name = params->{name};
    my $count = $webio->adc_count( $name );
    return $count;
};

get '/devices/:name/analog/maximum' => sub {
    # TODO deprecate this more explicitly (301 Moved Permanently?)
    my $name = params->{name};
    my $max = $webio->adc_max_int( $name, 0 );
    return $max;
};

get '/devices/:name/analog/:pin/maximum' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $max = $webio->adc_max_int( $name, $pin );
    return $max;
};

get '/devices/:name/analog/:pin/integer/vref' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_volt_ref( $name, $pin );
    return $value;
};

get '/devices/:name/analog/integer/vref' => sub {
    # TODO deprecate this more explicitly (301 Moved Permanently?)
    my $name = params->{name};
    my $value = $webio->adc_volt_ref( $name, 0 );
    return $value;
};

get '/devices/:name/analog/:pin/integer' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};

    my $value;
    if( $pin eq '*' ) {
        my @val = map {
            $webio->adc_input_int( $name, $_ ) // 0
        } 0 .. ($webio->adc_count( $name ) - 1);
        $value = join ',', @val;
    }
    else {
        $value = $webio->adc_input_int( $name, $pin );
    }
    return $value;
};

get '/devices/:name/analog/:pin/float' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_input_float( $name, $pin );
    return $value;
};

get '/devices/:name/analog/:pin/volt' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_input_volts( $name, $pin );
    return $value;
};


sub _int_to_array
{
    my ($int, @index_list) = @_;
    my @values = map {
        ($int >> $_) & 1
    } @index_list;
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
