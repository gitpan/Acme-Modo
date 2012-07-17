## TODO:
# Make it so Data types don't have standard methods imported (like say, Conditional, etc)
{
    package Acme::Modo;

    use warnings;
    use strict;

    our $VERSION = '0.001';
    $Acme::Modo::Classes = [];

    sub import {
        my ($class, %args) = @_;
        my $caller = caller;

        warnings->import();
        strict->import();

        localscope: {
            no strict 'refs';

            *{"${caller}::lambda"} = sub(&$) {
                my ($block, $ref) = @_;

                if (ref($ref) eq 'ARRAY') {
                    for (@{$ref}) {
                        $block->($_);
                    }
                }
                elsif (ref($ref) eq 'HASH') {
                    while(my ($key, $val) = each(%{$ref})) {
                        $block->($key, $val);
                    }
                }
            };

            *{"${caller}::enum"} = sub {
                my ($name, @args) = @_;
                for (my $i = 0; $i < @args; $i++) {
                    my $n = $i+1;
                    my $opt = $args[$i];
                    my @a = split(':', $opt);
                    if (@a > 1) {
                        $n   = $a[1];
                        $opt = $a[0];
                    }
                    *{"${name}::$opt"} = sub { return $n; };
                }
            };
                
            *{"${caller}::this"} = sub {
                return caller;
            };            

            *{"${caller}::prompt"} = sub {
                my ($text, $v) = @_;
                if ($v && $v == -1) {
                    print $text;
                }
                else { print "${text}\n"; }
                my $in = <STDIN>;
                chomp $in;
                return $in;
            };

            *{"${caller}::say"} = sub {
                my $str = shift;
                if (! defined $str) {
                    warn "say() requires an argument";
                    return 0;
                }
                if (ref($str) eq 'Int' or ref($str) eq 'Str') {
                    $str->say;
                }
                else {
                    print "${str}\n";
                }
            };

            *{"${caller}::conditional"} = sub {
                my ($name, @args) = @_;
                if ($name) {
                    my $pname = "Conditional::${name}";
                    *{$pname} = sub {
                        my $i;
                        my @err = ();
                        for (@args) {
                            $i++;
                            if ($_ =~ /^(\d+)/) {
                                push @err, $i
                                    if $1 == 0;
                            }
                        }

                        if (scalar(@err) > 0) {
                            return 0;
                        }
                        else {
                            return 1;
                        }
                    };
                }
            };

            *{"${caller}::private"} = sub {
                my ($name, $code) = @_;
            
                *{"${caller}::${name}"} = sub {
                    my $this = shift;
                    if (ref($this)) {
                        warn "${name} is a private method";
                        return;
                    }
                    $code->(@_);
                };
            };

            if ($args{as}) {
                if ($args{as} eq 'Class') {
                    *{ "$caller\::new" } = sub {
                        my ($self, %args) = @_;
                        my $a = { _used => {} };
                        if (%args) {
                            foreach my $arg (keys %args) {
                                $a->{$arg} = $args{$arg};
                                $a->{_used}->{$arg} = 1;
                            }
                        }
                        return bless $a, $caller;
                    };

                    *{ "$caller\::has" } = sub {
                        my ($name, %args) = @_;
                        $name = "${caller}::${name}";
                        my $rtype   = delete $args{is}||"";
                        my $default = delete $args{default}||"";
                        no strict 'refs';
                        if ($rtype eq 'ro') {
                            *{$name} = sub {
                                my ($self, $val) = @_;
                                if (@_ == 2) {
                                    warn "Cannot alter a Read-Only accessor";
                                    return ;
                                }
                                return $default;
                            };
                        }
                        else {
                            *{$name} = sub {
                                my ($self, $val) = @_;
                                if ($default && ! $self->{_used}->{$name}) {
                                    $self->{$name} = $default;
                                    $self->{_used}->{$name} = 1;
                                }
                                if (@_ == 2) {
                                    $self->{$name} = $val;
                                }
                                else {
                                    return $self->{$name}||"";
                                }
                            };
                        }
                    };

                    *{ "$caller\::extends" } = sub {
                        my (@classes) = @_;
                        my $pkg = $caller;

                        if ($pkg eq 'main') {
                            warn "Cannot extend main";
                            return ;
                        }

                        _extend_class( \@classes, $pkg );
                    };
                }
            }
        } # end localscope

        if ($args{is}) {
            _extend_class( $args{is}, $caller );
        }
    }
    
    sub _extend_class {
        my ($mothers, $class) = @_;

        foreach my $mother (@$mothers) {
            # if class is unknown to us, import it (FIXME)
            unless (grep { $_ eq $mother } @$Acme::Modo::Classes) {
                eval "use $mother";
                warn "Could not load $mother: $@"
                    if $@;
            
                $mother->import;
            }
            push @$Acme::Modo::Classes, $class;
        }

        {
            no strict 'refs';
            @{"${class}::ISA"} = @$mothers;
        }
    }

    sub clone { bless { %{ $_[0] } }, ref $_[0] }

    sub WHAT {
        my $self = shift;
        if (ref($self) eq 'Int') { return 'Int' }
        elsif (ref($self) eq 'Str') { return 'Str' }
        elsif (ref($self) eq 'Array') { return 'Array' }
    }

    sub val {
        my $self = shift;
        return @{$self->{_value}}
            if ref($self) eq 'Array';
        return $self->{_value};
    }

    sub say {
        my $self = shift;
        print $self->{_value} . "\n";
    }

    sub has {
        my ($self, $find) = @_;
        my $index = index($self->{_value}, $find);
        if ($index != -1) {
            return $index;
        }
        else { return 0; }
    }

    sub size {
        my $self = shift;
        my $val = $self->{_value};
        return scalar(@{$val}) if $self->WHAT eq 'Array';
        return length($val) if $self->WHAT eq 'Str';
        return $val if $self->WHAT eq 'Int';
    }

    sub substr {
        my ($self, $off, $len, $rep) = @_;
        return substr($self->{_value}, $off, $len, $rep);
    }
}

