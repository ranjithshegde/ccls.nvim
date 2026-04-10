return {
    cmd = { "ccls" },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    offset_encoding = "utf-32",
    workspace_required = true,
    root_markers = { "compile_commands.json", "compile_flags.txt", ".ccls", ".git" },
}
