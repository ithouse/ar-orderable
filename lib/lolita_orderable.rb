module Lolita # :nodoc:
  module Orderable # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :orderable_column
      # @:column [string] column name
      # acts_as_orderable :column => "order_nr"
      def acts_as_orderable options = {}
        @orderable_column = options[:column] ? options[:column] : "order_nr"
        self.before_save :pre_save_ordering
        self.before_destroy :pre_destroy_ordering
        self.default_scope :order => @orderable_column
        include Lolita::Orderable::InstanceMethods
      end

      # returns options list for :options parameter in Managed config
      def options_for_orderable
        [["",0]] + (1..self.count).to_a.collect{|i| [i,i]}
      end
    end

    module InstanceMethods
      # Moves Item to given position, if second argument == false, then it's not saved
      def move_to order_nr, save = true
        self[self.class.orderable_column] = order_nr
        self.save if save
      end
      
      private
      def pre_save_ordering
        self[self.class.orderable_column] = 0 if self[self.class.orderable_column].nil?
        if self.id
          self[self.class.orderable_column] = 1 if self[self.class.orderable_column] == 0
          old_order_nr = self.class.find(self.id)[self.class.orderable_column]
        else
          self[self.class.orderable_column] = self.class.count + 1 if self[self.class.orderable_column] == 0
          old_order_nr = nil
        end
        self.class.all.each do |item|
          if old_order_nr
            if item.id != self.id
              if self[self.class.orderable_column] > old_order_nr
                if item[self.class.orderable_column] <= self[self.class.orderable_column] && item[self.class.orderable_column] > old_order_nr
                  item[self.class.orderable_column] -= 1
                end
              else
                if item[self.class.orderable_column] >= self[self.class.orderable_column] && item[self.class.orderable_column] < old_order_nr
                  item[self.class.orderable_column] += 1
                end
              end
              ActiveRecord::Base.connection().execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
            end
          else
            if item[self.class.orderable_column] >= self[self.class.orderable_column]
              item.order_nr += 1
              ActiveRecord::Base.connection().execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
            end
          end
        end
      end

      def pre_destroy_ordering
        self.class.all.each do |item|
          if item[self.class.orderable_column] > self[self.class.orderable_column]
            item.order_nr -= 1
            ActiveRecord::Base.connection().execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
          end
        end
      end
    end
  end
end