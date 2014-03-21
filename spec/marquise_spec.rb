require_relative './spec_helper'

require 'marquise'

describe Marquise do
	describe ".new" do
		it "bombs out without an argument" do
			expect { Marquise.new }.to raise_error
		end
		
		it "returns a Marquise instance when given a zmq URL" do
			expect(Marquise.new('tcp://localhost:4567')).to be_a(Marquise)
		end

		it "calls marquise_consumer_new with a zmq URL" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('19')

			Marquise.new('tcp://localhost:4567')
		end
		
		it "raises RuntimeError if marquise_consumer_new returns nil" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return(nil)

			expect { Marquise.new('tcp://localhost:4567') }.
			  to raise_error(RuntimeError, "libmarquise failed; check syslog (no, seriously)")
		end
		
		it "passes non-default batch_period if given" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 0.05).
			  and_return('38')

			Marquise.new('tcp://localhost:4567', 0.05)
		end
		
		it "defines a finalizer to call marquise_consumer_shutdown" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('xyzzy')
			ObjectSpace.
			  should_receive(:define_finalizer).
			  with(instance_of(Marquise), mock_janitor = double('janitor'))
			Marquise::Janitor.
			  should_receive(:new).
			  with('xyzzy', {}).
			  and_return(mock_janitor)

			x = Marquise.new('tcp://localhost:4567')
		end
	end
	
	describe ".open" do
		it "bombs out without an argument" do
			expect { Marquise.open }.to raise_error
		end
		
		it "returns a Marquise instance when given a zmq URL" do
			expect(Marquise.open('tcp://localhost:4567')).to be_a(Marquise)
		end

		it "calls marquise_consumer_new with a zmq URL" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('81')

			Marquise.open('tcp://localhost:4567')
		end
		
		it "raises RuntimeError if marquise_consumer_new returns nil" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return(nil)

			expect { Marquise.open('tcp://localhost:4567') }.
			  to raise_error(RuntimeError, "libmarquise failed; check syslog (no, seriously)")
		end
		
		it "passes non-default batch_period if given" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 0.05).
			  and_return('100')

			Marquise.open('tcp://localhost:4567', 0.05)
		end

		it "bombs out with a block but without an argument" do
			expect { Marquise.open() { |x| puts x } }.to raise_error
		end
		
		it "yields a Marquise instance when given a block" do
			expect do |b|
				Marquise.open('tcp://localhost:4567', &b)
			end.to yield_with_args(Marquise)
		end
	end
	
	describe "#connect" do
		it "calls marquise_connect" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('118')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('118').
			  and_return('122')

			x = Marquise.open('tcp://localhost:4567').connect
			# This is just cheating... avoid possibly sending insane data
			# to libmarquise via calling close functions on GC
			ObjectSpace.undefine_finalizer(x)
		end

		it "calls marquise_connect only once per thread" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('118')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('118').
			  and_return('122')

			x = Marquise.open('tcp://localhost:4567')
			# This is just cheating... avoid possibly sending insane data
			# to libmarquise via calling close functions on GC
			ObjectSpace.undefine_finalizer(x)
			
			10.times { x.connect }
		end

		it "barfs if marquise_connect fails" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('134')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('134').
			  and_return(nil)

			x = Marquise.open('tcp://localhost:4567')
			# This is just cheating... avoid possibly sending insane data
			# to libmarquise via calling close functions on GC
			ObjectSpace.undefine_finalizer(x)

			expect { x.connect }.
			  to raise_error(
			       RuntimeError,
			       "marquise_connect() failed... consult syslog (no, seriously)"
			     )
		end
		
		it "creates separate connections for each thread" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('156')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  twice.
			  with('156').
			  and_return('161.1', '161.2')

			x = Marquise.open('tcp://localhost:4567')
			# This is just cheating... avoid possibly sending insane data
			# to libmarquise via calling close functions on GC
			ObjectSpace.undefine_finalizer(x)
			
			th1 = Thread.new { 10.times { x.connect } }
			th2 = Thread.new { 10.times { x.connect } }
			
			th1.join
			th2.join
			
			# Digging inside the object... how naughty...
			conns = x.instance_variable_get(:@connections)
			
			expect(conns[th1]).to_not eq(conns[th2])
		end
	end
	
	describe "#close" do
		it "calls marquise_consumer_shutdown" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('121')
			Marquise::FFI.
			  should_receive(:marquise_consumer_shutdown).
			  with('121')

			Marquise.open('tcp://localhost:4567').close
		end
		
		it "doesn't call marquise_consumer_shutdown more than once" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('131')
			Marquise::FFI.
			  should_receive(:marquise_consumer_shutdown).
			  with('131')

			x = Marquise.open('tcp://localhost:4567').close
			
			# Creating a huge chunk of junk memory and then releasing it should
			# cause the GC to cleanup everything, running all finalizers
			x = 'x' * 100_000_000
			x = nil
			GC.start
		end
		
		it "calls marquise_close on the connection" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('148')
			Marquise::FFI.
			  should_receive(:marquise_consumer_shutdown).
			  with('148')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('148').
			  and_return('155')
			Marquise::FFI.
			  should_receive(:marquise_close).
			  with('155')

			x = Marquise.open('tcp://localhost:4567')
			x.connect
			x.close
		end

		it "calls marquise_close on all connections" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('255')
			Marquise::FFI.
			  should_receive(:marquise_consumer_shutdown).
			  with('255')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('255').
			  twice.
			  and_return('263.1', '263.2')
			Marquise::FFI.
			  should_receive(:marquise_close).
			  with('263.1')
			Marquise::FFI.
			  should_receive(:marquise_close).
			  with('263.2')

			x = Marquise.open('tcp://localhost:4567')
			
			Thread.new { x.connect }.join
			Thread.new { x.connect }.join

			x.close
		end
	end
end
