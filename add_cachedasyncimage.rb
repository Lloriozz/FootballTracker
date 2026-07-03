require 'xcodeproj'
project_path = 'FootballTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Check if already added
if target.source_build_phase.files.any? { |f| f.file_ref && f.file_ref.path == 'CachedAsyncImage.swift' }
  puts "Already exists"
  exit
end

group = project.main_group.find_subpath('FootballTracker/UI', false)
if group.nil?
  # Create group if not exist, relative to FootballTracker
  ft_group = project.main_group.find_subpath('FootballTracker', false)
  group = ft_group.new_group('UI', 'UI')
end

file_ref = group.new_reference('CachedAsyncImage.swift')
target.source_build_phase.add_file_reference(file_ref)
project.save
puts "Added CachedAsyncImage.swift to project"
