# Script XSCT para T6: crear y compilar el FSBL de Zynq desde el XSA exportado.
# Ejecutar desde la raiz del repositorio tras cargar settings64.sh de Vitis 2022.2.

set repo_root [file normalize [pwd]]
set workspace_dir [file join $repo_root sw vitis workspace]
set xsa_file [file join $repo_root artifacts hw tfg_zedboard.xsa]
set boot_dir [file join $repo_root artifacts boot]

set platform_name tfg_zedboard_platform
set app_name tfg_zedboard_fsbl
set domain_name standalone_domain
set clean_workspace 1

if {![file exists $xsa_file]} {
    error "XSA not found: $xsa_file"
}

if {$clean_workspace && [file exists $workspace_dir]} {
    puts "Eliminando workspace previo generado por T6: $workspace_dir"
    file delete -force $workspace_dir
}

file mkdir $workspace_dir
file mkdir $boot_dir

setws $workspace_dir

puts "Creando plataforma desde XSA: $xsa_file"
platform create \
    -name $platform_name \
    -hw $xsa_file \
    -proc ps7_cortexa9_0 \
    -os standalone

platform active $platform_name
domain active $domain_name

puts "Activando libreria xilffs en el BSP standalone"
bsp setlib -name xilffs

puts "Generando plataforma: $platform_name"
platform generate

puts "Creando aplicacion FSBL: $app_name"
app create \
    -name $app_name \
    -platform $platform_name \
    -domain $domain_name \
    -template "Zynq FSBL"

puts "Compilando aplicacion FSBL: $app_name"
app build -name $app_name

set fsbl_elf [file join $workspace_dir $app_name Debug "${app_name}.elf"]
set output_fsbl [file join $boot_dir fsbl.elf]

if {![file exists $fsbl_elf]} {
    error "No se genero el ELF del FSBL en la ruta esperada: $fsbl_elf"
}

file copy -force $fsbl_elf $output_fsbl

puts "FSBL copiado en: $output_fsbl"
