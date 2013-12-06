## Activerecord::Orderable

Rails 3 plugin for simple ordering.

### Install

Insert into your `Gemfile`:

    gem "ar-orderable"

then `bundle install`

### Setup

1. Add order field, like `order_nr` as integer
2. In model add line `acts_as_orderable` and if needed add options
	- `column: "my_custom_order_field" # default it's order_nr`
	- `scope: :locale # to order in some scope, you can add also as array [:locale, :some_type]`
3. If your table already has some rows of data then call the `YourModel.order_unordered` after adding new column.

Example migration:

    add_column :categories, :order_nr, :integer # change to your column name
    Category.order_unordered # remove this for new table
    add_index :categories, :order_nr

### Examples

To reorder items use the `move_to(<integer>)`, `move_up` and `move_down` methods, for example:

    item.move_to 3 # moved to 3rd position
    item.move_up # moved to 2rd position
    item.move_down # moved to 3d position

To skip model callbacks and just update order information you can specify `:skip_callbacks => true` option:

    # in your model
    acts_as_orderable :skip_callbacks => true

    # or whenever you call one of the ordering methods
    item.move_to 3, :skip_callbacks => true
    item.move_up :skip_callbacks => true
    item.move_down :skip_callbacks => true

### Tests

    rspec spec # all examples should be green

Copyright (c) 2009 IT House, released under the MIT license
