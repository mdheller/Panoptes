class UserGroupSerializer
  include RestPack::Serializer
  attributes :id, :name, :display_name, :owner_name, :classifications_count, :created_at, :updated_at
  can_include :memberships, :users, :projects, :collections

  def owner_name
    @model.owner_uniq_name
  end
end