{
    ## Str class
    package Str;
    
    use base 'Acme::Modo';
   
    use overload (
        '+' => sub {
            my $orig = shift;
                for (@_) {
                $orig->concat($_);
            }

            return $orig;
        },
        '/' => sub {
            my ($str, $delim) = @_;
            my @s = split($delim, $str->val);
            my $a = Array->new(@s);
            return $a;
        },
        fallback => 1
    );
 
    sub new {
        my ($class, @str) = @_;
        return bless { _value => $str[0]||'' }, 'Str'
            if scalar(@str) == 1;
    
        my @a = ();
        for (@str) {
            push @a, Str->new($_);
        }
        return @a;
    }

    sub concat {
        my ($self, $what) = @_;
        $what = $self->val
            if ref($what) eq 'Str';

        $self->{_value} .= $what;
        return $self;
    }

    sub first {
        my $self = shift;

        return substr($self->{_value}, 0, 1);
    }
}

{
    ## Int class
    package Int;
   
    use overload (
        '+' => sub {
            my $orig = shift;
            for(@_) {
                $orig->add($_);
            }
            return $orig;
        },
        '-' => sub {
            my $orig = shift;
            for(@_) {
                $orig->subtract($_);
            }
            return $orig;
        },
        '/' => sub {
            my $orig = shift;
            for(@_) {
                $orig->divide($_);
            }
            return $orig;
        },
        '*' => sub {
            my $orig = shift;
            for(@_) {
                $orig->mult($_);
            }
            return $orig;
        },
    );

    use base 'Acme::Modo';
 
    sub new {
        my ($class, $int) = @_;
        
        my $self = {
            _value => $int||0,
        };

        return bless $self, 'Int';
    }

    sub add {
        my ($self, $int) = @_;
       
        $int = $int->val
            if ref($int) eq 'Int';
 
        $self->{_value} = $self->{_value} + $int;
        return $self;
    }

    sub subtract {
        my ($self, $int) = @_;

        $int = $int->val
            if ref($int) eq 'Int';

        $self->{_value} = $self->{_value} - $int;
        return $self;
    }

    sub divide {
        my ($self, $int) = @_;

        $int = $int->val
            if ref($int) eq 'Int';
    
        $self->{_value} = $self->{_value} / $int;
        return $self;
    }

    sub mult {
        my ($self, $int) = @_;

        $int = $int->val
            if ref($int) eq 'Int';
        
        $self->{_value} = $self->{_value} * $int;
        return $self;
    }
}

{
    ## Array class
    package Array;
    
    use base 'Acme::Modo';
    
    use overload (
        '+' => sub {
            my $orig = shift;
            for my $arr (@_) {
                $orig->push(@{$arr});
            }
            return $orig;
        },
        '<<' => sub {
            my $orig = shift;
            for my $arr (@_) {
                $orig->insert(@{$arr});
            }
            return $orig;
        },
        '~~' => sub {
            my ($ob, $match) = @_;
            return $ob->any($match);
        },
        '/=' => sub {
            my ($ob, $delim) = @_;
            return Str->new(join $delim, @{$ob->{_value}});
        },
        fallback => 1,
    );
        
    sub new {
        my ($class, @j) = @_;
        
        if (! @j) {
            die "No list passed to Array\n";
        }

        my $self = {
            _value => \@j,
        };
        
        return bless $self, 'Array';
    }

    sub loop {
        my ($self, $code) = @_;
        for (@{$self->{_value}}) { $code->($_); }
    }

    sub push {
        my ($self, @list) = @_;
        push @{$self->{_value}}, @list;
        return $self;
    }

    sub insert {
        my ($self, @list) = @_;
        unshift @{$self->{_value}}, @list;
        return $self;
    }

    sub any {
        my ($self, $what) = @_;
        
        if (ref($what) eq 'Str') {
            $what = $what->val;
        }
        elsif (ref($what) eq 'Int') {
            $what = $what->val;
        }

        return grep { $_ eq $what } @{$self->{_value}};
    }
    
    sub first {
        my $self = shift;
        
        return $self->{_value}->[0];
    }

    sub last {
        my $self = shift;
        
        return $self->{_value}->[@{$self->{_value}}-1];
    }

    sub sort {
        my $self = shift;
    
        my @s = sort { $a cmp $b } @{$self->{_value}};
        $self->{_value} = \@s;
        return $self;
    }
}

