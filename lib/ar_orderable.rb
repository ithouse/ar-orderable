module ActiveRecord # :nodoc:
  module Orderable # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_reader :orderable_column
      attr_accessor :orderable_scope

      # @:column [string] column name
      # acts_as_orderable :column => "order_nr"
      def acts_as_orderable options = {}
        @orderable_column = options[:column] ? options[:column].to_s : "order_nr"
        if self.columns_hash.keys.include? @orderable_column
          @orderable_scope  = options[:scope] or self.respond_to?(:custom_columns_to_localize) ? [:locale] : nil
          self.before_save :pre_save_ordering
          self.before_destroy :pre_destroy_ordering
          self.default_scope :order => @orderable_column
          #self.validates_uniqueness_of @orderable_column, :scope => @orderable_scope
          include ActiveRecord::Orderable::InstanceMethods
        else
          msg = "[IMPORTANT] ActiveRecord::Orderable plugin: class #{self} has missing column '#{@orderable_column}'"
          puts msg if Rails.env == "development"
          RAILS_DEFAULT_LOGGER.error msg
        end
      end

      # updates all unordered items puts them into the end of list
      def order_unordered
        self.reset_column_information # because before this usual 'add_column' is executed and the new column isn't fetched yet
        self.group(self.orderable_scope).each do |obj|
          unordered_conditions = "#{self.orderable_column} IS NULL OR #{self.table_name}.#{self.orderable_column} = 0"
          ordered_conditions   = "#{self.orderable_column} IS NOT NULL AND #{self.table_name}.#{self.orderable_column} != 0"
          order_nr = obj.all_orderable.order(@orderable_column).last[@orderable_column] || 0
          obj.all_orderable.where(unordered_conditions).each do |item|
            order_nr += 1
            self.connection.execute("update #{self.table_name} set #{self.orderable_column} = '#{order_nr}' where #{self.table_name}.id = #{item.id};")
          end
        end
      end
    end

    module InstanceMethods
      
      # Moves Item to given position
      def move_to nr
        self.update_attribute(self.class.orderable_column, nr)
      end

      def move_up
        move_to(self[self.class.orderable_column] - 1) if self[self.class.orderable_column]
      end

      def move_down
        move_to(self[self.class.orderable_column] + 1) if self[self.class.orderable_column]
      end

      def all_orderable
        if self.class.orderable_scope
          self.class.where(:"#{self.class.orderable_scope}" => self[self.class.orderable_scope])
        else
          self.class.where
        end
      end

      private

      def pre_save_ordering
        self[self.class.orderable_column] = 0 if self[self.class.orderable_column].nil?
        if self.id
          if self[self.class.orderable_column] == 0
            self[self.class.orderable_column] = 1
          end
          if self[self.class.orderable_column] > self.all_orderable.count
            self[self.class.orderable_column] = self[self.class.orderable_column] -1
          end
        else
          self[self.class.orderable_column] = self.all_orderable.count + 1 if self[self.class.orderable_column] == 0
        end
        self.all_orderable.where(["#{self.class.table_name}.id != ?",self.id || 0]).each do |item|
          item[self.class.orderable_column] = 0 if item[self.class.orderable_column].nil?
          if self.id
            if item[self.class.orderable_column] > (self.send("#{self.class.orderable_column}_was") || 0 )
              if item[self.class.orderable_column] <= self[self.class.orderable_column]
                item[self.class.orderable_column] -= 1
              end
            else
              if item[self.class.orderable_column] >= self[self.class.orderable_column]
                item[self.class.orderable_column] += 1
              end
            end
            
            if item[self.class.orderable_column] != item.send("#{self.class.orderable_column}_was")
              self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where #{self.class.table_name}.id = #{item.id};")
            end
          else
            if item[self.class.orderable_column] >= self[self.class.orderable_column]
              item[self.class.orderable_column] += 1
              self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where #{self.class.table_name}.id = #{item.id};")
            end
          end
        end
      end

      def pre_destroy_ordering
        self.all_orderable.each do |item|
          if item[self.class.orderable_column] > self[self.class.orderable_column]
            item[self.class.orderable_column] -= 1
            self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where #{self.class.table_name}.id = #{item.id};")
          end
        end
      end
    end
  end
end
