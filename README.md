## Activerecord::Orderable

Rails 3 plugin for simple ordering through one order field, main difference from other plugins - on order change it executes plain sql without triggering model save.


### Example

1. Add order field, like "order_nr" as integer
2. In model add line "acts_as_orderable" and if needed add :column => "my_orderfield_name".
3. If your table already has some rows of data then use the 'order_unordered' after adding new column:

Example migration:

    add_column :categories, :order_nr, :integer
    Category.order_unordered # remove this for new table
    add_index :categories, :order_nr

To reorder items use the `move_to(<integer>)`, `move_up` and `move_down` methods, for example:

    item = Item.find 1
    item.move_to 3 # moved to 3rd position
    item.move_up # moved to 2rd position
    item.move_down # moved to 3d position

### Tests

    rspec spec # all examples should be green

Copyright (c) 2009 IT House, released under the MIT license