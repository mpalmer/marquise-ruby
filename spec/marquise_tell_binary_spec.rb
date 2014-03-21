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
		
		describe "(binary)" do
			it "sends a simple binary" do
				Marquise::FFI.stub(:send) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(8)

					method, conn, src_f, src_v, src_c, data, len, tstamp = args
					
					expect(method).to eq(:marquise_send_binary)
					expect(conn).to eq('#tellconn')

					expect(tstamp).
					  to be_within(1_000_000_000).
					  of(Time.now.to_f * 1_000_000_000)

					expect(src_c).to eq(0)
					expect(src_f).to be(nil)
					expect(src_v).to be(nil)
					
					expect(len).to eq("hello world".length)
					expect(data).to eq("hello world")
					
					0
				end
				
				marquise.tell "hello world".encode('ASCII-8BIT')
			end

			it "sends a non-UTF-8 string as binary" do
				Marquise::FFI.stub(:send) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(8)

					method, conn, src_f, src_v, src_c, data, len, tstamp = args
					
					expect(method).to eq(:marquise_send_binary)
					expect(conn).to eq('#tellconn')

					expect(tstamp).
					  to be_within(1_000_000_000).
					  of(Time.now.to_f * 1_000_000_000)

					expect(src_c).to eq(0)
					expect(src_f).to be(nil)
					expect(src_v).to be(nil)
					
					expect(len).to eq(1)
					expect(data).to eq("\xC0")
					
					0
				end
				
				marquise.tell "\xC0"
			end

			it "sends binary and a timestamp" do
				t = Time.now - 86400
				
				Marquise::FFI.stub(:send) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(8)

					method, conn, src_f, src_v, src_c, data, len, tstamp = args
					
					expect(method).to eq(:marquise_send_binary)
					expect(conn).to eq('#tellconn')

					expect(tstamp).to eq(t.to_f * 1_000_000_000)

					expect(src_c).to eq(0)
					expect(src_f).to be(nil)
					expect(src_v).to be(nil)
					
					expect(len).to eq("hello world".length)
					expect(data).to eq("hello world")
					
					0
				end
				
				marquise.tell "hello world".encode('ASCII-8BIT'), t
			end

			it "sends binary and tags" do
				Marquise::FFI.stub(:send) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(8)

					method, conn, src_f, src_v, src_c, data, len, tstamp = args
					
					expect(method).to eq(:marquise_send_binary)
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
					
					expect(len).to eq("hello world".length)
					expect(data).to eq("hello world")
					
					0
				end
				
				marquise.tell "hello world".encode('ASCII-8BIT'),
				              :foo => 'bar', 'answer' => 42
			end

			it "sends binary, timestamp and source" do
				t = Time.now + 86400
				
				Marquise::FFI.stub(:send) do |*args|
					expect(args).to be_an(Array)
					expect(args.length).to eq(8)

					method, conn, src_f, src_v, src_c, data, len, tstamp = args
					
					expect(method).to eq(:marquise_send_binary)
					expect(conn).to eq('#tellconn')

					expect(tstamp).to eq(t.to_f * 1_000_000_000)

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
					
					expect(len).to eq("hello world".length)
					expect(data).to eq("hello world")
					
					0
				end
				
				marquise.tell "hello world".encode('ASCII-8BIT'),
				              t,
				              :foo => 'bar', 'answer' => 42
			end
		end
	end
end
