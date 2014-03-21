require_relative './spec_helper'
require 'marquise'

describe Marquise do
	describe "#tell" do
		let(:marquise) do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('#tell')
			Marquise::FFI.
			  should_receive(:marquise_connect).
			  with('#tell').
			  and_return('#tellconn')

			x = Marquise.new('tcp://localhost:4567')
			# Neuter the Marquise
			ObjectSpace.undefine_finalizer(x)
			
			x
		end
		
		describe "(counter)" do
			it "calls marquise_send_counter" do
				Marquise::FFI.
				  should_receive(:marquise_send_counter).
				  and_return(0)
			
				marquise.tell
			end

			it "passes sensible arguments to marquise_send_counter" do
				Marquise::FFI.stub(:marquise_send_counter) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(5)
					
					conn, src_f, src_v, src_c, tstamp = args
					
					expect(conn).to eq('#tellconn')

					expect(tstamp).
					  to be_within(1_000_000_000).
					  of(Time.now.to_f * 1_000_000_000)

					expect(src_c).to eq(0)
					expect(src_f).to be(nil)
					expect(src_v).to be(nil)
					
					0
				end
			
				marquise.tell
			end
			
			it "bombs out if marquise_send_counter fails" do
				Marquise::FFI.
				  should_receive(:marquise_send_counter).
				  and_return(-1)
				FFI.
				  should_receive(:errno).
				  with().
				  and_return(Errno::ENOEXEC::Errno)
				
				expect { marquise.tell }.to raise_error(Errno::ENOEXEC)
			end
			
			it "passes a custom timestamp" do
				t = Time.now - 86400

				Marquise::FFI.stub(:marquise_send_counter) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(5)
					
					conn, src_f, src_v, src_c, tstamp = args
					
					expect(tstamp).
					  to eq(t.to_f * 1_000_000_000)
					
					0
				end
			
				marquise.tell(t)
			end

			it "passes tags to marquise_send_counter" do
				Marquise::FFI.stub(:marquise_send_counter) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(5)
					
					conn, src_f, src_v, src_c, tstamp = args
					
					expect(conn).to eq('#tellconn')

					expect(tstamp).
					  to be_within(1_000_000_000).
					  of(Time.now.to_f * 1_000_000_000)

					expect(src_c).to eq(2)
					
					expect(src_f).to be_a(FFI::MemoryPointer)
					expect(src_f.size).to eq(3*src_f.type_size)
					expect(src_f[0].read_pointer.read_string).to eq('foo')
					expect(src_f[1].read_pointer.read_string).to eq('answer')
					expect(src_f[2].read_pointer.address).to eq(0)

					expect(src_v).to be_a(FFI::MemoryPointer)
					expect(src_v.size).to eq(3*src_f.type_size)
					expect(src_v[0].read_pointer.read_string).to eq('bar')
					expect(src_v[1].read_pointer.read_string).to eq('42')
					expect(src_v[2].read_pointer.address).to eq(0)
					
					0
				end
			
				marquise.tell(:foo => 'bar', 'answer' => 42)
			end

			it "passes timestamp *and* tags to marquise_send_counter" do
				t = Time.now + 86400
				
				Marquise::FFI.stub(:marquise_send_counter) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(5)
					
					conn, src_f, src_v, src_c, tstamp = args
					
					expect(conn).to eq('#tellconn')

					expect(tstamp).
					  to eq(t.to_f * 1_000_000_000)

					expect(src_c).to eq(2)
					
					expect(src_f).to be_a(FFI::MemoryPointer)
					expect(src_f.size).to eq(3*src_f.type_size)
					expect(src_f[0].read_pointer.read_string).to eq('foo')
					expect(src_f[1].read_pointer.read_string).to eq('answer')
					expect(src_f[2].read_pointer.address).to eq(0)

					expect(src_v).to be_a(FFI::MemoryPointer)
					expect(src_v.size).to eq(3*src_f.type_size)
					expect(src_v[0].read_pointer.read_string).to eq('bar')
					expect(src_v[1].read_pointer.read_string).to eq('42')
					expect(src_v[2].read_pointer.address).to eq(0)
					
					0
				end
			
				marquise.tell(t, :foo => 'bar', 'answer' => 42)
			end
		end
	end
end
