require 'ffi'

class Marquise
	module FFI
		extend ::FFI::Library
		ffi_lib 'libmarquise.so.1'
		
		attach_function :marquise_consumer_new, [ :string, :double ], :pointer
		attach_function :marquise_consumer_shutdown, [ :pointer ], :void
		
		attach_function :marquise_connect, [ :pointer ], :pointer
		attach_function :marquise_close,   [ :pointer ], :void
		
		attach_function :marquise_send_text, [ :pointer,
		                                       :pointer,
		                                       :pointer,
		                                       :size_t,
		                                       :string,
		                                       :size_t,
		                                       :uint64 ],
		                                     :int
		attach_function :marquise_send_int, [ :pointer,
		                                      :pointer,
		                                      :pointer,
		                                      :size_t,
		                                      :int64,
		                                      :uint64 ],
		                                    :int
		attach_function :marquise_send_real, [ :pointer,
		                                       :pointer,
		                                       :pointer,
		                                       :size_t,
		                                       :double,
		                                       :uint64 ],
		                                     :int
		attach_function :marquise_send_counter, [ :pointer,
		                                          :pointer,
		                                          :pointer,
		                                          :size_t,
		                                          :uint64 ],
		                                        :int
		attach_function :marquise_send_binary, [ :pointer,
		                                         :pointer,
		                                         :pointer,
		                                         :size_t,
		                                         :pointer,
		                                         :size_t,
		                                         :uint64 ],
		                                       :int

		# Common helper to take an array of strings (or things that we'll turn
		# into strings) and turn it into an FFI::MemoryPointer containing
		# FFI::MemoryPointers for each string.
		def self.pointer_list_from_string_array(ary)
			ptrs = []
			ary.each { |e| ptrs << ::FFI::MemoryPointer.from_string(e.to_s) }
			ptrs << nil
			
			ptr = ::FFI::MemoryPointer.new(:pointer, ptrs.length)
			ptrs.each_with_index { |p, i| ptr[i].write_pointer(p) }
			
			ptr
		end
	end
end
