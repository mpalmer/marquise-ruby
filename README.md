# Marquise for Ruby

This package contains Ruby bindings for the
[Marquise](https://github.com/anchor/libmarquise) data vault insertion
library.  You should use it if you want to send data points to
[Vaultaire](https://github.com/anchor/vaultaire) in Ruby code.


# Installation

You should make sure you have libmarquise installed correctly first -- this
package will not work properly without it.

Then, simply install the `marquise` gem from Rubygems:

    gem install marquise

And you should be good to go.


# Usage

Simply create a `Marquise` object, with the URL of the zeroMQ broker you
wish to use:

    s = Marquise.new('tcp://chateau.example.com:5560')

When you're finished with your instance, you should close it, to cleanup
file handles and such:

    s.close

If you're someone who doesn't like to stuff around with manual resource
release, there's also the very Rubyish block form:

    Marquise.open('tcp://chateau.example.com:5560') do |s|
        # Do things with s
    end

Which will create a new Marquise object, yield it to your block, then close
off the thing when you're done.


# Sending data points

You send data points through a `Marquise` instance by `tell`ing it; these
are the simplest possible forms for each type of data Vaultaire can store:

    s.tell(42)              # Send an integer
    s.tell(Math::PI)        # Send a float
    s.tell("Hello World")   # Send a string
    s.tell("Hello World".encode("ASCII-8BIT")  # Send a binary blob
    s.tell                  # Send a counter increment


## Types and type conversion

Vaultaire is able to store:

 * UTF-8 Strings;
 * Binary blobs;
 * Integers, in the range -(2^63)+1 to (2^63)-1;
 * Double-precision floating-point numbers;
 * Counter increments.

Marquise will automatically determine the most appropriate type to store the
value in, given the type of the first argument passed to `#tell`, by
applying the following rules:

 1. If the first argument `is_a? Hash`, then store a counter increment with
    a timestamp of `Time.now`;

 1. If the first argument `is_a? Time`, then store a counter increment with
    a timestamp of the first argument;

 1. If the first argument has a `#to_str` method, then call that and store
    the result as a binary (if the `#encoding` method returns `ASCII-8BIT`
    or the string does not encode cleanly to UTF-8), or as a UTF-8 string
    otherwise;
 
 1. If the first argument has a `#integer?` method, then call that, and
    based on whether the result of that is `true` or `false`, store either
    an integer or float.

 1. Otherwise, raise `ArgumentError`, as we were unable to determine how to
    convert the provided argument into something that would be understood.


## Timestamps

Vaultaire stores all data points with a timestamp.  If you want to specify
the timestamp that should be associated with your data point, you should
pass a `Time` object to `Marquise#send` as the first non-value argument
(that is, the first argument if storing a counter increment, or the second
argument otherwise).  If you do not specify a timestamp, then `Time.now`
will be called within the `#send` method, and that time used as the
timestamp.


## Tagging data points

To differentiate data points from different series, Vaultaire allows the
specification of arbitrary key/value hashes, which you specify in the usual
Rubyesque fashion:

    s.tell(42, :answer => 'ultimate')
    s.tell(Math::PI, constant: 'yes', closest_to: 3)

Note that all keys and values will be converted into strings using `#to_s`,
because Vaultaire only supports strings in its tag hashes.
