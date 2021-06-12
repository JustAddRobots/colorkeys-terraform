output "projectname" {
  value = "${var.projectname}"
}

output "image" {
  value = "${var.ecr_repo}:default-x86_64"
}  
