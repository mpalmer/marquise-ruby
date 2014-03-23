require_relative './spec_helper'
require 'marquise'

describe Marquise do
	describe "#tell" do
		let(:marquise) do
			Marquise::FFI.
			  should_receive(:marquise_consumer_new).
			  with('tcp://localhost:4567', 5).
			  and_return('#tell')

			x = Marquise.new('tcp://localhost:4567')
			# Neuter the Marquise
			ObjectSpace.undefine_finalizer(x)
			
			x
		end
		
		it "fails if an unknown type of value is passed" do
			expect { marquise.tell [1, 2, 3] }.
			  to raise_error(
			       ArgumentError,
			       /Invalid call to Marquise#tell/
			     )
		end

		it "assplodes if #close has previously been called" do
			Marquise::FFI.
			  should_receive(:marquise_consumer_shutdown).
			  with('#tell')

			marquise.close

			expect { marquise.tell }.
			  to raise_error(
			       IOError,
			       /Connection has been closed/
			     )
		end
	end
end
