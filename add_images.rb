require 'rubygems'
require 'xcodeproj'
project_path = 'FootballTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

images_dir = 'FootballTracker/Resources/Assets/Images'
images_group = project.main_group.find_subpath(images_dir, true)

Dir.glob("#{images_dir}/*.{jpg,jpeg,png}").each do |img_path|
  filename = File.basename(img_path)
  # Check if the file is already in the group
  file_ref = images_group.files.find { |f| f.path == filename || f.name == filename }
  unless file_ref
    file_ref = images_group.new_reference(filename)
    puts "Added reference for #{filename}"
  end
  
  # Ensure it's in the Copy Bundle Resources phase
  build_phase = target.resources_build_phase
  unless build_phase.files_references.include?(file_ref)
    build_phase.add_file_reference(file_ref)
    puts "Added #{filename} to build phase"
  end
end

project.save
puts "Saved project."
