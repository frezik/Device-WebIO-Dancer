# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use Test::More tests => 21;
use v5.14;
use lib 't/lib';
use PlackTest;
use HTTP::Request::Common;
use Device::WebIO::Dancer;
use Device::WebIO;
use MockDigitalInputOutput;

my $io = MockDigitalInputOutput->new({
    input_pin_count  => 8,
    output_pin_count => 8,
});
my $webio = Device::WebIO->new;
$webio->register( 'foo', $io );
my $test = PlackTest->get_plack_test( $webio );

$io->mock_set_input( 0, 1 );
$io->mock_set_input( 1, 0 );
$io->mock_set_input( 2, 1 );

my $res = $test->request( GET "/devices/foo/count" );
cmp_ok( $res->code, '==', 200, "Got input count response" );
cmp_ok( $res->content, 'eq', 8, "Got input count" );

$res = $test->request( GET "/devices/foo/0/value" );
cmp_ok( $res->code, '==', 200, "Got value response" );
cmp_ok( $res->content, 'eq', 1 );

$res = $test->request( GET "/devices/foo/*/value" );
cmp_ok( $res->code, '==', 200, "Got read all list response" );
cmp_ok( $res->content, 'eq', '0,0,0,0,0,1,0,1' );

$res = $test->request( GET "/devices/foo/*/integer" );
cmp_ok( $res->code, '==', 200, "Got read all int response" );
cmp_ok( $res->content, '==', 0b00000101 );

$res = $test->request( POST "/devices/foo/0/function/IN" );
cmp_ok( $res->code, '==', 200, "Got function set response" );

$res = $test->request( GET "/devices/foo/0/function" );
cmp_ok( $res->code, '==', 200, "Got function type response" );
cmp_ok( $res->content, 'eq', "IN" );

$res = $test->request( POST "/devices/foo/1/function/OUT" );
cmp_ok( $res->code, '==', 200, "Got function set response" );
ok( $io->is_set_output( 1 ) );

$res = $test->request( POST "/devices/foo/1/value/1" );
cmp_ok( $res->code, '==', 200, "Set output value" );
ok( $io->mock_get_output( 1 ), "Output value was set to TRUE" );

$res = $test->request( POST "/devices/foo/1/value/0" );
cmp_ok( $res->code, '==', 200, "Set output value" );
ok(! $io->mock_get_output( 1 ), "Output value was set to FALSE" );

$res = $test->request( POST "/devices/foo/*/integer/00000010" );
cmp_ok( $res->code, '==', 200, "Write port response" );
ok( $io->mock_get_output( 1 ), "Output value set by port write" );

$res = $test->request( GET "/devices/foo/*" );
cmp_ok( $res->code, '==', 200, "Got read all everything response" );
cmp_ok( $res->content, 'eq', "0:UNSET,0:UNSET,0:UNSET,0:UNSET,0:UNSET,0:UNSET,0:OUT,1:IN" );