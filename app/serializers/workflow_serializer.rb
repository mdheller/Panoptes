class WorkflowSerializer
  include RestPack::Serializer
  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise
  
  can_include :project, :subject_sets, :tutorial_subject, :expert_subject_set

  def version
    "#{@model.versions.last.id}.#{content.versions.last.id}"
  end

  def content_language
    content.language
  end

  def tasks
    tasks = @model.tasks.dup
    TasksVisitors::InjectStrings.new(content.strings).visit(tasks)
    tasks
  end

  def content
    languages = @context[:languages] || [@model.primary_language]
    @content = @model.content_for(languages, [:strings, :language, :id])
  end
end