{
    ## Method class
    package Method;
   
    sub new {
        my ($class, $code) = @_;
        
        my $self = {
            _value => $code,
        };
        
        return bless $self, 'Method';
    }

    sub inject {
        my ($self, $name) = @_;
        my $caller = caller(1);
        *{"${caller}::${name}"} = $self->{_value};
    }

    sub push {
        my ($self, %args) = @_;
        
        my $class = $args{to}||undef;
        my $name  = $args{as}||undef;
        
        if ($class && $name) {
            *{"${class}::${name}"} = $self->{_value};
            return 1;
        }
        else {
            warn "Attributes 'as' and 'to' needed to push";
            return 0;
        }
    }

    sub run {
        my $self = shift;
        return $self->{_value}->(@_);
    }
}

=head1 NAME

Acme::Modo - An attempt at a Modern Perl 5 implementation

=head1 DESCRIPTION

There is no real description for this module, hence why it's in the Acme::* namespace. It gives you the features to perform perl5 in a.. different way. It makes data type classes available (Int, Str and Array) and adds extra methods. You can even turn your package into a fully working object, if you wish. This module is still very experimental.

=head1 SYNOPSIS

    # Use / to split a string and return an Array class
    # You can do it all inline too, if you wish
    my $str = Str->new("player=Arthas;class=Spellsword;race=Imperial");
    ($str / ';')->loop(sub {
        my ($key, $val) = (Str->new($_) / '=')->val;
        say "$key = $val";
    });

=head1 DATA TYPE CLASSES

There are currently 3 classes; Str, Int and Array. Each have their own overloaded operators to perform different actions, or you can use it the object way.

=head2 Str

From the synopsis ypu cam see to create a Str you just need to
    
    my $str = Str->new("Some fancy string here");

Now, in my mind, strings shouldn't be allowed to perform math. That's just weird.

    my $arr = $str / ':' # splits a string using the ':' delimeter, returning an Array class
    $str = $str + " How" + " are" + " you?"; # adds extra strings to your current string

You can even set multiple Str classes in one hit. Using C<say> then a Str object will just print its value to the screen, not return the object

    sub name {
        my ($first, $last) = Str->new(@_);
        say $first; # prints Foo
        say $last;  # prints Bar
    }

    name "Foo", "Bar";

=head2 Int

These ones aren't very interesting yet. I haven't done a lot with them, but they are then when I'm ready to extend them.

=head2 Array

Initialisation is easy enough..

    my $arr = Array->new(1..6);
    my $arr = Array->new(qw( Hello there world ));

You can loop through an Array with C<loop>

    my $arr = Array->new(1..5);
    $arr->loop(sub {
        say $_;
    });

Push items to it (takes a reference)

    my $arr = Array->new('Hello');
    # $arr = $arr + ['something'];
    ($arr + [' World'])->loop(sub {
        say $_;
    });

Inserting will add an element to the beginning

    $arr = $arr << ['Boing'];

Matching is fairly easy too

    my $day = 'Tuesday';
    my $weekdays = Array->new(qw< Monday Tuesday Wednesday Thursday Friday >);
    
    say "See you on $day"
        if $weekdays ~~ $day;

=head2 Method

This one isn't really a data class. Infact it doesn't do much, but you may find it useful. It allows you to create a method on the fly, inject to the current package, run it or push it into another class.

    my $method = Method->new(sub {
        my ($class, $name) = @_;
        $name = $class if !$name;
        say "Hello, ${name};
    });

Now, we can use C<inject> to add the new subroutine into the currect package. The only argument it takes is the name of the subroutine.

    $method->inject('foo');
    foo("World");
    __PACKAGE__->foo("World"); # prints Hello, World

Or, we can use C<push> to inject it into a different class.

    use FooClass;
    
    $method->push(
        to => 'FooClass',
        as => 'foo'
    );

    FooClass->foo("World"); # prints Hello, World

Using C<run> you can execute the subroutine, which it will then return the results. Arguments to C<run> are actually the arguments you want to pass to the subroutine.

    say $method->run("World", "Something else", "Foo");

