module Lolita # :nodoc:
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
          @orderable_scope  = options[:scope]
          self.before_save :pre_save_ordering
          self.before_destroy :pre_destroy_ordering
          self.default_scope :order => @orderable_column
          #self.validates_uniqueness_of @orderable_column, :scope => @orderable_scope
          include Lolita::Orderable::InstanceMethods
        else
          msg = "[IMPORTANT] Lolita Orderable plugin: class #{self} has missing column '#{@orderable_column}'"
          puts msg if Rails.env == "development"
          RAILS_DEFAULT_LOGGER.error msg
        end
      end

      # returns options list for :options parameter in Managed config
      def options_for_orderable
        [["",0]] + (1..self.all.size).to_a.collect{|i| [i,i]}
      end

      # updates all unordered items puts them into the end of list
      def order_unordered
        self.reset_column_information # because before this usual 'add_column' is executed and the new column isn't fetched yet
        unordered_conditions = ["#{self.orderable_column} IS NULL OR #{self.orderable_column} = 0"]
        ordered_conditions   = ["#{self.orderable_column} IS NOT NULL AND #{self.orderable_column} != 0"]
        order_nr = self.count(:conditions => ordered_conditions)
        items = self.all(:conditions => unordered_conditions)
        items.each do |item|
          order_nr += 1
          self.connection.execute("update #{self.table_name} set #{self.orderable_column} = '#{order_nr}' where id = #{item.id};")
        end
      end
    end

    module InstanceMethods
      # Moves Item to given position, if second argument == false, then it's not saved
      def move_to nr, save = true
        self[self.class.orderable_column] = nr
        self.save! if save
      end

      # returns all orderable for current scope
      # :scope works as Rails :scope option
      def all_orderable conditions = {}
        scope_conditions = []
        if scope = self.class.orderable_scope
          condition_sql = []
          condition_params = []
          Array(scope).map do |scope_item|
            scope_value = self.send(scope_item)
            condition_sql <<  self.class.send(:attribute_condition,"#{self.class.quoted_table_name}.#{scope_item}",scope_value)
            condition_params << scope_value
          end
          scope_conditions = [condition_sql.join(" AND "),*condition_params]
        end
        self.class.find(:all, :conditions => self.class.merge_conditions(conditions,scope_conditions))
      end

      private
      def pre_save_ordering
        self[self.class.orderable_column] = 0 if self[self.class.orderable_column].nil?
        if self.id
          self[self.class.orderable_column] = 1 if self[self.class.orderable_column] == 0
        else
          self[self.class.orderable_column] = self.all_orderable.size + 1 if self[self.class.orderable_column] == 0
        end
        all_orderable(["id != ?",self.id || 0]).each do |item|
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
              self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
            end
          else
            if item[self.class.orderable_column] >= self[self.class.orderable_column]
              item[self.class.orderable_column] += 1
              self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
            end
          end
        end
      end

      def pre_destroy_ordering
        all_orderable.each do |item|
          if item[self.class.orderable_column] > self[self.class.orderable_column]
            item[self.class.orderable_column] -= 1
            self.class.connection.execute("update #{self.class.table_name} set #{self.class.orderable_column} = '#{item[self.class.orderable_column]}' where id = #{item.id};")
          end
        end
      end
    end
  end
end