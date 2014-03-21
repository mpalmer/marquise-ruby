require 'marquise/ffi'
require 'ffi/dry/errno'

# A Vaultaire data point transport
#
# Instances of `Marquise` send data points that they are told about to a
# Vaultaire data store.  It has a very simple interface that hides a lot
# of complexity.
class Marquise
	include ::FFI::DRY::ErrnoHelper
	
	# Open a Marquise consumer and (optionally) yield it to a block
	#
	# With no associated block, `Marquise.open` is a synonym for
	# `Marquise.new`.  If the optional block is given, a newly created
	# `Marquise` object will be passed to the block, and will then be
	# automatically closed when the block terminates, and the value of
	# the block returned.
	def self.open(zmq_url, batch_period = 5)
		m = Marquise.new(zmq_url, batch_period)
		rv = m
		
		if block_given?
			begin
				rv = yield m
			ensure
				m.close
			end
		end
		
		rv
	end
	
	# Create a new `Marquise` transport object
	#
	# `zmq_url` is the URL to your ZeroMQ broker associated with the
	# Vaultaire system you're dumping data into.  `batch_period` is optional
	# (defaults to `5`) is the number of seconds between "flushes" of data
	# points to ZeroMQ.  It can be a floating-point number if you wish to
	# have sub-second flushes.  Increasing the `batch_period` increases the
	# possibility of losing data points in the event of a spectacular
	# failure, but also improves performance.
	def initialize(zmq_url, batch_period = 5)
		@consumer = Marquise::FFI.marquise_consumer_new(zmq_url, batch_period)
		
		if @consumer.nil?
			raise RuntimeError,
			      "libmarquise failed; check syslog (no, seriously)"
		end
		
		@connections = {}

		@janitor = Janitor.new(@consumer, @connections)
		ObjectSpace.define_finalizer(self, @janitor)
	end
	
	def tell(*args)
		val, ts, opts = parse_tell_opts(args)
				
		k, v, len = if opts.length == 0
			[nil, nil, 0]
		else
			[
			 Marquise::FFI.pointer_list_from_string_array(opts.keys),
			 Marquise::FFI.pointer_list_from_string_array(opts.values),
			 opts.length
			]
		end
			
		rv = if val.nil?
			Marquise::FFI.marquise_send_counter(
			                connection,
			                k,
			                v,
			                len,
			                ts.to_f * 1_000_000_000
			              )
		elsif val.respond_to? :to_str and val.respond_to? :encoding
			s = val.to_str
			method = nil
			
			if s.encoding.to_s == 'ASCII-8BIT' or !s.force_encoding('UTF-8').valid_encoding?
				method = :marquise_send_binary
			else
				method = :marquise_send_text
				s = s.encode('UTF-8')
			end

			Marquise::FFI.send(
			                method,
			                connection,
			                k,
			                v,
			                len,
			                s,
			                s.length,
			                ts.to_f * 1_000_000_000
			              )
		elsif val.respond_to? :integer? and val.integer?
			if val < -(2**63)+1 or val > (2**63)-1
				raise ArgumentError,
				      "Integer out of range for Marquise#tell"
			end
			
			Marquise::FFI.marquise_send_int(
			                connection,
			                k,
			                v,
			                len,
			                val,
			                ts.to_f * 1_000_000_000
			              )
		elsif val.respond_to? :integer? and !val.integer?
			Marquise::FFI.marquise_send_real(
			                connection,
			                k,
			                v,
			                len,
			                val,
			                ts.to_f * 1_000_000_000
			              )
		end
		
		if rv == -1
			raise errno_exception
		end
	end
	
	# Close a Marquise instance
	#
	# This must be called when you are done with your Marquise instance, to
	# avoid leaving memory and file descriptors.
	def close
		@janitor.call
		ObjectSpace.undefine_finalizer(self)
		@connections = {}
		@consumer = nil
	end
	
	# :stopdoc:
	# Initialize a connection
	#
	# You should rarely have to call this method yourself; Marquise will do
	# it automatically for you when required.
	def connect
		th = Thread.current
		
		return if @connections[th]
		
		@connections[th] = Marquise::FFI.marquise_connect(@consumer)
		
		if @connections[th].nil?
			raise RuntimeError.new("marquise_connect() failed... consult syslog (no, seriously)")
		end
		
		nil
	end
	
	# Get the connection pointer for the current thread
	def connection
		self.connect
		
		@connections[Thread.current]
	end
	
	# A helper class to cleanup Marquise consumers.  We can't just do the
	# obvious, which would be to create a Proc inside `Marquise.initialize`,
	# because that would leave a reference to the object laying around and
	# we'd never get GC'd.  So we do this instead.  I stole this technique
	# from Tempfile; blame them if this is insane.
	class Janitor
		def initialize(ptr, conns)
			@ptr = ptr
			@conns = conns
		end
		
		def call(*args)
			@conns.values.each { |c| Marquise::FFI.marquise_close(c) }
			Marquise::FFI.marquise_consumer_shutdown(@ptr)
		end
	end
	
	private
	def parse_tell_opts(args)
		orig_args = args.dup
		
		val  = nil
		ts   = Time.now
		opts = {}
		
		if ((args[0].respond_to? :to_str and args[0].respond_to? :encoding) or
		    args[0].respond_to? :integer?)
			val = args.shift
		end
		
		if args[0].is_a? Time
			ts = args.shift
		end

		if args[0].is_a? Hash
			opts = args.shift
		end
		
		unless args.empty?
			raise ArgumentError,
			      "Invalid call to Marquise#tell (you passed '#{orig_args.map(&:inspect).join(', ')}')"
		end

		[val, ts, opts]
	end
	# :startdoc:
end
