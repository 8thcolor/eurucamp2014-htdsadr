class AddIndexToForkedProjectLinks < ActiveRecord::Migration
  def change
    add_index :forked_project_links, :forked_from_project_id
  end
end