=head1 OBJECT BUILDING

Turning Modo into a working class is simple.

    package MyFoo;
    use Modo as => 'Class';
    
    1;

Above is a fully working class.. that doesn't do much, really. It injects the method 'new' for you, and also imports some class-only methods like C<has> and C<extends>.
Those familiar with modules like L<Moose> will know what I'm talking about.
C<has> creates a read-writable, or read-only accessor, and C<extends> will inherit another class.

    {
        package MyFoo;
        use Modo as => 'Class';
    
        has 'x' => ( is => 'rw', default => 5 );
    }

    my $foo = MyFoo->new;
    say $foo->x; # prints 5
    
    $foo->x(7); # updates x to 7
    say $foo->x; # prints 7

As you can see it supports minimal features from dedicated OOP frameworks, like C<rw> (Read-Writable) and C<ro> (Read-Only) accessors.

=head1 METHODS

=head2 private

We can create "private" methods, which means that method cannot be called by anything outside of the class it lives in. For example,

    {
        package MyFoo;
    
        use Acme::Modo as => 'Class';
    
        private 'baz' => sub {
            say "Hello, World!";
        };
    }
    
    my $foo = MyFoo->new;
    $foo->baz; # throws a warning

However, if we create a method that calls it from within itself..

    sub callbaz {
        this->baz;
    }

then..
    
    $foo->callbaz; # prints Hello, World!

This seems to be OK because we called a public method that ran the private method for us. Oh, by the way, you can use C<this> to return the package name.

=head2 enum

Let's take a look at the C<enum> method. I wanted something similar to perl6's enum, but done in perl5-style. With this we can create constants out of dynamically generated classes. Say we wanted to create our very own Boolean type.. yeah, we can do that.

    use Acme::Modo;

    enum Bool => ( 'True:1', 'False:0' );

    # set up a couple of test methods to test against our new Boolean type
    sub ok { return 1; }
    sub not_ok { return 0; }

    if (ok() == Bool->True) { say "We're good!"; }
    if (not_ok() == Bool->False) { say "This is false"; }

If you seperate an element with ':', then the value to the right will become the value of the method. If you omit this, then it will be the number of position in the list. For example, if we omited the 1 and 0 from our True and False elements, then True would have returned '1' and False would have returned '2'.

=head2 lambda

Not really a proper lambda, I guess. But I wasn't sure what else to name it. This works on arrayrefs or hashrefs, simply pass it a block, then the ref and it will iterate through it while passing the value, or key and value if applicable as arguments. You know, this almost resembles a C<map {}>. Oh well.

    # print 1 to 5
    lambda {
        say $_[0];
    } [ 1..5 ];

    # or you can do hashrefs
    my $h = {
        name  => 'Foo',
        age   => 5,
        place => 'Perl Land'
    };

    lambda {
        my ($key, $val) = @_;
        say "Key: $key";
        say "Value: $val";
    } $h;

=head2 clone

C<clone> can be performed on most data type classes (ie: Array, Str and Int). It creates a copy of the instance so you can perform actions without mutating the original object.

    my $str = Str->new("Hello");
    say $str->clone->concat(", World");
    say $str;

    # outputs:
    # Hello, World
    # Hello

=head2 prompt

Takes user input and returns it. This will also chomp the newline from the end for you. It takes two arguments, the last one being optional. The first argument is a line of text to present to the user before the STDIN is taken, the second, if you pass a -1 it will not add a newline to the end of the string sent.

    my $name = prompt("Please enter your name: ", -1);
    say "Hello, ${name}!";

    my $stuff = prompt("Type stuff below");
    say "You said: ${stuff}";

=head2 size

This is another data type method you can use on Strings, Integers and Arrays. For strings, it will return the length of the string. With Arrays it will return the number of elements, and it just returns the integer as itself. Useless, right?

    my $arr = Array->new(qw< a b c d e >);
    say $arr->size;

=head2 WHAT

Call this on any data type method to get its type. For example,

    my $this = Str->new("Hey");
    my $that = Array->new(1..6);
    
    say $this->WHAT; # Str
    say $that->WHAT; # Array

=head1 CONDITIONALS

A new type of class in Acme::Modo is C<Conditionals>. Basically, instead of writing an C<if> statement with a large number of tests, you can convert them all into one conditional and test that. As it creates a class per-conditional you can share them anywhere and resume them.

    # The conditional below would fail
    # because one of the tests equals 0
    conditional 'MyCond' => (
        this_method(),
        that_method(),
        10-10,
    );

    if (Conditional->MyCond) {
        say "We're good :-)";
    }
    else {
        say "There was a problem";
    }

When you call C<Conditional>, it will run through every test, and if any are false (equal to 0), then it returns 0 itself. If they all pass, it will return 1 for true.

=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

