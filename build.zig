const std = @import("std");

pub fn build( b: *std.Build ) void {
    const target = b.standardTargetOptions(  .{} );
    const optimize = b.standardOptimizeOption( .{} );

    // Create app module:
    const app_module = b.createModule(.{
        .root_source_file = b.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
    });
    // Add compile-time info constants (for app name and semantic version):
    const app_info_options = b.addOptions();
    app_info_options.addOption( u32, "major", 0 );
    app_info_options.addOption( u32, "minor", 1 );
    app_info_options.addOption( u32, "patch", 0 );
    app_info_options.addOption( []const u8, "name", "App Demo" );
    app_module.addOptions( "app_info", app_info_options );

    // Create app binary:
    const app_exe = b.addExecutable(.{
        .name = "app",
        .root_module = app_module,
    });

    // Declare and import app dependencies:
    const zglfw_dep = b.dependency( "zglfw", .{ .target = target } );
    app_exe.root_module.addImport( "zglfw", zglfw_dep.module("root") );
    app_exe.linkLibrary( zglfw_dep.artifact("glfw") );

    const zopengl_dep = b.dependency( "zopengl", .{} );
    app_exe.root_module.addImport( "zopengl", zopengl_dep.module("root") );

    const zgui_dep = b.dependency( "zgui", .{
        .target        = target,
        .backend       = .glfw_opengl3,
        .shared        = false,
        .with_freetype = false,
    });
    app_exe.root_module.addImport( "zgui", zgui_dep.module("root") );
    app_exe.linkLibrary( zgui_dep.artifact("imgui") );

    b.installArtifact( app_exe );

    // Add run step for the binary:
    const run_exe = b.addRunArtifact( app_exe );
    const run_step = b.step( "run", "Run the application" );
    run_step.dependOn( &run_exe.step );
}
