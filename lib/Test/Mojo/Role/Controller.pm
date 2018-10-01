package Test::Mojo::Role::Controller;

use Role::Tiny;

use Mojo::Loader 'load_class';

sub controller {
    my $t     = shift;
    my $class = shift;

    # load first matching class in namespace(s)
    my @classes = ($class);
    push @classes, "${_}::$class" for @{ $t->app->routes->namespaces };

    foreach (@classes) {
        my $err = load_class $_ or last;
    }

    my $tx = $t->app->ua->build_tx( @_ ? @_ : ( 'GET', '/' ) );

    return $class->new(
        {   app => $t->app,
            tx  => $tx,
        }
    );
}

1;

__END__

=pod

=head1 NAME

Test::Mojo::Role::Controller - easier testing of controllers and plugins

=head1 SYNOPSIS

    use Test::Mojo::WithRoles 'Controller';

    my $t = Test::Mojo::WithRoles->new('My::App');

    # controller with current GET / request
    my $c = $t->controller('Foo'); # searches in $t->app->routes->namespaces

    # Alternatively pass in the same arguments as for transaction building in
    # Test::Mojo
    # e.g.
    my $c = $t->controller( 'Foo' => POST => '/foo' => json => { foo => 'bar' } );

    # now can call methods on the controller
    $c->stash( ... );
    is $c->my_internal_method( ...' ), ...;
    is $c->my_helper( ... ), ...;

=head1 DESCRIPTION

Role for C<Test::Mojo> to facilitate testing functionality in controllers and
plugins.

Helpers in Mojolicious applications are added to both application and controller
but in many cases are only applicable on the controller. This allows testing
of a helper without the need to construct a fake route to call that helper.

=head1 METHODS

=head2 controller

    # Pass in:
    # * class name (or partial class name to be found in namespace)
    # * optional transaction building arguments (same as for $t->get_ok, $t->post_ok, etc)
    my $c = $t->controller('My::App::Controller');
    my $c = $t->controller( 'My::App::Controller', GET => '/foo' );
    my $c = $t->controller( 'My::App::Controller', POST => '/foo' => json => { ... } );

Returns a L<Mojolicious::Controller> object that can be used in tests. Takes optional
arguments to build a fake request.

=cut

