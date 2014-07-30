class AddIndexOnIid < ActiveRecord::Migration
  def change
    RemoveDuplicateIid.clean(self, Issue)
    RemoveDuplicateIid.clean(self, MergeRequest, 'target_project_id')
    RemoveDuplicateIid.clean(self, Milestone)

    add_index :issues, [:project_id, :iid], unique: true
    add_index :merge_requests, [:target_project_id, :iid], unique: true
    add_index :milestones, [:project_id, :iid], unique: true
  end
end

class RemoveDuplicateIid
  def self.clean(migration, klass, project_field = 'project_id')
    duplicates = klass.find_by_sql("SELECT iid, #{project_field} FROM #{klass.table_name} GROUP BY #{project_field}, iid HAVING COUNT(*) > 1")

    migration.say_with_time("Remove Duplicate Iid") do
      duplicates.each do |duplicate|
        project_id = duplicate.send(project_field)
        iid = duplicate.iid
        items = klass.of_projects(project_id).where(iid: iid)

        if items.size > 1
          migration.say "Remove #{klass.name} duplicates for iid: #{iid} and project_id: #{project_id}"
          items.shift
          items.each do |item|
            item.destroy
            puts '.'
          end
        end
      end
    end
  end
end
