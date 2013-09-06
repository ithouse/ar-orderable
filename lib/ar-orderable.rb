module ActiveRecord
  module Orderable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :orderable_scope, :orderable_column, :skip_callbacks_for_orderable

      # @:column [string] column name
      # acts_as_orderable :column => "order_nr"
      def acts_as_orderable options = {}
        return unless self.connection.table_exists?(self.table_name)
        self.orderable_column = (options[:column] || "order_nr").to_s
        self.skip_callbacks_for_orderable = options[:skip_callbacks]
        if self.columns_hash.keys.include? self.orderable_column
          self.orderable_scope  = options[:scope]
          self.before_save :pre_save_ordering
          self.before_destroy :pre_destroy_ordering
          self.default_scope { order(self.orderable_column) }
          #self.validates_uniqueness_of self.orderable_column, :scope => @orderable_scope
          include ActiveRecord::Orderable::InstanceMethods
        else
          msg = "[IMPORTANT] ActiveRecord::Orderable plugin: class #{self} has missing column '#{self.orderable_column}'"
          if defined?(RAILS_DEFAULT_LOGGER)
            RAILS_DEFAULT_LOGGER.error msg
          elsif defined?(Rails.logger)
            Rails.logger.error msg
          elsif Rails.env == "development"
            puts msg
          end
        end
      end

      # updates all unordered items puts them into the end of list
      def order_unordered
        self.reset_column_information # because before this usual 'add_column' is executed and the new column isn't fetched yet
        self.group(self.orderable_scope).each do |obj|
          unordered_conditions = "#{self.orderable_column} IS NULL OR #{self.table_name}.#{self.orderable_column} = 0"
          ordered_conditions   = "#{self.orderable_column} IS NOT NULL AND #{self.table_name}.#{self.orderable_column} != 0"
          order_nr = obj.all_orderable.order(self.orderable_column).last[self.orderable_column] || 0
          obj.all_orderable.where(unordered_conditions).each do |item|
            order_nr += 1
            raw_orderable_update(item.id, order_nr)
          end
        end
      end

      def raw_orderable_update id, nr
        self.connection.execute("update #{self.table_name} set #{self.orderable_column} = #{nr.to_i} where #{self.table_name}.id = #{id.to_i};")
      end
    end

    module InstanceMethods

      # Moves Item to given position
      def move_to nr, options = {}
        if options[:skip_callbacks].nil? ? self.class.skip_callbacks_for_orderable : options[:skip_callbacks]
          self[self.class.orderable_column] = nr
          self.send(:pre_save_ordering)
          self.class.raw_orderable_update(self.id, nr)
        else
          self.update_attribute(self.class.orderable_column, nr)
        end
      end

      def move_up options = {}
        move_to(self[self.class.orderable_column] - 1, options) if self[self.class.orderable_column]
      end

      def move_down options = {}
        move_to(self[self.class.orderable_column] + 1, options) if self[self.class.orderable_column]
      end

      def all_orderable
        if self.class.orderable_scope
          self.class.where(:"#{self.class.orderable_scope}" => self[self.class.orderable_scope])
        else
          self.class.scoped
        end
      end

      private

      def pre_save_ordering
        column_name = self.class.orderable_column
        self[column_name] = 0 if self[column_name].nil?
        if self.id
          if self[column_name] == 0
            self[column_name] = 1
          end
          if self[column_name] > self.all_orderable.count
            self[column_name] = self[column_name] -1
          end
        else
          self[column_name] = self.all_orderable.count + 1 if self[column_name].to_i == 0
        end

        return unless self.all_orderable.where("id != ? and #{column_name} = ?", self.id, self[column_name]).count > 0
        self.all_orderable.where("#{self.class.table_name}.id != ?",self.id || 0).each do |item|
          item[column_name] = 0 if item[column_name].nil?
          if self.id
            if item[column_name] > (self.send("#{column_name}_was") || 0 )
              if item[column_name] <= self[column_name]
                item[column_name] -= 1
              end
            else
              if item[column_name] >= self[column_name]
                item[column_name] += 1
              end
            end

            if item[column_name] != item.send("#{column_name}_was")
              self.class.raw_orderable_update(item.id, item[column_name])
            end
          else
            if item[column_name] >= self[column_name]
              item[column_name] += 1
              self.class.raw_orderable_update(item.id, item[column_name])
            end
          end
        end
      end

      def pre_destroy_ordering
        self.all_orderable.each do |item|
          if item[self.class.orderable_column].to_i > self[self.class.orderable_column].to_i
            item[self.class.orderable_column] -= 1
            self.class.raw_orderable_update(item.id, item[self.class.orderable_column])
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include ActiveRecord::Orderable }
