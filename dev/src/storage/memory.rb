module Storage
  # TODO: Just replace with sqlite + ActiveRecord
  class Memory
    @@data = {}

    class << self
      def clear!
        @@data = {}
      end

      def save(klass, id, object)
        id = id.to_s
        return if id.empty?

        @@data[klass] ||= {}
        @@data[klass][id] = object
      end

      def find(klass, id)
        id = id.to_s
        return if id.empty?

        @@data[klass] ||= {}
        @@data[klass][id]
      end

      def find!(klass, id)
        id = id.to_s
        return if id.empty?

        find(klass, id) || raise(ArgumentError, "#{klass} <#{id}> not found")
      end

      def keys(klass)
        @@data[klass]&.keys || []
      end
    end
  end
end
