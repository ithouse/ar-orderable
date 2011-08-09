require 'ar_orderable'
ActiveRecord::Base.send(:include, ActiveRecord::Orderable)